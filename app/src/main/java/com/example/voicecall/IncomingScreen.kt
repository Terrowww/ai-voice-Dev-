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
