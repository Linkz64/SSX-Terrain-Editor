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
const BEZIER_SURFACE_SHADER = preload("res://world/bezier_surface_shader.tres")
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
	
	control_points[5].local_position += Vector3(0, 0, 10)
	
	var default_mesh_instance := MeshInstance3D.new()
	self.add_child(default_mesh_instance)
	default_mesh_instance.mesh = get_default_plane_mesh()
	default_mesh_instance.mesh.surface_set_material(0, ShaderMaterial.new())
	var mesh_mat := default_mesh_instance.mesh.surface_get_material(0) as ShaderMaterial
	mesh_mat.shader = BEZIER_SURFACE_SHADER
	mesh_mat.set_shader_parameter("image", ICON_GODOT)
	
	var cp_array = []
	for cp in 16:
		cp_array.append(control_points[cp].local_position)
	mesh_mat.set_shader_parameter("control_points", cp_array)


func create_copy():
	pass


func get_default_plane_mesh() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(DEFAULT_SIZE, DEFAULT_SIZE)
	plane.subdivide_width = 5
	plane.subdivide_depth = 5
	return plane
