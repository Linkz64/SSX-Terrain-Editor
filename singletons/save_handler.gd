extends Node

signal new_terrain_created


# The terrain path that was opened or created. i.e the terrain currently
# active in the editor.
var current_working_terrain_path: String
# Dependancy injection of the 3D world root node.
var dep_world: Node3D
# Dependancy injection of the Tree node.
var dep_tree: Node
var _thread: Thread


#---------Public methods--------
func new_terrain(terrain_path: String, import_json: bool, grouping: Enum.GroupingIndex):
	current_working_terrain_path = terrain_path
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))
	if import_json:
		_thread.start(_create_ssxt_from_json.bind(terrain_path, grouping))
	else:
		_thread.start(_create_ssxt_default.bind(terrain_path))


func open_terrain(terrain_path: String):
	current_working_terrain_path = terrain_path
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))
	_thread.start(func(): return _ssxt_struct_to_nodes(_read_struct_from_disk(terrain_path)))


#----------Private methods-------
func _ready():
	_thread = Thread.new()
	get_tree().process_frame.connect(_check_thread_finished)


func _exit_tree() -> void:
	_thread.wait_to_finish()


func _check_thread_finished() -> void:
	if _thread.is_started() and not _thread.is_alive():
		var node: Node = _thread.wait_to_finish()
		var old_node = dep_world.object_pool
		if old_node:
			old_node.queue_free()
		dep_world.add_child(node)
		dep_world.object_pool = node
		new_terrain_created.emit()


func _update_camera(xform: Transform3D):
	dep_world.get_camera().transform = xform
	dep_world.get_camera().init_rotation = Vector2.ZERO


func _create_ssxt_from_json(terrain_path: String, grouping: Enum.GroupingIndex):
	# Read the json and turn it into a Godot ssxt structured class
	#var start = Time.get_ticks_msec()
	var json_data: Array[JsonPatch] = Multitool.open_extracted_patch_data( \
			terrain_path.get_base_dir())
	var ssxt_struct := SsxtFileStructure.new()
	
	var version_str: String = ProjectSettings.get_setting("application/config/version")
	var version_str_array = version_str.substr(1).split(".")
	var editor_version: Array[int] = []
	for digit in version_str_array:
		editor_version.append(int(digit))
	ssxt_struct.editor_version = editor_version
	
	ssxt_struct.date_time_created = Time.get_datetime_string_from_system()
	
	ssxt_struct.camera_xform = Transform3D().rotated(Vector3.RIGHT, TAU/4)
	match grouping:
		Enum.GroupingIndex.NONE:
			_grouping_none_edit(ssxt_struct, json_data)
		Enum.GroupingIndex.BATCH:
			_grouping_batch_edit(ssxt_struct, json_data)
		Enum.GroupingIndex.SURFACE_TYPE:
			_grouping_surface_type_edit(ssxt_struct, json_data)
	
	var write_thread := Thread.new()
	write_thread.start(_write_struct_to_disk.bind(terrain_path, ssxt_struct))
	
	var nodes = _ssxt_struct_to_nodes(ssxt_struct)
	write_thread.wait_to_finish()
	return nodes


