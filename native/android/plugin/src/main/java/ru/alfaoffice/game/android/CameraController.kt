package ru.alfaoffice.game.android

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * CameraX image analysis without an Android preview surface: the game draws a low-resolution copy
 * of each frame itself. Detectors run on the upright bitmap; their coordinates are normalized to
 * it and mirrored for the front camera, the same way as the preview frame.
 */
class CameraController(
    private val activity: Activity,
    private val mode: Mode,
    private val front: Boolean,
    private val listener: Listener,
) : LifecycleOwner {

    enum class Mode {
        PREVIEW, QR, POSE, FACES, MARKERS, LABELS;

        companion object {
            fun fromName(name: String): Mode = entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: PREVIEW
        }
    }

    interface Listener {
        fun onFrame(width: Int, height: Int, rgb: ByteArray)
        fun onLabels(json: String)
        fun onPose(json: String)
        fun onFaces(json: String)
        fun onMarkers(json: String)
        fun onQr(text: String)
    }

    /** Detector for one mode. [analyze] must call [done] exactly once when the frame is processed. */
    interface Detector {
        fun analyze(frame: UprightFrame, done: () -> Unit)
        fun close()
    }

    /** Upright camera image; mirrored for the front camera, so detectors see what the player sees. */
    class UprightFrame(val bitmap: Bitmap)

    private val registry = LifecycleRegistry(this)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var provider: ProcessCameraProvider? = null
    private var detector: Detector? = null
    private var lastPreviewAt = 0L
    @Volatile private var running = false

    override fun getLifecycle(): Lifecycle = registry

    fun start() {
        running = true
        detector = when (mode) {
            Mode.QR -> QrDetector(listener::onQr)
            Mode.POSE -> PoseDetector(listener::onPose)
            Mode.FACES -> FaceDetector(listener::onFaces)
            Mode.MARKERS -> MarkerDetector(listener::onMarkers)
            Mode.LABELS -> LabelDetector(listener::onLabels)
            Mode.PREVIEW -> null
        }
        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({
            if (!running) return@addListener
            try {
                bind(future.get())
            } catch (error: Exception) {
                Log.e(TAG, "Camera start failed", error)
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    fun stop() {
        running = false
        ContextCompat.getMainExecutor(activity).execute {
            provider?.unbindAll()
            provider = null
            if (registry.currentState.isAtLeast(Lifecycle.State.CREATED)) {
                registry.currentState = Lifecycle.State.DESTROYED
            }
            // The analyzer is unbound now; release the detector on its own thread.
            executor.execute { detector?.close() }
            executor.shutdown()
        }
    }

    private fun bind(cameraProvider: ProcessCameraProvider) {
        provider = cameraProvider
        val selector = if (front) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
        val resolution = ResolutionSelector.Builder()
            .setResolutionStrategy(
                ResolutionStrategy(ANALYSIS_SIZE, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
            )
            .build()
        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolution)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysis.setAnalyzer(executor, ::analyze)
        registry.currentState = Lifecycle.State.RESUMED
        cameraProvider.unbindAll()
        cameraProvider.bindToLifecycle(this, selector, analysis)
    }

    private fun analyze(image: ImageProxy) {
        if (!running) {
            image.close()
            return
        }
        val frame = try {
            UprightFrame(upright(image))
        } catch (error: RuntimeException) {
            Log.w(TAG, "Frame conversion failed", error)
            image.close()
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastPreviewAt >= PREVIEW_INTERVAL_MS) {
            lastPreviewAt = now
            sendPreview(frame.bitmap)
        }
        val active = detector
        if (active == null) {
            image.close()
            return
        }
        // KEEP_ONLY_LATEST delivers the next frame only after this one is closed.
        active.analyze(frame) { image.close() }
    }

    /** Rotated to the screen orientation and mirrored for the front camera, like a selfie. */
    private fun upright(image: ImageProxy): Bitmap {
        val source = image.toBitmap()
        val rotation = image.imageInfo.rotationDegrees
        if (rotation == 0 && !front) return source
        val matrix = Matrix().apply {
            postRotate(rotation.toFloat())
            if (front) postScale(-1f, 1f)
        }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, false)
    }

    private fun sendPreview(bitmap: Bitmap) {
        val scale = PREVIEW_LONG_SIDE.toFloat() / maxOf(bitmap.width, bitmap.height)
        val width = maxOf(1, (bitmap.width * scale).toInt())
        val height = maxOf(1, (bitmap.height * scale).toInt())
        val small = Bitmap.createScaledBitmap(bitmap, width, height, false)
        val pixels = IntArray(width * height)
        small.getPixels(pixels, 0, width, 0, 0, width, height)
        val rgb = ByteArray(width * height * 3)
        for (i in pixels.indices) {
            val color = pixels[i]
            rgb[i * 3] = (color shr 16).toByte()
            rgb[i * 3 + 1] = (color shr 8).toByte()
            rgb[i * 3 + 2] = color.toByte()
        }
        listener.onFrame(width, height, rgb)
    }

    companion object {
        private const val TAG = "OfficeGameCamera"
        private val ANALYSIS_SIZE = Size(640, 480)
        private const val PREVIEW_LONG_SIDE = 160
        private const val PREVIEW_INTERVAL_MS = 66L
    }
}
