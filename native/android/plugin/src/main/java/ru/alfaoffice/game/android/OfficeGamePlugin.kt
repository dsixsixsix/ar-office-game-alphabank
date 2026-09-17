package ru.alfaoffice.game.android

import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.speech.SpeechRecognizer
import android.util.Log
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot Android plugin (v2) behind PlatformServices: step counter, camera frames with ML Kit /
 * OpenCV detectors, and the system speech recognizer. Every result goes back to GDScript as a
 * signal; frames and audio never leave the device.
 */
class OfficeGamePlugin(godot: Godot) : GodotPlugin(godot) {

    private var stepCounter: StepCounter? = null
    private var camera: CameraController? = null
    private var speech: SpeechController? = null
    private var resumeCamera: Pair<String, Boolean>? = null

    override fun getPluginName(): String = BuildConfig.GODOT_PLUGIN_NAME

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo(SIGNAL_STEPS, INT),
        SignalInfo(SIGNAL_FRAME, INT, INT, ByteArray::class.java),
        SignalInfo(SIGNAL_POSE, String::class.java),
        SignalInfo(SIGNAL_FACES, String::class.java),
        SignalInfo(SIGNAL_MARKERS, String::class.java),
        SignalInfo(SIGNAL_LABELS, String::class.java),
        SignalInfo(SIGNAL_QR, String::class.java),
        SignalInfo(SIGNAL_SPEECH, String::class.java, BOOLEAN),
        SignalInfo(SIGNAL_SPEECH_ERROR, String::class.java),
    )

    @UsedByGodot
    fun hasFeature(name: String): Boolean {
        val context = activity ?: return false
        val packages = context.packageManager
        return when (name) {
            "pedometer" -> {
                val sensors = context.getSystemService(SensorManager::class.java)
                sensors?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null ||
                    sensors?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR) != null
            }
            "camera", "qr", "pose", "faces", "markers", "labels" ->
                packages.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
            "speech" -> SpeechRecognizer.isRecognitionAvailable(context)
            else -> false
        }
    }

    @UsedByGodot
    fun startStepCounter() {
        val context = activity ?: return
        stopStepCounter()
        stepCounter = StepCounter(context) { steps -> emit(SIGNAL_STEPS, steps) }.also { it.start() }
    }

    @UsedByGodot
    fun stopStepCounter() {
        stepCounter?.stop()
        stepCounter = null
    }

    @UsedByGodot
    fun startCamera(mode: String, front: Boolean) {
        val context = activity ?: return
        stopCamera()
        val listener = object : CameraController.Listener {
            override fun onFrame(width: Int, height: Int, rgb: ByteArray) = emit(SIGNAL_FRAME, width, height, rgb)
            override fun onPose(json: String) = emit(SIGNAL_POSE, json)
            override fun onFaces(json: String) = emit(SIGNAL_FACES, json)
            override fun onMarkers(json: String) = emit(SIGNAL_MARKERS, json)
            override fun onLabels(json: String) = emit(SIGNAL_LABELS, json)
            override fun onQr(text: String) = emit(SIGNAL_QR, text)
        }
        camera = CameraController(context, CameraController.Mode.fromName(mode), front, listener).also { it.start() }
        resumeCamera = mode to front
    }

    @UsedByGodot
    fun stopCamera() {
        camera?.stop()
        camera = null
        resumeCamera = null
    }

    @UsedByGodot
    fun startSpeech(locale: String) {
        val context = activity ?: return
        context.runOnUiThread {
            speech?.stop()
            speech = SpeechController(context, object : SpeechController.Listener {
                override fun onResult(text: String, isFinal: Boolean) = emit(SIGNAL_SPEECH, text, isFinal)
                override fun onError(error: String) = emit(SIGNAL_SPEECH_ERROR, error)
            }).also { it.start(locale) }
        }
    }

    @UsedByGodot
    fun stopSpeech() {
        activity?.runOnUiThread {
            speech?.stop()
            speech = null
        }
    }

    override fun onMainPause() {
        super.onMainPause()
        stepCounter?.stop()
        val cameraToResume = resumeCamera
        camera?.stop()
        camera = null
        resumeCamera = cameraToResume
        activity?.runOnUiThread {
            speech?.stop()
            speech = null
        }
    }

    override fun onMainResume() {
        super.onMainResume()
        stepCounter?.start()
        resumeCamera?.let { (mode, front) -> startCamera(mode, front) }
    }

    override fun onMainDestroy() {
        stopStepCounter()
        stopCamera()
        stopSpeech()
        super.onMainDestroy()
    }

    /** Signals are delivered on the Godot render thread. */
    private fun emit(signal: String, vararg args: Any) {
        runOnRenderThread {
            try {
                emitSignal(signal, *args)
            } catch (error: IllegalArgumentException) {
                Log.e(TAG, "Cannot emit $signal", error)
            }
        }
    }

    companion object {
        private const val TAG = "OfficeGamePlugin"
        private val INT = Int::class.javaObjectType
        private val BOOLEAN = Boolean::class.javaObjectType
        const val SIGNAL_STEPS = "steps_changed"
        const val SIGNAL_FRAME = "camera_frame"
        const val SIGNAL_POSE = "pose_detected"
        const val SIGNAL_FACES = "faces_detected"
        const val SIGNAL_MARKERS = "markers_detected"
        const val SIGNAL_LABELS = "labels_detected"
        const val SIGNAL_QR = "qr_detected"
        const val SIGNAL_SPEECH = "speech_result"
        const val SIGNAL_SPEECH_ERROR = "speech_error"
    }
}
