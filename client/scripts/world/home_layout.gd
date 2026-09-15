class_name HomeLayout
extends MapLayout
## The player's apartment: bedroom, bathroom, hallway, living room and kitchen, plus the objects
## the player can walk up to. Remark texts live in res://data/home_remarks.json.

enum Kind { REMARK, WARDROBE, LAPTOP, DOOR, GARAGE }


class Interactable:
	extends RefCounted

	## Key in home_remarks.json.
	var id: String
	var kind: Kind
	var prop_id: String
	var prop_cell: Vector2i
	## Walkable cell where the player stands to use the object.
	var stand_cell: Vector2i

	func _init(p_id: String, p_kind: Kind, p_prop_id: String, p_prop_cell: Vector2i, p_stand_cell: Vector2i) -> void:
		id = p_id
		kind = p_kind
		prop_id = p_prop_id
		prop_cell = p_prop_cell
		stand_cell = p_stand_cell


var interactables: Array[Interactable] = []


func _init() -> void:
	size = Vector2i(20, 29)
	spawn_cell = Vector2i(15, 24)
	var s: Dictionary = OfficeTiles.Style
	add_room(&"bedroom", "HOME_ROOM_BEDROOM", Rect2i(1, 1, 10, 9), s.BEDROOM)
	add_room(&"bathroom", "HOME_ROOM_BATHROOM", Rect2i(12, 1, 5, 9), s.BATH)
	add_room(&"hall", "HOME_ROOM_HALL", Rect2i(1, 11, 18, 5), s.HALL)
	add_room(&"living", "HOME_ROOM_LIVING", Rect2i(1, 17, 10, 11), s.LIVING)
	add_room(&"kitchen", "HOME_ROOM_KITCHEN", Rect2i(12, 17, 7, 11), s.HOME_KITCHEN)
	doors = [Rect2i(5, 10, 2, 3), Rect2i(13, 10, 2, 3), Rect2i(5, 16, 2, 3), Rect2i(14, 16, 2, 3)]
	_add_props()
	finalize()


