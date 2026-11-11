#!/data/data/com.termux/files/usr/bin/bash
set -e
D=~/voicecall/app/src/main/java/com/example/voicecall

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
import com.google.firebase.database.ServerValue
import com.google.firebase.database.ValueEventListener

// "Почта" между телефонами: вход в Firebase, свой код, записка о звонке
class Signaling(ctx: Context) {
    private val prefs = ctx.getSharedPreferences("vc", Context.MODE_PRIVATE)
    private val db = FirebaseDatabase
        .getInstance("https://voicecall-62a00-default-rtdb.europe-west1.firebasedatabase.app")
        .reference

    // свой код: 4 цифры, создаётся один раз и запоминается
    val myCode: String = prefs.getString("code", null)
        ?: (1000 + java.util.Random().nextInt(9000)).toString()
            .also { prefs.edit().putString("code", it).apply() }

    var status by mutableStateOf("подключение...")
    var incomingFrom by mutableStateOf<String?>(null)

    fun start() {
        FirebaseAuth.getInstance().signInAnonymously()
            .addOnSuccessListener {
                status = "онлайн"
                db.child("users").child(myCode).setValue(it.user?.uid)
                listen()
            }
            .addOnFailureListener { status = "ошибка: ${it.message}" }
    }

    // слушаем записки, адресованные нам
    private fun listen() {
        db.child("calls").child(myCode).addValueEventListener(object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                incomingFrom = s.child("from").getValue(String::class.java)
            }
            override fun onCancelled(e: DatabaseError) {
                status = "ошибка: ${e.message}"
            }
        })
    }

    // кладём записку "звонит такой-то" на код второго телефона
    fun call(to: String) {
        if (to.isEmpty()) return
        db.child("calls").child(to).setValue(
            mapOf("from" to myCode, "ts" to ServerValue.TIMESTAMP)
        )
    }

    fun clearIncoming() {
        db.child("calls").child(myCode).removeValue()
    }
}
EOF

cat > $D/MainActivity.kt <<'EOF'
package com.example.voicecall

import android.app.Activity
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
    LaunchedEffect(Unit) { sig.start() }

    var screen by remember { mutableStateOf<Screen>(Screen.Main) }
    val view = LocalView.current
    val inCall = screen is Screen.Call

    SideEffect {
        val window = (view.context as Activity).window
        val c = WindowCompat.getInsetsController(window, view)
        c.isAppearanceLightStatusBars = !inCall
        c.isAppearanceLightNavigationBars = !inCall
    }
    DisposableEffect(Unit) { onDispose { vs.engine.stop() } }
    BackHandler(enabled = screen !is Screen.Main) { screen = Screen.Main }

    Box {
        when (val s = screen) {
            is Screen.Main -> PhoneScreen(
                onCall = { n, num ->
                    sig.call(num.filter { it.isDigit() })
                    screen = Screen.Call(n, num)
                },
                onVoice = { screen = Screen.Voice }
            )
            is Screen.Voice -> VoiceSettingsScreen(vs) { screen = Screen.Main }
            is Screen.Call -> CallScreen(s.name, s.number, vs) { screen = Screen.Main }
        }

        // свой код и статус подключения (только на главном экране)
        if (screen is Screen.Main) {
            Text(
                "Мой код: ${sig.myCode} · ${sig.status}",
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(top = 4.dp),
                color = Color.Gray,
                fontSize = 13.sp
            )
        }

        // входящая записка: пока просто плашка, настоящий звонок будет дальше
        val from = sig.incomingFrom
        if (from != null) {
            Row(
                Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(top = 36.dp)
                    .background(Color(0xFF2E7D32))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Звонок от $from", color = Color.White, fontSize = 18.sp)
                Spacer(Modifier.width(12.dp))
                Button(onClick = { sig.clearIncoming() }) { Text("Сброс") }
            }
        }
    }
}
EOF

cd ~/voicecall && git add -A && git commit -m "update4 signaling" && git push
