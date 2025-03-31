extends Camera3D


const ROTATION_SENSITIVITY = Vector2(0.004, 0.004)
const SPEED_RANGE = {"min": 1, "max": 200}
const SPEED_RANGE_CHANGE = 4
var movable: bool = false
var speed: float = 30
var _rotation: Vector2 = Vector2.ZERO




func _unhandled_input(event: InputEvent) -> void:
	if not movable:
		return

	if event is InputEventMouseMotion:
		_rotation.y += event.screen_relative.x * ROTATION_SENSITIVITY.x
		_rotation.x += event.screen_relative.y * ROTATION_SENSITIVITY.y
		_rotation.x = clampf(_rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("CameraSpeedUp"):
		speed += SPEED_RANGE_CHANGE
	if Input.is_action_just_pressed("CameraSpeedDown"):
		speed -= SPEED_RANGE_CHANGE
	speed = clampf(speed, SPEED_RANGE["min"], SPEED_RANGE["max"])


func _process(delta: float) -> void:
	if not movable:
		return
	
	self.quaternion = Quaternion(Vector3.UP, -_rotation.y)
	self.quaternion = Quaternion(self.basis.x, -_rotation.x) * self.quaternion
	
	var direction := Vector3.ZERO
	if Input.is_action_pressed("CameraForward"):
		direction += -basis.z
	if Input.is_action_pressed("CameraBackward"):
		direction += basis.z
	if Input.is_action_pressed("CameraLeft"):
		direction += -basis.x
	if Input.is_action_pressed("CameraRight"):
		direction += basis.x
	if Input.is_action_pressed("CameraUp"):
		direction += basis.y
	if Input.is_action_pressed("CameraDown"):
		direction += -basis.y
	direction = direction.normalized()
	self.global_translate(direction * speed * delta)
	
	
	
