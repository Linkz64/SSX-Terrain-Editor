extends Control


const SIDE_ALERT = preload("res://gui/viewport_overlay/side_alert/side_alert.tscn")

@onready var object_mode_tools: PanelContainer = $ToolBar/ObjectModeTools
@onready var edit_mode_tools: PanelContainer = $ToolBar/EditModeTools
@onready var side_alerts_handler: Control = $SideAlertsHandler
@onready var sac_mode: Control = $SACMode

@onready var outline_mode_0: Panel = $EditingMode/ModeSwitch/OutlineMode0
@onready var outline_mode_1: Panel = $EditingMode/ModeSwitch/OutlineMode1

@onready var sac_outlines: Array[Panel] = [
	$SACMode/HBoxContainer/SACMode0/Outline,
	$SACMode/HBoxContainer/SACMode1/Outline,
	$SACMode/HBoxContainer/SACMode2/Outline,
]

@onready var orient0_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode0/Outline
@onready var orient1_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode1/Outline
@onready var orient2_outline: Panel = $TransformOrientation/HBoxContainer/OrientMode2/Outline



func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	outline_mode_1.visible = false
	edit_mode_tools.visible = false
	sac_mode.visible = edit_mode_tools.visible


func _on_mode_switch_pressed() -> void:
	object_mode_tools.hide()
	edit_mode_tools.hide()
	outline_mode_0.hide()
	outline_mode_1.hide()
	sac_mode.hide()
	
	if UserState.editing_mode == UserState.OBJECT:
		UserState.editing_mode = UserState.EDIT
		edit_mode_tools.show()
		outline_mode_1.show()
		sac_mode.show()
	else:
		UserState.editing_mode = UserState.OBJECT
		object_mode_tools.show()
		outline_mode_0.show()


func _on_sac_mode_pressed(sac_button_index) -> void:
	for outline in sac_outlines:
		outline.hide()
	sac_outlines[sac_button_index].show()
	

func _on_orient_mode_pressed(orient_button_index) -> void:
	orient0_outline.hide()
	orient1_outline.hide()
	orient2_outline.hide()
	
	match orient_button_index:
		0:
			orient0_outline.show()
			UserState.update_gizmo_orientation(UserState.GLOBAL)
		1:
			orient1_outline.show()
			UserState.update_gizmo_orientation(UserState.LOCAL)
		2:
			orient2_outline.show()
			# TODO
			UserState.update_gizmo_orientation(UserState.GLOBAL)


func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	for c in side_alerts_handler.get_children():
		c.move_up()
	
	var alert = SIDE_ALERT.instantiate()
	side_alerts_handler.add_child(alert)
	alert.init(text, type)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ModeSwitch"):
		_on_mode_switch_pressed()
	
	
		
	if UserState.editing_mode == UserState.EDIT:
		if Input.is_action_just_pressed("CornerHotkey"):
			UserState.sac_mode = UserState.CORNER
			_on_sac_mode_pressed(0)
		elif Input.is_action_just_pressed("HandleHotkey"):
			UserState.sac_mode = UserState.HANDLE
			_on_sac_mode_pressed(1)
		elif Input.is_action_just_pressed("FreeHotkey"):
			UserState.sac_mode = UserState.FREE
			_on_sac_mode_pressed(2)
