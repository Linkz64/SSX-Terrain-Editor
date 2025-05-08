extends Node
## All textures are loaded when a terrain file is opened or created.
## Texture requests should be asked from here.


signal loaded_textures

const MISSING_TEXTURE = preload("res://assets/world/missing_texture.tres")


var _textures: Dictionary[String, Texture2D]


func load_textures(textures_directory: String):
	if not DirAccess.dir_exists_absolute(textures_directory):
		push_warning("Could not load textures. Textures directory does not exist.")
		return
	
	var texture_filenames: PackedStringArray = DirAccess.get_files_at(textures_directory)
	for file in texture_filenames:
		var path := textures_directory.path_join(file)
		var texture_file = FileAccess.open(path, FileAccess.READ)
		var buffer = texture_file.get_buffer(texture_file.get_length())
		var image := Image.new()
		var error = image.load_png_from_buffer(buffer)
		if error == OK:
			_textures[file] = ImageTexture.create_from_image(image)
		else:
			push_warning("Texture file %s is invalid. Only png is supported." % file)
	loaded_textures.emit()


func get_texture(filename: String) -> Texture2D:
	# If the texture is not found then it will return the missing texture.
	if filename not in _textures:
		return MISSING_TEXTURE
	else:
		return _textures[filename]
