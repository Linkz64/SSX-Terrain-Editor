extends ControlPoint
class_name Inner
## Inners are located diagonally to the corners. [br] [br]
## This is the only control point type that only has one shared segment. We could easily 
## retrieve the patch segment by selecting this inner.


## The segment this inner is part of.
var shared_segment: PatchSegment = null

## The corner diagonal to this inner.
var corner: ControlPoint

# The 2 handles next to the inner. Only 2 of these keys are used.
var handles: Dictionary = {
	"north": null,
	"west": null,
	"east": null,
	"south": null,
}

## If aligned, their position will be set to the sum of the vectors from the
## corner, to neighbouring handles of the inner. [br]
## Corner -> Handle A + Corner -> Handle B = Inner position [br][br]
func align():
	if not aligned:
		return

	var side_handles_positions: Array[Vector3] = []
	for handle in handles.keys():
		if handles[handle]:
			side_handles_positions.append(handles[handle].local_position)
	if side_handles_positions.size() != 2:
		push_error("Not enough handles to align this inner.")
		return
	if not corner:
		push_error("Corner is invalid to align this inner.")
		return
	
	var a = side_handles_positions[0] - corner.local_position	
	var b = side_handles_positions[1] - corner.local_position	
	self.local_position = a + b
