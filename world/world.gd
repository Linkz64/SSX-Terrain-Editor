extends Node3D


func _process(delta: float) -> void:
	$Cube.rotate_x(delta*0.7)
	$Cube.rotate_z(delta*0.87)


func get_camera():
	return $MainCamera
