extends ColorRect

"""
This node will propagade methods and signals in and out of the tree and properties panel.
I want the viewport and IO systems to fully interact with this node to communicate with the children


Tree Methods I need:
-Enable
-Disable
-Select Object (as multiselect)
-Deselect all
-Delete selected objects
-Duplicate selected objects

Tree Signals I need:
-Selection changed
	Desc: Emmited when an object is selected. 
		  Only emited when an object is selected, and now a group.
	Args: Array of objects currently selected.
	
-Object created
	Desc: Emitted when the Add Object button is pressed.
	Args: Objects created,
		  Group visiblity bool.
-Visiblity toggled
	Desc: Emited when a group's eye is clicked.
	Args: Array of objects in the toggled group
	



-Objects moved(array of objects moved, also return the new group's visiblity)



"""




var is_properties_visible: bool = false
var _retracted_tree_anchor_bottom: float = 0

@onready var tree: Tree = $Tree
@onready var properties_panel: ScrollContainer = $PropertiesPanelScroll


#------Private------
func _ready() -> void:
	_retracted_tree_anchor_bottom = tree.anchor_bottom
	hide_properties()


#-----Public-------
func show_properties():
	tree.anchor_bottom = _retracted_tree_anchor_bottom
	properties_panel.show()
	is_properties_visible = true


func hide_properties():
	tree.anchor_bottom = 1
	properties_panel.hide()
	is_properties_visible = false


#------Signal Callbacks-----
