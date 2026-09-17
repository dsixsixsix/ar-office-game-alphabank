extends PlatformBackend
## Android implementation. Wraps the "OfficeGameAndroid" plugin (native/android): step counter,
## CameraX frames with ML Kit / OpenCV detectors, and SpeechRecognizer.

const SINGLETON: String = "OfficeGameAndroid"
const PERMISSION_TIMEOUT: float = 30.0
const PERMISSIONS: Dictionary[PlatformBackend.Feature, String] = {
	Feature.PEDOMETER: "android.permission.ACTIVITY_RECOGNITION",
	Feature.CAMERA: "android.permission.CAMERA",
	Feature.QR_SCAN: "android.permission.CAMERA",
	Feature.POSE_DETECTION: "android.permission.CAMERA",
	Feature.FACE_DETECTION: "android.permission.CAMERA",
	Feature.MARKER_DETECTION: "android.permission.CAMERA",
	Feature.OBJECT_RECOGNITION: "android.permission.CAMERA",
	Feature.MICROPHONE: "android.permission.RECORD_AUDIO",
	Feature.SPEECH_RECOGNITION: "android.permission.RECORD_AUDIO",
}
const FEATURE_NAMES: Dictionary[PlatformBackend.Feature, String] = {
	Feature.PEDOMETER: "pedometer",
	Feature.CAMERA: "camera",
	Feature.QR_SCAN: "qr",
	Feature.POSE_DETECTION: "pose",
	Feature.FACE_DETECTION: "faces",
	Feature.MARKER_DETECTION: "markers",
	Feature.OBJECT_RECOGNITION: "labels",
	Feature.SPEECH_RECOGNITION: "speech",
}
const CAMERA_MODE_NAMES: Dictionary[PlatformBackend.CameraMode, String] = {
	CameraMode.PREVIEW: "preview",
	CameraMode.QR: "qr",
	CameraMode.POSE: "pose",
	CameraMode.FACES: "faces",
	CameraMode.MARKERS: "markers",
	CameraMode.LABELS: "labels",
}

var _plugin: Object


func _ready() -> void:
	if not Engine.has_singleton(SINGLETON):
		push_warning("Android plugin %s is missing; native features are disabled" % SINGLETON)
		return
	_plugin = Engine.get_singleton(SINGLETON)
	_plugin.connect("steps_changed", func(steps: int) -> void: steps_changed.emit(steps))
	_plugin.connect("camera_frame", _on_camera_frame)
	_plugin.connect("pose_detected", func(json: String) -> void: pose_detected.emit(SensorModels.parse_pose(json)))
	_plugin.connect("faces_detected", func(json: String) -> void: faces_detected.emit(SensorModels.parse_faces(json)))
	_plugin.connect("markers_detected", func(json: String) -> void: markers_detected.emit(SensorModels.parse_markers(json)))
	_plugin.connect("labels_detected", func(json: String) -> void: labels_detected.emit(SensorModels.parse_labels(json)))
	_plugin.connect("qr_detected", func(text: String) -> void: qr_detected.emit(text))
	_plugin.connect("speech_result", func(text: String, is_final: bool) -> void: speech_recognized.emit(text, is_final))
	_plugin.connect("speech_error", func(error: String) -> void: speech_failed.emit(error))


func has_feature(feature: PlatformBackend.Feature) -> bool:
	if FEATURE_NAMES.has(feature):
		return _plugin != null and bool(_plugin.call("hasFeature", FEATURE_NAMES[feature]))
	return super(feature)


func request_access(features: Array[PlatformBackend.Feature]) -> bool:
	var pending: Array[String] = []
	for feature: PlatformBackend.Feature in features:
		var permission: String = PERMISSIONS.get(feature, "")
		if permission.is_empty() or pending.has(permission) or OS.get_granted_permissions().has(permission):
			continue
		pending.append(permission)
	for permission: String in pending:
		if OS.request_permission(permission):
			continue
		if not await _wait_for_permission(permission):
			return false
	return true


func _wait_for_permission(permission: String) -> bool:
	var state: Dictionary = {"done": false, "granted": false}
	var on_result: Callable = func(name: String, granted: bool) -> void:
		if name == permission:
			state["done"] = true
			state["granted"] = granted
	get_tree().on_request_permissions_result.connect(on_result)
	var waited: float = 0.0
	while not bool(state["done"]) and waited < PERMISSION_TIMEOUT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	get_tree().on_request_permissions_result.disconnect(on_result)
	return bool(state["granted"]) or OS.get_granted_permissions().has(permission)


func start_step_counter() -> void:
	if _plugin != null:
		_plugin.call("startStepCounter")


func stop_step_counter() -> void:
	if _plugin != null:
		_plugin.call("stopStepCounter")


func start_camera(mode: PlatformBackend.CameraMode, front: bool) -> void:
	if _plugin != null:
		_plugin.call("startCamera", CAMERA_MODE_NAMES[mode], front)


func stop_camera() -> void:
	if _plugin != null:
		_plugin.call("stopCamera")


func start_speech(locale: String) -> void:
	if _plugin == null:
		speech_failed.emit("unsupported")
		return
	_plugin.call("startSpeech", locale)


func stop_speech() -> void:
	if _plugin != null:
		_plugin.call("stopSpeech")


func _on_camera_frame(width: int, height: int, rgb: PackedByteArray) -> void:
	var frame: Image = SensorModels.frame_from_rgb(width, height, rgb)
	if frame != null:
		camera_frame.emit(frame)
