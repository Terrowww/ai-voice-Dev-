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
