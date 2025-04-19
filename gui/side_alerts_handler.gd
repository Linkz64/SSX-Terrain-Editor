extends Control


const SIDE_ALERT = preload("res://gui/side_alert/side_alert.tscn")


func _ready():
	AlertBus.connect("side_alert_creation_requested", _instanticate_side_alert)
	

func _instanticate_side_alert(text: String, type: Enum.SideAlertType):
	for c in self.get_children():
		c.move_up()
	
	var inst = SIDE_ALERT.instantiate()
	self.add_child(inst)
	inst.init(text, type)
