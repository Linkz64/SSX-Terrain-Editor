extends Control


const PLAIN_PATCH = preload("res://world/entities/plain_patch.tscn")

@export var tree: Tree
#@onready var axis_cam_pivot: Node3D = $AxisHelperViewport/AxisHelperSubViewport/AxisCamPivot
@onready var object_mode_tools: PanelContainer = $ToolBar/ObjectModeTools
@onready var edit_mode_tools: PanelContainer = $ToolBar/EditModeTools
@onready var start_menu: Control = $StartMenu
@onready var world: Node3D = $MainViewport/MainRender/World


func _ready():
	AlertBus.create_side_alert("AAHHHH", Enum.SideAlertType.ERROR)
	await get_tree().create_timer(3).timeout
	AlertBus.create_side_alert("jk mothing is wrong", Enum.SideAlertType.LOG)
	await get_tree().create_timer(3).timeout
	AlertBus.create_side_alert("SIKE Watch out!", Enum.SideAlertType.WARNING)
	await get_tree().create_timer(3).timeout
	AlertBus.create_side_alert("ERROR: GUAH GUAH GUAH GUAH", Enum.SideAlertType.ERROR)
	
	# Enable back if not interesting in seeing the alerts above for testing.
	#start_menu.activate() 


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _on_import_json_dir_selected(dir: String) -> void:
	var patches: Array[JsonPatch] = Multitool.open_extracted_patch_data(dir)
	
	var error = tree.create_from_json(patches)
	if error:
		print("Failed to create tree from json, There are duplicate patch names.")
		return
	
	for patch in patches:
		var plain_inst = PLAIN_PATCH.instantiate()
		$MainViewport/MainRender/World.add_child(plain_inst)
		plain_inst.name = patch.patch_name
		plain_inst.set_points(patch.points, patch.uv_points)
		plain_inst.set_texture(patch.texture)
		plain_inst.scale /= 100
	
	




func _on_mode_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		object_mode_tools.visible = false
		edit_mode_tools.visible = true
	else:
		object_mode_tools.visible = true
		edit_mode_tools.visible = false
