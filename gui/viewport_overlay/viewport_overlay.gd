extends Control


const SIDE_ALERT = preload("res://gui/viewport_overlay/side_alert/side_alert.tscn")

@onready var object_mode_tools: PanelContainer = $ToolBar/ObjectModeTools
@onready var edit_mode_tools: PanelContainer = $ToolBar/EditModeTools
@onready var outline_mode_0: Panel = $EditingMode/ModeSwitch/OutlineMode0
@onready var outline_mode_1: Panel = $EditingMode/ModeSwitch/OutlineMode1
@onready var side_alerts_handler: Control = $SideAlertsHandler


func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	outline_mode_1.visible = false
	edit_mode_tools.visible = false
	

func _on_mode_switch_toggled(toggled_on: bool) -> void:
	object_mode_tools.visible = not toggled_on
	edit_mode_tools.visible = toggled_on
	outline_mode_0.visible = not toggled_on
	outline_mode_1.visible = toggled_on


func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	for c in side_alerts_handler.get_children():
		c.move_up()
	
	var alert = SIDE_ALERT.instantiate()
	side_alerts_handler.add_child(alert)
	alert.init(text, type)
