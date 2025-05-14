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

enum InitType {
	EMPTY,
	DEFAULT,
	COPY,
}
const DEFAULT_SEGMENT_SIZE = 10 # 10x10

var control_points: Dictionary[int, ControlPoint] = {}
var control_points_id: int = 0 # Increment when adding CP. Unique to this object

var segments: Dictionary[int, PatchSegment] = {}
var segment_id: int = 0 # Increment when adding segments. Unique to this object

var _init_type: InitType
var _object_to_copy: PatchObject
var _is_ready: bool


func _init(init_type: InitType = InitType.DEFAULT, object_to_copy: PatchObject = null):
	_init_type = init_type
	_object_to_copy = object_to_copy
	if init_type == InitType.COPY:
		assert(object_to_copy, "Object to copy is null while passing a Copy init type")


func _ready():
	_is_ready = true
	match _init_type:
		InitType.DEFAULT:
			_create_default()
		InitType.COPY:
			_create_copy()


func set_wireframe_overlay(value: bool):
	for c in get_children():
		if c is TessellatedMesh:
			if value:
				c.enable_wireframe_overlay()
			else:
				c.disable_wireframe_overlay()



func update_surface():
	for child in get_children():
		child.queue_free()
	
	for segment:PatchSegment in segments.values():
		var cp_array: PackedVector3Array = []
		for cp in 16:
			var id = segment.control_point_ids[cp]
			cp_array.append(control_points[id].position)
			
		var uvs: PackedVector2Array = [
			segment.uv_points["top-left"],
			segment.uv_points["top-right"],
			segment.uv_points["bottom-left"],
			segment.uv_points["bottom-right"],
		]
		var surface := TessellatedMesh.new(cp_array, segment.texture_filename, uvs, true)
		
		for i in cp_array.size():
			if i != 0 and cp_array[i] == Vector3.ZERO:
				print(cp_array)
				print("\n")
				break
		
		add_child(surface)


func _create_default():
	for y in range(3, -1, -1):
		for x in 4:
			var new_x = x * DEFAULT_SEGMENT_SIZE/3.0
			var new_y = y * DEFAULT_SEGMENT_SIZE/3.0
			control_points[control_points_id] = ControlPoint.new(ControlPoint.Type.CORNER, self, Vector3(new_x, new_y, 0))
			control_points_id += 1
			
	# Set the ids for the segment
	var ids: Array[int]
	for i in 16:
		ids.append(i)
	
	segments[segment_id] = PatchSegment.new(ids, self)
	segment_id += 1
	
	var cp_array: Array[Vector3] = []
	for cp in 16:
		cp_array.append(control_points[cp].position)
	
	# Test control grid
	#var grid := ControlGrid.new(cp_array, Color.GREEN, Color.GREEN)
	#add_child(grid)
	
	# Test tesselated mesh
	var uv_points: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
	]
	var surface := TessellatedMesh.new(cp_array, "0025.png", uv_points, true)
	add_child(surface)


func _create_copy():
	pass
