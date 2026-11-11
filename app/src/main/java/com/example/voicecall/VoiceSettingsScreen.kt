package com.example.voicecall

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceSettingsScreen(vs: VoiceState, onBack: () -> Unit) {
    val context = LocalContext.current
    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { ok ->
        if (ok) { vs.engine.start(); vs.listening = true }
    }

    fun toggleListen(on: Boolean) {
        if (!on) { vs.engine.stop(); vs.listening = false; return }
        val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) { vs.engine.start(); vs.listening = true }
        else launcher.launch(Manifest.permission.RECORD_AUDIO)
    }

    LaunchedEffect(vs.listening) {
        if (vs.listening) { delay(400); vs.latency = vs.engine.latencyMs }
    }
    DisposableEffect(Unit) {
        onDispose {
            if (vs.listening) { vs.engine.stop(); vs.listening = false }
        }
    }

    Column(
        Modifier.fillMaxSize().background(Color(0xFFF1F1F6))
            .statusBarsPadding().navigationBarsPadding()
    ) {
        Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, "Назад", tint = Color.Black) }
            Text("Настройки голоса", fontSize = 22.sp, fontWeight = FontWeight.Medium, color = Color.Black)
        }
        Column(Modifier.padding(16.dp)) {
            Surface(shape = RoundedCornerShape(28.dp), color = Color(0xFFFAFAFD)) {
                Column(Modifier.padding(20.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Смена голоса", Modifier.weight(1f), fontSize = 18.sp, color = Color.Black)
                        Switch(
                            checked = vs.voiceOn,
                            onCheckedChange = { vs.voiceOn = it; vs.apply() }
                        )
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("Голос", fontSize = 14.sp, color = Color(0xFF6B6B75))
                    Spacer(Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("Низкий" to 0.84f, "Ниже" to 0.75f, "Выше" to 1.15f).forEach { (n, v) ->
                            FilterChip(
                                selected = vs.preset == v,
                                onClick = { vs.preset = v; vs.apply() },
                                label = { Text(n) }
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
            Surface(shape = RoundedCornerShape(28.dp), color = Color(0xFFFAFAFD)) {
                Column(Modifier.padding(20.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Слушать себя (тест)", Modifier.weight(1f), fontSize = 18.sp, color = Color.Black)
                        Switch(checked = vs.listening, onCheckedChange = { toggleListen(it) })
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(
                        if (vs.listening) "Задержка: ≈ ${vs.latency} мс (оценка)"
                        else "Включи и надень наушники, иначе будет свист",
                        color = Color(0xFF6B6B75), fontSize = 14.sp
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text(
                "Голос меняется на твоём телефоне. Собеседник слышит уже изменённый голос, ты его обычный.",
                color = Color(0xFF6B6B75), fontSize = 14.sp
            )
        }
    }
}
