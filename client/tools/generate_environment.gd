extends SceneTree
## Generates the 32px tile atlas and the prop atlas with its manifest.
## Run: godot --headless --path client --script res://tools/generate_environment.gd


func _init() -> void:
	_save(TilePainter.new().paint(), OfficeTiles.TEXTURE_PATH)
	var props: PropAtlasBuilder = PropAtlasBuilder.new()
	props.build()
	_save(props.image, PropCatalog.TEXTURE_PATH)
	var file: FileAccess = FileAccess.open(PropCatalog.MANIFEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(props.manifest, "\t"))
	print("Saved ", PropCatalog.MANIFEST_PATH)
	quit()


func _save(image: Image, path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error: Error = image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])
	else:
		print("Saved ", path)
