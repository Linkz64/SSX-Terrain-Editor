extends Control


const SIDE_ALERT = preload("res://gui/viewport_overlay/side_alert/side_alert.tscn")

@onready var object_mode_tools: PanelContainer = $ToolBar/ObjectModeTools
@onready var edit_mode_tools: PanelContainer = $ToolBar/EditModeTools
@onready var side_alerts_handler: Control = $SideAlertsHandler
@onready var sac_mode: Control = $SACMode
@onready var outline_modes: Array[Panel] = [
	$EditingMode/ModeSwitch/OutlineMode0,
	$EditingMode/ModeSwitch/OutlineMode1,
]
@onready var sac_outlines: Array[Panel] = [
	$SACMode/HBoxContainer/SACMode0/Outline,
	$SACMode/HBoxContainer/SACMode1/Outline,
	$SACMode/HBoxContainer/SACMode2/Outline,
]
@onready var orient_outlines: Array[Panel] = [
	$TransformOrientation/HBoxContainer/OrientMode0/Outline,
	$TransformOrientation/HBoxContainer/OrientMode1/Outline,
	$TransformOrientation/HBoxContainer/OrientMode2/Outline,
]


func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	outline_modes[1].visible = false
	edit_mode_tools.visible = false
	sac_mode.visible = edit_mode_tools.visible
	_on_sac_mode_pressed(2)


func _on_mode_switch_pressed() -> void:
	if GizmoProxy.selected_object == null:
		return
	
	object_mode_tools.hide()
	edit_mode_tools.hide()
	outline_modes[0].hide()
	outline_modes[1].hide()
	sac_mode.hide()
	
	if GizmoProxy.editing_mode == GizmoProxy.OBJECT:
		GizmoProxy.switch_to_edit()
		edit_mode_tools.show()
		outline_modes[1].show()
		sac_mode.show()
	else:
		GizmoProxy.switch_to_object()
		object_mode_tools.show()
		outline_modes[0].show()


func _on_sac_mode_pressed(sac_button_index) -> void:
	for outline in sac_outlines:
		outline.hide()
	sac_outlines[sac_button_index].show()
	

func _on_orient_mode_pressed(orient_button_index) -> void:
	# 0 - GLobal
	# 1 - Local
	# 2 - View
	for outline in orient_outlines:
		outline.hide()
	orient_outlines[orient_button_index].show()
	GizmoProxy.orientation = orient_button_index


func _on_add_segment_pressed() -> void:
	var object = GizmoProxy.selected_object
	var control_point = GizmoProxy.selected_control_point
	if object == null or control_point == null:
		return
	if control_point.type != ControlPoint.HANDLE:
		AlertBus.create_side_alert("Can only create segments from handles", Enum.SideAlertType.ERROR)
		return
	object.create_segment_from_handle(control_point)

func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	for c in side_alerts_handler.get_children():
		c.move_up()
	
	var alert = SIDE_ALERT.instantiate()
	side_alerts_handler.add_child(alert)
	alert.init(text, type)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ModeSwitch"):
		_on_mode_switch_pressed()
	
	if GizmoProxy.editing_mode == GizmoProxy.EDIT:
		if Input.is_action_just_pressed("AlignToggle"):
			var cp = GizmoProxy.selected_control_point
			if cp and cp.type == ControlPoint.HANDLE:
				cp.aligned = not cp.aligned
				print("Pressed")
		
		if Input.is_action_just_pressed("CornerHotkey"):
			GizmoProxy.sac_mode = GizmoProxy.CORNER
			_on_sac_mode_pressed(0)
			GizmoProxy.deselect_control_point()
		elif Input.is_action_just_pressed("HandleHotkey"):
			GizmoProxy.sac_mode = GizmoProxy.HANDLE
			_on_sac_mode_pressed(1)
			GizmoProxy.deselect_control_point()
		elif Input.is_action_just_pressed("FreeHotkey"):
			GizmoProxy.sac_mode = GizmoProxy.FREE
			_on_sac_mode_pressed(2)
			GizmoProxy.deselect_control_point()
