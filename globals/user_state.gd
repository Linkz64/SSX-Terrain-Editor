extends Node

## Handles the state of th user.
## Like edit mode, camera orientation.

enum GizmoOrientation {
	GLOBAL,
	LOCAL,
	CAMERA,
}
enum SACmode {
	OBJECT,
	CORNER,
	HANDLE,
	FREE,
}

var gizmo_orientation :=  GizmoOrientation.GLOBAL
var sac_mode := SACmode.OBJECT
