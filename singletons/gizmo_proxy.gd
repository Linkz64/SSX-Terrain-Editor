extends Node


# Orientation
enum {
	GLOBAL,
	LOCAL,
	VIEW,
}

# Editing modes
enum {
	OBJECT,
	EDIT,
}

# SAC Modes
enum {
	CORNER,
	HANDLE,
	FREE,
}

var gizmo_proxy_node: Node3D:
	set(value):
		gizmo_proxy_node = value
		gizmo = value.get_node("Gizmo")
		pivot = value.get_node("Pivot")
		set_process(true)
var gizmo: Gizmo3D
var pivot: Node3D

var orientation: int = GLOBAL
var editing_mode = OBJECT
var sac_mode = FREE
var selected_objects: Array[PatchObject]
var selected_control_points: Array[ControlPoint]
var is_editing: bool:
	get():
		return gizmo.editing

var _initial_relative_position: Array[Vector3]
var _pivot_initial: Vector3


func select_single_control_point(cp: ControlPoint) -> void:
	pass


func select_multi_control_point(cp: ControlPoint) -> void:
	pass
	

func deselect_control_points() -> void:
	pass


func select_single_object(object: PatchObject) -> void:
	selected_objects.clear()
	selected_objects.append(object)
	_init_transform()
	gizmo.select(pivot)
	for obj in selected_objects:
		var pos = pivot.to_local(obj.position)
		_initial_relative_position.append(pos)
	_pivot_initial = pivot.position
	

func select_multi_object(object: PatchObject) -> void:
	selected_objects.append(object)
	_init_transform()
	gizmo.select(pivot)
	for obj in selected_objects:
		var pos = pivot.to_local(obj.position)
		_initial_relative_position.append(pos)


func deselect_objects() -> void:
	selected_objects.clear()
	gizmo.deselect(pivot)
	

func switch_to_object() -> void:
	pass


func switch_to_edit() -> void:
	pass


func show_gizmo() -> void:
	pass


func hide_gizmo() -> void:
	pass




##----------Private methods---------------
func _init() -> void:
	set_process(false) # Safety, to prevent process from using the null pivot


func _process(_delta: float) -> void:
	if pivot not in gizmo._selections.keys():
		return
	
	match editing_mode:
		OBJECT:
			for obj in selected_objects.size():
				selected_objects[obj].position = _initial_relative_position[obj] + (pivot.position - _pivot_initial)
				
		EDIT:
			pass
	
	#if pivot:
		#var normal = -MainCamera.camera.transform.basis.z
		#pivot.look_at(pivot.position + normal, Vector3.BACK)
		#pivot.rotate(MainCamera.camera.transform.basis.x, -TAU/4)



func _init_transform() -> void:
	match orientation:
		GLOBAL:
			var average := Vector3.ZERO
			for obj in selected_objects:
				average += obj.position
			average = average / selected_objects.size()
			pivot.transform = Transform3D()
			pivot.transform.origin = average


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("HideGizmo"):
		gizmo_proxy_node.hide()
	elif Input.is_action_just_released("HideGizmo"):
		gizmo_proxy_node.show()
