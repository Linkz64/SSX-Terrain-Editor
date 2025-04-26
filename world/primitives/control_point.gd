extends RefCounted
class_name ControlPoint
## Base class for the 3 types of control points


## Patch object that this control point belongs to
var patch_object: PatchObject = null
	
## Position local to the object it's part of.
var local_position: Vector3 = Vector3.ZERO

## If true, it influences the control points around it based on this
## control point's movement.
var aligned: bool = true


func _init(p_position, p_patch_object):
	self.local_position = p_position
	self.patch_object = p_patch_object


func get_global_position() -> Vector3:
	if not patch_object:
		push_error("Invalid patch object")
		return Vector3.ZERO
	return patch_object.to_global(local_position)
