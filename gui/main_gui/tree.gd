extends Tree


const EYE_CLOSE = preload("res://assets/ui/eye_close_16.svg")
const EYE_OPEN = preload("res://assets/ui/eye_open_16.svg")

@onready var tree_extras: MenuButton = $"../TreeButtons/Extras"
@onready var properties_panel: ScrollContainer = $"../PropertiesPanelScroll"


var root: TreeItem
var used_group_names: Dictionary # Unique group names
var used_object_names: Dictionary # Unique object names
var name_before_edit: String # Revert back to this name if new name already exists
var group_id: int = 0
var object_id: int = 0
var is_mouse_inside_tree: bool = false
var is_tree_focused: bool = false
var initial_anchor_bottom: float = 0.0

var DEBUG_on = false

func _ready():
	root = self.create_item()
	create_object(create_group()) # Create initial group and object
	var poop: PopupMenu = tree_extras.get_popup()
	poop.index_pressed.connect(_on_select_all_button)
	
	initial_anchor_bottom = self.anchor_bottom



func _unhandled_input(_event: InputEvent) -> void:
	# DEBUG CODE
	if Input.is_action_just_pressed("ui_right"):
		if DEBUG_on:
			self.anchor_bottom = initial_anchor_bottom
			properties_panel.show()
		else:
			self.anchor_bottom = 1
			properties_panel.hide()
		DEBUG_on = not DEBUG_on


func _input(event: InputEvent) -> void:
	# Make sure the tree is focused to use the delete key safely.
	if event is InputEventMouseButton and event.pressed:
		is_tree_focused = is_mouse_inside_tree
	
	# Delete the selected items if the Delete key is pressed.
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DELETE and is_tree_focused:
			delete_items()


func _get_drag_data(_at_position: Vector2) -> Variant:
	# Get all the selected objects and append them to the array
	var selected_items: Array[TreeItem] = []
	var selected = get_root()
	while true:
		selected = get_next_selected(selected)
		if not selected:
			break
		if selected.get_meta("type") == "object":
			selected_items.append(selected)
	if selected_items.is_empty():
		return null
	
	# Preview
	var label = Label.new()
	var objs = " Object" if selected_items.size() == 1 else " Objects"
	label.text = "Moving " + str(selected_items.size()) + objs
	var preview = Control.new()
	preview.add_child(label)
	label.position.y += 15
	set_drag_preview(preview)
	return selected_items
	
	
func _can_drop_data(at_position: Vector2, _data: Variant) -> bool:
	return get_item_at_position(at_position) != null
	
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dragged_into = get_item_at_position(at_position)
	if dragged_into.get_meta("type") == "object":
		dragged_into = dragged_into.get_parent() # Drop it on group of this object
	
	# Reparent the item to the new group
	for i in data.size():
		if data[i].get_parent() == dragged_into:
			continue # Dont bother if its aleady inside the group.
		data[i].get_parent().remove_child(data[i])
		dragged_into.add_child(data[i])
		var hue = Color.GRAY if dragged_into.get_meta("visible") else Color.WEB_GRAY 
		data[i].set_custom_color(0, hue)


func create_group() -> TreeItem:
	# Make unique name
	var new_name = "Group."+str(group_id)
	while new_name in used_group_names:
		group_id += 1
		new_name = "Group."+str(group_id)
	used_group_names[new_name] = null
	
	# Create item, it's button, and it's metadata
	var new_group = self.create_item(root)
	new_group.set_text(0, new_name)
	new_group.set_custom_color(0, Color.DEEP_SKY_BLUE)
	new_group.add_button(0, EYE_OPEN, -1, false, "Toggle Hidden")
	new_group.set_meta("type", "group")
	new_group.set_meta("visible", true)
	
	return new_group


func create_object(group_or_sibling: TreeItem) -> TreeItem:
	if not group_or_sibling:
		return
		
	# Make unique name
	var new_name = "Object."+str(object_id)
	while new_name in used_object_names:
		object_id += 1
		new_name = "Object."+str(object_id)
	used_object_names[new_name] = null
	
	# Create item, and it's metadata.
	# If the argument is a group then create it as a child,
	# If its an object then make it a sibling.
	var new_object: TreeItem
	var is_group_visible: bool
	if group_or_sibling.get_meta("type") == "group":
		new_object = self.create_item(group_or_sibling)
		is_group_visible = group_or_sibling.get_meta("visible")
	else:
		new_object = self.create_item(group_or_sibling.get_parent())
		is_group_visible = group_or_sibling.get_parent().get_meta("visible")
		
	new_object.set_text(0, new_name)
	var hue = Color.GRAY if is_group_visible else Color.WEB_GRAY 
	new_object.set_custom_color(0, hue)
	new_object.set_meta("type", "object")
	return new_object
	

