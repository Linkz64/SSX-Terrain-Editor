extends SubViewportContainer


var is_mouse_inside_viewport: bool = false
@onready var world: Node3D = $Render/World


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("RightClick"):
		if is_mouse_inside_viewport:
			world.get_camera().movable = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_pressed("LeftClick"):
		var space_state = world.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(world.get_camera().position, \
				-world.get_camera().transform.basis.z * 90000)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)
		
		var mouse_screen_pos = get_viewport().get_mouse_position()
		var inside_mouse = (get_child(0) as SubViewport).get_mouse_position()
		var local_mouse_pos = get_global_transform_with_canvas().affine_inverse()
		#print(local_mouse_pos)
		#print(size)
		#print(get_viewport_transform())
		$"../ColorRect".position = inside_mouse
		#print(inside_mouse)
		print(size)
		
		
		if result:
			for node in world.get_node("Gizmo")._selections:
				node.get_child(0).material_overlay.albedo_color = Color(1, 1, 1, 0)
				
			world.get_node("Gizmo").clear_selection()
			# Selecting PatchObject
			world.get_node("Gizmo").select(result["collider"].get_parent().get_parent())
			result["collider"].get_parent().material_overlay.albedo_color = Color.ORANGE * Color(1, 1, 1, 0.5)
		
	if Input.is_action_just_released("RightClick"):
			world.get_camera().movable = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
			

func _on_mouse_entered() -> void:
	is_mouse_inside_viewport = true


func _on_mouse_exited() -> void:
	is_mouse_inside_viewport = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
