extends ColorRect


func _on_file_index_pressed(index: int) -> void:
	if index == 4: # Import json
		$ImportJson.show()
