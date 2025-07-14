extends Node


# Orientation
enum {
	GLOBAL,
	LOCAL,
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
var editing_mode: int = OBJECT
var sac_mode: int = FREE
var selected_object: PatchObject
var selected_control_point: ControlPoint
var is_editing: bool:
	get():
		return gizmo.editing
var selectable_cps: Array[ControlPoint]


func select_control_point(cp: ControlPoint) -> void:
	selected_control_point = cp
func deselect_control_point() -> void:
	selected_control_point = null


func select_object(object: PatchObject) -> void:
	selected_object = object
	selected_object.highlight(true)
func deselect_object() -> void:
	if selected_object:
		selected_object.highlight(false)
	selected_object = null
	

func switch_to_object() -> void:
	pass
func switch_to_edit() -> void:
	pass


##----------Private methods---------------
func _on_transform_start(mode: Gizmo3D.TransformMode):
	pass
func _on_transform_changed(mode: Gizmo3D.TransformMode, value : Vector3):
	pass
func _on_transform_end(mode: Gizmo3D.TransformMode):
	pass


func _init() -> void:
	set_process(false) # Safety, to prevent process from using the null pivot


func _process(_delta: float) -> void:

		
	
	
	match editing_mode:
		OBJECT:
			pass
		EDIT:
			match sac_mode:
				CORNER:
					pass
				HANDLE:
					pass
				FREE:
					pass
