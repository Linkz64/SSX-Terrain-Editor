extends ControlPoint
class_name Corner
## They're located on the 4 corners of a patch. [br]
## The corner is the main control point when it comes to communication
## between the other types.


## The 4 handles around the corner.
var handles: Dictionary = {
	"north": null,
	"west": null,
	"east": null,
	"south": null,
}

## The 4 inners around the corner. 
var inners: Dictionary = {
	"north-west": null, 
	"north-east": null,
	"south-west": null,
	"south-east": null,
}

## The patch segments that use this control point
var shared_segments: Dictionary = {
	"north-west": null, 
	"north-east": null,
	"south-west": null,
	"south-east": null,
}


func _init(p_position):
	self.position = p_position
