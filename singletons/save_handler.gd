extends Node

signal new_terrain_created

var world: Node3D
var current_terrain_path: String:
	set(value): current_terrain_path = ""
	get: return _current_working_terrain_path

var _current_working_terrain_path: String


#---------Public methods--------
func new_terrain(terrain_path: String, import_json: bool, grouping: Enum.GroupingIndex):
	_current_working_terrain_path = terrain_path
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))
	_create_ssxt_default(terrain_path)
	new_terrain_created.emit()


func open_terrain(terrain_path: String):
	_current_working_terrain_path = terrain_path
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))
	_ssxt_struct_to_nodes(_read_struct_from_disk(terrain_path))
	new_terrain_created.emit()


#-------Private methods--------
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
	
	_ssxt_struct_to_nodes(ssxt_struct)
	write_thread.wait_to_finish()


func _create_ssxt_default(terrain_path: String):
	# create the ssxt with a predefined structure
	const SEGMENT_SIZE = 1_000
	var ssxt_struct := SsxtFileStructure.new()
	
	var version_str: String = ProjectSettings.get_setting("application/config/version")
	var version_str_array = version_str.substr(1).split(".")
	var editor_version: Array[int] = []
	for digit in version_str_array:
		editor_version.append(int(digit))
	ssxt_struct.editor_version = editor_version
	ssxt_struct.date_time_created = Time.get_datetime_string_from_system()
	ssxt_struct.camera_xform = Transform3D().rotated(Vector3.RIGHT, TAU/4)
	ssxt_struct.camera_xform.origin = Vector3(0, -1000, 1000)
	ssxt_struct.group_count = 1
	
	var group_entry := GroupEntry.new()
	ssxt_struct.groups.append(group_entry)
	group_entry.group_name = "Group.0"
	group_entry.group_name_size = group_entry.group_name.length()
	group_entry.group_visible = true
	group_entry.object_count = 1
	
	var object_entry := ObjectEntry.new()
	group_entry.objects.append(object_entry)
	object_entry.object_name = "Object.0"
	object_entry.object_name_size = object_entry.object_name.length()
	object_entry.object_xform = Transform3D(Basis.IDENTITY, Vector3(-SEGMENT_SIZE*3, 0, 0))
	object_entry.control_point_count = 28
	var cp_index: int = 0
	for y in 4:
		for x in 7:
			var control_point_entry := ControlPointEntry.new()
			object_entry.control_points.append(control_point_entry)
			control_point_entry.tilemap_cell = Vector2i(x, y)
			control_point_entry.type = _get_control_point_type(cp_index)
			control_point_entry.aligned = true
			control_point_entry.position = Vector3(x * SEGMENT_SIZE, y * SEGMENT_SIZE, 0)
			cp_index += 1
	
	object_entry.segment_count = 2
	
	# Segment 1
	var segment_left := SegmentEntry.new()
	object_entry.segments.append(segment_left)
	for y in 4:
		for x in 4:
			segment_left.tilemap_cells.append(Vector2i(x, y))
	segment_left.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
	segment_left.lightmap_id = 0
	segment_left.uv_points = [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
	]
	segment_left.surface_type = Enum.SurfaceType.SNOW_MAIN
	segment_left.showoff_only = false
	segment_left.texture_path = "0000.png"
	segment_left.texture_path_size = segment_left.texture_path.length()
	
	# Segment 2
	var segment_right := SegmentEntry.new()
	object_entry.segments.append(segment_right)
	for y in 4:
		for x in 4:
			segment_right.tilemap_cells.append(Vector2i(x + 3, y))
	segment_right.lightmap_rect = Rect2(0, 0, 0.0625, 0.0625)
	segment_right.lightmap_id = 0
	segment_right.uv_points = [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
	]
	segment_right.surface_type = Enum.SurfaceType.SNOW_MAIN
	segment_right.showoff_only = false
	segment_right.texture_path = "0000.png"
	segment_right.texture_path_size = segment_right.texture_path.length()
	
	_write_struct_to_disk(terrain_path, ssxt_struct)
	_ssxt_struct_to_nodes(ssxt_struct)


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


