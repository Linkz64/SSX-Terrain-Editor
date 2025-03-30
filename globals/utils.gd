extends RefCounted
class_name Utils


static func ssx_to_godot_position(ssx_position: Vector3) -> Vector3:
	return Vector3(0, 0, 0)


static func godot_to_ssx_position(godot_position: Vector3) -> Vector3:
	return Vector3(0, 0, 0)
	
	
static func parse_multitool_json(multitool_dir: String) -> Array:
	# Returns an array of JsonPatch objects. Similar to the json but
	# the points are Vector3, UVs are Vector2, the lightmaps are a Rect2,
	# and the texture path is replaced with the loaded texture resource.
	#
	# Set the texture to missing_texture if the texture is not found. 
	# Returns an empty array if the json failed to load
	
	
	var json_path: String = multitool_dir.path_join("Patches.json")
	var texture_dir: String = multitool_dir.path_join("Textures")
	var lightmaps_dir: String = multitool_dir.path_join("Lightmaps")
	
	
	var json_file: FileAccess = FileAccess.open(multitool_dir, FileAccess.READ)
	
	
	
	
	var data = json_file.get_as_text()
	var json_data = JSON.parse_string(data)
	
	var patches: Array = []
	for patch in json_data["Patches"]:
		patches.append({})
		# Points
		patches.back()["Points"]= []
		for points in patch["Points"]:
			patches.back()["Points"].append(Vector3(points[0], points[2], -points[1]))
		
		# UVs
		patches.back()["UVPoints"] = []
		for uv in patch["UVPoints"]:
			patches.back()["UVPoints"].append(Vector2(uv[0], uv[1]))
			
		# Texture
		patches.back()["TexturePath"] = patch["TexturePath"]
	
	
	
		
	var path = dir_path.path_join("Textures".path_join(patch["TexturePath"]))
	var texture_file = FileAccess.open(path, FileAccess.READ)
	
	var buffer = texture_file.get_buffer(texture_file.get_length())
	var image = Image.new()
	var error = image.load_png_from_buffer(buffer)
	var texture: ImageTexture
	if error == OK:
		texture = ImageTexture.create_from_image(image)
	
	
	return patches
