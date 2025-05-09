extends Node3D



#func _unhandled_input(_event: InputEvent) -> void:
	#if Input.is_action_just_pressed("AddObject"):
		#ObjectManager.request_patch_object_creation(PatchObject.InitType.DEFAULT)


func get_camera() -> Camera3D:
	return $MainCamera