func delete_items() -> void:
	var items_to_delete: Array[TreeItem] = []
	var selected = get_root()
	while true:
		selected = get_next_selected(selected)
		if not selected:
			break
		items_to_delete.append(selected)
	
	for item in items_to_delete:
		delete_item(item)


func delete_item(group_or_object: TreeItem):
	if group_or_object.get_meta("type") == "object":
		used_object_names.erase(group_or_object.get_text(0))
		group_or_object.free()
	else:
		if group_or_object.get_children().is_empty(): # Delete group only if its empty
			used_group_names.erase(group_or_object.get_text(0))
			group_or_object.free()
		else:
			print("Cant delete non-empty groups")


func duplicate_object_item(item: TreeItem):
	# Scan the item name from right to left, checking every character.
	# If the character is a digit, add it to the numbers variable backwards.
	# Once it finds a letter, it will break out of the loop, and the numbers variable
	# will have the final number (including padded 0s)
	var item_name: String = item.get_text(0)
	var string_number: String = ""
	var index: int = -1
	while true:
		if item_name[index].is_valid_int():
			string_number = item_name[index] + string_number
			index -= 1
		else:
			break
	# If the name has no numbers, then just add a 0 at the end.
	var int_number: int = 0 if string_number.is_empty() else string_number.to_int()
	
	# Pad the number as it was at the beginning. I think this also
	# automatically adds a 0 if the string is empty.
	# Loop to see if the name already exists.
	var item_name_without_number: String = item_name.substr(0, item_name.length()+index+1)
	var new_name: String
	while true:
		# Create the new name by padding the number to its original size
		# and appending it to the original name.
		# Dont pad the number if the original name had no numbers
		var padded_number: String = str(int_number)
		if string_number.length() != 0:
			padded_number = padded_number.pad_zeros(string_number.length())
		new_name = item_name_without_number + padded_number
		
		# Break if the new name is not taken.
		# If it is then increment the new number and keep looping.
		if new_name not in used_object_names:
			break 
		int_number += 1
	used_object_names[new_name] = null
	
	var new_object: TreeItem = self.create_item(item.get_parent())
	var is_group_visible: bool = new_object.get_parent().get_meta("visible")
	new_object.set_text(0, new_name)
	var hue = Color.GRAY if is_group_visible else Color.WEB_GRAY 
	new_object.set_custom_color(0, hue)
	new_object.set_meta("type", "object")


func _on_select_all_button(index: int):
	# 0 - Select all objects
	# 1 - Select all objects in group
	# 2 - hell nauh. Duplicate selected objects
	match index:
		0:
			var main = root
			self.deselect_all()
			while true:
				main = main.get_next_in_tree()
				if not main:
					break
				if main.get_meta("type") == "object":
					main.select(0)
		1:
			var group: TreeItem
			if not get_selected():
				return
			if get_selected().get_meta("type") == "group":
				group = get_selected()
			else:
				group = get_selected().get_parent()
				
			self.deselect_all()
			
			for c in group.get_children():
				c.select(0)
		2:
			var selected_objects: Array[TreeItem] = []
			var selected = get_root()
			while true:
				selected = get_next_selected(selected)
				if not selected:
					break
				if selected.get_meta("type") == "object":
					selected_objects.append(selected)
			if selected_objects.is_empty():
				return null
			for i in selected_objects:
				duplicate_object_item(i)


func _on_add_group_button_pressed() -> void:
	create_group()


func _on_item_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if item.get_button(0, 0) == EYE_CLOSE:
		item.set_button(0, 0, EYE_OPEN)
		item.set_meta("visible", true)
		for c in item.get_children():
			c.set_custom_color(0, Color.GRAY)
	else:
		item.set_button(0, 0, EYE_CLOSE)
		item.set_meta("visible", false)
		for c in item.get_children():
			c.set_custom_color(0, Color.WEB_GRAY)


func _on_item_activated() -> void:
	name_before_edit = self.get_selected().get_text(0)
	edit_selected(true)


func _on_item_edited() -> void:
	# Make sure the new name is not taken or empty. If it is then revert
	# the name to the previous name.
	var selected = get_selected()
	if selected.get_meta("type") == "group":
		if selected.get_text(0) in used_group_names or selected.get_text(0) == "":
			print("Group name: ", selected.get_text(0), " already exists")
			selected.set_text(0, name_before_edit)
			return
		used_object_names.erase(name_before_edit)
		used_group_names[selected.get_text(0)] = null
	else:
		if selected.get_text(0) in used_object_names or selected.get_text(0) == "":
			print("Object name: ", selected.get_text(0), " already exists")
			selected.set_text(0, name_before_edit)
			return
		used_object_names.erase(name_before_edit)
		used_object_names[selected.get_text(0)] = null


func _on_add_object_button_pressed() -> void:
	create_object(self.get_selected())


func _on_mouse_entered() -> void:
	is_mouse_inside_tree = true


func _on_mouse_exited() -> void:
	is_mouse_inside_tree = false


func _on_delete_pressed() -> void:
	delete_items()