func _create_ssxt_default(terrain_path: String):
	# create the ssxt with a predefined structure
	var ssxt_struct := SsxtFileStructure.new()
	
	var version_str: String = ProjectSettings.get_setting("application/config/version")
	var version_str_array = version_str.substr(1).split(".")
	var editor_version: Array[int] = []
	for digit in version_str_array:
		editor_version.append(int(digit))
	ssxt_struct.editor_version = editor_version
	
	ssxt_struct.date_time_created = Time.get_datetime_string_from_system()
	
	ssxt_struct.camera_xform = Transform3D().rotated(Vector3.RIGHT, TAU/4)
	
	ssxt_struct.group_count = 1
	var group_entry := GroupEntry.new()
	group_entry.group_name = "Group.0"
	group_entry.group_name_size = group_entry.group_name.length()
	group_entry.group_visible = true
	group_entry.object_count = 1
	
	var object_entry := ObjectEntry.new()
	object_entry.object_name = "Object.0"
	object_entry.object_name_size = object_entry.object_name.length()
	object_entry.object_xform = Transform3D()
	object_entry.greatest_control_point_id = 16
	object_entry.control_point_count = 16
	
	for y in range(3, -1, -1):
		for x in 4: 
			var cp_index = y * 4 + x
			var control_point_entry := ControlPointEntry.new()
			control_point_entry.type = _get_control_point_type(cp_index)
			control_point_entry.id = cp_index
			control_point_entry. aligned = true
			control_point_entry.position = Vector3(x, y, 0) - object_entry.object_xform.origin
			
			var north = _get_neighbour(cp_index, "north")
			var west = _get_neighbour(cp_index, "west")
			var south = _get_neighbour(cp_index, "south")
			var east = _get_neighbour(cp_index, "east")
			control_point_entry.has_north_ref = north != null
			control_point_entry.ref_north_id = north if north else 0
			control_point_entry.has_west_ref = west != null
			control_point_entry.ref_west_id = west if west else 0
			control_point_entry.has_south_ref = south != null
			control_point_entry.ref_south_id = south if south else 0
			control_point_entry.has_east_ref = east != null
			control_point_entry.ref_east_id = east if east else 0
			object_entry.control_points.append(control_point_entry)
	
	object_entry.greatest_segment_id = 1
	var segment := SegmentEntry.new()
	segment.id = 0
	for i in 16:
		segment.control_point_ids.append(i)
	segment.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
	segment.lightmap_id = 0
	segment.uv_points = [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
	]
	segment.patch_style = Enum.SurfaceType.SNOW_MAIN
	segment.tricky_only_patch = false
	segment.texture_path = "0000.png"
	segment.texture_path_size = segment.texture_path.length()
	object_entry.segments.append(segment)
	group_entry.objects.append(object_entry)
	ssxt_struct.groups.append(group_entry)
	
	_write_struct_to_disk(terrain_path, ssxt_struct)
	return _ssxt_struct_to_nodes(ssxt_struct)


## Edits the struct if the grouping flag is None.
## Edits the Group count and after.
func _grouping_none_edit(ssxt_struct: SsxtFileStructure, json_data: Array[JsonPatch]):
	ssxt_struct.group_count = 1
	var group_entry := GroupEntry.new()
	group_entry.group_name = "Group.0"
	group_entry.group_name_size = group_entry.group_name.length()
	group_entry.group_visible = true
	group_entry.object_count = json_data.size()
	ssxt_struct.groups.append(group_entry)
	
	for patch in json_data:
		var object_entry := ObjectEntry.new()
		object_entry.object_name = patch.patch_name
		object_entry.object_name_size = patch.patch_name.length()
		object_entry.object_xform = Transform3D(Basis.IDENTITY, patch.points[0])
		object_entry.greatest_control_point_id = 16
		object_entry.control_point_count = 16
		group_entry.objects.append(object_entry)
		
		for cp in 16:
			var control_point_entry := ControlPointEntry.new()
			control_point_entry.type = _get_control_point_type(cp)
			control_point_entry.id = cp
			control_point_entry. aligned = false
			control_point_entry.position = patch.points[cp] - object_entry.object_xform.origin
			
			var north = _get_neighbour(cp, "north")
			var west = _get_neighbour(cp, "west")
			var south = _get_neighbour(cp, "south")
			var east = _get_neighbour(cp, "east")
			control_point_entry.has_north_ref = north != null
			control_point_entry.ref_north_id = north if north else 0
			control_point_entry.has_west_ref = west != null
			control_point_entry.ref_west_id = west if west else 0
			control_point_entry.has_south_ref = south != null
			control_point_entry.ref_south_id = south if south else 0
			control_point_entry.has_east_ref = east != null
			control_point_entry.ref_east_id = east if east else 0
			object_entry.control_points.append(control_point_entry)
		
		object_entry.greatest_segment_id = 1
		var segment := SegmentEntry.new()
		segment.id = 0
		for i in 16:
			segment.control_point_ids.append(i)
		segment.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
		segment.lightmap_id = 0
		segment.uv_points = patch.uv_points
		segment.patch_style = patch.patch_style
		segment.tricky_only_patch = patch.tricky_only_patch
		segment.texture_path = patch.texture_path
		segment.texture_path_size = patch.texture_path.length()
		object_entry.segments.append(segment)
		
	
