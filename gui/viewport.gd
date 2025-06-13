extends SubViewportContainer

const RAY_DISTANCE = 1_000_000

var is_mouse_inside_viewport: bool = false
@onready var render: SubViewport = $Render
@onready var world: Node3D = $Render/World
@onready var gizmo: Node3D = $Render/World/Gizmo
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
			
	if Input.is_action_just_pressed("MultiSelect") and UserState.editing_mode == UserState.OBJECT:
		var space_state = world.get_world_3d().direct_space_state
		var camera: Camera3D = world.get_camera()
		
		# wait one frame to see if the user clicked over the gizmo
		await get_tree().process_frame
		if gizmo._editing:
			return
			
		var screen_position = get_viewport().get_mouse_position() + Vector2(0, 32)#position
		var start = camera.project_ray_origin(screen_position)
		var end = (camera.project_ray_normal(screen_position) * RAY_DISTANCE) + start
		var query = PhysicsRayQueryParameters3D.create(start, end)
		var result = space_state.intersect_ray(query)
		
		if result:
			# Selecting PatchObject
			UserState.select(result["collider"].get_parent().get_parent())
			result["collider"].get_parent().material_overlay.albedo_color = Color.ORANGE * Color(1, 1, 1, 0.5)
	elif Input.is_action_just_pressed("LeftClick") and UserState.editing_mode == UserState.OBJECT:
		var space_state = world.get_world_3d().direct_space_state
		var camera: Camera3D = world.get_camera()
		
		# Wait one frame to see if the user clicked over the gizmo
		await get_tree().process_frame
		if gizmo._editing:
			return
			
		var screen_position = render.get_mouse_position()
		var start = camera.project_ray_origin(screen_position)
		var end = (camera.project_ray_normal(screen_position) * RAY_DISTANCE) + start
		var query = PhysicsRayQueryParameters3D.create(start, end)
		var result = space_state.intersect_ray(query)

		#world.get_node("Cube").position = start
		#world.get_node("Cube2").position = end
		
		for node in UserState.get_selection():
			node.get_child(0).material_overlay.albedo_color = Color(1, 1, 1, 0)
		UserState.clear_selection()
		
		if result:
			# Selecting PatchObject
			UserState.select(result["collider"].get_parent().get_parent())
			result["collider"].get_parent().material_overlay.albedo_color = Color.ORANGE * Color(1, 1, 1, 0.5)
			#world.get_node("Cube3").position = result["position"]

	if Input.is_action_just_pressed("HideGizmo"):
		UserState.hide_gizmo()
	elif Input.is_action_just_released("HideGizmo"):
		UserState.show_gizmo()


func _on_mouse_entered() -> void:
	is_mouse_inside_viewport = true


func _on_mouse_exited() -> void:
	is_mouse_inside_viewport = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
