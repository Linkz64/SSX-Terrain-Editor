extends Control


const SIDE_ALERT = preload("res://gui/side_alert/side_alert.tscn")

@onready var v_box: VBoxContainer = $VBoxContainer


func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	

func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	var inst = SIDE_ALERT.instantiate()
	v_box.add_child(inst)
	inst.init(text, type)
