package com.example.voicecall

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun IconMic(color: Color, slash: Boolean = true, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val w = s * 0.07f
        val st = Stroke(width = w, cap = StrokeCap.Round, join = StrokeJoin.Round)
        drawRoundRect(
            color, topLeft = Offset(s * 0.38f, s * 0.12f),
            size = Size(s * 0.24f, s * 0.44f), cornerRadius = CornerRadius(s * 0.12f), style = st
        )
        val p = Path().apply {
            moveTo(s * 0.26f, s * 0.46f)
            quadraticBezierTo(s * 0.26f, s * 0.72f, s * 0.5f, s * 0.72f)
            quadraticBezierTo(s * 0.74f, s * 0.72f, s * 0.74f, s * 0.46f)
        }
        drawPath(p, color, style = st)
        drawLine(color, Offset(s * 0.5f, s * 0.72f), Offset(s * 0.5f, s * 0.86f), strokeWidth = w, cap = StrokeCap.Round)
        drawLine(color, Offset(s * 0.38f, s * 0.86f), Offset(s * 0.62f, s * 0.86f), strokeWidth = w, cap = StrokeCap.Round)
        if (slash) {
            drawLine(color, Offset(s * 0.16f, s * 0.1f), Offset(s * 0.84f, s * 0.9f), strokeWidth = w, cap = StrokeCap.Round)
        }
    }
}

@Composable
fun IconBluetooth(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val p = Path().apply {
            moveTo(s * 0.28f, s * 0.32f)
            lineTo(s * 0.72f, s * 0.68f)
            lineTo(s * 0.5f, s * 0.88f)
            lineTo(s * 0.5f, s * 0.12f)
            lineTo(s * 0.72f, s * 0.32f)
            lineTo(s * 0.28f, s * 0.68f)
        }
        drawPath(p, color, style = st)
    }
}

@Composable
fun IconSpeaker(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val body = Path().apply {
            moveTo(s * 0.16f, s * 0.4f)
            lineTo(s * 0.32f, s * 0.4f)
            lineTo(s * 0.5f, s * 0.24f)
            lineTo(s * 0.5f, s * 0.76f)
            lineTo(s * 0.32f, s * 0.6f)
            lineTo(s * 0.16f, s * 0.6f)
            close()
        }
        drawPath(body, color, style = st)
        drawArc(
            color, startAngle = -45f, sweepAngle = 90f, useCenter = false,
            topLeft = Offset(s * 0.32f, s * 0.32f), size = Size(s * 0.36f, s * 0.36f), style = st
        )
        drawArc(
            color, startAngle = -45f, sweepAngle = 90f, useCenter = false,
            topLeft = Offset(s * 0.2f, s * 0.2f), size = Size(s * 0.6f, s * 0.6f), style = st
        )
    }
}

@Composable
fun IconKeypad(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val r = s * 0.055f
        val xs = listOf(0.3f, 0.5f, 0.7f)
        val ys = listOf(0.22f, 0.4f, 0.58f)
        for (y in ys) for (x in xs) drawCircle(color, r, Offset(s * x, s * y))
        drawCircle(color, r, Offset(s * 0.5f, s * 0.76f))
    }
}

@Composable
fun IconMore(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val r = s * 0.07f
        for (y in listOf(0.25f, 0.5f, 0.75f)) drawCircle(color, r, Offset(s * 0.5f, s * y))
    }
}

@Composable
fun IconVoicemail(color: Color, dp: Dp = 34.dp) {
    Canvas(Modifier.size(dp)) {
        val s = this.size.minDimension
        val st = Stroke(width = s * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        drawRoundRect(
            color, topLeft = Offset(s * 0.12f, s * 0.28f),
            size = Size(s * 0.76f, s * 0.44f), cornerRadius = CornerRadius(s * 0.12f), style = st
        )
        drawCircle(color, s * 0.07f, Offset(s * 0.34f, s * 0.5f), style = st)
        drawCircle(color, s * 0.07f, Offset(s * 0.66f, s * 0.5f), style = st)
    }
}