## Edits the struct if the grouping flag is Batch.
## Edits the Group count and after.
func _grouping_batch_edit(ssxt_struct: SsxtFileStructure, json_data: Array[JsonPatch]):
	var batch_counter: int = 700 # 0 - 700
	var current_group: GroupEntry
	
	for patch in json_data:
		if batch_counter == 700:
			# Create new group
			batch_counter = 0
			var group_entry := GroupEntry.new()
			group_entry.group_name = "Batch." + str(ssxt_struct.group_count)
			group_entry.group_name_size = group_entry.group_name.length()
			group_entry.group_visible = true
			ssxt_struct.group_count += 1
			ssxt_struct.groups.append(group_entry)
			current_group = group_entry
		batch_counter += 1
		
		# Create objects on current group
		var object_entry := ObjectEntry.new()
		object_entry.object_name = patch.patch_name
		object_entry.object_name_size = patch.patch_name.length()
		object_entry.object_xform = Transform3D(Basis.IDENTITY, patch.points[0])
		object_entry.greatest_control_point_id = 16
		object_entry.control_point_count = 16
		
		for cp in 16:
			var control_point_entry := ControlPointEntry.new()
			control_point_entry.type = _get_control_point_type(cp)
			control_point_entry.id = cp
			control_point_entry. aligned = false
			control_point_entry.position = patch.points[cp] - object_entry.object_xform.origin
			
			var north = _get_neighbour(cp, "north")
			var west = _get_neighbour(cp, "west")
			var south = _get_neighbour(cp, "south")
			var east = _get_neighbour(cp, "east")
			control_point_entry.has_north_ref = north != null
			control_point_entry.ref_north_id = north if north else 0
			control_point_entry.has_west_ref = west != null
			control_point_entry.ref_west_id = west if west else 0
			control_point_entry.has_south_ref = south != null
			control_point_entry.ref_south_id = south if south else 0
			control_point_entry.has_east_ref = east != null
			control_point_entry.ref_east_id = east if east else 0
			object_entry.control_points.append(control_point_entry)
		
		object_entry.greatest_segment_id = 1
		var segment := SegmentEntry.new()
		segment.id = 0
		for k in 16:
			segment.control_point_ids.append(k)
		segment.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
		segment.lightmap_id = 0
		segment.uv_points = patch.uv_points
		segment.patch_style = patch.patch_style
		segment.tricky_only_patch = patch.tricky_only_patch
		segment.texture_path = patch.texture_path
		segment.texture_path_size = patch.texture_path.length()
		object_entry.segments.append(segment)
		current_group.objects.append(object_entry)
		current_group.object_count += 1

	
