extends ColorRect


signal json_imported(patches: Array, dir_path: String)


func _on_file_index_pressed(index: int) -> void:
	if index == 4: # Import json
		$ImportJson.show()


func _on_file_dialog_dir_selected(dir: String) -> void:
	var json_path: String
	var texture_dir: String
	
	var extracted_dir = DirAccess.open(dir)
	if extracted_dir:
		extracted_dir.list_dir_begin()
		var file_name = extracted_dir.get_next()
		while file_name != "":
			if extracted_dir.current_is_dir():
				if file_name == "Textures":
					texture_dir = extracted_dir.get_current_dir().path_join("Textures")
					print("Found valid texture folder: ", texture_dir)
			else:
				if file_name == "Patches.json":
					json_path = extracted_dir.get_current_dir().path_join("Patches.json")
					print("Found valid json file: ", json_path)
					var patches = Utils.parse_patch_json(json_path)
					json_imported.emit(patches, extracted_dir.get_current_dir())
			
			if not texture_dir.is_empty() and not json_path.is_empty():
				break
			file_name = extracted_dir.get_next()


		
		
		
		
		
		
		
		
		
		
		
		
		
