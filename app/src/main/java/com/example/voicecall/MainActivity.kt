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
    fun apply() { engine.ratio = if (voiceOn) preset else 1f; VoiceFx.ratio = engine.ratio }
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
