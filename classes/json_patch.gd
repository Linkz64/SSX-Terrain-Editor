extends RefCounted
class_name JsonPatch
## Data held by a patch on the json file but in godot format.


var patch_name: String = ""
var lightmap_point: Rect2
var uv_points: Array[Vector2] = [] # Size 4
var points: Array[Vector3] = [] # Size 16
var patch_style: int = 0
var tricky_only_patch: bool = false
var texture_path: String = ""
var lightmap_id: int = 0

func _to_string() -> String:
	return \
	"""
name: %s
lightmap: %s
uvs: %s
points: %s
patch style: %s
tricky only: %s
texture path: %s
lightmap id: %s
	""" % [patch_name, lightmap_point, uv_points, points, patch_style, tricky_only_patch,
	texture_path, lightmap_id]
