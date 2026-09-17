class_name PlatformBackend
extends Node
## Platform implementation behind PlatformServices. This base class is the "nothing available"
## platform (iOS until its plugin exists): accelerometer and microphone come from the Godot core,
## everything else reports unsupported. Subclasses override what their platform provides.

@warning_ignore_start("unused_signal")
signal steps_changed(steps: int)
signal camera_frame(frame: Image)
signal pose_detected(landmarks: Dictionary)
signal faces_detected(faces: Array[SensorModels.Face])
signal markers_detected(marker_ids: PackedInt32Array)
signal labels_detected(labels: Array[SensorModels.ObjectLabel])
signal qr_detected(text: String)
signal speech_recognized(text: String, is_final: bool)
signal speech_failed(error: String)
@warning_ignore_restore("unused_signal")

enum Feature {
	ACCELEROMETER,
	PEDOMETER,
	CAMERA,
	QR_SCAN,
	POSE_DETECTION,
	FACE_DETECTION,
	MARKER_DETECTION,
	OBJECT_RECOGNITION,
	MICROPHONE,
	SPEECH_RECOGNITION,
}

enum CameraMode { PREVIEW, QR, POSE, FACES, MARKERS, LABELS }


func has_feature(feature: Feature) -> bool:
	match feature:
		Feature.ACCELEROMETER:
			return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
		Feature.MICROPHONE:
			return bool(ProjectSettings.get_setting("audio/driver/enable_input", false))
	return false


## Asks the OS for the permissions the features need. Resolves to true when all are granted.
func request_access(_features: Array[Feature]) -> bool:
	return true


func get_acceleration() -> Vector3:
	return Input.get_accelerometer()


func start_step_counter() -> void:
	pass


func stop_step_counter() -> void:
	pass


func start_camera(_mode: CameraMode, _front: bool) -> void:
	pass


func stop_camera() -> void:
	pass


func start_speech(_locale: String) -> void:
	speech_failed.emit("unsupported")


func stop_speech() -> void:
	pass
