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

const BEZIER_SURFACE_SHADER = preload("res://world/bezier_surface_shader.tres")
const DEFAULT_SIZE = 10 # 10x10


## Key is the control point id, value is the ControlPoint object
var control_points: Dictionary = {} # Unlimited size.
var control_points_id: int = 0 # Increment when adding CP.

## Key is the segment id, value is the PatchSegment object
var segments: Dictionary = {} # Unlimited size.
var segment_id: int = 0 # Increment when adding segments.


	


func create_default():
	const HIGH = DEFAULT_SIZE
	const TOP_MID = DEFAULT_SIZE - (DEFAULT_SIZE/3)
	const BOTTOM_MID = DEFAULT_SIZE + (DEFAULT_SIZE/3)
	const LOW = 0
	
	control_points[control_points_id] = Corner.new(Vector3(0, HIGH, 0), self)
	var top_left_corner = control_points[control_points_id] as Corner
	control_points_id += 1
	
	control_points[control_points_id] = Corner.new(Vector3(BOTTOM_MID, HIGH, 0), self)
	var top_left_handle = control_points[control_points_id] as Handle
	control_points_id += 1
	top_left_corner.handles["east"] = top_left_handle
	top_left_handle.corner = top_left_corner
	
	control_points[control_points_id] = Corner.new(Vector3(TOP_MID, HIGH, 0), self)
	var top_right_handle = control_points[control_points_id] as Handle
	control_points_id += 1
	
	control_points[control_points_id] = Corner.new(Vector3(HIGH, HIGH, 0), self)
	var top_right_corner = control_points[control_points_id] as Corner
	control_points_id += 1
	top_right_corner.handles["west"] = top_right_handle
	top_right_handle.corner = top_right_corner
	
	
	
	
	
	
	var default_mesh_instance := MeshInstance3D.new()
	self.add_child(default_mesh_instance)
	default_mesh_instance.mesh = get_default_plane_mesh()
	default_mesh_instance.mesh.surface_set_material(0, ShaderMaterial.new())
	var mesh_mat := default_mesh_instance.mesh.surface_get_material(0) as ShaderMaterial
	mesh_mat.shader = BEZIER_SURFACE_SHADER



func create_copy():
	pass


func get_default_plane_mesh() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(DEFAULT_SIZE, DEFAULT_SIZE)
	plane.subdivide_width = 5
	plane.subdivide_depth = 5
	return plane
