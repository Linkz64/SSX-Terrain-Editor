extends Node3D


const BIG = 0xBBBBB


func _ready():
	SaveHandler.world = self
	GizmoProxy.gizmo_proxy_node = get_node("GizmoProxy")
	$DirectionalLight3D.directional_shadow_max_distance = BIG
	

func get_camera() -> Camera3D:
	return $MainCamera
	
	
	
