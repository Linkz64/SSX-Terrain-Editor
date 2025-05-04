extends RefCounted
class_name ControlPoint
## Base class for the 3 types of control points


enum Type {
	CORNER,
	HANDLE,
	INNER,
}

var type: Type

## Patch object that this control point belongs to
var patch_object: PatchObject
	
## Position local to the object it's part of.
var position: Vector3

## If true, it influences the control points around it based on this
## control point's movement.
var aligned: bool = true

## Reference to the 4 neighbouring control points
var neighbours: Dictionary[String, ControlPoint] = {
	"north": null,
	"west": null,
	"east": null,
	"south": null,
}


func _init(p_type: Type, p_patch_object: PatchObject, p_position: Vector3):
	type = p_type
	position = p_position
	patch_object = p_patch_object


##------------Corner-------------
## They're located on the 4 corners of a patch segment.

func get_inners() -> Array[ControlPoint]:
	assert(type == Type.CORNER)
	var inners: Array[ControlPoint]
	var north = neighbours.get("north")
	var south = neighbours.get("south")
	if north:
		var west = south.neighbours.get("west")
		var east = south.neighbours.get("east")
		if west and west not in inners:
			inners.append(west)
		if east and east not in inners:
			inners.append(east)
	if south:
		var west = south.neighbours.get("west")
		var east = south.neighbours.get("east")
		if west and west not in inners:
			inners.append(west)
		if east and east not in inners:
			inners.append(east)
	return inners


## Sets the aligned flag for all 9 Control points around it.
func set_alignment(_align_flag: bool):
	pass

##------------Handle-------------
## Handles are located othogonal to the corners.
## If aligned, they move the opposite handle to create a collinear line
## between the opposite, corner, and this handle.

func align_opposite():
	assert(type == Type.HANDLE)
	if not aligned:
		return
	var corner: ControlPoint
	var side: String
	for k in neighbours.keys():
		if neighbours[k].type == Type.CORNER:
			corner = neighbours[k]
			side = k
			break
	assert(corner)
	
	# Align to this handle's direction while preserving the distance
	var normal_from_corner: Vector3 = (position - corner.position).normalized()
	var opposite: ControlPoint = corner.neighbours[side]
	var opposite_distance_to_corner: float = (opposite.local_position - corner.local_position).length()
	opposite.local_position = (-normal_from_corner * opposite_distance_to_corner) + corner.position
	

##------------Inner-------------
## Inners are located diagonally to the corners.

## If aligned, it's position will be set to the sum of the vectors from the
## corner, to neighbouring handles of the inner.
## Corner -> Handle A + Corner -> Handle B = Inner position
func align():
	assert(type == Type.HANDLE)
	if not aligned:
		return
	
	# Find corner
	var corner: ControlPoint
	var north = neighbours.get("north")
	var south = neighbours.get("south")
	var corner_direction: String
	if north:
		var west = north.neighbours.get("west")
		var east = north.neighbours.get("east")
		if west:
			if west.type == Type.CORNER:
				corner = west
				corner_direction = "north-west"
		elif east:
			if west.type == Type.CORNER:
				corner = east
				corner_direction = "north-east"
	if south:
		var west = south.neighbours.get("west")
		var east = south.neighbours.get("east")
		if west:
			if west.type == Type.CORNER:
				corner = west
				corner_direction = "south-west"
		elif east:
			if west.type == Type.CORNER:
				corner = east
				corner_direction = "south-east"
	assert(corner)

	var handle_A: ControlPoint
	var handle_B: ControlPoint
	match corner_direction:
		"north-west":
			handle_A = neighbours["north"]
			handle_B = neighbours["west"]
		"north-east":
			handle_A = neighbours["north"]
			handle_B = neighbours["east"]
		"south-west":
			handle_A = neighbours["south"]
			handle_B = neighbours["west"]
		"south-east":
			handle_A = neighbours["south"]
			handle_B = neighbours["east"]
			
	var a = handle_A.position - corner.position	
	var b = handle_B.position - corner.position	
	position = a + b
	
	
