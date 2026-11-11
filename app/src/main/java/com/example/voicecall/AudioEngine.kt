package com.example.voicecall

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Process
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.sin

/** Микрофон -> смена тона (две линии задержки с кроссфейдом) -> динамик/наушники. */
class AudioEngine {
    private val sr = 48000
    private val chunk = 240          // 5 мс
    private val win = 1920           // окно смены тона, 40 мс
    private val ring = FloatArray(4096)
    private var w = 0
    private var d1 = 0f

    @Volatile var ratio = 1f
    @Volatile var muted = false
    @Volatile var latencyMs = 0
    @Volatile private var running = false
    private var thread: Thread? = null

    private fun push(x: Float) {
        ring[w and 4095] = x
        w++
    }

    private fun tap(d: Float): Float {
        val pos = w - d
        val i = floor(pos).toInt()
        val f = pos - i
        val a = ring[i and 4095]
        val b = ring[(i + 1) and 4095]
        return a + (b - a) * f
    }

    private fun gain(d: Float): Float {
        val s = sin(PI.toFloat() * d / win)
        return s * s
    }

    private fun shift(x: Float, r: Float): Float {
        ring[w and 4095] = x
        var d2 = d1 + win / 2f
        if (d2 >= win) d2 -= win
        val y = tap(d1) * gain(d1) + tap(d2) * gain(d2)
        w++
        d1 += 1f - r
        if (d1 >= win) d1 -= win
        if (d1 < 0f) d1 += win
        return y
    }

    @android.annotation.SuppressLint("MissingPermission")
    fun start() {
        if (running) return
        running = true
        thread = Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            var rec: AudioRecord? = null
            var track: AudioTrack? = null
            try {
                val minRec = AudioRecord.getMinBufferSize(
                    sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
                )
                rec = AudioRecord(
                    MediaRecorder.AudioSource.MIC, sr,
                    AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
                    maxOf(minRec, chunk * 4)
                )
                val minTrack = AudioTrack.getMinBufferSize(
                    sr, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT
                )
                track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sr)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(maxOf(minTrack, chunk * 2))
                    .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                latencyMs = ((chunk + track.bufferSizeInFrames + win / 2) * 1000) / sr
                rec.startRecording()
                track.play()
                val buf = ShortArray(chunk)
                while (running) {
                    val n = rec.read(buf, 0, chunk)
                    if (n <= 0) continue
                    val r = ratio
                    for (i in 0 until n) {
                        val x = if (muted) 0f else buf[i] / 32768f
                        val y = if (r == 1f) { push(x); x } else shift(x, r)
                        buf[i] = (y * 32767f).toInt().coerceIn(-32768, 32767).toShort()
                    }
                    track.write(buf, 0, n)
                }
            } catch (e: Exception) {
                // оставляем тихо, UI просто покажет, что звука нет
            } finally {
                try { rec?.stop() } catch (_: Exception) {}
                rec?.release()
                try { track?.stop() } catch (_: Exception) {}
                track?.release()
                running = false
            }
        }.also { it.start() }
    }

    fun stop() {
        running = false
        thread?.join(1000)
        thread = null
    }
}
