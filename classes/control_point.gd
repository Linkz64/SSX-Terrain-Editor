extends Node3D
class_name ControlPoint
## A Control point can be a Corner, Handle, or Inner


signal local_transform_changed
signal selection_changed(select: bool)

enum {CORNER, HANDLE, INNER}

## If true, it influences the control points around it based on this
## control point's movement.
var aligned: bool = true
var type: int # CORNER, HANDLE, INNER
var tilemap_cell: Vector2i
var is_selected: bool = false


func select():
	is_selected = true
	selection_changed.emit(true)


func deselect():
	is_selected = false
	selection_changed.emit(false)


##------------Corner-------------
## They're located on the 4 corners of a patch segment.

func get_neighbors() -> Array[ControlPoint]:
	assert(type == CORNER)
	
	var offsets = {
		"north_west": Vector2i(-1, -1),
		"north_east": Vector2i(1, -1),
		"south_west": Vector2i(-1, 1),
		"south_east": Vector2i(1, 1),
		"north": Vector2i(0, -1),
		"west": Vector2i(-1, 0),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
	}
	var neighbors: Array[ControlPoint]
	for offset: Vector2i in offsets.values():
		var neighbor = _tilemap_get_cp_from_cell(tilemap_cell + offset)
		if neighbor:
			neighbors.append(neighbor)
	assert(not neighbors.is_empty(), "Corner has no neighbors")
	print(neighbors.size())
	return neighbors


func get_inners() -> Array[ControlPoint]:
	assert(type == CORNER)
	
	var offsets = {
		"north_west": Vector2i(-1, -1),
		"north_east": Vector2i(1, -1),
		"south_west": Vector2i(-1, 1),
		"south_east": Vector2i(1, 1),
	}
	var inners: Array[ControlPoint]
	for offset: Vector2i in offsets.values():
		var neighbor = _tilemap_get_cp_from_cell(tilemap_cell + offset)
		if neighbor:
			inners.append(neighbor)
	assert(not inners.is_empty(), "Corner has no inners")
	return inners


## Sets the aligned property for all 9 Control points around it.
func set_alignment(align_value: bool) -> void:
	assert(type == CORNER)
	
	var offsets = {
		"north": Vector2i(0, -1),
		"west": Vector2i(-1, 0),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
		"north_west": Vector2i(-1, -1),
		"north_east": Vector2i(1, -1),
		"south_west": Vector2i(-1, 1),
		"south_east": Vector2i(1, 1),
	}
	var neighbors_count: int = 0
	for offset: Vector2i in offsets.values():
		var neighbor: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offset)
		if neighbor:
			neighbor.aligned = align_value
			neighbors_count += 1
	assert(neighbors_count >= 3, "Corner has less than 3 neighbors.")
	

##------------Handle-------------
## Handles are located othogonal to the corners.
## If aligned, they move the opposite handle to create a collinear line
## between the opposite, corner, and this handle.

func align_opposite() -> void:
	assert(type == HANDLE)
	if not aligned:
		return
	assert(tilemap_cell)
	
	# Find the opposite handle.
	# Moving 2 cells on each side will give us only one handle, the handle we need.
	var offsets = {
		"north": Vector2i(0, -2),
		"west": Vector2i(-2, 0),
		"south": Vector2i(0, 2),
		"east": Vector2i(2, 0),
	}
	var opposite_handle: ControlPoint = null
	var opposite_handle_cell: Vector2i 
	for offset: Vector2i in offsets.values():
		var neighbor: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offset)
		if neighbor and neighbor.type == HANDLE:
			opposite_handle = neighbor
			opposite_handle_cell = tilemap_cell + offset
			break
	if not opposite_handle:
		return # Didn't find opposite handle 
	
	# Align to this handle's direction while preserving the distance

	var corner_position: Vector2i = (opposite_handle_cell + tilemap_cell) / 2 # Midpoint
	var corner: ControlPoint = _tilemap_get_cp_from_cell(corner_position)
	var normal_from_corner: Vector3 = ((position - corner.position) as Vector3).normalized()
	var opposite_distance_to_corner: float = \
			((opposite_handle.local_position - corner.local_position) as Vector3).length()
	opposite_handle.local_position = \
			(-normal_from_corner * opposite_distance_to_corner) + corner.position


func get_side_inners() -> Array[ControlPoint]:
	assert(type == HANDLE)
	
	var offsets = {
		"north": Vector2i(0, -1),
		"west": Vector2i(-1, 0),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
	}
	
	var inners: Array[ControlPoint]
	var north: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offsets["north"])
	var south: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offsets["south"])
	if north and north.type == INNER:
		inners.append(north)
	if south and south.type == INNER:
		inners.append(south)
	var west: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offsets["west"])
	var east: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offsets["east"])
	if west and west.type == INNER:
		inners.append(west)
	if east and east.type == INNER:
		inners.append(east)
	assert(not inners.is_empty(), "There are no inners next to the handle.")
	return inners


##------------Inner-------------
## Inners are located diagonally to the corners.

## If aligned, it's position will be set to the sum of the vectors from the
## corner, to neighboring handles of the inner.
## (Corner -> Handle A) + (Corner -> Handle B) = Inner position
func align():
	assert(type == INNER)
	if not aligned:
		return
	
	var offsets = {
		"north": Vector2i(0, -1),
		"west": Vector2i(-1, 0),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
		"north_west": Vector2i(-1, -1),
		"north_east": Vector2i(1, -1),
		"south_west": Vector2i(-1, 1),
		"south_east": Vector2i(1, 1),
	}
	var corner: ControlPoint
	var corner_offset: Vector2i
	var corner_count: int = 0
	# Find the corner
	for offset: Vector2i in offsets.values():
		var neighbor: ControlPoint = _tilemap_get_cp_from_cell(tilemap_cell + offset)
		if neighbor and neighbor.type == CORNER:
			corner = neighbor
			corner_offset = offset
			corner_count += 1
	assert(corner, "Inner has no corner")
	assert(corner_count == 1, "Inner has more than one corner ")
	# Find handles
	var handles: Array[ControlPoint]
	handles.append(_tilemap_get_cp_from_cell(tilemap_cell + Vector2i(corner_offset.x, 0)))
	handles.append(_tilemap_get_cp_from_cell(tilemap_cell + Vector2i(0, corner_offset.y)))
	assert(handles.size() == 2, "Inner has more/less than 2 handles")
	
	var a = handles[0].position - corner.position	
	var b = handles[1].position - corner.position	
	position = (a + b) + corner.position	
	

##------------Private-----------
func _init(p_type: int, p_tilemap_cell: Vector2i) -> void:
	type = p_type
	tilemap_cell = p_tilemap_cell


func _ready() -> void:
	set_notify_local_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and is_node_ready():
		local_transform_changed.emit()


func _tilemap_get_cp_from_cell(cell: Vector2i) -> ControlPoint:
	var control_points := get_parent().get_children()
	for cp: ControlPoint in control_points:
		if cell == cp.tilemap_cell:
			return cp
	return null
