extends RefCounted
class_name Multitool
## Helper and utility functions for interacting with Multitool formats
## https://github.com/GlitcherOG/SSX-Collection-Multitool


const MISSING_TEXTURE_PATH = "res://assets/world/missing_texture.tres"


## Returns an array of JsonPatch objects - based on the patch.json.
static func open_extracted_patch_data(multitool_dir: String) -> Array[JsonPatch]:
	var json_path: String = multitool_dir.path_join("Patches.json")
	var _lightmaps_dir: String = multitool_dir.path_join("Lightmaps")
	
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if not json_file:
		push_error("Json path %s does not exist" % json_path)
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
			var vec3 := Vector3(json_point[0], json_point[1], json_point[2])
			final_patches.back().points.append(vec3)
		
		# Patch style
		final_patches.back().patch_style = json_patch["PatchStyle"]
		
		# Trick only patch
		final_patches.back().tricky_only_patch = json_patch["TrickOnlyPatch"]
		
		# Texture path
		final_patches.back().texture_path = json_patch["TexturePath"]
	
		# Lightmap ID
		final_patches.back().lightmap_id = json_patch["LightmapID"]
	
	return final_patches
