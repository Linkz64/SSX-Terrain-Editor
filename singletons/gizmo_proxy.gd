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
		gizmo.transform_begin.connect(_on_transform_begin)
		gizmo.transform_changed.connect(_on_transform_changed)
		gizmo.transform_end.connect(_on_transform_end)
var gizmo: Gizmo3D
var pivot: Node3D
var orientation: int = GLOBAL:
	set(value):
		orientation = value
		_update_orientation(orientation)
var editing_mode: int = OBJECT
var sac_mode: int = FREE:
	set(value):
		sac_mode = value
		_sac_mode_changed(value)
var selected_object: PatchObject
var selected_control_point: ControlPoint
var is_editing: bool:
	get():
		return gizmo.editing
		
var _initial_positions: Array
var _initial_selected_position: Vector3




func select_control_point(cp: ControlPoint) -> void:
	gizmo.clear_selection()
	if selected_control_point:
		selected_control_point.deselect()
	selected_control_point = cp
	selected_control_point.select()
	gizmo.select(selected_control_point)


func deselect_control_point() -> void:
	gizmo.clear_selection()
	if selected_control_point == null:
		return
	selected_control_point.deselect()
	selected_control_point = null


func select_object(object: PatchObject) -> void:
	selected_object = object
	selected_object.highlight(true)
	if orientation == GLOBAL:
		pivot.global_transform.basis = Basis.IDENTITY
	elif orientation == LOCAL:
		pivot.global_transform.basis = selected_object.global_transform.basis
	pivot.global_position = selected_object.global_position
	gizmo.select(pivot)
	gizmo.mode |= gizmo.ToolMode.ROTATE


func deselect_object() -> void:
	gizmo.clear_selection()
	if selected_object:
		selected_object.highlight(false)
	selected_object = null
	gizmo.mode &= ~gizmo.ToolMode.ROTATE
	

func switch_to_object() -> void:
	editing_mode = OBJECT
	selected_object.show_grid(false)
	for cp in selected_object.get_node("ControlPoints").get_children():
		cp.remove_from_group("selectable_cps")
	
	if selected_control_point:
		selected_control_point.deselect()
	
	selected_control_point = null
	gizmo.mode |= gizmo.ToolMode.ROTATE
	
	gizmo.clear_selection()
	if selected_object:
		gizmo.select(selected_object)
	
	
func switch_to_edit() -> void:
	gizmo.clear_selection()
	editing_mode = EDIT
	selected_object.show_grid(true)
	for cp in selected_object.get_node("ControlPoints").get_children():
		cp.add_to_group("selectable_cps")
	gizmo.mode &= ~gizmo.ToolMode.ROTATE
		

##----------Private methods---------------
func _update_orientation(orientation: int) -> void:
	gizmo.use_local_space = orientation == LOCAL
		
		
func _sac_mode_changed(value: int):
	for cp in selected_object.get_node("ControlPoints").get_children():
		cp.remove_from_group("selectable_cps")
	
	if value == CORNER:
		for cp in selected_object.get_node("ControlPoints").get_children():
			if cp.type == ControlPoint.CORNER:
				cp.add_to_group("selectable_cps")
	elif value == HANDLE:
		for cp in selected_object.get_node("ControlPoints").get_children():
			if cp.type == ControlPoint.HANDLE:
				cp.add_to_group("selectable_cps")
	elif value == FREE:
		for cp in selected_object.get_node("ControlPoints").get_children():
			cp.add_to_group("selectable_cps")


func _on_transform_begin(mode: Gizmo3D.TransformMode):
	if sac_mode == CORNER:
		_initial_positions.clear()
		_initial_selected_position = selected_control_point.position
		for n in selected_control_point.get_neighbors():
			_initial_positions.append([n, n.position])
			
func _on_transform_changed(mode: Gizmo3D.TransformMode, value : Vector3):
	if editing_mode == OBJECT:
		selected_object.global_transform = pivot.global_transform
	
	if sac_mode == CORNER:
		var dir := selected_control_point.position - _initial_selected_position
		for n in _initial_positions:
			n[0].position =  n[1] + dir
	elif sac_mode == HANDLE:
		selected_control_point.align_opposite()
		for inner in selected_control_point.get_side_inners():
			inner.align()


func _on_transform_end(mode: Gizmo3D.TransformMode):
	pass


func _init() -> void:
	set_process(false) # Safety, to prevent process from using the null pivot
