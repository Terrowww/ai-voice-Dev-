#!/data/data/com.termux/files/usr/bin/bash
set -e
D=~/voicecall/app/src/main/java/com/example/voicecall
G=~/voicecall/app/build.gradle.kts
M=~/voicecall/app/src/main/AndroidManifest.xml

# 1) Зависимость WebRTC и только arm64 (чтобы APK не раздулся)
grep -q "stream-webrtc-android" $G || sed -i 's|^dependencies {|dependencies {\n    implementation("io.getstream:stream-webrtc-android:1.3.10")|' $G
grep -q "abiFilters" $G || sed -i 's|        versionName = "0.1"|        versionName = "0.1"\n        ndk { abiFilters += listOf("arm64-v8a") }|' $G

# 2) Разрешение на состояние сети (нужно WebRTC)
grep -q "ACCESS_NETWORK_STATE" $M || sed -i 's|<application|<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n    <application|' $M

# 3) Signaling: теперь только вход, свой номер и слушатель входящих
cat > $D/Signaling.kt <<'EOF'
package com.example.voicecall

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

// 10 цифр -> "123 456 78 90", чтобы выглядело как номер
fun fmtNumber(d: String): String =
    if (d.length == 10) "${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8)}" else d

// Вход в Firebase, свой номер, слежение за входящими
class Signaling(ctx: Context) {
    private val prefs = ctx.getSharedPreferences("vc", Context.MODE_PRIVATE)
    val db = FirebaseDatabase
        .getInstance("https://voicecall-62a00-default-rtdb.europe-west1.firebasedatabase.app")
        .reference

    // свой номер: 10 цифр, создаётся один раз и запоминается (внутренний номер приложения)
    val myNumber: String = prefs.getString("num", null)
        ?: (1000000000L + (java.util.Random().nextDouble() * 8999999999L).toLong()).toString()
            .also { prefs.edit().putString("num", it).apply() }

    var status by mutableStateOf("подключение...")
    var incomingFrom by mutableStateOf<String?>(null)
    var incomingOffer by mutableStateOf<String?>(null)

    fun start() {
        FirebaseAuth.getInstance().signInAnonymously()
            .addOnSuccessListener {
                status = "онлайн"
                db.child("users").child(myNumber).setValue(it.user?.uid)
                listen()
            }
            .addOnFailureListener { status = "ошибка: ${it.message}" }
    }

    // входящий = у нас по адресу calls/МОЙ_НОМЕР есть и "from", и "offer"
    private fun listen() {
        db.child("calls").child(myNumber).addValueEventListener(object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                val from = s.child("from").getValue(String::class.java)
                val offer = s.child("offer").getValue(String::class.java)
                incomingOffer = offer
                incomingFrom = if (offer != null) from else null
            }
            override fun onCancelled(e: DatabaseError) {
                status = "ошибка: ${e.message}"
            }
        })
    }

    // отклонить / завершить: удаляем звонок целиком, второй телефон это увидит
    fun clearIncoming() {
        db.child("calls").child(myNumber).removeValue()
    }
}
EOF

# 4) CallEngine: сам разговор через WebRTC
cat > $D/CallEngine.kt <<'EOF'
package com.example.voicecall

import android.content.Context
import android.media.AudioManager
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.firebase.database.ChildEventListener
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.ServerValue
import com.google.firebase.database.ValueEventListener
import org.webrtc.AudioTrack
import org.webrtc.DataChannel
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription
import org.webrtc.audio.JavaAudioDeviceModule

open class SdpAdapter : SdpObserver {
    override fun onCreateSuccess(sdp: SessionDescription?) {}
    override fun onSetSuccess() {}
    override fun onCreateFailure(error: String?) {}
    override fun onSetFailure(error: String?) {}
}

/**
 * Звонок между двумя телефонами. Все "записки" лежат в Firebase по адресу calls/НОМЕР_ТОГО_КОМУ_ЗВОНЯТ:
 *   from, offer       - кладёт звонящий
 *   answer            - кладёт тот, кто взял трубку
 *   callerIce/calleeIce - данные для соединения от каждой стороны
 * Кто угодно кладёт трубку = удаляет calls/НОМЕР, второй телефон видит это и завершает звонок.
 */
