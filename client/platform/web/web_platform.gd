extends PlatformBackend
## Web implementation (v2). Accelerometer (DeviceMotion) and microphone come from the Godot core.
## Camera, QR (getUserMedia + jsQR), MediaPipe and the Web Speech API will be bridged through
## JavaScriptBridge here; until then those features report unsupported and tasks use fallbacks.
## Notifications use the Notification API: they are timed in the page, so they arrive only while the
## game tab is open (closed-tab delivery needs Web Push from the server). On iPhone the API exists
## only for a web app added to the home screen (iOS 16.4+).
## Pictures are picked with a hidden <input type="file">.

const PERMISSION_TIMEOUT: float = 60.0
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


func _ready() -> void:
	JavaScriptBridge.eval(HELPERS_JS, true)


func has_feature(feature: PlatformBackend.Feature) -> bool:
	match feature:
		Feature.ACCELEROMETER:
			return OS.has_feature("web_android") or OS.has_feature("web_ios")
		Feature.MICROPHONE:
			return super(feature)
		Feature.NOTIFICATIONS:
			return str(JavaScriptBridge.eval("window.alfaOffice.permission()", true)) != "unsupported"
		Feature.PHOTO_LIBRARY:
			return true
	return false


## Browsers show the permission prompt only after a tap, so call this from a button handler.
func request_access(features: Array[PlatformBackend.Feature]) -> bool:
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


func schedule_notification(id: int, title: String, body: String, delay_seconds: int) -> void:
	var helpers: JavaScriptObject = JavaScriptBridge.get_interface("alfaOffice")
	if helpers != null:
		helpers.call("schedule", id, title, body, delay_seconds * 1000)


func cancel_all_notifications() -> void:
	JavaScriptBridge.eval("window.alfaOffice.cancelAll()", true)


func page_host() -> String:
	return str(JavaScriptBridge.eval("window.location.hostname", true))


func pick_image() -> Image:
	var helpers: JavaScriptObject = JavaScriptBridge.get_interface("alfaOffice")
	if helpers == null:
		return null
	# The callback must stay referenced until JavaScript calls it.
	_pick_callback = JavaScriptBridge.create_callback(_on_image_data)
	helpers.call("pickImage", _pick_callback)
	return await _image_picked


func _on_image_data(args: Array) -> void:
	_pick_callback = null
	var encoded: String = str(args[0]) if not args.is_empty() else ""
	_image_picked.emit(null if encoded.is_empty() else PlatformBackend.decode_image(Marshalls.base64_to_raw(encoded)))
