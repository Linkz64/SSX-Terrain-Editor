extends Node3D





func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("AddObject"):
		ObjectManager.create_patch_object()
		AlertBus.create_side_alert("Create object in front of camera.", Enum.SideAlertType.LOG)


func get_camera() -> Camera3D:
	return $MainCamera