## Edits the struct if the grouping flag is Surface Type.
## Edits the Group count and after.
func _grouping_surface_type_edit(ssxt_struct: SsxtFileStructure, json_data: Array[JsonPatch]):
	"""
	Create a group for every type
	
	for every patch:
		create the object entry and check its surface type
	"""
	const SURFACE_TYPE_NAMES: Array[String]= [
		"Reset",
		"Snow Main",
		"Snow Side",
		"Snow Powder",
		"Snow Powder Heavy",
		"Ice",
		"Rebound",
		"Ice Water",
		"Snow_5",
		"Rock",
		"Rebound Rock",
		"Unknown",
		"Wood",
		"Metal",
		"Unknown_2",
		"Snow_6",
		"Sand",
		"No Collision",
		"Metal Ramp",
		"Metal Ramp_2",
	]
	
	# Create groups
	ssxt_struct.group_count = 20
	for i in 20:
		var group_entry := GroupEntry.new()
		group_entry.group_name = SURFACE_TYPE_NAMES[i]
		group_entry.group_name_size = group_entry.group_name.length()
		group_entry.group_visible = true
		ssxt_struct.groups.append(group_entry)
	
	# Create objects and palce them in their corresponding surface type group 
	for patch in json_data:
		var object_entry := ObjectEntry.new()
		object_entry.object_name = patch.patch_name
		object_entry.object_name_size = patch.patch_name.length()
		object_entry.object_xform = Transform3D(Basis.IDENTITY, patch.points[0])
		object_entry.greatest_control_point_id = 16
		object_entry.control_point_count = 16
		
		for cp in 16:
			var control_point_entry := ControlPointEntry.new()
			control_point_entry.type = _get_control_point_type(cp)
			control_point_entry.id = cp
			control_point_entry. aligned = false
			control_point_entry.position = patch.points[cp] - object_entry.object_xform.origin
			
			var north = _get_neighbour(cp, "north")
			var west = _get_neighbour(cp, "west")
			var south = _get_neighbour(cp, "south")
			var east = _get_neighbour(cp, "east")
			control_point_entry.has_north_ref = north != null
			control_point_entry.ref_north_id = north if north else 0
			control_point_entry.has_west_ref = west != null
			control_point_entry.ref_west_id = west if west else 0
			control_point_entry.has_south_ref = south != null
			control_point_entry.ref_south_id = south if south else 0
			control_point_entry.has_east_ref = east != null
			control_point_entry.ref_east_id = east if east else 0
			object_entry.control_points.append(control_point_entry)
		
		object_entry.greatest_segment_id = 1
		var segment := SegmentEntry.new()
		segment.id = 0
		for k in 16:
			segment.control_point_ids.append(k)
		segment.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
		segment.lightmap_id = 0
		segment.uv_points = patch.uv_points
		segment.patch_style = patch.patch_style
		segment.tricky_only_patch = patch.tricky_only_patch
		segment.texture_path = patch.texture_path
		segment.texture_path_size = patch.texture_path.length()
		object_entry.segments.append(segment)
		ssxt_struct.groups[patch.patch_style].objects.append(object_entry)


func _ssxt_struct_to_nodes(ssxt_struct: SsxtFileStructure) -> Node:
	assert(dep_world, "World node dependancy was not set.")
	call_thread_safe("_update_camera", ssxt_struct.camera_xform)
	
	var root := Node.new()
	root.name = "ObjectPool"
	for group: GroupEntry in ssxt_struct.groups:
		var group_node := Node3D.new()
		group_node.name = group.group_name
		group_node.visible = group.group_visible
		root.add_child(group_node)
		
		for object: ObjectEntry in group.objects:
			var object_node := PatchObject.new(PatchObject.InitType.EMPTY)
			object_node.name = object.object_name
			object_node.transform = object.object_xform
			group_node.add_child(object_node)
			
			var cp_id := 0
			for cp_entry:ControlPointEntry in object.control_points:
				var control_point = ControlPoint.new(cp_entry.type, object_node, cp_entry.position)
				control_point.aligned = cp_entry.aligned
				object_node.control_points[cp_id] = control_point
				cp_id += 1
			object_node.control_points_id = cp_id
			
			var segment_id := 0
			for segment_entry:SegmentEntry in object.segments:
				var segment := PatchSegment.new(segment_entry.control_point_ids, object_node)
				segment.surface_type = segment_entry.patch_style as Enum.SurfaceType
				segment.texture_filename = segment_entry.texture_path
				segment.showoff_only = segment_entry.tricky_only_patch
				segment.uv_points["top-left"] = segment_entry.uv_points[0]
				segment.uv_points["top-right"] = segment_entry.uv_points[1]
				segment.uv_points["bottom-left"] = segment_entry.uv_points[2]
				segment.uv_points["bottom-right"] = segment_entry.uv_points[3]
				segment.lightmap_id = segment_entry.lightmap_id
				segment.lightmap_point = segment_entry.lightmap_rect
				object_node.segments[segment_id] = segment
				segment_id += 1
			object_node.segment_id = segment_id
			object_node.update_surface()
				
			# Do this later
			#if cp.has_north_ref:
			#control_point.neighbours["north"] = cp.ref_north_id

	return root


