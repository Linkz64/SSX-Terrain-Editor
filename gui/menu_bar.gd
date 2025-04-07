extends ColorRect


@export var start_menu: Control

@onready var start_button: MenuButton = $StartButton


func _ready() -> void:
	start_button.get_popup().connect("index_pressed", _on_s_index_pressed)


func _on_s_index_pressed(index: int) -> void:
	match index:
		0:
			start_menu.activate()


func _on_start_button_pressed() -> void:
	start_button.get_popup().position = Vector2i(4, 32)
	start_button.get_popup().size = Vector2i(90, 60)
