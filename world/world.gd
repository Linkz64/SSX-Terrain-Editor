extends Node3D

const BIG = 0xBBBBB

@onready var gizmo: Gizmo3D = $Gizmo

var object_pool: Node


func _ready():
	SaveHandler.dep_world = self
	UserState.gizmo = gizmo
	$DirectionalLight3D.directional_shadow_max_distance = BIG
	match UserState.gizmo_orientation:
		UserState.GLOBAL:
			gizmo.use_local_space = false
		UserState.LOCAL:
			gizmo.use_local_space = true
	

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("HideGizmo"):
		gizmo.hide()
	elif Input.is_action_just_released("HideGizmo"):
		gizmo.show()

func get_camera() -> Camera3D:
	return $MainCamera
	
	
	