static func _read_struct_from_disk(terrain_path: String) -> SsxtFileStructure:
	var ssxt_file := FileAccess.open(terrain_path, FileAccess.READ)
	var ssxt_struct := SsxtFileStructure.new()
	ssxt_struct.signature = ssxt_file.get_buffer(4).get_string_from_utf8()
	ssxt_struct.file_structure_version[0] = ssxt_file.get_8()
	ssxt_struct.file_structure_version[1] = ssxt_file.get_8()
	ssxt_struct.file_structure_version[2] = ssxt_file.get_8()
	ssxt_struct.editor_version[0] = ssxt_file.get_8()
	ssxt_struct.editor_version[1] = ssxt_file.get_8()
	ssxt_struct.editor_version[2] = ssxt_file.get_8()
	
	ssxt_struct.date_time_created = ssxt_file.get_buffer(19).get_string_from_utf8()
	
	ssxt_struct.camera_xform.origin.x = ssxt_file.get_float()
	ssxt_struct.camera_xform.origin.y = ssxt_file.get_float()
	ssxt_struct.camera_xform.origin.z = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.x.x = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.x.y = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.x.z = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.y.x = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.y.y = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.y.z = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.z.x = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.z.y = ssxt_file.get_float()
	ssxt_struct.camera_xform.basis.z.z = ssxt_file.get_float()
	ssxt_struct.group_count = ssxt_file.get_32()
	
	for group_index in ssxt_struct.group_count:
		var group := GroupEntry.new()
		ssxt_struct.groups.append(group)
		group.group_name_size = ssxt_file.get_8()
		group.group_name = ssxt_file.get_buffer(group.group_name_size).get_string_from_utf8()
		group.group_visible = ssxt_file.get_8()
		group.object_count = ssxt_file.get_32()
		
		for object_index in group.object_count:
			var object := ObjectEntry.new()
			group.objects.append(object)
			object.object_name_size = ssxt_file.get_8()
			object.object_name = ssxt_file.get_buffer(object.object_name_size).get_string_from_utf8()
			object.object_xform.origin.x = ssxt_file.get_float()
			object.object_xform.origin.y = ssxt_file.get_float()
			object.object_xform.origin.z = ssxt_file.get_float()
			object.object_xform.basis.x.x = ssxt_file.get_float()
			object.object_xform.basis.x.y = ssxt_file.get_float()
			object.object_xform.basis.x.z = ssxt_file.get_float()
			object.object_xform.basis.y.x = ssxt_file.get_float()
			object.object_xform.basis.y.y = ssxt_file.get_float()
			object.object_xform.basis.y.z = ssxt_file.get_float()
			object.object_xform.basis.z.x = ssxt_file.get_float()
			object.object_xform.basis.z.y = ssxt_file.get_float()
			object.object_xform.basis.z.z = ssxt_file.get_float()
			
			object.greatest_control_point_id = ssxt_file.get_32()
			object.control_point_count = ssxt_file.get_32()
			for cp_index in object.control_point_count:
				var control_point = ControlPointEntry.new()
				object.control_points.append(control_point)
				control_point.type = ssxt_file.get_8()
				control_point.id = ssxt_file.get_32()
				control_point.aligned = ssxt_file.get_8()
				control_point.position.x = ssxt_file.get_float()
				control_point.position.y = ssxt_file.get_float()
				control_point.position.z = ssxt_file.get_float()
				control_point.has_north_ref = ssxt_file.get_8()
				control_point.ref_north_id = ssxt_file.get_32()
				control_point.has_west_ref = ssxt_file.get_8()
				control_point.ref_west_id = ssxt_file.get_32()
				control_point.has_south_ref = ssxt_file.get_8()
				control_point.ref_south_id = ssxt_file.get_32()
				control_point.has_east_ref = ssxt_file.get_8()
				control_point.ref_east_id = ssxt_file.get_32()
			
			object.greatest_segment_id = ssxt_file.get_32()
			
			for segment_index in object.greatest_segment_id:
				var segment := SegmentEntry.new()
				object.segments.append(segment)
				segment.id = ssxt_file.get_32()
				
				for cp_id in 16:
					segment.control_point_ids.append(ssxt_file.get_32())
			
				segment.lightmap_rect.position.x = ssxt_file.get_float()
				segment.lightmap_rect.position.y = ssxt_file.get_float()
				segment.lightmap_rect.size.x = ssxt_file.get_float()
				segment.lightmap_rect.size.y = ssxt_file.get_float()
				segment.lightmap_id = ssxt_file.get_32()
			
				for uv in 4:
					var point: Vector2
					point.x = ssxt_file.get_float() 
					point.y = ssxt_file.get_float() 
					segment.uv_points.append(point)
			
				segment.patch_style = ssxt_file.get_8()
				segment.tricky_only_patch = ssxt_file.get_8()
				segment.texture_path_size = ssxt_file.get_32()
				segment.texture_path = ssxt_file.get_buffer(segment.texture_path_size).get_string_from_utf8()
			
	return ssxt_struct

	
