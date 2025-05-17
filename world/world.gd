extends Node3D

const BIG = 0xBBBBB


func _ready():
	SaveHandler.dep_world = self
	$DirectionalLight3D.directional_shadow_max_distance = BIG


func get_camera() -> Camera3D:
	return $MainCamera
