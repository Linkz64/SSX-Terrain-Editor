extends Gizmo3D
class_name GizmoCustom




## Optional method to override the user translating the gizmo.
func _edit_translate(p_translation : Vector3) -> Vector3:
	return p_translation

## Optional method to override the user scaling the gizmo.
func _edit_scale(p_scale : Vector3) -> Vector3:
	return p_scale

## Optional method to override the user rotating the gizmo.
func _edit_rotate(p_rotation : Vector3) -> Vector3:
	return p_rotation