static func _write_struct_to_disk(terrain_path: String, ssxt_struct: SsxtFileStructure):
	var ssxt_file := FileAccess.open(terrain_path, FileAccess.WRITE)
	ssxt_file.store_string(ssxt_struct.signature)
	ssxt_file.store_8(ssxt_struct.file_structure_version[0])
	ssxt_file.store_8(ssxt_struct.file_structure_version[1])
	ssxt_file.store_8(ssxt_struct.file_structure_version[2])
	ssxt_file.store_8(ssxt_struct.editor_version[0])
	ssxt_file.store_8(ssxt_struct.editor_version[1])
	ssxt_file.store_8(ssxt_struct.editor_version[2])

	ssxt_file.store_string(ssxt_struct.date_time_created)

	ssxt_file.store_float(ssxt_struct.camera_xform.origin.x)
	ssxt_file.store_float(ssxt_struct.camera_xform.origin.y)
	ssxt_file.store_float(ssxt_struct.camera_xform.origin.z)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.x.x)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.x.y)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.x.z)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.y.x)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.y.y)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.y.z)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.z.x)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.z.y)
	ssxt_file.store_float(ssxt_struct.camera_xform.basis.z.z)
	ssxt_file.store_32(ssxt_struct.group_count)
	
	for group in ssxt_struct.groups:
		ssxt_file.store_8(group.group_name_size)
		ssxt_file.store_string(group.group_name)
		ssxt_file.store_8(int(group.group_visible))
		ssxt_file.store_32(int(group.object_count))
		
		for object in group.objects:
			ssxt_file.store_8(object.object_name_size)
			ssxt_file.store_string(object.object_name)
			ssxt_file.store_float(object.object_xform.origin.x)
			ssxt_file.store_float(object.object_xform.origin.y)
			ssxt_file.store_float(object.object_xform.origin.z)
			ssxt_file.store_float(object.object_xform.basis.x.x)
			ssxt_file.store_float(object.object_xform.basis.x.y)
			ssxt_file.store_float(object.object_xform.basis.x.z)
			ssxt_file.store_float(object.object_xform.basis.y.x)
			ssxt_file.store_float(object.object_xform.basis.y.y)
			ssxt_file.store_float(object.object_xform.basis.y.z)
			ssxt_file.store_float(object.object_xform.basis.z.x)
			ssxt_file.store_float(object.object_xform.basis.z.y)
			ssxt_file.store_float(object.object_xform.basis.z.z)
			
			ssxt_file.store_32(object.greatest_control_point_id)
			ssxt_file.store_32(object.control_point_count)
			
			for control_point in object.control_points:
				ssxt_file.store_8(control_point.type)
				ssxt_file.store_32(control_point.id)
				ssxt_file.store_8(int(control_point.aligned))
				ssxt_file.store_float(control_point.position.x)
				ssxt_file.store_float(control_point.position.y)
				ssxt_file.store_float(control_point.position.z)
				ssxt_file.store_8(int(control_point.has_north_ref))
				ssxt_file.store_32(control_point.ref_north_id)
				ssxt_file.store_8(int(control_point.has_west_ref))
				ssxt_file.store_32(control_point.ref_west_id)
				ssxt_file.store_8(int(control_point.has_south_ref))
				ssxt_file.store_32(control_point.ref_south_id)
				ssxt_file.store_8(int(control_point.has_east_ref))
				ssxt_file.store_32(control_point.ref_east_id)

			ssxt_file.store_32(object.greatest_segment_id)
			
			for segment in object.segments:
				ssxt_file.store_32(segment.id)
				
				for cp_id in segment.control_point_ids:
					ssxt_file.store_32(cp_id)
				
				ssxt_file.store_float(segment.lightmap_rect.position.x)
				ssxt_file.store_float(segment.lightmap_rect.position.y)
				ssxt_file.store_float(segment.lightmap_rect.size.x)
				ssxt_file.store_float(segment.lightmap_rect.size.y)
				ssxt_file.store_32(segment.lightmap_id)
				
				for uv in segment.uv_points:
					ssxt_file.store_float(uv.x)
					ssxt_file.store_float(uv.y)
					
				ssxt_file.store_8(segment.patch_style)
				ssxt_file.store_8(int(segment.tricky_only_patch))
				
				ssxt_file.store_32(segment.texture_path_size)
				ssxt_file.store_string(segment.texture_path)