func _ssxt_struct_to_nodes(ssxt_struct: SsxtFileStructure) -> void:
	assert(world, "World node dependancy was not set.")
	
	for child: Node in world.get_node("Groups").get_children():
		child.queue_free()
	
	world.get_camera().transform = ssxt_struct.camera_xform
	world.get_camera().init_rotation = Vector2.ZERO
	
	var group_parent = world.get_node("Groups")
	for group_entry: GroupEntry in ssxt_struct.groups:
		var group_node := Node3D.new()
		group_parent.add_child(group_node)
		group_node.name = group_entry.group_name
		group_node.visible = group_entry.group_visible
		
		for object_entry: ObjectEntry in group_entry.objects:
			var object_node := PatchObject.new()
			group_node.add_child(object_node)
			object_node.name = object_entry.object_name
			object_node.transform = object_entry.object_xform
			var collision_shape_node := CollisionShape3D.new()
			collision_shape_node.debug_color = Color.SKY_BLUE
			collision_shape_node.name = "CollisionMesh"
			collision_shape_node.shape = ConcavePolygonShape3D.new()
			collision_shape_node.shape.backface_collision = true
			object_node.add_child(collision_shape_node)
			var control_points_parent := Node3D.new()
			control_points_parent.name = "ControlPoints"
			object_node.add_child(control_points_parent)
			var segments_parent := Node3D.new()
			segments_parent.name = "PatchSegments"
			object_node.add_child(segments_parent)
			
			for cp_entry in object_entry.control_points:
				var control_point = ControlPoint.new(cp_entry.type,cp_entry.tilemap_cell)
				control_point.aligned = cp_entry.aligned
				control_points_parent.add_child(control_point)
				control_point.position = cp_entry.position
				
			for segment_entry:SegmentEntry in object_entry.segments:
				var segment_node := PatchSegment.new(segment_entry.tilemap_cells)
				segments_parent.add_child(segment_node)
				segment_node.surface_type = segment_entry.surface_type as Enum.SurfaceType
				segment_node.texture_filename = segment_entry.texture_path
				segment_node.showoff_only = segment_entry.showoff_only
				for i in 4:
					segment_node.uv_points[i] = segment_entry.uv_points[i]
				segment_node.lightmap_id = segment_entry.lightmap_id
				segment_node.lightmap_point = segment_entry.lightmap_rect
				
				segment_node.tilemap_cells = segment_entry.tilemap_cells
				
				# Connect the CP signals to the segment
				for cell: Vector2i in segment_node.tilemap_cells:
					# Find the Cp from the cell
					var cp_found: ControlPoint
					for cp: ControlPoint in control_points_parent.get_children():
						if cp.tilemap_cell == cell:
							cp_found = cp
							break
					assert(cp_found)
					cp_found.local_transform_changed.connect(segment_node._control_point_moved)
					cp_found.selection_changed.connect(segment_node._control_point_selection_changed)
				
				# Connect the segment signals to the object. 
				segment_node.mesh_changed.connect(object_node._on_mesh_changed)
				
				# The segments automatically generate the meshes on ready
				

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
		group.group_visible = bool(ssxt_file.get_8())
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
			object.control_point_count = ssxt_file.get_32()
			
			for cp_index in object.control_point_count:
				var control_point = ControlPointEntry.new()
				object.control_points.append(control_point)
				control_point.type = ssxt_file.get_8()
				control_point.tilemap_cell.x = ssxt_file.get_32()
				control_point.tilemap_cell.y = ssxt_file.get_32()
				control_point.aligned = bool(ssxt_file.get_8())
				control_point.position.x = ssxt_file.get_float()
				control_point.position.y = ssxt_file.get_float()
				control_point.position.z = ssxt_file.get_float()
			
			object.segment_count = ssxt_file.get_32()
			for segment_index in object.segment_count:
				var segment := SegmentEntry.new()
				object.segments.append(segment)
				
				for cell_index in 16:
					var cell: Vector2i
					cell.x = ssxt_file.get_32()
					cell.y = ssxt_file.get_32()
					segment.tilemap_cells.append(cell)
			
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
			
				segment.surface_type = ssxt_file.get_8()
				segment.showoff_only = bool(ssxt_file.get_8())
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
			ssxt_file.store_32(object.control_point_count)
			
			for control_point in object.control_points:
				ssxt_file.store_8(control_point.type)
				ssxt_file.store_32(control_point.tilemap_cell.x)
				ssxt_file.store_32(control_point.tilemap_cell.y)
				ssxt_file.store_8(int(control_point.aligned))
				ssxt_file.store_float(control_point.position.x)
				ssxt_file.store_float(control_point.position.y)
				ssxt_file.store_float(control_point.position.z)
			
			ssxt_file.store_32(object.segment_count)
			for segment in object.segments:
				for cell: Vector2i in segment.tilemap_cells:
					ssxt_file.store_32(cell.x)
					ssxt_file.store_32(cell.y)
				
				ssxt_file.store_float(segment.lightmap_rect.position.x)
				ssxt_file.store_float(segment.lightmap_rect.position.y)
				ssxt_file.store_float(segment.lightmap_rect.size.x)
				ssxt_file.store_float(segment.lightmap_rect.size.y)
				ssxt_file.store_32(segment.lightmap_id)
				
				for uv in segment.uv_points:
					ssxt_file.store_float(uv.x)
					ssxt_file.store_float(uv.y)
					
				ssxt_file.store_8(segment.surface_type)
				ssxt_file.store_8(int(segment.showoff_only))
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


## Gets the control point type based on its index. Only used for making the
## default struct with 2 segments.
static func _get_control_point_type(index: int) -> int:
	const CORNERS = [0, 3, 6, 21, 24, 27]
	const HANDLES = [1, 2, 4, 5, 7, 10, 13, 14, 17, 20, 22, 23, 25, 26]
	const INNERS = [8, 9, 11, 12, 15, 16, 18, 19]
	if index in CORNERS:
		return ControlPoint.CORNER # 0
	elif index in HANDLES:
		return ControlPoint.HANDLE # 1
	elif index in INNERS:
		return ControlPoint.INNER # 2
	else:
		assert(false, "Invalid control point index " + str(index))
		return 0


#--------Inner classes---------
class SsxtFileStructure:
	var signature: String = "ssxt"
	var file_structure_version: Array[int] = [0, 1, 0] # Bytes. Major, Minor, Patch
	var editor_version: Array[int] = [0, 3, 0] # Bytes. Major, Minor, Patch
	var date_time_created: String # 19 bytes
	var camera_xform: Transform3D # 4 Vector3's
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
	var control_point_count: int
	var control_points: Array[ControlPointEntry]
	var segment_count: int
	var segments: Array[SegmentEntry]
	
class ControlPointEntry:
	var type: int # byte
	var tilemap_cell: Vector2i
	var aligned: bool
	var position: Vector3

class SegmentEntry:
	var tilemap_cells: Array[Vector2i] # Size 16
	var lightmap_rect: Rect2
	var lightmap_id: int
	var uv_points: Array[Vector2] # Size 4
	var surface_type: int # byte
	var showoff_only: bool
	var texture_path_size: int
	var texture_path: String
	
	
