package com.example.voicecall

import android.content.Context
import android.media.AudioManager
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.firebase.database.ChildEventListener
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.ServerValue
import com.google.firebase.database.ValueEventListener
import org.webrtc.AudioTrack
import org.webrtc.DataChannel
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription
import org.webrtc.audio.JavaAudioDeviceModule

open class SdpAdapter : SdpObserver {
    override fun onCreateSuccess(sdp: SessionDescription?) {}
    override fun onSetSuccess() {}
    override fun onCreateFailure(error: String?) {}
    override fun onSetFailure(error: String?) {}
}

/**
 * Звонок между двумя телефонами. Все "записки" лежат в Firebase по адресу calls/НОМЕР_ТОГО_КОМУ_ЗВОНЯТ:
 *   from, offer       - кладёт звонящий
 *   answer            - кладёт тот, кто взял трубку
 *   callerIce/calleeIce - данные для соединения от каждой стороны
 * Кто угодно кладёт трубку = удаляет calls/НОМЕР, второй телефон видит это и завершает звонок.
 */
class CallEngine(ctx: Context, private val sig: Signaling) {
    private val app = ctx.applicationContext
    private val audioManager = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var factory: PeerConnectionFactory? = null
    private var pc: PeerConnection? = null
    private var track: AudioTrack? = null
    private var node: DatabaseReference? = null
    private var isCaller = false
    private var remoteSet = false
    private val pending = mutableListOf<IceCandidate>()
    private val regs = mutableListOf<() -> Unit>()

    var connected by mutableStateOf(false)
    var onEnded: () -> Unit = {}

