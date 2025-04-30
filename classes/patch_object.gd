extends Node3D
class_name PatchObject

"""
An object renders the segments as MeshInstance3Ds for each of them.
It also gives data for the color collision system.

This contains all the CPs. The patch segments use references from the
CPs stored here.

create_default should make the patch object have one segment, with the size of the
constant, and the rest are default values in the segment class.

"""

const ICON_GODOT = preload("res://assets/icon_godot.svg")
const DEFAULT_SIZE = 10 # 10x10


## Key is the control point id, value is the ControlPoint object
var control_points: Dictionary = {} # Unlimited size.
var control_points_id: int = 0 # Increment when adding CP.

## Key is the segment id, value is the PatchSegment object
var segments: Dictionary = {} # Unlimited size.
var segment_id: int = 0 # Increment when adding segments.


func create_default():
	segments[segment_id] = PatchSegment.new()
	var main_segment = segments[segment_id] as PatchSegment
	segment_id += 1
	
	for y in range(3, -1, -1):
		for x in 4:
			var new_x = x * DEFAULT_SIZE/3.0
			var new_y = y * DEFAULT_SIZE/3.0
			control_points[control_points_id] = ControlPoint.new(Vector3(new_x, new_y, 0), self)
			control_points_id += 1
			
	# Set the ids for the segment
	for i in 16:
		main_segment.control_point_ids.append(i)
	main_segment.patch_object = self



	control_points[0].local_position += Vector3(0, 0, 10)
	control_points[1].local_position += Vector3(0, 0, 10)
	control_points[2].local_position += Vector3(0, 0, 10)
	control_points[3].local_position += Vector3(0, 0, 10)

	control_points[4].local_position += Vector3(0, 4, 4)
	control_points[5].local_position += Vector3(0, 4, 4)
	control_points[6].local_position += Vector3(0, 4, 4)
	control_points[7].local_position += Vector3(0, 4, 4)
	

	#control_points[0].local_position += Vector3(0, 0, 5)
	#control_points[1].local_position += Vector3(0, 0, 10)
	#control_points[4].local_position += Vector3(0, 0, 10)
	#control_points[5].local_position += Vector3(0, 0, 10)
	#
	#control_points[2].local_position += Vector3(0, 0, 5)
	#control_points[3].local_position += Vector3(0, 0, 5)
	#control_points[6].local_position += Vector3(0, 0, 5)
	#control_points[7].local_position += Vector3(0, 0, 5)

	var cp_array: Array[Vector3] = []
	for cp in 16:
		cp_array.append(control_points[cp].local_position)
	
	# Test control grid
	var grid := ControlGrid.new(cp_array, Color.GREEN, Color.GREEN)
	add_child(grid)
	
	# Test tesselated mesh
	var uv_points: Dictionary = {
		"top-left": Vector2.ZERO,
		"top-right": Vector2(1, 0),
		"bottom-left": Vector2(0, 1),
		"bottom-right": Vector2(1, 1),
	}
	var surface := Tessellatedmesh.new(cp_array, "0001.png", uv_points)
	add_child(surface)
	
	


func create_copy():
	pass


func get_default_plane_mesh() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(DEFAULT_SIZE, DEFAULT_SIZE)
	plane.subdivide_width = 5
	plane.subdivide_depth = 5
	return plane
