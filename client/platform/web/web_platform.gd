extends PlatformBackend
## Web implementation (v2). Accelerometer (DeviceMotion) and microphone come from the Godot core.
## Camera, QR (getUserMedia + jsQR), faces (MediaPipe) and the step counter run in camera_bridge.js;
## only results come back: a small RGB preview, QR text, face boxes, steps. Pose, markers, objects
## and speech are not bridged yet, so those tasks use their fallbacks. The camera needs HTTPS.
## Notifications use the Notification API: they are timed in the page, so they arrive only while the
## game tab is open (closed-tab delivery needs Web Push from the server). On iPhone the API exists
## only for a web app added to the home screen (iOS 16.4+).
## Pictures are picked with a hidden <input type="file">.

const PERMISSION_TIMEOUT: float = 60.0
const BRIDGE_PATH: String = "res://platform/web/camera_bridge.js"
const CAMERA_FEATURES: Array[Feature] = [Feature.CAMERA, Feature.QR_SCAN, Feature.FACE_DETECTION]
const MOTION_FEATURES: Array[Feature] = [Feature.ACCELEROMETER, Feature.PEDOMETER]
const CAMERA_MODES: Dictionary[CameraMode, String] = {CameraMode.QR: "qr", CameraMode.FACES: "faces"}
const HELPERS_JS: String = """
window.alfaOffice = window.alfaOffice || {
	timers: {},
	schedule: function (id, title, body, delayMs) {
		this.cancel(id);
		this.timers[id] = setTimeout(function () {
			delete window.alfaOffice.timers[id];
			try { new Notification(title, { body: body, tag: String(id), icon: 'icon.png' }); } catch (e) {}
		}, delayMs);
	},
	cancel: function (id) {
		if (this.timers[id] !== undefined) { clearTimeout(this.timers[id]); delete this.timers[id]; }
	},
	cancelAll: function () {
		for (var id in this.timers) { clearTimeout(this.timers[id]); }
		this.timers = {};
	},
	permission: function () { return ('Notification' in window) ? Notification.permission : 'unsupported'; },
	requestPermission: function () { if ('Notification' in window) { Notification.requestPermission(); } },
	pickImage: function (callback) {
		var input = document.createElement('input');
		input.type = 'file';
		input.accept = 'image/*';
		var done = false;
		function finish(value) { if (!done) { done = true; callback(value); } }
		input.addEventListener('cancel', function () { finish(''); });
		input.onchange = function () {
			var file = input.files && input.files[0];
			if (!file) { finish(''); return; }
			var reader = new FileReader();
			reader.onload = function () { finish(String(reader.result).split(',')[1] || ''); };
			reader.onerror = function () { finish(''); };
			reader.readAsDataURL(file);
		};
		input.click();
	}
};
"""

var _pick_callback: JavaScriptObject
## Callbacks stay referenced while JavaScript may call them.
var _camera_callbacks: JavaScriptObject
var _camera_callback_refs: Array[JavaScriptObject] = []
var _counting_steps: bool = false
var _steps: int = 0


func _ready() -> void:
	JavaScriptBridge.eval(HELPERS_JS, true)
	var bridge: FileAccess = FileAccess.open(BRIDGE_PATH, FileAccess.READ)
	if bridge == null:
		push_error("Web bridge missing: %s (check the Web export include filter)" % BRIDGE_PATH)
	else:
		JavaScriptBridge.eval(bridge.get_as_text(), true)


func _process(_delta: float) -> void:
	if not _counting_steps:
		return
	var steps: int = int(JavaScriptBridge.eval("window.alfaMotion.steps()", true))
	if steps != _steps:
		_steps = steps
		steps_changed.emit(steps)


func has_feature(feature: PlatformBackend.Feature) -> bool:
	match feature:
		Feature.ACCELEROMETER, Feature.PEDOMETER:
			return _is_phone() and _motion_permission() not in ["denied", "unsupported"]
		Feature.CAMERA, Feature.QR_SCAN, Feature.FACE_DETECTION:
			return bool(JavaScriptBridge.eval("window.alfaCamera.supported()", true)) and _camera_permission() != "denied"
		Feature.MICROPHONE:
			return super(feature)
		Feature.NOTIFICATIONS:
			return str(JavaScriptBridge.eval("window.alfaOffice.permission()", true)) != "unsupported"
		Feature.PHOTO_LIBRARY:
			return true
	return false


