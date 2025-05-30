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

var gizmo_orientation: int = LOCAL
var editing_mode = OBJECT
var sac_mode = FREE
var selected_nodes: Array