    private fun factory(): PeerConnectionFactory {
        factory?.let { return it }
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(app).createInitializationOptions()
        )
        val adm = JavaAudioDeviceModule.builder(app).createAudioDeviceModule()
        return PeerConnectionFactory.builder()
            .setAudioDeviceModule(adm)
            .createPeerConnectionFactory()
            .also { factory = it }
    }

    private val observer = object : PeerConnection.Observer {
        override fun onSignalingChange(s: PeerConnection.SignalingState?) {}
        override fun onIceConnectionChange(s: PeerConnection.IceConnectionState?) {
            when (s) {
                PeerConnection.IceConnectionState.CONNECTED,
                PeerConnection.IceConnectionState.COMPLETED -> connected = true
                PeerConnection.IceConnectionState.FAILED -> finish()
                else -> {}
            }
        }
        override fun onIceConnectionReceivingChange(b: Boolean) {}
        override fun onIceGatheringChange(s: PeerConnection.IceGatheringState?) {}
        override fun onIceCandidate(c: IceCandidate?) {
            if (c == null) return
            val key = if (isCaller) "callerIce" else "calleeIce"
            node?.child(key)?.push()?.setValue(
                mapOf("mid" to c.sdpMid, "idx" to c.sdpMLineIndex, "sdp" to c.sdp)
            )
        }
        override fun onIceCandidatesRemoved(c: Array<out IceCandidate>?) {}
        override fun onAddStream(s: MediaStream?) {}
        override fun onRemoveStream(s: MediaStream?) {}
        override fun onDataChannel(d: DataChannel?) {}
        override fun onRenegotiationNeeded() {}
    }

    private fun newPc(): PeerConnection {
        val f = factory()
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        val cfg = PeerConnection.RTCConfiguration(
            listOf(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())
        )
        cfg.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
        val p = f.createPeerConnection(cfg, observer)!!
        val src = f.createAudioSource(MediaConstraints())
        val t = f.createAudioTrack("audio0", src)
        p.addTrack(t, listOf("stream0"))
        track = t
        return p
    }

    private fun audioConstraints() = MediaConstraints().apply {
        mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
    }

    // ---- звонящий ----
    fun startCall(to: String) {
        if (to.isEmpty() || pc != null) return
        isCaller = true
        remoteSet = false
        pending.clear()
        connected = false
        val ref = sig.db.child("calls").child(to)
        node = ref
        // сначала чистим старые остатки, потом начинаем
        ref.removeValue().addOnCompleteListener {
            if (node == null) return@addOnCompleteListener
            val p = newPc()
            pc = p
            p.createOffer(object : SdpAdapter() {
                override fun onCreateSuccess(sdp: SessionDescription?) {
                    if (sdp == null) return
                    p.setLocalDescription(SdpAdapter(), sdp)
                    ref.updateChildren(
                        mapOf(
                            "from" to sig.myNumber,
                            "offer" to sdp.description,
                            "ts" to ServerValue.TIMESTAMP
                        )
                    )
                    watch()
                    listenIce()
                    listenAnswer()
                }
            }, audioConstraints())
        }
    }

    // ---- тот, кому звонят, взял трубку ----
    fun accept(offer: String) {
        if (pc != null) return
        isCaller = false
        remoteSet = false
        pending.clear()
        connected = false
        val ref = sig.db.child("calls").child(sig.myNumber)
        node = ref
        val p = newPc()
        pc = p
        watch()
        listenIce()
        p.setRemoteDescription(object : SdpAdapter() {
            override fun onSetSuccess() {
                remoteSet = true
                flushPending()
                p.createAnswer(object : SdpAdapter() {
                    override fun onCreateSuccess(sdp: SessionDescription?) {
                        if (sdp == null) return
                        p.setLocalDescription(SdpAdapter(), sdp)
                        ref.child("answer").setValue(sdp.description)
                    }
                }, audioConstraints())
            }
        }, SessionDescription(SessionDescription.Type.OFFER, offer))
    }

    // ---- Firebase: слежение ----
    private fun listenAnswer() {
        val ref = node?.child("answer") ?: return
        val l = object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                val sdp = s.value as? String ?: return
                if (remoteSet) return
                pc?.setRemoteDescription(object : SdpAdapter() {
                    override fun onSetSuccess() {
                        remoteSet = true
                        flushPending()
                    }
                }, SessionDescription(SessionDescription.Type.ANSWER, sdp))
            }
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addValueEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    private fun listenIce() {
        val key = if (isCaller) "calleeIce" else "callerIce"
        val ref = node?.child(key) ?: return
        val l = object : ChildEventListener {
            override fun onChildAdded(s: DataSnapshot, prev: String?) {
                val mid = s.child("mid").value as? String
                val idx = (s.child("idx").value as? Long)?.toInt() ?: 0
                val sdp = s.child("sdp").value as? String ?: return
                addRemoteIce(IceCandidate(mid, idx, sdp))
            }
            override fun onChildChanged(s: DataSnapshot, prev: String?) {}
            override fun onChildRemoved(s: DataSnapshot) {}
            override fun onChildMoved(s: DataSnapshot, prev: String?) {}
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addChildEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    // если звонок удалили из базы, значит второй положил трубку
    private fun watch() {
        val ref = node ?: return
        var seen = false
        val l = object : ValueEventListener {
            override fun onDataChange(s: DataSnapshot) {
                if (s.exists()) seen = true else if (seen) finish()
            }
            override fun onCancelled(e: DatabaseError) {}
        }
        ref.addValueEventListener(l)
        regs.add { ref.removeEventListener(l) }
    }

    private fun addRemoteIce(c: IceCandidate) {
        if (remoteSet) pc?.addIceCandidate(c) else pending.add(c)
    }

    private fun flushPending() {
        val list = pending.toList()
        pending.clear()
        list.forEach { pc?.addIceCandidate(it) }
    }

    // ---- завершение ----
    fun hangup() {
        node?.removeValue()
        cleanup()
    }

    private fun finish() {
        val had = pc != null
        cleanup()
        if (had) onEnded()
    }

    private fun cleanup() {
        regs.forEach { it() }
        regs.clear()
        pc?.close()
        pc?.dispose()
        pc = null
        track = null
        node = null
        connected = false
        audioManager.isSpeakerphoneOn = false
        audioManager.mode = AudioManager.MODE_NORMAL
    }

    fun mute(m: Boolean) { track?.setEnabled(!m) }
    fun speaker(on: Boolean) { audioManager.isSpeakerphoneOn = on }
}
