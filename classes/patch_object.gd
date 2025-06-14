extends StaticBody3D
class_name PatchObject
## Patch objects represent a bezier surface. It's a parent to all the data needed to make
## an interactive and renderable surface. This script however only holds data 
## that the patch object specifically needs - or to mediate communication between
## child nodes, like the tilemap database for control point neighbor detection.
## Everything else is a node as a child of this one, that includes Collision mesh,
## control points, segments, textured mesh, wireframe mesh, and control grid.
##
## World:
##     Groups:
##         -Group_0
##         -Group_1
##         ...
##         -Group_6:
##             -Patch_Object_0
##             -Patch_Object_1
##             ...
##             -Patch_Object_6: ---StaticBody---
##             	CollisionShapeMesh
##                 Control_points:
##                     -cp0
##                     -cp1
##                     ...
##                 Patch_Segments: 
##                     -segment_0
## 		                Meshes:
## 				            TexturedMesh
## 				            WireframeMesh
## 				            ControlGrid
##                     -segment_1
##                     ...


enum {
	# An empty patch object. Used when importing json files for creating the patch through code. 
	EMPTY,
	
	# A single segment with a standard size. Used when creating a new terrain or patch object
	# with a hotkey.
	DEFAULT,
}

const DEFAULT_SEGMENT_SIZE = 100_000 # 100_000x100_000

var _init_type: int
var _object_to_copy: PatchObject
var _is_ready: bool
var _tilemap: Dictionary[ControlPoint, Vector2i]


#func _init(init_type: InitType = InitType.DEFAULT, object_to_copy: PatchObject = null):
	#_init_type = init_type
	#_object_to_copy = object_to_copy
	#if init_type == InitType.COPY:
		#assert(object_to_copy, "Object to copy is null while passing a Copy init type")


#func _ready():
	#_is_ready = true
	#match _init_type:
		#InitType.DEFAULT:
			#_create_default()
		#InitType.COPY:
			#_create_copy()



func tilemap_get_position(cp: ControlPoint) -> Variant:
	return Vector2i.ZERO # or null

func tilemap_get_control_point(cell: Vector2i) -> Variant:
	return ControlPoint.new(ControlPoint.CORNER) # or null

func tilemap_clear_cell(cell: Vector2i) -> void:
	pass

func tilemap_clear_cell_with_cp(cp: ControlPoint) -> void:
	pass


func set_wireframe_overlay(value: bool):
	for c in get_children():
		if c is TessellatedMesh:
			if value:
				c.enable_wireframe_overlay()
			else:
				c.disable_wireframe_overlay()


#func update_surface():
	#for child in get_children():
		#child.queue_free()
	#
	#for segment:PatchSegment in segments.values():
		#var cp_array: PackedVector3Array = []
		#for cp in 16:
			#var id = segment.control_point_ids[cp]
			#cp_array.append(control_points[id].position)
			#
		#var uvs: PackedVector2Array = [
			#segment.uv_points["top-left"],
			#segment.uv_points["top-right"],
			#segment.uv_points["bottom-left"],
			#segment.uv_points["bottom-right"],
		#]
		#var surface := TessellatedMesh.new(cp_array, segment.texture_filename, uvs, true)
		#add_child(surface)


#func _create_default():
	#for y in range(3, -1, -1):
		#for x in 4:
			#var new_x = x * DEFAULT_SEGMENT_SIZE/3.0
			#var new_y = y * DEFAULT_SEGMENT_SIZE/3.0
			##control_points[control_points_id] = ControlPoint.new(ControlPoint.Type.CORNER, self, Vector3(new_x, new_y, 0))
			#control_points_id += 1
			#
	## Set the ids for the segment
	#var ids: Array[int]
	#for i in 16:
		#ids.append(i)
	#
	#segments[segment_id] = PatchSegment.new(ids, self)
	#segment_id += 1
	#
	#var cp_array: Array[Vector3] = []
	#for cp in 16:
		#cp_array.append(control_points[cp].position)
	#
	## Test control grid
	##var grid := ControlGrid.new(cp_array, Color.GREEN, Color.GREEN)
	##add_child(grid)
	#
	## Test tesselated mesh
	#var uv_points: Array[Vector2] = [
		#Vector2.ZERO,
		#Vector2(1, 0),
		#Vector2(0, 1),
		#Vector2(1, 1),
	#]
	#var surface := TessellatedMesh.new(cp_array, "0001.png", uv_points, true)
	#add_child(surface)


func _create_copy():
	pass
