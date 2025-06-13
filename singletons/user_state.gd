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
var selected_nodes: Array[Node3D]
var selected_cps: Array[Node3D]

var CP_database: Array[Node3D]

# Injection
var gizmo_visible: bool = true
var gizmo: Gizmo3D
var world: Node3D


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
	if editing_mode == EDIT:
		return
	gizmo_visible = true
	for node in selected_nodes:
		gizmo.select(node)
	
	
func hide_gizmo():
	if editing_mode == EDIT:
		return
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


func switch_gizmo_to_object():
	gizmo.clear_selection()
	selected_cps.clear()
	for node in selected_nodes:
		gizmo.select(node)
	
	for grid in world.get_node("ControlPoints").get_children():
		grid.queue_free()


func switch_gizmo_to_edit():
	gizmo.clear_selection()
	for object: PatchObject in selected_nodes:
		for segment: PatchSegment in object.segments.values():
			var ids = segment.control_point_ids
			var cps: Array[Vector3]
			for id: int in ids:
				cps.append(object.control_points[id].position + object.position)
				CP_database.append(cps.back())
			
			var color = Color.GREEN
			#var grid = ControlGrid.new(cps, color, color)
			#cp_parent.add_child(grid)
	
	
	
	
	
	
