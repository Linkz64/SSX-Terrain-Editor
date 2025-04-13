extends Node3D
class_name PatchObject


const DEFAULT_SIZE = 10 # 10x10

var control_points: Array[Vector3] = [] # Unlimited size.
var segments: Array[PatchSegment] = [] # Unlimited size.


func get_default_plane_mesh() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(3, 3)
	plane.subdivide_width = 5
	plane.subdivide_depth = 5
	return plane
