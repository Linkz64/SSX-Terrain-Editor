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
		
	if Input.is_action_just_released("RightClick"):
			world.get_camera().movable = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_mouse_entered() -> void:
	is_mouse_inside_viewport = true


func _on_mouse_exited() -> void:
	is_mouse_inside_viewport = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
