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
