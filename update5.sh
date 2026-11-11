#!/data/data/com.termux/files/usr/bin/bash
set -e
D=~/voicecall/app/src/main/java/com/example/voicecall

# 1) плашки в списке "Последние" поменьше (повторный запуск безопасен)
sed -i '117s/vertical = 20.dp/vertical = 10.dp/;151s/vertical = 20.dp/vertical = 10.dp/;122s/22.sp/18.sp/;127s/24.sp/18.sp/;154s/24.sp/18.sp/;129s/16.sp/14.sp/;155s/15.sp/13.sp/;64s/80.dp/40.dp/;69s/40.dp/20.dp/' $D/PhoneScreen.kt

# 2) Signaling: свой номер из 10 цифр, форматирование, отмена вызова
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

// 10 цифр -> "123 456 78 90", чтобы выглядело как номер
fun fmtNumber(d: String): String =
    if (d.length == 10) "${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8)}" else d

// "Почта" между телефонами: вход в Firebase, свой номер, записка о звонке
class Signaling(ctx: Context) {
    private val prefs = ctx.getSharedPreferences("vc", Context.MODE_PRIVATE)
    private val db = FirebaseDatabase
        .getInstance("https://voicecall-62a00-default-rtdb.europe-west1.firebasedatabase.app")
        .reference

    // свой номер: 10 цифр, создаётся один раз и запоминается (это внутренний номер приложения)
    val myNumber: String = prefs.getString("num", null)
        ?: (1000000000L + (java.util.Random().nextDouble() * 8999999999L).toLong()).toString()
            .also { prefs.edit().putString("num", it).apply() }

    var status by mutableStateOf("подключение...")
    var incomingFrom by mutableStateOf<String?>(null)

    fun start() {
        FirebaseAuth.getInstance().signInAnonymously()
            .addOnSuccessListener {
                status = "онлайн"
                db.child("users").child(myNumber).setValue(it.user?.uid)
                listen()
            }
            .addOnFailureListener { status = "ошибка: ${it.message}" }
    }

    private fun listen() {
        db.child("calls").child(myNumber).addValueEventListener(object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                incomingFrom = s.child("from").getValue(String::class.java)
            }
            override fun onCancelled(e: DatabaseError) {
                status = "ошибка: ${e.message}"
            }
        })
    }

    fun call(to: String) {
        if (to.isEmpty()) return
        db.child("calls").child(to).setValue(
            mapOf("from" to myNumber, "ts" to ServerValue.TIMESTAMP)
        )
    }

    // звонящий положил трубку: убираем записку у второго
    fun cancel(to: String) {
        if (to.isNotEmpty()) db.child("calls").child(to).removeValue()
    }

    fun clearIncoming() {
        db.child("calls").child(myNumber).removeValue()
    }
}
EOF

# 3) Экран входящего вызова, как у системной звонилки
cat > $D/IncomingScreen.kt <<'EOF'
package com.example.voicecall

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun IncomingScreen(number: String, onAccept: () -> Unit, onDecline: () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFF0B0B14), Color(0xFF3A1B33), Color(0xFF8A86A6))
                )
            )
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(48.dp))
            Text("Входящий вызов", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.height(90.dp))
            Text(number, color = Color.White, fontSize = 40.sp)
            Spacer(Modifier.height(8.dp))
            Text("Мобильный телефон", color = Color.White, fontSize = 18.sp)
            Spacer(Modifier.weight(1f))
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 72.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Box(
                    Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF1FB45A))
                        .clickable { onAccept() },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        androidx.compose.material.icons.Icons.Filled.Phone,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(36.dp)
                    )
                }
                Box(
                    Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE0392F))
                        .clickable { onDecline() },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        androidx.compose.material.icons.Icons.Filled.Phone,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier
                            .size(36.dp)
                            .rotate(135f)
                    )
                }
            }
        }
    }
}
EOF

# 4) MainActivity: убрали "Мой код" с главного экрана, входящий = полный экран
cat > $D/MainActivity.kt <<'EOF'
package com.example.voicecall

import android.app.Activity
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
        (screen as? Screen.Call)?.let { c -> sig.cancel(c.number.filter { d -> d.isDigit() }) }
        screen = Screen.Main
    }

    Box(Modifier.fillMaxSize()) {
        when (val s = screen) {
            is Screen.Main -> PhoneScreen(
                onCall = { n, num ->
                    val digits = num.filter { it.isDigit() }
                    sig.call(digits)
                    screen = Screen.Call(if (digits.length == 10) fmtNumber(digits) else n, num)
                },
                onVoice = { screen = Screen.Voice }
            )
            is Screen.Voice -> VoiceSettingsScreen(vs) { screen = Screen.Main }
            is Screen.Call -> CallScreen(s.name, s.number, vs) {
                sig.cancel(s.number.filter { it.isDigit() })
                screen = Screen.Main
            }
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
            IncomingScreen(
                number = fmtNumber(incoming),
                onAccept = {
                    sig.clearIncoming()
                    screen = Screen.Call(fmtNumber(incoming), incoming)
                },
                onDecline = { sig.clearIncoming() }
            )
        }
    }
}
EOF

cd ~/voicecall && git add -A && git commit -m "update5 incoming screen, number id" && git push
