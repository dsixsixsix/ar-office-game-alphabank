class_name NpcRoster
extends RefCounted
## Prototype NPC placement and routines. Dialogue text lives in res://data/dialogues.json.


class Activity:
	extends RefCounted

	var cell: Vector2i
	var action: NpcAction.Kind
	## Direction the NPC faces while doing the action.
	var facing: Vector2

	func _init(p_cell: Vector2i, p_action: NpcAction.Kind, p_facing: Vector2) -> void:
		cell = p_cell
		action = p_action
		facing = p_facing


class Definition:
	extends RefCounted

	var id: String
	var display_name: String
	var activities: Array[Activity]

	func _init(p_id: String, p_display_name: String, p_activities: Array[Activity]) -> void:
		id = p_id
		display_name = p_display_name
		activities = p_activities


static func all() -> Array[Definition]:
	return [
		Definition.new("anna", "Аня", [
			Activity.new(Vector2i(15, 5), NpcAction.Kind.TYPING, Vector2.UP),
			Activity.new(Vector2i(2, 19), NpcAction.Kind.COFFEE, Vector2.UP),
			Activity.new(Vector2i(21, 8), NpcAction.Kind.PAPERS, Vector2.UP),
		]),
		Definition.new("sergey", "Серёга", [
			Activity.new(Vector2i(27, 5), NpcAction.Kind.TYPING, Vector2.UP),
			Activity.new(Vector2i(36, 7), NpcAction.Kind.PHONE, Vector2.RIGHT),
			Activity.new(Vector2i(30, 13), NpcAction.Kind.PHONE, Vector2.DOWN),
		]),
		Definition.new("olga", "Ольга", [
			Activity.new(Vector2i(5, 19), NpcAction.Kind.COFFEE, Vector2.UP),
			Activity.new(Vector2i(37, 21), NpcAction.Kind.PHONE, Vector2.LEFT),
			Activity.new(Vector2i(45, 26), NpcAction.Kind.WATERING, Vector2.RIGHT),
		]),
		Definition.new("igor", "Игорь Петрович", [
			Activity.new(Vector2i(6, 4), NpcAction.Kind.PAPERS, Vector2.DOWN),
			Activity.new(Vector2i(24, 13), NpcAction.Kind.PHONE, Vector2.DOWN),
			Activity.new(Vector2i(6, 19), NpcAction.Kind.COFFEE, Vector2.UP),
		]),
		Definition.new("reception", "Марина с ресепшна", [
			Activity.new(Vector2i(24, 19), NpcAction.Kind.TYPING, Vector2.DOWN),
		]),
		Definition.new("fox", "Лис (арт-директор)", [
			Activity.new(Vector2i(59, 4), NpcAction.Kind.MUSIC, Vector2.DOWN),
			Activity.new(Vector2i(52, 9), NpcAction.Kind.DANCE, Vector2.DOWN),
		]),
		Definition.new("raccoon", "Енот (UX)", [
			Activity.new(Vector2i(57, 10), NpcAction.Kind.DRINK, Vector2.RIGHT),
		]),
		Definition.new("deer", "Олень (моушн)", [
			Activity.new(Vector2i(52, 5), NpcAction.Kind.DRINK, Vector2.UP),
			Activity.new(Vector2i(53, 10), NpcAction.Kind.DANCE, Vector2.DOWN),
		]),
		Definition.new("cat", "Кошка (иллюстратор)", [
			Activity.new(Vector2i(49, 20), NpcAction.Kind.SKETCH, Vector2.UP),
			Activity.new(Vector2i(55, 11), NpcAction.Kind.DANCE, Vector2.DOWN),
		]),
	]
