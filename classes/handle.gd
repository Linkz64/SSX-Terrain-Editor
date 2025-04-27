extends ControlPoint
class_name Handle
## Handles are located othogonal to the corners. [br] [br]
## If aligned, they move the opposite handle to create a collinear line [br]
## between the oppsite, corner, and this handle.


## The corner next to this handle
var corner: ControlPoint

## The handle to move if this handle both moves and has the align flag on.
var opposite_handle: ControlPoint

## The 2 inners orthogonal to the handle. Only 2 of these keys are used.
var inners: Dictionary = {
	"north": null,
	"west": null,
	"east": null,
	"south": null,
}

## The patch segments that use this control point. Only 2 of these keys are used.
var shared_segments: Dictionary = {
	"north": null,
	"west": null,
	"east": null,
	"south": null,
}


## Changes this handles's position so that its collinear with the corner and it's opposite 
func align():
	if not aligned:
		return
	if not opposite_handle:
		push_error("Opposite handle is invalid to align this handle.")
		return
	if not corner:
		push_error("Corner is invalid to align this handle.")
		return
	
	var corner_to_opposite = opposite_handle.local_position - corner.local_position
	self.local_position = -corner_to_opposite + corner.local_position
	
	
	
