extends Control


const RECENT_BUTTON = preload("res://gui/start_menu/recent_button.tscn")

var _new_ssxt_path: String
var _opened_once: bool = false

@onready var version: Label = $Version
@onready var new_path_choice_text: TextEdit = $New/NewPathChoice/NewPathChoiceText
@onready var path_select_window: FileDialog = $PathSelectWindow
@onready var import_patches_check_box: CheckBox = $New/ImportPatchesCheckBox
@onready var grouping_menu_button: MenuButton = $New/GroupingChoice/GroupingMenuButton
@onready var info_label: Label = $InfoLabel
@onready var open_terrain_window: FileDialog = $OpenTerrainWindow
@onready var recents_box: VBoxContainer = $RecentsBox
@export var loading: Control


func _ready() -> void:
	version.text = ProjectSettings.get_setting("application/config/version")
	grouping_menu_button.get_popup().connect("index_pressed", _grouping_choice_pressed)
	_reload_recents()
	activate()


func activate():
	_reload_recents()
	new_path_choice_text.text = ""
	import_patches_check_box.button_pressed = false
	grouping_menu_button.text = "None"
	grouping_menu_button.set_meta("index", Enum.GroupingIndex.NONE)
	show()


func disactivate():
	_opened_once = true
	hide()


func _reload_recents():
	if not FileAccess.file_exists("user://recents.dat"):
		return

	# Update the recents file. Remove duplicates and non-existing paths. 
	var file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.READ)
	var recents: Array = file.get_var()
	var filtered_recents: Array = []
	for path in recents:
		if not FileAccess.file_exists(path) or (path in filtered_recents):
			continue
		filtered_recents.append(path)
	var write_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.WRITE)
	write_file.store_var(recents)

	# Delete and Create Buttons
	for child in recents_box.get_children():
		child.queue_free()
	
	for path in filtered_recents:
		var splited_path: Array = path.split("/")
		var button = RECENT_BUTTON.instantiate()
		button.text = "../" + splited_path[-2].path_join(splited_path[-1])
		button.set_meta("path", path)
		recents_box.add_child(button)
		button.connect("pressed", _recent_button_pressed.bind(button))


func _recent_button_pressed(button: Button):
	var path = button.get_meta("path")
	if not FileAccess.file_exists(path):
		info_label.text = "Terrain file no longer exists"
		return
	loading.show()
	disactivate()
	_open_terrain(path)


func _grouping_choice_pressed(index: int):
	match index:
		0:
			grouping_menu_button.text = "None"
			grouping_menu_button.set_meta("index", Enum.GroupingIndex.NONE)
		1:
			grouping_menu_button.text = "Batch"
			grouping_menu_button.set_meta("index", Enum.GroupingIndex.BATCH)
		2:
			grouping_menu_button.text = "Surface Type"
			grouping_menu_button.set_meta("index", Enum.GroupingIndex.SURFACE_TYPE)


func _create_terrain(terrain_path: String, import_json: bool, grouping: Enum.GroupingIndex):
	SaveHandler.new_terrain(terrain_path, import_json, grouping)


func _open_terrain(path: String):
	pass


func _on_new_path_choice_button_pressed() -> void:
	path_select_window.show()


func _on_path_select_window_file_selected(path: String) -> void:
	# Only show the parent directory plus file.ssxt
	var splited_path: Array = path.split("/")
	new_path_choice_text.text = "../" + splited_path[-2].path_join(splited_path[-1])
	_new_ssxt_path = path


func _on_button_new_pressed() -> void:
	if _new_ssxt_path.is_empty():
		info_label.text = "Please select a terrain path"
		return
	
	# Confirm that the folder still exists.
	if not DirAccess.dir_exists_absolute(_new_ssxt_path.get_base_dir()):
		info_label.text = "Folder does not exist."
		return
		
	# Check if json is imported and exists, Only if Import patches is checked
	var json_path: String = _new_ssxt_path.get_base_dir().path_join("Patches.json")
	var import_json: bool = false
	if import_patches_check_box.button_pressed:
		import_json = true
		if not FileAccess.file_exists(json_path):
			info_label.text = "Patches.json does not exist."
			return
		
	# Update Recents file
	if FileAccess.file_exists("user://recents.dat"):
		var read_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.READ)
		var recents: Array = read_file.get_var()
		
		# Only append if the file doesnt exist. If it does then wrap to the back of the
		# recents array.
		if _new_ssxt_path in recents:
			recents.remove_at(recents.find(_new_ssxt_path))
			recents.append(_new_ssxt_path)
		else:
			recents.push_back(_new_ssxt_path)
			if recents.size() > 4:
				recents.pop_front()
			
		var write_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.WRITE)
		write_file.store_var(recents)
	else:
		var write_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.WRITE)
		write_file.store_var([_new_ssxt_path])
	
	# Let main handle the json importing by connecting to this emited signal.
	# This script only takes care of creating the terrain file, and
	# recents file.
	var grouping: int = grouping_menu_button.get_meta("index")
	loading.show()
	disactivate()
	_create_terrain(_new_ssxt_path, import_json, grouping)
	
	
func _on_button_open_pressed() -> void:
	open_terrain_window.show()


func _on_open_terrain_window_file_selected(path: String) -> void:
	if path.get_extension() != "ssxt":
		open_terrain_window.show()
		return
		
	# Update Recents file
	if FileAccess.file_exists("user://recents.dat"):
		var read_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.READ)
		var recents: Array = read_file.get_var()
		recents.push_back(path)
		if recents.size() > 4:
			recents.pop_front()
			
		var write_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.WRITE)
		write_file.store_var(recents)
	else:
		var write_file: FileAccess = FileAccess.open("user://recents.dat", FileAccess.WRITE)
		write_file.store_var([])
	
	loading.show()
	disactivate()
	_open_terrain(path)
	

func _on_start_menu_bg_clicked_bg() -> void:
	if _opened_once:
		disactivate()