class CallEngine(ctx: Context, private val sig: Signaling) {
    private val app = ctx.applicationContext
    private val audioManager = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var factory: PeerConnectionFactory? = null
    private var pc: PeerConnection? = null
    private var track: AudioTrack? = null
    private var node: DatabaseReference? = null
    private var isCaller = false
    private var remoteSet = false
    private val pending = mutableListOf<IceCandidate>()
    private val regs = mutableListOf<() -> Unit>()

    var connected by mutableStateOf(false)
    var onEnded: () -> Unit = {}

    private fun factory(): PeerConnectionFactory {
        factory?.let { return it }
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(app).createInitializationOptions()
        )
        val adm = JavaAudioDeviceModule.builder(app).createAudioDeviceModule()
        return PeerConnectionFactory.builder()
            .setAudioDeviceModule(adm)
            .createPeerConnectionFactory()
            .also { factory = it }
    }

    private val observer = object : PeerConnection.Observer {
        override fun onSignalingChange(s: PeerConnection.SignalingState?) {}
        override fun onIceConnectionChange(s: PeerConnection.IceConnectionState?) {
            when (s) {
                PeerConnection.IceConnectionState.CONNECTED,
                PeerConnection.IceConnectionState.COMPLETED -> connected = true
                PeerConnection.IceConnectionState.FAILED -> finish()
                else -> {}
            }
        }
        override fun onIceConnectionReceivingChange(b: Boolean) {}
        override fun onIceGatheringChange(s: PeerConnection.IceGatheringState?) {}
        override fun onIceCandidate(c: IceCandidate?) {
            if (c == null) return
            val key = if (isCaller) "callerIce" else "calleeIce"
            node?.child(key)?.push()?.setValue(
                mapOf("mid" to c.sdpMid, "idx" to c.sdpMLineIndex, "sdp" to c.sdp)
            )
        }
        override fun onIceCandidatesRemoved(c: Array<out IceCandidate>?) {}
        override fun onAddStream(s: MediaStream?) {}
        override fun onRemoveStream(s: MediaStream?) {}
        override fun onDataChannel(d: DataChannel?) {}
        override fun onRenegotiationNeeded() {}
    }

    private fun newPc(): PeerConnection {
        val f = factory()
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        val cfg = PeerConnection.RTCConfiguration(
            listOf(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())
        )
        cfg.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
        val p = f.createPeerConnection(cfg, observer)!!
        val src = f.createAudioSource(MediaConstraints())
        val t = f.createAudioTrack("audio0", src)
        p.addTrack(t, listOf("stream0"))
        track = t
        return p
    }

    private fun audioConstraints() = MediaConstraints().apply {
        mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
    }

    // ---- звонящий ----
    fun startCall(to: String) {
        if (to.isEmpty() || pc != null) return
        isCaller = true
        remoteSet = false
        pending.clear()
        connected = false
        val ref = sig.db.child("calls").child(to)
        node = ref
        // сначала чистим старые остатки, потом начинаем
        ref.removeValue().addOnCompleteListener {
            if (node == null) return@addOnCompleteListener
            val p = newPc()
            pc = p
            p.createOffer(object : SdpAdapter() {
                override fun onCreateSuccess(sdp: SessionDescription?) {
                    if (sdp == null) return
                    p.setLocalDescription(SdpAdapter(), sdp)
                    ref.updateChildren(
                        mapOf(
                            "from" to sig.myNumber,
                            "offer" to sdp.description,
                            "ts" to ServerValue.TIMESTAMP
                        )
                    )
                    watch()
                    listenIce()
                    listenAnswer()
                }
            }, audioConstraints())
        }
    }

    // ---- тот, кому звонят, взял трубку ----
    fun accept(offer: String) {
        if (pc != null) return
        isCaller = false
        remoteSet = false
        pending.clear()
        connected = false
        val ref = sig.db.child("calls").child(sig.myNumber)
        node = ref
        val p = newPc()
        pc = p
        watch()
        listenIce()
        p.setRemoteDescription(object : SdpAdapter() {
            override fun onSetSuccess() {
                remoteSet = true
                flushPending()
                p.createAnswer(object : SdpAdapter() {
                    override fun onCreateSuccess(sdp: SessionDescription?) {
                        if (sdp == null) return
                        p.setLocalDescription(SdpAdapter(), sdp)
                        ref.child("answer").setValue(sdp.description)
                    }
                }, audioConstraints())
            }
        }, SessionDescription(SessionDescription.Type.OFFER, offer))
    }

    // ---- Firebase: слежение ----
    private fun listenAnswer() {
        val ref = node?.child("answer") ?: return
        val l = object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                val sdp = s.value as? String ?: return
                if (remoteSet) return
                pc?.setRemoteDescription(object : SdpAdapter() {
                    override fun onSetSuccess() {
                        remoteSet = true
                        flushPending()
                    }
                }, SessionDescription(SessionDescription.Type.ANSWER, sdp))
            }
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addValueEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    private fun listenIce() {
        val key = if (isCaller) "calleeIce" else "callerIce"
        val ref = node?.child(key) ?: return
        val l = object : ChildEventListener {
            override fun onChildAdded(s: DataSnapshot, prev: String?) {
                val mid = s.child("mid").value as? String
                val idx = (s.child("idx").value as? Long)?.toInt() ?: 0
                val sdp = s.child("sdp").value as? String ?: return
                addRemoteIce(IceCandidate(mid, idx, sdp))
            }
            override fun onChildChanged(s: DataSnapshot, prev: String?) {}
            override fun onChildRemoved(s: DataSnapshot) {}
            override fun onChildMoved(s: DataSnapshot, prev: String?) {}
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addChildEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    // если звонок удалили из базы, значит второй положил трубку
    private fun watch() {
        val ref = node ?: return
        var seen = false
        val l = object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                if (s.exists()) seen = true else if (seen) finish()
            }
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addValueEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    private fun addRemoteIce(c: IceCandidate) {
        if (remoteSet) pc?.addIceCandidate(c) else pending.add(c)
    }

    private fun flushPending() {
        val list = pending.toList()
        pending.clear()
        list.forEach { pc?.addIceCandidate(it) }
    }

    // ---- завершение ----
    fun hangup() {
        node?.removeValue()
        cleanup()
    }

    private fun finish() {
        val had = pc != null
        cleanup()
        if (had) onEnded()
    }

    private fun cleanup() {
        regs.forEach { it() }
        regs.clear()
        pc?.close()
        pc?.dispose()
        pc = null
        track = null
        node = null
        connected = false
        audioManager.isSpeakerphoneOn = false
        audioManager.mode = AudioManager.MODE_NORMAL
    }

    fun mute(m: Boolean) { track?.setEnabled(!m) }
    fun speaker(on: Boolean) { audioManager.isSpeakerphoneOn = on }
}
EOF

# 5) CallScreen: таймер и "Вызов..." теперь от настоящего соединения
cat > $D/CallScreen.kt <<'EOF'
package com.example.voicecall

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun CallScreen(
    name: String,
    number: String,
    vs: VoiceState,
    live: Boolean,
    onMute: (Boolean) -> Unit,
    onSpeaker: (Boolean) -> Unit,
    onEnd: () -> Unit
) {
    var seconds by remember { mutableIntStateOf(0) }
    var muted by remember { mutableStateOf(false) }
    var speaker by remember { mutableStateOf(false) }
    val connected = live

    LaunchedEffect(live) {
        seconds = 0
        if (live) {
            while (true) { delay(1000); seconds++ }
        }
    }
    val time = "%02d:%02d".format(seconds / 60, seconds % 60)

    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(listOf(Color(0xFF0B0B14), Color(0xFF3A1A30), Color(0xFF7A7F9A)))
        )
    ) {
        Column(
            Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(40.dp))
            Text(
                if (connected) "HD  $time" else "Вызов...",
                color = Color.White, fontSize = 22.sp
            )
            Spacer(Modifier.height(80.dp))
            Text(name, color = Color.White, fontSize = 44.sp, fontWeight = FontWeight.Medium)
            Text("Мобильный телефон  $number", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.weight(1f))

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                CallButton(if (connected) time else "Записать", connected, onClick = {}) {
                    IconVoicemail(if (connected) Color(0xFF1FA463) else Color.White)
                }
                CallButton("Выключить\nмикрофон", muted, onClick = {
                    muted = !muted
                    vs.engine.muted = muted
                    onMute(muted)
                }) { IconMic(if (muted) Color.Black else Color.White) }
                CallButton("Bluetooth", false, onClick = {}) { IconBluetooth(Color.White) }
            }
            Spacer(Modifier.height(20.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                CallButton("Динамик", speaker, onClick = {
                    speaker = !speaker
                    onSpeaker(speaker)
                }) {
                    IconSpeaker(if (speaker) Color.Black else Color.White)
                }
                CallButton("Клавиатура", false, onClick = {}) { IconKeypad(Color.White) }
                CallButton("Еще", false, onClick = {}) { IconMore(Color.White) }
            }

            Spacer(Modifier.height(32.dp))
            Box(
                Modifier.size(80.dp).clip(CircleShape).background(Color(0xFFDB3A34)).clickable { onEnd() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Call, null, tint = Color.White,
                    modifier = Modifier.size(34.dp).rotate(135f)
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
fun CallButton(label: String, active: Boolean, onClick: () -> Unit, icon: @Composable () -> Unit) {
    Column(Modifier.width(100.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(72.dp).clip(RoundedCornerShape(26.dp))
                .background(if (active) Color(0xFFE4E4EA) else Color(0x44FFFFFF))
                .clickable { onClick() },
            contentAlignment = Alignment.Center
        ) { icon() }
        Spacer(Modifier.height(6.dp))
        Text(label, color = Color.White, fontSize = 13.sp, textAlign = TextAlign.Center)
    }
}
EOF

# 6) MainActivity: запрос микрофона, настоящий звонок и сброс
cat > $D/MainActivity.kt <<'EOF'
package com.example.voicecall

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
        )
        setContent { AppRoot() }
    }
}

