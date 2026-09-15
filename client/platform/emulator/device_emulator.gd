extends CanvasLayer
## Desktop phone emulator (autoload "DeviceEmulator"). Active only in debug builds started with
## `-- --device=<id>`. Reproduces the phone's viewport size, safe area and screen cutouts.
## The window opens at the phone's physical size, computed from the phone's pixel density and the
## monitor DPI. Pass `--screen-dpi=<value>` when the OS reports the monitor DPI wrong.
## Keys: F1 help, F2 next device, F4 safe-area outline, F5/F6 zoom out/in, F7 real size / fit screen.

const DEVICE_ARG_PREFIX: String = "--device="
const DPI_ARG_PREFIX: String = "--screen-dpi="
const WINDOW_FIT_WIDTH: float = 0.92
const WINDOW_FIT_HEIGHT: float = 0.9
const HELP_DURATION: float = 5.0
const ZOOM_STEP: float = 1.1
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 4.0

var _profile_index: int = 0
var _zoom: float = 1.0
var _fit_screen: bool = false
var _profiles: Array[DeviceProfile] = []
var _frame: DeviceFrame
var _help: Label
var _help_left: float = 0.0


func _ready() -> void:
	var requested_id: String = _get_requested_device()
	if not OS.is_debug_build() or requested_id.is_empty():
		queue_free()
		return
	_profiles = DeviceProfile.all()
	_profile_index = _profiles.find_custom(func(profile: DeviceProfile) -> bool: return profile.id == requested_id)
	if _profile_index < 0:
		push_warning("Unknown device '%s', using %s" % [requested_id, _profiles[0].id])
		_profile_index = 0

	layer = 100
	_frame = DeviceFrame.new()
	add_child(_frame)
	_help = Label.new()
	_help.label_settings = LabelSettings.new()
	_help.label_settings.font_size = 10
	_help.label_settings.font_color = Color("#1d1d1f")
	_help.label_settings.outline_size = 3
	_help.label_settings.outline_color = Color.WHITE
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_help)
	_apply_profile.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			_show_help()
		KEY_F2:
			_profile_index = (_profile_index + 1) % _profiles.size()
			_apply_profile()
		KEY_F4:
			_frame.show_safe_area = not _frame.show_safe_area
		KEY_F5, KEY_F6:
			_fit_screen = false
			_zoom = clampf(_zoom * (ZOOM_STEP if key.keycode == KEY_F6 else 1.0 / ZOOM_STEP), MIN_ZOOM, MAX_ZOOM)
			_apply_profile()
		KEY_F7:
			_fit_screen = not _fit_screen
			_zoom = 1.0
			_apply_profile()


func _process(delta: float) -> void:
	if _help_left > 0.0:
		_help_left -= delta
		_help.modulate.a = clampf(_help_left, 0.0, 1.0)


func _get_requested_device() -> String:
	return _get_argument(DEVICE_ARG_PREFIX)


func _get_argument(prefix: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func _get_screen_dpi(screen: int) -> float:
	var override: String = _get_argument(DPI_ARG_PREFIX)
	if override.is_valid_float() and override.to_float() > 0.0:
		return override.to_float()
	return float(maxi(DisplayServer.screen_get_dpi(screen), 1))


## Window pixels per device pixel.
func _get_window_scale(profile: DeviceProfile, screen: int, usable: Rect2i) -> float:
	var fit: float = minf(
		usable.size.x * WINDOW_FIT_WIDTH / profile.resolution.x,
		usable.size.y * WINDOW_FIT_HEIGHT / profile.resolution.y
	)
	if _fit_screen:
		return fit
	var real_size: float = _get_screen_dpi(screen) / profile.ppi
	return minf(real_size * _zoom, fit)


func _apply_profile() -> void:
	var profile: DeviceProfile = _profiles[_profile_index]
	var game_scale: int = profile.get_game_scale()
	var logical_size: Vector2i = profile.get_logical_size()

	var root: Window = get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	root.content_scale_size = logical_size

	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen: Rect2i = DisplayServer.screen_get_usable_rect(screen_index)
	var window_scale: float = _get_window_scale(profile, screen_index, screen)
	var window_size: Vector2i = Vector2i((Vector2(profile.resolution) * window_scale).round())
	root.mode = Window.MODE_WINDOWED
	root.size = window_size
	root.position = screen.position + (screen.size - window_size) / 2
	root.title = "Office Game - %s (%dx%d, emulated)" % [profile.display_name, profile.resolution.x, profile.resolution.y]

	var insets: Vector4 = Vector4(profile.insets) / float(game_scale)
	var safe_rect: Rect2 = Rect2(
		insets.x, insets.y, logical_size.x - insets.x - insets.z, logical_size.y - insets.y - insets.w
	)
	PlatformServices.set_safe_rect_override(safe_rect)
	_frame.configure(profile, game_scale, logical_size)
	_show_help()


func _show_help() -> void:
	var profile: DeviceProfile = _profiles[_profile_index]
	var logical_size: Vector2i = profile.get_logical_size()
	var size_mm: Vector2 = profile.get_size_mm()
	var window_mm: Vector2 = Vector2(get_tree().root.size) / _get_screen_dpi(DisplayServer.window_get_current_screen()) * DeviceProfile.MM_PER_INCH
	var mode: String = "fit screen" if _fit_screen else "zoom x%.2f" % _zoom
	_help.text = "%s %dx%d\nscreen %dx%d mm, window %dx%d mm (%s)\nF2 device  F3 CRT  F4 safe area\nF5/F6 zoom  F7 real size / fit" % [
		profile.display_name, logical_size.x, logical_size.y,
		roundi(size_mm.x), roundi(size_mm.y), roundi(window_mm.x), roundi(window_mm.y), mode,
	]
	var safe_rect: Rect2 = PlatformServices.get_safe_rect()
	_help.reset_size()
	_help.position = Vector2(safe_rect.end.x - _help.size.x - 6.0, safe_rect.end.y - _help.size.y - 40.0)
	_help_left = HELP_DURATION
	_help.modulate.a = 1.0
