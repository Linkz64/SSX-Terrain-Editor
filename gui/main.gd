extends Control


func _unhandled_input(_event: InputEvent) -> void:
	# DEBUG
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
