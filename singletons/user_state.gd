extends Node
## Handles the state of the user.
## Like edit mode or gizmo orientation.

# Gizmo orientation
enum {
	GLOBAL,
	LOCAL,
	VIEW,
}

# SAC Modes
enum {
	OBJECT,
	CORNER,
	HANDLE,
	FREE,
}

var gizmo_orientation: int = LOCAL
var sac_mode = OBJECT
var selected_nnodes: Array
