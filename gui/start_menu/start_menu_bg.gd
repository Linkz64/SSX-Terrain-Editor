extends ColorRect


signal clicked_bg


func _gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LeftClick"):
		clicked_bg.emit()
