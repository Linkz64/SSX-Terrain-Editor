extends RefCounted
class_name JsonPatch

var patch_name: String = ""
var lightmap_point: Rect2
var uv_points: Array[Vector2] = [] # Size 4
var points: Array[Vector3] = [] # Size 16
var patch_style: int = 0
var tricky_only_patch: bool = false
var texture: Texture2D = null
var lightmap_id: int = 0
