extends Node

signal new_terrain_created


func new_terrain(terrain_path: String, import_json: bool, grouping: Enum.GroupingIndex):
	TextureManager.load_textures(terrain_path.get_base_dir().path_join("Textures"))

	if import_json:
		_json_import(terrain_path, grouping)
	else:
		pass


func _json_import(terrain_path: String, grouping: Enum.GroupingIndex):
	# Read the json and turn it into a Godot ssxt structured class
	var json_data: Array[JsonPatch] = Multitool.open_extracted_patch_data( \
			terrain_path.get_base_dir())
	var ssxt_struct := SsxtFileStructure.new()
	
	var version_str: String = ProjectSettings.get_setting("application/config/version")
	var version_str_array = version_str.substr(1).split(",")
	var editor_version: Array[int] = []
	for char in version_str:
		editor_version.append(int(char))
	ssxt_struct.editor_version = editor_version
	
	ssxt_struct.date_time_created = Time.get_datetime_string_from_system()
	
	ssxt_struct.camera_xform = Transform3D().rotated(Vector3.RIGHT, TAU/4)

	if grouping == Enum.GroupingIndex.NONE:
		ssxt_struct.group_count = 1
		
		var group_entry := GroupEntry.new()
		group_entry.group_name = "Group0"
		group_entry.group_name_size = group_entry.group_name.length()
		group_entry.group_visible = true
		group_entry.object_count = json_data.size()
		
		#for patch in json_data:
			#pass


class SsxtFileStructure:
	var signature: String = "ssxt"
	var file_sctructure_version: Array[int] = [0, 1, 0] # Bytes. Major, Minor, Patch
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
	var ref_north_id: int # References to the neighbouring CPs to complete the doubly linked grid
	var ref_west_id: int
	var ref_south_id: int
	var ref_east_id: int

class SegmentEntry:
	var id: int
	var control_point_ids: Array[int] # Size 16
	var lightmap_rect: Rect2
	var lightmap_id: int
	var uv_points: Array[Vector2] # Size 4
	var patch_style: int # byte
	var tricky_only_patch: bool
	var texture_path_size: int # byte
	var texture_path: String
	
	
