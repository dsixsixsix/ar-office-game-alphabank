extends SceneTree
## Generates 3/4-view NPC sheets: assets/characters/<id>.png (6x3 frames of 48x64).
## The player sheet is painted at runtime from the saved outfit.
## Run: godot --headless --path client --script res://tools/generate_characters.gd


func _init() -> void:
	var looks: Dictionary[String, Dictionary] = CharacterLooks.all()
	for id: String in looks:
		var sheet: PixelCanvas = PixelCanvas.create(CharacterPainter.sheet_size())
		CharacterPainter.new(looks[id]).paint_sheet(sheet)
		_save(sheet.image, "res://assets/characters/%s.png" % id)
	quit()


func _save(image: Image, path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error: Error = image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])
	else:
		print("Saved ", path)
