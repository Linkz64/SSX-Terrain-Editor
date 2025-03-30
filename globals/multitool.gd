extends RefCounted
class_name Multitool


const MISSING_TEXTURE_PATH = "res://assets/world/missing_texture.tres"


static func open_extracted_patch_data(multitool_dir: String) -> Array[JsonPatch]:
	# 	Returns an array of JsonPatch objects. Similar to the json but
	# the points are Vector3, UVs are Vector2, the lightmaps are a Rect2,
	# and the texture path is replaced with the loaded texture resource.
	#
	# 	Set the texture to missing_texture if the texture is not found. 
	# Returns an empty array if the json failed to load
	
	var json_path: String = multitool_dir.path_join("Patches.json")
	var texture_dir: String = multitool_dir.path_join("Textures")
	var _lightmaps_dir: String = multitool_dir.path_join("Lightmaps")
	
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if not json_file:
		print("Json path %s does not exist" % json_path)
		return []
	
	var json_data = JSON.parse_string(json_file.get_as_text())
	
	var final_patches: Array[JsonPatch] = []
	for json_patch in json_data["Patches"]:
		final_patches.append(JsonPatch.new())
		
		# Name
		final_patches.back().patch_name = json_patch["PatchName"]
		
		# Lightmap point
		final_patches.back().lightmap_point = \
				Rect2(
					json_patch["LightMapPoint"][0],
					json_patch["LightMapPoint"][1],
					json_patch["LightMapPoint"][2],
					json_patch["LightMapPoint"][3]
				)
		
		# UV points
		final_patches.back().uv_points =  [
					Vector2(json_patch["UVPoints"][0][0], json_patch["UVPoints"][0][1]),
					Vector2(json_patch["UVPoints"][1][0], json_patch["UVPoints"][1][1]),
					Vector2(json_patch["UVPoints"][2][0], json_patch["UVPoints"][2][1]),
					Vector2(json_patch["UVPoints"][3][0], json_patch["UVPoints"][3][1]),
				] as Array[Vector2]
		
		# Points
		for json_point in json_patch["Points"]:
			var vec3 := Utils.ssx_to_godot_position(
					Vector3(json_point[0], json_point[1], json_point[2]))
			final_patches.back().points.append(vec3)
		
		# Patch style
		final_patches.back().patch_style = json_patch["PatchStyle"]
		
		# Trick only patch
		final_patches.back().tricky_only_patch = json_patch["TrickOnlyPatch"]
		
		# Texture
		var texture_path = texture_dir.path_join(json_patch["TexturePath"])
		var texture_file = FileAccess.open(texture_path, FileAccess.READ)
		if not texture_file:
			print("Texture could not be found for patch %s " % json_patch["PatchName"])
			final_patches.back().texture = load(MISSING_TEXTURE_PATH)
		else:
			var buffer = texture_file.get_buffer(texture_file.get_length())
			var image := Image.new()
			var error = image.load_png_from_buffer(buffer)
			if error == OK:
				final_patches.back().texture = ImageTexture.create_from_image(image)
			else:
				print("Texture file is invalid. Only png is supported.")
	
		# Lightmap ID
		final_patches.back().lightmap_id = json_patch["LightmapID"]
	
	return final_patches
