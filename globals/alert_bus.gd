extends Node


signal side_alert_creation_requested(text: String, type: Enum.SideAlertType)


func create_side_alert(text: String, type: Enum.SideAlertType):
	side_alert_creation_requested.emit(text, type)
	