## Browsers show the permission prompt only after a tap, so call this from a button handler.
## Motion permission on iPhone is asked by the bridge on the first tap on the page.
func request_access(features: Array[PlatformBackend.Feature]) -> bool:
	if features.any(func(feature: Feature) -> bool: return feature in MOTION_FEATURES) and _motion_permission() == "denied":
		return false
	if features.any(func(feature: Feature) -> bool: return feature in CAMERA_FEATURES) and not await _request_camera():
		return false
	if not features.has(Feature.NOTIFICATIONS):
		return true
	var permission: String = str(JavaScriptBridge.eval("window.alfaOffice.permission()", true))
	if permission == "default":
		JavaScriptBridge.eval("window.alfaOffice.requestPermission()", true)
		var waited: float = 0.0
		while permission == "default" and waited < PERMISSION_TIMEOUT:
			await get_tree().process_frame
			waited += get_process_delta_time()
			permission = str(JavaScriptBridge.eval("window.alfaOffice.permission()", true))
	return permission == "granted"


func start_camera(mode: CameraMode, front: bool) -> void:
	var camera_mode: String = CAMERA_MODES.get(mode, "preview")
	_camera_callback_refs = [
		JavaScriptBridge.create_callback(_on_frame), JavaScriptBridge.create_callback(_on_qr),
		JavaScriptBridge.create_callback(_on_faces), JavaScriptBridge.create_callback(_on_camera_error),
	]
	_camera_callbacks = JavaScriptBridge.create_object("Object")
	for index: int in _camera_callback_refs.size():
		_camera_callbacks.set(["frame", "qr", "faces", "error"][index], _camera_callback_refs[index])
	var camera: JavaScriptObject = JavaScriptBridge.get_interface("alfaCamera")
	camera.call("start", camera_mode, front, _camera_callbacks)


func stop_camera() -> void:
	JavaScriptBridge.eval("window.alfaCamera.stop()", true)
	_camera_callbacks = null
	_camera_callback_refs.clear()


func start_step_counter() -> void:
	_steps = 0
	_counting_steps = true
	JavaScriptBridge.eval("window.alfaMotion.startSteps()", true)
	steps_changed.emit(0)


func stop_step_counter() -> void:
	_counting_steps = false
	JavaScriptBridge.eval("window.alfaMotion.stopSteps()", true)


func schedule_notification(id: int, title: String, body: String, delay_seconds: int) -> void:
	var helpers: JavaScriptObject = JavaScriptBridge.get_interface("alfaOffice")
	if helpers != null:
		helpers.call("schedule", id, title, body, delay_seconds * 1000)


func cancel_all_notifications() -> void:
	JavaScriptBridge.eval("window.alfaOffice.cancelAll()", true)


func page_origin() -> String:
	return str(JavaScriptBridge.eval("window.location.protocol + '//' + window.location.hostname", true))


func pick_image() -> Image:
	var helpers: JavaScriptObject = JavaScriptBridge.get_interface("alfaOffice")
	if helpers == null:
		return null
	# The callback must stay referenced until JavaScript calls it.
	_pick_callback = JavaScriptBridge.create_callback(_on_image_data)
	helpers.call("pickImage", _pick_callback)
	return await _image_picked


func _on_frame(args: Array) -> void:
	if args.size() < 3 or not args[2] is JavaScriptObject:
		return
	var rgb: PackedByteArray = JavaScriptBridge.js_buffer_to_packed_byte_array(args[2])
	var frame: Image = SensorModels.frame_from_rgb(int(args[0]), int(args[1]), rgb)
	if frame != null:
		camera_frame.emit(frame)


func _on_qr(args: Array) -> void:
	if not args.is_empty():
		qr_detected.emit(str(args[0]))


func _on_faces(args: Array) -> void:
	if not args.is_empty():
		faces_detected.emit(SensorModels.parse_faces(str(args[0])))


func _on_camera_error(args: Array) -> void:
	push_warning("Web camera: %s" % (str(args[0]) if not args.is_empty() else "error"))


## Shows the browser's camera prompt once; true when the camera may be used.
func _request_camera() -> bool:
	JavaScriptBridge.eval("window.alfaCamera.requestPermission()", true)
	var waited: float = 0.0
	while _camera_permission() in ["unknown", "pending"] and waited < PERMISSION_TIMEOUT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	return _camera_permission() == "granted"


func _camera_permission() -> String:
	return str(JavaScriptBridge.eval("window.alfaCamera.permission()", true))


func _motion_permission() -> String:
	return str(JavaScriptBridge.eval("window.alfaMotion.permission()", true))


func _is_phone() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios")


func _on_image_data(args: Array) -> void:
	_pick_callback = null
	var encoded: String = str(args[0]) if not args.is_empty() else ""
	_image_picked.emit(null if encoded.is_empty() else PlatformBackend.decode_image(Marshalls.base64_to_raw(encoded)))
