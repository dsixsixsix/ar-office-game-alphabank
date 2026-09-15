class_name DialogueRepository
extends RefCounted
## Loads placeholder conversations from JSON and rotates them per NPC.

const PATH: String = "res://data/dialogues.json"


class Line:
	extends RefCounted

	var is_player: bool
	var text: String

	func _init(p_is_player: bool, p_text: String) -> void:
		is_player = p_is_player
		text = p_text


var _conversations: Dictionary[String, Array] = {}
var _next_index: Dictionary[String, int] = {}


func _init() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s must contain a JSON object" % PATH)
		return
	var root: Dictionary = parsed
	for key: Variant in root:
		if key is String and not (key as String).begins_with("_") and root[key] is Array:
			_conversations[key] = root[key]


## Next conversation for npc_id; empty when the NPC has nothing to say.
func next_conversation(npc_id: String) -> Array[Line]:
	var lines: Array[Line] = []
	var conversations: Array = _conversations.get(npc_id, [])
	if conversations.is_empty():
		return lines
	var index: int = _next_index.get(npc_id, 0) % conversations.size()
	_next_index[npc_id] = index + 1
	var conversation: Variant = conversations[index]
	if not conversation is Array:
		return lines
	for entry: Variant in conversation:
		if entry is Dictionary:
			var data: Dictionary = entry
			lines.append(Line.new(data.get("who", "npc") == "player", str(data.get("text", ""))))
	return lines
