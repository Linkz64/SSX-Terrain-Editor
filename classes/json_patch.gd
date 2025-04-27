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
