extends StaticBody3D
class_name PatchObject
## Patch objects represent a bezier surface. It's a parent to all the data needed to make
## an interactive and renderable surface. This script however only holds data 
## that the patch object specifically needs - or to mediate communication between
## child nodes, like the tilemap database for control point neighbor detection.
## Everything else is a node as a child of this one, that includes Collision mesh,
## control points, segments, textured mesh, wireframe mesh, and control grid.


enum {
	# An empty patch object. Used when importing json files for creating the patch through code. 
	EMPTY,
	
	# A single segment with a standard size. Used when creating a new terrain or patch object
	# with a hotkey.
	DEFAULT,
}

const DEFAULT_SEGMENT_SIZE = 100_000 # 100_000x100_000
var _init_type: int
var _tilemap: Dictionary[ControlPoint, Vector2i]


func tilemap_get_position(cp: ControlPoint) -> Variant:
	return Vector2i.ZERO # or null

func tilemap_get_control_point(cell: Vector2i) -> Variant:
	return ControlPoint.new(ControlPoint.CORNER) # or null

func tilemap_clear_cell(cell: Vector2i) -> void:
	pass

func tilemap_clear_cell_with_cp(cp: ControlPoint) -> void:
	pass


func _init(init_type: int):
	_init_type = init_type


func _enter_tree() -> void:
	# Collision mesh
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.name = "CollisionMesh"
	var shape_node := CollisionShape3D.new()
	shape_node.shape = shape
	add_child(shape_node)
	
	# Control points parent
	var control_points_parent := Node3D.new()
	control_points_parent.name = "ControlPoints"
	add_child(control_points_parent)
	
	# Segments parent
	var segments_parent := Node3D.new()
	segments_parent.name = "PatchSegments"
	add_child(segments_parent)
	
	# Setup object if type is default
	if _init_type == DEFAULT:
		_create_default()


func _create_default():
	# Create point positions
	var points: Array[Vector3]
	var tile_positions: Array[Vector2i]
	for y in 4:
		for x in range(0, -4, -1):
			points.append(Vector3(x, y, 0) * DEFAULT_SEGMENT_SIZE)
			tile_positions.append(Vector2i(x, y))
			
	# Create control points
	var CORNERS = [0, 3, 12, 15]
	var HANDLES = [1, 2, 4, 7, 8, 11, 13, 14]
	var INNERS = [5, 6, 9, 10]
	for point_idx: int in points.size():
		var type: int
		if point_idx in CORNERS:
			type = ControlPoint.CORNER
		elif point_idx in HANDLES:
			type = ControlPoint.HANDLE
		elif point_idx in INNERS:
			type = ControlPoint.INNER
		else:
			assert(false, "Point index out of range")
			
		var cp = ControlPoint.new(type)
		get_node("ControlPoints").add_child(cp)
		cp.position = points[point_idx]
		_tilemap[cp] = tile_positions[point_idx]
	
	# Create segment
	var segment = PatchSegment.new(tile_positions)
	get_node("PatchSegments").add_child(segment)
	
	
	
	
	
	