## Get the neighbour of a cp from all 4 sides, returns null if its not valid,
## returns the neighbour index if is valid. 
## This is only used for json importing - where objects only have one segment.
static func _get_neighbour(index: int, side: String) -> Variant:
	if side == "north":
		if (index - 4) >= 0:
			return (index - 4)
		return null
	elif side == "west":
		var neighbour = index - 1
		if neighbour > 0 and neighbour % 4 != 3:
			return neighbour
		else:
			return null
	elif side == "south":
		if (index + 4) < 16:
			return (index + 4)
		return null
	elif side == "east":
		var neighbour = index + 1
		if neighbour > 0 and neighbour % 4 != 0:
			return neighbour
		else:
			return null
	else:
		push_error("Invalid control point side ", side)
		return null


static func _get_control_point_type(index: int) -> int:
	const CORNERS = [0, 3, 12, 15]
	const HANDLES = [1, 2, 4, 7, 8, 11, 13, 14]
	const INNERS = [5, 6, 9, 10]
	if index in CORNERS:
		return 0 # corner
	elif index in HANDLES:
		return 1 # handle
	elif index in INNERS:
		return 2 # inner
	else:
		push_error("Invalid control point index ", index)
		return 0


#--------Inner classes---------
class SsxtFileStructure:
	var signature: String = "ssxt"
	var file_structure_version: Array[int] = [0, 1, 0] # Bytes. Major, Minor, Patch
	var editor_version: Array[int] = [0, 1, 0] # Bytes. Major, Minor, Patch
	var date_time_created: String # 19 bytes
	var camera_xform: Transform3D
	var group_count: int
	var groups: Array[GroupEntry]

class GroupEntry:
	var group_name_size: int # byte
	var group_name: String
	var group_visible: bool
	var object_count: int
	var objects: Array[ObjectEntry]
	
class ObjectEntry:
	var object_name_size: int # byte
	var object_name: String
	var object_xform: Transform3D
	var greatest_control_point_id: int
	var control_point_count: int
	var control_points: Array[ControlPointEntry]
	var greatest_segment_id: int
	var segment_count: int
	var segments: Array[SegmentEntry]
	
class ControlPointEntry:
	var type: int # byte
	var id: int
	var aligned: bool
	var position: Vector3
	var has_north_ref: bool # If the below id is valid (i.e Does this cp have a north neighbour?)
	var ref_north_id: int # References to the neighbouring CPs to complete the doubly linked grid
	var has_west_ref: bool
	var ref_west_id: int
	var has_south_ref: bool
	var ref_south_id: int
	var has_east_ref: bool
	var ref_east_id: int

class SegmentEntry:
	var id: int
	var control_point_ids: Array[int] # Size 16
	var lightmap_rect: Rect2
	var lightmap_id: int
	var uv_points: Array[Vector2] # Size 4
	var patch_style: int # byte
	var tricky_only_patch: bool
	var texture_path_size: int
	var texture_path: String
	
	
