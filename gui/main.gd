extends Control


const PLAIN_PATCH = preload("res://world/entities/plain_patch.tscn")


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _on_menu_bar_bg_json_imported(patches: Array, dir_path: String) -> void:
	for patch in patches:
		var plain_inst = PLAIN_PATCH.instantiate()
		$MainViewport/MainRender/World.add_child(plain_inst)
		plain_inst.set_points(patch["Points"], patch["UVPoints"])
		
		var path = dir_path.path_join("Textures".path_join(patch["TexturePath"]))
		var texture_file = FileAccess.open(path, FileAccess.READ)
		
		var buffer = texture_file.get_buffer(texture_file.get_length())
		var image = Image.new()
		var error = image.load_png_from_buffer(buffer)
		var texture: ImageTexture
		if error == OK:
			texture = ImageTexture.create_from_image(image)
		
		plain_inst.set_texture(texture.duplicate())
		plain_inst.scale /= 100
