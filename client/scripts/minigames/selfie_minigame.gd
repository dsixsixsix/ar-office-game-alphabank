class_name SelfieMinigame
extends Minigame
## "Selfie with a colleague": two or more smiling faces in the front camera, then the colleague's
## profile code confirms who was there. The server checks the colleague and daily repeats.
## No photo is stored or sent.

const MIN_FACES: int = 2
const SMILE_THRESHOLD: float = 0.7
const HOLD_SECONDS: float = 1.0
const DEFAULT_TIME_LIMIT: float = 120.0

var _faces: Array[SensorModels.Face] = []
var _hold: float = 0.0
var _time_left: float = DEFAULT_TIME_LIMIT
var _captured: bool = false
var _flash: float = 0.0

var _view: CameraView
var _status: Label


func _ready() -> void:
	if task != null:
		_time_left = float(task.params.get("time_limit", DEFAULT_TIME_LIMIT))
	add_hint(tr("MG_SELFIE_HINT"))
	_view = add_camera_view()
	_view.overlay = _draw_faces
	_status = add_status()
	PlatformServices.faces_detected.connect(_on_faces)
	PlatformServices.start_camera(PlatformBackend.CameraMode.FACES, true)


func _exit_tree() -> void:
	super()
	PlatformServices.faces_detected.disconnect(_on_faces)


func _on_faces(faces: Array[SensorModels.Face]) -> void:
	_faces = faces


func _smiling_count() -> int:
	return _faces.filter(func(face: SensorModels.Face) -> bool: return face.smiling >= SMILE_THRESHOLD).size()


func _process(delta: float) -> void:
	super(delta)
	_flash = maxf(0.0, _flash - delta * 1.5)
	if is_done():
		return
	_time_left -= delta
	if _time_left <= 0.0:
		finish(false)
		return
	if _captured:
		return
	var all_smiling: bool = _faces.size() >= MIN_FACES and _smiling_count() >= MIN_FACES
	_hold = _hold + delta if all_smiling else 0.0
	_status.text = "%s   %s" % [tr("MG_SELFIE_FACES") % [_smiling_count(), _faces.size()], tr("MG_TIME") % ceili(_time_left)]
	if _hold >= HOLD_SECONDS:
		_capture()
	_view.queue_redraw()


func _capture() -> void:
	_captured = true
	_flash = 1.0
	proof["faces"] = _faces.size()
	PlatformServices.stop_camera()
	await get_tree().create_timer(0.6).timeout
	var payload: QrPayload = await scan_qr(tr("MG_SELFIE_SCAN"), QrPayload.Kind.USER)
	proof["colleague_id"] = payload.value
	set_score(1.0)
	finish(true)


func _draw_faces(view: CameraView, image_rect: Rect2) -> void:
	for face: SensorModels.Face in _faces:
		var rect: Rect2 = Rect2(image_rect.position + face.bounds.position * image_rect.size, face.bounds.size * image_rect.size)
		var color: Color = UiStyle.RED if face.smiling >= SMILE_THRESHOLD else Color.WHITE
		view.draw_rect(rect, color, false, 2.0)
	if _flash > 0.0:
		view.draw_rect(Rect2(Vector2.ZERO, view.size), Color(1, 1, 1, _flash))
