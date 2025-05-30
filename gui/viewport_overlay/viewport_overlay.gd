extends Control


const SIDE_ALERT = preload("res://gui/viewport_overlay/side_alert/side_alert.tscn")

@onready var object_mode_tools: PanelContainer = $ToolBar/ObjectModeTools
@onready var edit_mode_tools: PanelContainer = $ToolBar/EditModeTools
@onready var side_alerts_handler: Control = $SideAlertsHandler
@onready var sac_mode: Control = $SACMode

@onready var outline_mode_0: Panel = $EditingMode/ModeSwitch/OutlineMode0
@onready var outline_mode_1: Panel = $EditingMode/ModeSwitch/OutlineMode1

@onready var sac0_outline: Panel = $SACMode/HBoxContainer/SACMode0/Outline
@onready var sac1_outline: Panel = $SACMode/HBoxContainer/SACMode1/Outline
@onready var sac2_outline: Panel = $SACMode/HBoxContainer/SACMode2/Outline

@onready var orient0_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode0/Outline
@onready var orient1_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode1/Outline
@onready var orient2_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode2/Outline


func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	outline_mode_1.visible = false
	edit_mode_tools.visible = false
	sac_mode.visible = edit_mode_tools.visible


func _on_mode_switch_toggled(toggled_on: bool) -> void:
	object_mode_tools.visible = not toggled_on
	edit_mode_tools.visible = toggled_on
	outline_mode_0.visible = not toggled_on
	outline_mode_1.visible = toggled_on
	
	sac_mode.visible = outline_mode_1.visible


func _on_sac_mode_pressed(sac_button_index) -> void:
	match sac_button_index:
		0:
			sac0_outline.visible = true
			sac1_outline.visible = false
			sac2_outline.visible = false
		1:
			sac0_outline.visible = false
			sac1_outline.visible = true
			sac2_outline.visible = false
		2:
			sac0_outline.visible = false
			sac1_outline.visible = false
			sac2_outline.visible = true

func _on_orient_mode_pressed(orient_button_index) -> void:
	match orient_button_index:
		0:
			orient0_outline.visible = true
			orient1_outline.visible = false
			orient2_outline.visible = false
		1:
			orient0_outline.visible = false
			orient1_outline.visible = true
			orient2_outline.visible = false
		2:
			orient0_outline.visible = false
			orient1_outline.visible = false
			orient2_outline.visible = true


func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	for c in side_alerts_handler.get_children():
		c.move_up()
	
	var alert = SIDE_ALERT.instantiate()
	side_alerts_handler.add_child(alert)
	alert.init(text, type)