sealed class Screen {
    data object Main : Screen()
    data object Voice : Screen()
    data class Call(val name: String, val number: String) : Screen()
}

class VoiceState {
    val engine = AudioEngine()
    var voiceOn by mutableStateOf(false)
    var preset by mutableFloatStateOf(0.84f)
    var listening by mutableStateOf(false)
    var latency by mutableIntStateOf(0)
    fun apply() { engine.ratio = if (voiceOn) preset else 1f }
}

@Composable
fun AppRoot() {
    val vs = remember { VoiceState() }
    val ctx = LocalContext.current
    val sig = remember { Signaling(ctx) }
    val engine = remember { CallEngine(ctx, sig) }
    var screen by remember { mutableStateOf<Screen>(Screen.Main) }

    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }
    LaunchedEffect(Unit) {
        sig.start()
        engine.onEnded = { screen = Screen.Main }
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            permLauncher.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    val view = LocalView.current
    val incoming = sig.incomingFrom
    val showIncoming = incoming != null && screen !is Screen.Call
    val dark = screen is Screen.Call || showIncoming

    SideEffect {
        val window = (view.context as Activity).window
        val c = WindowCompat.getInsetsController(window, view)
        c.isAppearanceLightStatusBars = !dark
        c.isAppearanceLightNavigationBars = !dark
    }
    DisposableEffect(Unit) { onDispose { vs.engine.stop() } }
    BackHandler(enabled = screen !is Screen.Main) {
        if (screen is Screen.Call) engine.hangup()
        screen = Screen.Main
    }

    Box(Modifier.fillMaxSize()) {
        when (val s = screen) {
            is Screen.Main -> PhoneScreen(
                onCall = { n, num ->
                    val digits = num.filter { it.isDigit() }
                    if (digits.length >= 7) engine.startCall(digits)
                    screen = Screen.Call(if (digits.length == 10) fmtNumber(digits) else n, num)
                },
                onVoice = { screen = Screen.Voice }
            )
            is Screen.Voice -> VoiceSettingsScreen(vs) { screen = Screen.Main }
            is Screen.Call -> CallScreen(
                name = s.name,
                number = s.number,
                vs = vs,
                live = engine.connected,
                onMute = { engine.mute(it) },
                onSpeaker = { engine.speaker(it) },
                onEnd = {
                    engine.hangup()
                    screen = Screen.Main
                }
            )
        }

        // свой номер виден только в настройках голоса
        if (screen is Screen.Voice) {
            Text(
                "Мой номер: ${fmtNumber(sig.myNumber)} · ${sig.status}",
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(bottom = 12.dp),
                color = Color.Gray,
                fontSize = 14.sp
            )
        }

        // входящий вызов: полный экран как у системной звонилки
        if (showIncoming && incoming != null) {
            val offer = sig.incomingOffer
            IncomingScreen(
                number = fmtNumber(incoming),
                onAccept = {
                    if (offer != null) engine.accept(offer)
                    screen = Screen.Call(fmtNumber(incoming), incoming)
                },
                onDecline = { sig.clearIncoming() }
            )
        }
    }
}
EOF

cd ~/voicecall && git add -A && git commit -m "update6 webrtc call" && git push
