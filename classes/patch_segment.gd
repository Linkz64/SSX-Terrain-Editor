extends RefCounted
class_name PatchSegment



"""
	The 16 control points that make up this patch segment. Instead of storing them here,
we just store the CP's id from the PatchObject They should be in the same order as the json.

	When deleting this segment, it should return this array so that the PatchObject can check
which other patches are sharing these CPs. If none other is then delete the CPs from memory.
"""
var control_point_ids: Array[int] = []

var patch_object: PatchObject = null

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


# I can set the reference of this object to null after the PatchObject calls this.
func mark_for_deletion() -> Array[int]:
	return control_point_ids
	
		
