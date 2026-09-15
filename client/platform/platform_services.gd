extends Node
## Single entry point for platform-specific functionality (autoload "PlatformServices").
## Game code must use this instead of native plugins or JavaScriptBridge.

signal safe_rect_changed(rect: Rect2)

var _has_safe_rect_override: bool = false
var _safe_rect_override: Rect2 = Rect2()


func _ready() -> void:
	get_viewport().size_changed.connect(_emit_safe_rect)


## Area of the viewport (in viewport coordinates) not covered by notches, rounded corners or system bars.
func get_safe_rect() -> Rect2:
	if _has_safe_rect_override:
		return _safe_rect_override
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	if not OS.has_feature("mobile"):
		return visible_rect
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return visible_rect
	var to_viewport: Vector2 = visible_rect.size / window_size
	var safe_px: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var window_position: Vector2 = Vector2(DisplayServer.window_get_position())
	var safe: Rect2 = Rect2((safe_px.position - window_position) * to_viewport, safe_px.size * to_viewport)
	return safe.intersection(visible_rect)


## Used by the desktop device emulator to simulate a phone's safe area.
func set_safe_rect_override(rect: Rect2) -> void:
	_has_safe_rect_override = true
	_safe_rect_override = rect
	_emit_safe_rect()


func clear_safe_rect_override() -> void:
	_has_safe_rect_override = false
	_emit_safe_rect()


func _emit_safe_rect() -> void:
	safe_rect_changed.emit(get_safe_rect())
