extends Control

@onready var outline_mode_0: Panel = $ModeSwitch/OutlineMode0
@onready var outline_mode_1: Panel = $ModeSwitch/OutlineMode1

func _ready() -> void:
	outline_mode_0.visible = true
	outline_mode_1.visible = false

func _on_mode_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		outline_mode_0.visible = false
		outline_mode_1.visible = true
	else:
		outline_mode_0.visible = true
		outline_mode_1.visible = false
