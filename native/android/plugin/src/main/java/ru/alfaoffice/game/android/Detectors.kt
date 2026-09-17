package ru.alfaoffice.game.android

import android.os.SystemClock
import android.util.Log
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import org.json.JSONArray
import org.json.JSONObject
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Mat
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.ArucoDetector
import org.opencv.objdetect.DetectorParameters
import org.opencv.objdetect.Objdetect

private const val TAG = "OfficeGameDetectors"

/** QR codes through ML Kit barcode scanning (bundled model). The same code is reported once a second. */
class QrDetector(private val onQr: (String) -> Unit) : CameraController.Detector {
    private val scanner = BarcodeScanning.getClient(
        BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build(),
    )
    private var lastText = ""
    private var lastAt = 0L

    override fun analyze(frame: CameraController.UprightFrame, done: () -> Unit) {
        scanner.process(InputImage.fromBitmap(frame.bitmap, 0))
            .addOnSuccessListener { codes ->
                val text = codes.firstNotNullOfOrNull { it.rawValue } ?: return@addOnSuccessListener
                val now = SystemClock.elapsedRealtime()
                if (text != lastText || now - lastAt > REPEAT_MS) {
                    lastText = text
                    lastAt = now
                    onQr(text)
                }
            }
            .addOnFailureListener { Log.w(TAG, "QR detection failed", it) }
            .addOnCompleteListener { done() }
    }

    override fun close() = scanner.close()

    private companion object {
        const val REPEAT_MS = 1000L
    }
}

/** Face boxes and smile probability through ML Kit face detection. */
class FaceDetector(private val onFaces: (String) -> Unit) : CameraController.Detector {
    private val detector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .setMinFaceSize(0.15f)
            .build(),
    )

    override fun analyze(frame: CameraController.UprightFrame, done: () -> Unit) {
        val width = frame.bitmap.width.toDouble()
        val height = frame.bitmap.height.toDouble()
        detector.process(InputImage.fromBitmap(frame.bitmap, 0))
            .addOnSuccessListener { faces ->
                val list = JSONArray()
                for (face in faces) {
                    val box = face.boundingBox
                    list.put(
                        JSONObject()
                            .put("x", box.left / width)
                            .put("y", box.top / height)
                            .put("w", box.width() / width)
                            .put("h", box.height() / height)
                            .put("smiling", face.smilingProbability?.toDouble() ?: -1.0),
                    )
                }
                onFaces(JSONObject().put("faces", list).toString())
            }
            .addOnFailureListener { Log.w(TAG, "Face detection failed", it) }
            .addOnCompleteListener { done() }
    }

    override fun close() = detector.close()
}

/** Body landmarks through ML Kit pose detection (base model, stream mode). */
class PoseDetector(private val onPose: (String) -> Unit) : CameraController.Detector {
    private val detector = PoseDetection.getClient(
        PoseDetectorOptions.Builder().setDetectorMode(PoseDetectorOptions.STREAM_MODE).build(),
    )

    override fun analyze(frame: CameraController.UprightFrame, done: () -> Unit) {
        val width = frame.bitmap.width.toDouble()
        val height = frame.bitmap.height.toDouble()
        detector.process(InputImage.fromBitmap(frame.bitmap, 0))
            .addOnSuccessListener { pose ->
                val landmarks = JSONObject()
                for ((name, type) in LANDMARKS) {
                    val landmark = pose.getPoseLandmark(type) ?: continue
                    landmarks.put(
                        name,
                        JSONArray()
                            .put(landmark.position.x / width)
                            .put(landmark.position.y / height)
                            .put(landmark.inFrameLikelihood.toDouble()),
                    )
                }
                if (landmarks.length() > 0) {
                    onPose(JSONObject().put("landmarks", landmarks).toString())
                }
            }
            .addOnFailureListener { Log.w(TAG, "Pose detection failed", it) }
            .addOnCompleteListener { done() }
    }

    override fun close() = detector.close()

    private companion object {
        // Names match SensorModels.POSE_LANDMARKS in GDScript.
        val LANDMARKS = mapOf(
            "nose" to PoseLandmark.NOSE,
            "left_shoulder" to PoseLandmark.LEFT_SHOULDER,
            "right_shoulder" to PoseLandmark.RIGHT_SHOULDER,
            "left_hip" to PoseLandmark.LEFT_HIP,
            "right_hip" to PoseLandmark.RIGHT_HIP,
            "left_knee" to PoseLandmark.LEFT_KNEE,
            "right_knee" to PoseLandmark.RIGHT_KNEE,
            "left_ankle" to PoseLandmark.LEFT_ANKLE,
            "right_ankle" to PoseLandmark.RIGHT_ANKLE,
        )
    }
}

/** Objects in front of the camera through ML Kit image labeling (bundled base model). */
class LabelDetector(private val onLabels: (String) -> Unit) : CameraController.Detector {
    private val labeler = ImageLabeling.getClient(
        ImageLabelerOptions.Builder().setConfidenceThreshold(MIN_CONFIDENCE).build(),
    )

    override fun analyze(frame: CameraController.UprightFrame, done: () -> Unit) {
        labeler.process(InputImage.fromBitmap(frame.bitmap, 0))
            .addOnSuccessListener { labels ->
                val list = JSONArray()
                for (label in labels.take(MAX_LABELS)) {
                    list.put(JSONObject().put("id", label.text).put("confidence", label.confidence.toDouble()))
                }
                onLabels(JSONObject().put("labels", list).toString())
            }
            .addOnFailureListener { Log.w(TAG, "Image labeling failed", it) }
            .addOnCompleteListener { done() }
    }

    override fun close() = labeler.close()

    private companion object {
        const val MIN_CONFIDENCE = 0.35f
        const val MAX_LABELS = 5
    }
}

/** Printed ArUco markers (DICT_4X4_50) through OpenCV. Runs synchronously on the camera thread. */
class MarkerDetector(private val onMarkers: (String) -> Unit) : CameraController.Detector {
    private val available = OpenCVLoader.initLocal()
    private val detector: ArucoDetector? = if (available) {
        ArucoDetector(Objdetect.getPredefinedDictionary(Objdetect.DICT_4X4_50), DetectorParameters())
    } else {
        Log.e(TAG, "OpenCV failed to load")
        null
    }
    private val rgba = Mat()
    private val gray = Mat()

    override fun analyze(frame: CameraController.UprightFrame, done: () -> Unit) {
        try {
            val aruco = detector ?: return
            Utils.bitmapToMat(frame.bitmap, rgba)
            Imgproc.cvtColor(rgba, gray, Imgproc.COLOR_RGBA2GRAY)
            val corners = ArrayList<Mat>()
            val ids = Mat()
            aruco.detectMarkers(gray, corners, ids)
            val list = JSONArray()
            for (row in 0 until ids.rows()) {
                list.put(ids.get(row, 0)[0].toInt())
            }
            corners.forEach { it.release() }
            ids.release()
            onMarkers(JSONObject().put("markers", list).toString())
        } catch (error: RuntimeException) {
            Log.w(TAG, "Marker detection failed", error)
        } finally {
            done()
        }
    }

    override fun close() {
        rgba.release()
        gray.release()
    }
}
