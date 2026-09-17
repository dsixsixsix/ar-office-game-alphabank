extends Node
## Loads every game script and reports parse errors. Runs as a scene so autoloads exist:
## godot --headless --path client res://tools/check_scripts.tscn

const ROOTS: Array[String] = ["res://scripts", "res://platform", "res://tools", "res://tests"]


func _ready() -> void:
	var failed: int = 0
	var checked: int = 0
	for root: String in ROOTS:
		for path: String in _collect(root):
			if path == get_script().resource_path:
				continue
			checked += 1
			var script: GDScript = load(path) as GDScript
			if script == null or not script.can_instantiate():
				failed += 1
				printerr("FAILED: %s" % path)
	print("Checked %d scripts, %d failed" % [checked, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _collect(directory: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for file: String in DirAccess.get_files_at(directory):
		if file.get_extension() == "gd":
			result.append(directory.path_join(file))
	for child: String in DirAccess.get_directories_at(directory):
		result.append_array(_collect(directory.path_join(child)))
	return result
