extends Node


var gizmo_proxy_node: Node3D:
	set(value):
		gizmo_proxy_node = value
		gizmo = value.get_node("Gizmo")
		pivot = value.get_node("Pivot")
		gizmo.select(pivot)
var gizmo: Gizmo3D
var pivot: Node3D


func _process(_delta: float) -> void:
	if pivot:
		var normal = -MainCamera.camera.transform.basis.z
		pivot.look_at(pivot.position + normal, Vector3.BACK)
		pivot.rotate(MainCamera.camera.transform.basis.x, -TAU/4)
	
	

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("HideGizmo"):
		gizmo_proxy_node.hide()
	elif Input.is_action_just_released("HideGizmo"):
		gizmo_proxy_node.show()
