extends Node3D
class_name PatchSegment
## Patch segments represent a single patch from a Patch object.
## It keeps a list of 16 cells from the Patch object's tilemap, each of those is a Control point
## for rendering the meshes, and the collision shapes.


var surface_type: Enum.SurfaceType = Enum.SurfaceType.SNOW_MAIN
var texture_filename: String = "0001.png"
var showoff_only: bool = false
var uv_points: Dictionary = {
	"top-left": Vector2.ZERO,
	"top-right": Vector2(1, 0),
	"bottom-left": Vector2(0, 1),
	"bottom-right": Vector2(1, 1),
}
var lightmap_point: Rect2 = Rect2(0, 0, 0.0625, 0.0625)
var lightmap_id: int = 0

var control_point_cells: Array[Vector2i]


func _ready() -> void:
	var patch_object: PatchObject = get_parent().get_parent()
	for cell in control_point_cells:
		var cp: ControlPoint = patch_object.tilemap_get_control_point(cell)
		assert(cp)
		cp.local_transform_changed.connect(_control_point_moved)
		cp.selection_changed.connect(_control_point_selection_changed)
	

func _control_point_moved():
	pass

func _control_point_selection_changed(select: bool):
	pass
