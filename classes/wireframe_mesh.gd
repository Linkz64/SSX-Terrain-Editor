extends MeshInstance3D
class_name WireframeMesh


# Distance to offset from the textured vertices, towards the camera.
const WIREFRAME_MARGIN = 0.5
const WIREFRAME_COLOR = Color.BLACK


func update(control_points: Array[ControlPoint]) -> void:
	var vertices: Array[Vector3] = []
	vertices.resize(64)
	
	# Populate Bezier Vertices
	var cp_positions: PackedVector3Array
	for cp in control_points:
		cp_positions.append(cp.position)
	for y in 8:
		for x in 8:
			var blend = Vector2(x/7.0, y/7.0)
			vertices[y * 8 + x] = _evaluate_bezier_surface(cp_positions, blend.x, blend.y)

	# Make wireframe grid
	var immediate_mesh = mesh as ImmediateMesh # For cleaner code
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Vertical lines
	for y in 7:
		for x in 8:
			immediate_mesh.surface_set_color(WIREFRAME_COLOR)
			immediate_mesh.surface_add_vertex(vertices[y * 8 + x])
			immediate_mesh.surface_set_color(WIREFRAME_COLOR)
			immediate_mesh.surface_add_vertex(vertices[y * 8 + x + 8])
	# Horizontal lines
	for y in 7:
		for x in 8:
			immediate_mesh.surface_set_color(WIREFRAME_COLOR)
			immediate_mesh.surface_add_vertex(vertices[y * 8 + x])
			immediate_mesh.surface_set_color(WIREFRAME_COLOR)
			immediate_mesh.surface_add_vertex(vertices[y * 8 + x + 1])
	immediate_mesh.surface_end()


func _ready() -> void:
	var wireframe_material := StandardMaterial3D.new()
	wireframe_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wireframe_material.vertex_color_use_as_albedo = true
	material_override = wireframe_material
	
	mesh = ImmediateMesh.new()
	visibility_range_end = 100_000
	visibility_range_end_margin = 10000
	visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func _evaluate_bezier_surface(control_points: PackedVector3Array, u:float, v:float) -> Vector3:
	# Compute 4 control points along the u direction
	var u_points: PackedVector3Array = []
	u_points.resize(4)
	for i in 4:
		var row = i * 4
		var p0 = control_points[row]
		var p1 = control_points[row + 1]
		var p2 = control_points[row + 2]
		var p3 = control_points[row + 3]
		u_points[i] = p0.bezier_interpolate(p1, p2, p3, u)
	# Compute the final position on the surface using v
	return u_points[0].bezier_interpolate(u_points[1], u_points[2], u_points[3], v)
