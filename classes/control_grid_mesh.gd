extends MeshInstance3D
class_name ControlGridMesh
## Shows the control points in a 3D 4x4 grid, each control point has a diamond on top 


const LINE_COLOR = Color.ORANGE
const DIAMOND_COLOR = Color.BLACK
const DIAMOND_HIGHLIGHT_COLOR = Color.ORANGE
const DIAMOND_SIZE = 0.01
var _diamonds: Array[MeshInstance3D]


func update(control_points: Array[ControlPoint]):
	assert(is_node_ready())
	# Update main mesh
	var h_line_indices = [0, 1, 1, 2, 2, 3]
	var v_line_indices = [0, 4, 4, 8, 8, 12]
	var immediate_mesh := mesh as ImmediateMesh # For cleaner code
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_set_color(LINE_COLOR)
	for y in 4:
		for i in h_line_indices:
			immediate_mesh.surface_add_vertex(control_points[4 * y + i].position)
	immediate_mesh.surface_set_color(LINE_COLOR)
	for y in 4:
		for i in v_line_indices:
			immediate_mesh.surface_add_vertex(control_points[y + i].position)
	immediate_mesh.surface_end()

	# Update diamond meshes
	for i in control_points.size():
		var cp_position = control_points[i].position
		var diamond_mesh := _diamonds[i].mesh as ImmediateMesh # For cleaner code
		diamond_mesh.clear_surfaces()
		diamond_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		if control_points[i].is_selected:
			diamond_mesh.surface_set_color(DIAMOND_HIGHLIGHT_COLOR)
		else:
			diamond_mesh.surface_set_color(DIAMOND_COLOR)
		
		var vertices = [
			Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(1, 0, 0),
			Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, -1, 0),
		]
		for vert in vertices:
			diamond_mesh.surface_add_vertex(vert * DIAMOND_SIZE)
		diamond_mesh.surface_end()
		_diamonds[i].position = cp_position


func _ready() -> void:
	# Setup main mesh
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = false
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	
	# Setup control point diamonds
	var diamond_mat := StandardMaterial3D.new()
	diamond_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	diamond_mat.vertex_color_use_as_albedo = true
	diamond_mat.no_depth_test = true
	diamond_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	diamond_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	diamond_mat.fixed_size = true
	
	_diamonds.resize(16)
	for i in _diamonds.size():
		_diamonds[i] = MeshInstance3D.new()
		add_child(_diamonds[i])
		_diamonds[i].position = Vector3.ZERO
		_diamonds[i].mesh = ImmediateMesh.new()
		_diamonds[i].material_override = diamond_mat
	hide()
