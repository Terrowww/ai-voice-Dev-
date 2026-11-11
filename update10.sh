#!/data/data/com.termux/files/usr/bin/bash
set -e
D=~/voicecall/app/src/main/java/com/example/voicecall

cat > $D/VoiceFx.kt <<'EOF'
package com.example.voicecall

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.webrtc.audio.AudioRecordDataCallback
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.sin

/** Смена тона для голоса, который уходит в звонок. ratio = 1 значит без изменений. */
object VoiceFx {
    @Volatile var ratio = 1f
    var info by mutableStateOf("fx: колбэк ещё не вызывался")

    private var rate = 0
    private var win = 1920
    private val ring = FloatArray(8192)
    private var w = 0
    private var d1 = 0f
    private var calls = 0

    private fun reset(sampleRate: Int) {
        rate = sampleRate
        win = sampleRate * 40 / 1000
        ring.fill(0f)
        w = 0
        d1 = 0f
    }

    private fun tap(d: Float): Float {
        val pos = w - d
        val i = floor(pos).toInt()
        val f = pos - i
        val a = ring[i and 8191]
        val b = ring[(i + 1) and 8191]
        return a + (b - a) * f
    }

    private fun gain(d: Float): Float {
        val s = sin(PI.toFloat() * d / win)
        return s * s
    }

    private fun shift(x: Float, r: Float): Float {
        ring[w and 8191] = x
        var d2 = d1 + win / 2f
        if (d2 >= win) d2 -= win
        val y = tap(d1) * gain(d1) + tap(d2) * gain(d2)
        w++
        d1 += 1f - r
        if (d1 >= win) d1 -= win
        if (d1 < 0f) d1 += win
        return y
    }

    val callback = AudioRecordDataCallback { audioFormat, channelCount, sampleRate, audioBuffer ->
        calls++
        val r = ratio
        val head = "fx: вызовов=$calls fmt=$audioFormat ch=$channelCount sr=$sampleRate " +
            "cap=${audioBuffer.capacity()} pos=${audioBuffer.position()} lim=${audioBuffer.limit()} " +
            "direct=${audioBuffer.isDirect} ro=${audioBuffer.isReadOnly} ratio=$r"
        if (calls == 1 || calls % 100 == 0) info = head
        try {
            if (sampleRate != rate && sampleRate > 0 && sampleRate <= 96000) reset(sampleRate)
            if (r != 1f && channelCount == 1 && !audioBuffer.isReadOnly) {
                val b = audioBuffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
                val n = b.capacity() / 2
                for (i in 0 until n) {
                    val idx = i * 2
                    val x = b.getShort(idx) / 32768f
                    val y = shift(x, r)
                    b.putShort(idx, (y * 32767f).toInt().coerceIn(-32768, 32767).toShort())
                }
                if (calls % 100 == 0) info = "$head МЕНЯЮ"
            }
        } catch (e: Throwable) {
            info = "ОШИБКА: ${e.javaClass.simpleName} ${e.message}"
        }
    }
}
EOF

echo "Готово"
cd ~/voicecall && git add -A && git commit -m "update10 fx diagnostics" && git push
