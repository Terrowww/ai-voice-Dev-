#!/data/data/com.termux/files/usr/bin/bash
set -e
D=~/voicecall/app/src/main/java/com/example/voicecall

# 1) VoiceFx: смена тона для звука микрофона внутри звонка
cat > $D/VoiceFx.kt <<'EOF'
package com.example.voicecall

import android.media.AudioFormat
import org.webrtc.audio.JavaAudioDeviceModule
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.sin

/** Смена тона для голоса, который уходит в звонок. ratio = 1 значит без изменений. */
object VoiceFx {
    @Volatile var ratio = 1f

    private var rate = 0
    private var win = 1920
    private val ring = FloatArray(8192)
    private var w = 0
    private var d1 = 0f

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

    // WebRTC вызывает это на каждые 10 мс звука с микрофона, буфер меняем на месте
    val callback = JavaAudioDeviceModule.AudioRecordDataCallback { audioFormat, channelCount, sampleRate, audioBuffer ->
        val r = ratio
        if (r != 1f && audioFormat == AudioFormat.ENCODING_PCM_16BIT && channelCount == 1) {
            if (sampleRate != rate) reset(sampleRate)
            val b = audioBuffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
            val start = b.position()
            val n = (b.limit() - start) / 2
            for (i in 0 until n) {
                val idx = start + i * 2
                val x = b.getShort(idx) / 32768f
                val y = shift(x, r)
                b.putShort(idx, (y * 32767f).toInt().coerceIn(-32768, 32767).toShort())
            }
        }
    }
}
EOF

# 2) Подключаем к звонку
sed -i 's|JavaAudioDeviceModule.builder(app).createAudioDeviceModule()|JavaAudioDeviceModule.builder(app).setAudioRecordDataCallback(VoiceFx.callback).createAudioDeviceModule()|' $D/CallEngine.kt
grep -q "VoiceFx" $D/CallEngine.kt || { echo "ОШИБКА: CallEngine.kt не изменился"; exit 1; }

# 3) Переключатель и пресет из настроек голоса управляют и звонком
sed -i 's|fun apply() { engine.ratio = if (voiceOn) preset else 1f }|fun apply() { engine.ratio = if (voiceOn) preset else 1f; VoiceFx.ratio = engine.ratio }|' $D/MainActivity.kt
grep -q "VoiceFx" $D/MainActivity.kt || { echo "ОШИБКА: MainActivity.kt не изменился"; exit 1; }

echo "Правки применены"
cd ~/voicecall && git add -A && git commit -m "update7 voice change in call" && git push
