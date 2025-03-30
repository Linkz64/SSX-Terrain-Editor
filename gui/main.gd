extends Control


const PLAIN_PATCH = preload("res://world/entities/plain_patch.tscn")

@export var tree: Tree


#func _ready():
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME


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
	
	
	
	
	
	
	
