extends SubViewportContainer

const RAY_DISTANCE = 1_000_000

var is_mouse_inside_viewport: bool = false
@onready var render: SubViewport = $Render
@onready var world: Node3D = $Render/World
#@onready var gizmo: Node3D = $Render/World/Gizmo
@export var viewport_overlay: Node


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("RightClick"):
		if is_mouse_inside_viewport:
			world.get_camera().movable = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_released("RightClick"):
			world.get_camera().movable = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if Input.is_action_just_pressed("LeftClick") and GizmoProxy.editing_mode == GizmoProxy.OBJECT:
		var space_state = world.get_world_3d().direct_space_state
		var camera: Camera3D = world.get_camera()
		
		# Wait one frame to see if the user clicked over the gizmo
		await get_tree().process_frame
		if GizmoProxy.is_editing:
			return
			
		var screen_position = render.get_mouse_position()
		var start = camera.project_ray_origin(screen_position)
		var end = (camera.project_ray_normal(screen_position) * RAY_DISTANCE) + start
		var query = PhysicsRayQueryParameters3D.create(start, end)
		var result = space_state.intersect_ray(query)

		GizmoProxy.deselect_object()
		if result:
			GizmoProxy.select_object(result["collider"])
	elif Input.is_action_just_pressed("LeftClick") and GizmoProxy.editing_mode == GizmoProxy.EDIT:
		const CLICK_THRESHHOLD = 5
		var selected_cp: ControlPoint
		var mouse_position = render.get_mouse_position()
		var camera: Camera3D = world.get_camera()
		for cp: ControlPoint in get_tree().get_nodes_in_group("selectable_cps"):
			var pos = camera.unproject_position(cp.global_position)
			if pos.distance_to(mouse_position) < CLICK_THRESHHOLD:
				selected_cp = cp
				break
				
		# Wait one frame to see if the user clicked over the gizmo
		await get_tree().process_frame	
		if GizmoProxy.is_editing:
			return
			
		if selected_cp:
			GizmoProxy.select_control_point(selected_cp)
		else:
			GizmoProxy.deselect_control_point()

func _on_mouse_entered() -> void:
	is_mouse_inside_viewport = true


func _on_mouse_exited() -> void:
	is_mouse_inside_viewport = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