func _add_props() -> void:
	# Bedroom.
	add_prop("window", 2, 1)
	add_prop("poster_band", 6, 1)
	add_prop("clock", 9, 1)
	add_prop("nightstand", 1, 3)
	add_prop("bed_double", 2, 3)
	add_prop("nightstand", 4, 3)
	add_prop("wardrobe", 8, 3)
	add_prop("rug_bedroom", 4, 6)
	add_prop("dumbbells", 8, 8)
	add_prop("plant_small", 1, 9)
	add_prop("plant_small", 10, 9)
	_use("bed", Kind.REMARK, "bed_double", 2, 3, 4, 5)
	_use("wardrobe", Kind.WARDROBE, "wardrobe", 8, 3, 8, 4)
	_use("poster", Kind.REMARK, "poster_band", 6, 1, 6, 3)
	_use("dumbbells", Kind.REMARK, "dumbbells", 8, 8, 7, 8)
	# Bathroom.
	add_prop("towel_rail", 12, 1)
	add_prop("mirror_bath", 14, 2)
	add_prop("window_small", 16, 1)
	add_prop("washing_machine", 12, 3)
	add_prop("bath_sink", 14, 3)
	add_prop("toilet", 16, 3)
	add_prop("bath_mat", 15, 5)
	add_prop("bathtub", 12, 7)
	_use("sink", Kind.REMARK, "bath_sink", 14, 3, 14, 4)
	_use("toilet", Kind.REMARK, "toilet", 16, 3, 16, 4)
	_use("bathtub", Kind.REMARK, "bathtub", 12, 7, 13, 8)
	_use("washing_machine", Kind.REMARK, "washing_machine", 12, 3, 12, 4)
	# Hallway.
	add_prop("coat_rack", 2, 11)
	add_prop("key_hook", 8, 11)
	add_prop("frame_picture", 10, 11)
	add_prop("calendar_alfa", 16, 11)
	add_prop("front_door", 17, 11)
	add_prop("hall_mirror", 1, 13)
	add_prop("shoe_rack", 3, 13)
	add_prop("doormat", 17, 13)
	add_prop("plant_big", 9, 15)
	_use("mirror", Kind.REMARK, "hall_mirror", 1, 13, 2, 14)
	_use("coats", Kind.REMARK, "coat_rack", 2, 11, 2, 13)
	_use("keys", Kind.GARAGE, "key_hook", 8, 11, 8, 13)
	_use("calendar", Kind.REMARK, "calendar_alfa", 16, 11, 16, 13)
	_use("door", Kind.DOOR, "front_door", 17, 11, 17, 13)
	_use("plant", Kind.REMARK, "plant_big", 9, 15, 9, 14)
	# Living room.
	add_prop("window", 1, 17)
	add_prop("frame_picture", 3, 17)
	add_prop("tv", 7, 17)
	add_prop("clock", 10, 17)
	add_prop("bookshelf", 3, 19)
	add_prop("laptop_desk", 1, 20)
	add_prop("gaming_chair", 1, 21)
	add_prop("tv_console", 7, 19)
	add_prop("guitar", 10, 20)
	add_prop("rug_living", 6, 21)
	add_prop("pizza_table", 7, 22)
	add_prop("sofa_back", 7, 25)
	add_prop("floor_lamp", 10, 25)
	add_prop("pizza_boxes", 1, 27)
	add_prop("plant_big", 10, 27)
	_use("laptop", Kind.LAPTOP, "laptop_desk", 1, 20, 2, 21)
	_use("bookshelf", Kind.REMARK, "bookshelf", 3, 19, 4, 20)
	_use("tv", Kind.REMARK, "tv_console", 7, 19, 8, 20)
	_use("guitar", Kind.REMARK, "guitar", 10, 20, 9, 20)
	_use("sofa", Kind.REMARK, "sofa_back", 7, 25, 6, 25)
	_use("pizza", Kind.REMARK, "pizza_boxes", 1, 27, 2, 27)
	_use("window", Kind.REMARK, "window", 1, 17, 1, 19)
	# Kitchen.
	add_prop("window", 12, 17)
	for cabinet_x: int in [16, 17, 18]:
		add_prop("kitchen_cabinets", cabinet_x, 17)
	add_prop("fridge", 12, 19)
	add_prop("microwave", 13, 19)
	add_prop("stove", 16, 19)
	add_prop("counter_sink", 17, 19)
	add_prop("counter_kettle", 18, 19)
	add_prop("chair", 14, 22)
	add_prop("chair", 15, 22)
	add_prop("cafe_table", 14, 23)
	add_prop("trash_bin", 18, 27)
	add_prop("plant_small", 12, 27)
	_use("fridge", Kind.REMARK, "fridge", 12, 19, 12, 20)
	_use("stove", Kind.REMARK, "stove", 16, 19, 16, 20)
	_use("kettle", Kind.REMARK, "counter_kettle", 18, 19, 18, 20)
	_use("table", Kind.REMARK, "cafe_table", 14, 23, 14, 24)
	_use("trash", Kind.REMARK, "trash_bin", 18, 27, 17, 27)


func _use(id: String, kind: Kind, prop_id: String, prop_x: int, prop_y: int, stand_x: int, stand_y: int) -> void:
	interactables.append(Interactable.new(id, kind, prop_id, Vector2i(prop_x, prop_y), Vector2i(stand_x, stand_y)))


func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	for use: Interactable in interactables:
		if find_prop(use.prop_id, use.prop_cell) == null:
			errors.append("Interactable '%s' points to a missing prop %s at %s" % [use.id, use.prop_id, use.prop_cell])
		if not is_walkable_cell(use.stand_cell):
			errors.append("Interactable '%s' stand cell %s is not walkable" % [use.id, use.stand_cell])
	return errors
