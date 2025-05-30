extends Node3D

const BIG = 0xBBBBB

@onready var gizmo: Gizmo3D = $Gizmo

var object_pool: Node


func _ready():
	SaveHandler.dep_world = self
	$DirectionalLight3D.directional_shadow_max_distance = BIG
	match UserState.gizmo_orientation:
		UserState.GLOBAL:
			gizmo.use_local_space = false
		UserState.LOCAL:
			gizmo.use_local_space = true
	
	

func get_camera() -> Camera3D:
	return $MainCamera
	
	
	
