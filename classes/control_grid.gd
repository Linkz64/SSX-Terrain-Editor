extends MeshInstance3D
class_name ControlGrid
## Draws lines between the 16 control points to make a grid


var colors: Array[Color] = []
var _control_points: Array[Vector3] # Bus to transfer to _ready. clear after use.


func _init(control_points: Array[Vector3], h_color: Color, v_color: Color):
	_control_points = control_points
	colors.append(h_color)
	colors.append(v_color)
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat


func _ready() -> void:
	update(_control_points)
	_control_points.clear()


func update(control_points: Array[Vector3]):
	var h_line_indices = [0, 1, 1, 2, 2, 3]
	var v_line_indices = [0, 4, 4, 8, 8, 12]
	
	(mesh as ImmediateMesh).clear_surfaces()
	(mesh as ImmediateMesh).surface_begin(Mesh.PRIMITIVE_LINES)
	(mesh as ImmediateMesh).surface_set_color(colors[0])
	for y in 4:
		for i in h_line_indices:
			(mesh as ImmediateMesh).surface_add_vertex(control_points[4 * y + i])
	
	(mesh as ImmediateMesh).surface_set_color(colors[1])
	for y in 4:
		for i in v_line_indices:
			(mesh as ImmediateMesh).surface_add_vertex(control_points[y + i])
	
	# Duplicate
	#for i in control_points.size():
		#const OFFSET = 0.01
		#control_points[i] += Vector3(OFFSET, OFFSET, OFFSET)
	#
	#for y in 4:
		#for i in h_line_indices:
			#(mesh as ImmediateMesh).surface_add_vertex(control_points[4 * y + i])
			#
	#for y in 4:
		#for i in v_line_indices:
			#(mesh as ImmediateMesh).surface_add_vertex(control_points[y + i])
	
			
			
	
	(mesh as ImmediateMesh).surface_end()
	
