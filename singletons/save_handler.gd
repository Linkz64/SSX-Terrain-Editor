extends Node

signal new_terrain_created


func new_terrain(terrain_path: String, import_json: bool, grouping: Enum.GroupingIndex):
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))

	if import_json:
		_create_ssxt_from_json(terrain_path, grouping)
	else:
		pass


func _create_ssxt_from_json(terrain_path: String, grouping: Enum.GroupingIndex):
	# Read the json and turn it into a Godot ssxt structured class
	var json_data: Array[JsonPatch] = Multitool.open_extracted_patch_data( \
			terrain_path.get_base_dir())
	var ssxt_struct := SsxtFileStructure.new()
	
	var version_str: String = ProjectSettings.get_setting("application/config/version")
	var version_str_array = version_str.substr(1).split(".")
	var editor_version: Array[int] = []
	for char in version_str_array:
		editor_version.append(int(char))
	ssxt_struct.editor_version = editor_version
	
	ssxt_struct.date_time_created = Time.get_datetime_string_from_system()
	
	ssxt_struct.camera_xform = Transform3D().rotated(Vector3.RIGHT, TAU/4)

#region Grouping types
	if grouping == Enum.GroupingIndex.NONE:
		ssxt_struct.group_count = 1
		
		var group_entry := GroupEntry.new()
		group_entry.group_name = "Group0"
		group_entry.group_name_size = group_entry.group_name.length()
		group_entry.group_visible = true
		group_entry.object_count = json_data.size()
		
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
				control_point_entry.position = patch.points[0] - object_entry.object_xform.origin
				
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
			segment.uv_points = [
				Vector2.ZERO,
				Vector2(1, 0),
				Vector2(0, 1),
				Vector2(1, 1),
			]
			segment.patch_style = patch.patch_style
			segment.tricky_only_patch = patch.tricky_only_patch
			segment.texture_path = patch.texture_path
			segment.texture_path_size = patch.texture_path.length()
			object_entry.segments.append(segment)
			group_entry.objects.append(object_entry)
		ssxt_struct.groups.append(group_entry)
		
#endregion

	# Write ssxt file
#region Write ssxt file
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

#endregion


## Get the neighbour of a cp from all 4 sides, returns null if its not valid,
## returns the neighbour index if is valid, this is only used for json importing.
static func _get_neighbour(index: int, side: String) -> Variant:
	if side == "north":
		return null if (index - 4) < 0 else (index - 4)
	elif side == "west":
		var neighbour = index - 1
		if neighbour > 0 and neighbour % 4 != 3:
			return neighbour
		else:
			return null
	elif side == "south":
		return null if (index + 4) < 0 else (index + 4)
	elif side == "east":
		var neighbour = index + 1
		if neighbour > 0 and neighbour % 4 != 0:
			return neighbour
		else:
			return null
	else:
		assert(null)
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
		assert(null)
		return 0
		

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
	
	
