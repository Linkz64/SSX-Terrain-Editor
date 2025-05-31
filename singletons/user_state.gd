extends Node
## Handles the state of the user.
## Like edit mode or gizmo orientation.

# Gizmo orientation
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

var gizmo_orientation: int = GLOBAL
var editing_mode = OBJECT
var sac_mode = FREE
var selected_nodes: Array

# Injection
var gizmo_visible: bool = true
var gizmo: Gizmo3D


func select(node: Node3D):
	selected_nodes.append(node)
	if gizmo_visible:
		gizmo.select(node)
		

func clear_selection():
	selected_nodes.clear()
	if gizmo_visible:
		gizmo.clear_selection()


func get_selection() -> Array:
	return selected_nodes


func show_gizmo():
	gizmo_visible = true
	for node in selected_nodes:
		gizmo.select(node)
	
	
func hide_gizmo():
	gizmo_visible = false
	gizmo.clear_selection()
	
	
func update_gizmo_orientation(to):
	match to:
		GLOBAL:
			gizmo_orientation = GLOBAL
			gizmo.use_local_space = false
		LOCAL:
			gizmo_orientation = GLOBAL
			gizmo.use_local_space = true
		VIEW:
			gizmo_orientation = VIEW
			# TODO
			gizmo.use_local_space = true
			
	
