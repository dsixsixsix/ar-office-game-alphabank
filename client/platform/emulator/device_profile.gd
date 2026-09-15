class_name DeviceProfile
extends RefCounted
## Portrait screen description of a real phone, used only by the desktop emulator.

enum Cutout { NONE, PUNCH_HOLE, WATERDROP, DYNAMIC_ISLAND }

const BASE_SIZE: Vector2i = Vector2i(360, 640)
const MM_PER_INCH: float = 25.4

var id: String
var display_name: String
## Physical resolution in portrait, pixels.
var resolution: Vector2i
## Pixel density of the real panel, used to show the screen at its physical size.
var ppi: float
## Safe-area insets in physical pixels: left, top, right, bottom.
var insets: Vector4i
var corner_radius: int
var cutout: Cutout
var home_indicator: bool


func _init(
	p_id: String,
	p_display_name: String,
	p_resolution: Vector2i,
	p_ppi: float,
	p_insets: Vector4i,
	p_corner_radius: int,
	p_cutout: Cutout,
	p_home_indicator: bool
) -> void:
	id = p_id
	display_name = p_display_name
	resolution = p_resolution
	ppi = p_ppi
	insets = p_insets
	corner_radius = p_corner_radius
	cutout = p_cutout
	home_indicator = p_home_indicator


static func all() -> Array[DeviceProfile]:
	return [
		DeviceProfile.new("pixel_8", "Google Pixel 8", Vector2i(1080, 2400), 428.0, Vector4i(0, 136, 0, 0), 110, Cutout.PUNCH_HOLE, false),
		DeviceProfile.new("iphone_15", "iPhone 15", Vector2i(1179, 2556), 460.0, Vector4i(0, 177, 0, 102), 165, Cutout.DYNAMIC_ISLAND, true),
		DeviceProfile.new("iphone_17_pro", "iPhone 17 Pro", Vector2i(1206, 2622), 460.0, Vector4i(0, 186, 0, 102), 186, Cutout.DYNAMIC_ISLAND, true),
		DeviceProfile.new("iphone_17_pro_max", "iPhone 17 Pro Max", Vector2i(1320, 2868), 460.0, Vector4i(0, 186, 0, 102), 186, Cutout.DYNAMIC_ISLAND, true),
		DeviceProfile.new("galaxy_s24", "Samsung Galaxy S24", Vector2i(1080, 2340), 416.0, Vector4i(0, 110, 0, 0), 100, Cutout.PUNCH_HOLE, false),
		DeviceProfile.new("android_hd", "Android HD+ 720p", Vector2i(720, 1600), 270.0, Vector4i(0, 80, 0, 0), 40, Cutout.WATERDROP, false),
		DeviceProfile.new("iphone_se", "iPhone SE", Vector2i(750, 1334), 326.0, Vector4i(0, 40, 0, 0), 0, Cutout.NONE, false),
	]


static func find(profile_id: String) -> DeviceProfile:
	for profile: DeviceProfile in all():
		if profile.id == profile_id:
			return profile
	return null


## Integer scale the game would use on this device (base resolution 360x640, integer scale mode).
func get_game_scale() -> int:
	return maxi(1, mini(resolution.x / BASE_SIZE.x, resolution.y / BASE_SIZE.y))


## Viewport size the game sees on this device.
func get_logical_size() -> Vector2i:
	return resolution / get_game_scale()


## Physical screen size in millimetres.
func get_size_mm() -> Vector2:
	return Vector2(resolution) / ppi * MM_PER_INCH
