extends MeshInstance3D
class_name TexturedMesh


# Blend distance between the 7 vertices.
const BLEND_DISTANCE = 1.0 / 7.0
const HIGHLIGHT_COLOR = Color.ORANGE


func update(control_points: Array[ControlPoint], \
		texture_name: String, \
		uv_points: PackedVector2Array, \
		highlight: bool = false \
	) -> void:
	var triangles: Array[Triangle]
	
	# Populate Triangles
	var cp_positions: PackedVector3Array
	for cp in control_points:
		cp_positions.append(cp.position)
	for y in 7:
		for x in 7:
			# Quad blends
			var blends: Array[Vector2]  = [
				Vector2(x / 7.0, y / 7.0),
				Vector2((x + 1) / 7.0, y / 7.0),
				Vector2((x + 1) / 7.0, (y + 1) / 7.0),
				Vector2(x / 7.0, (y + 1) / 7.0),
			] 
			# UV blends for each vertex
			var uv_blends = [
				_uv_point(uv_points, blends[0].x, blends[0].y),
				_uv_point(uv_points, blends[1].x, blends[1].y),
				_uv_point(uv_points, blends[2].x, blends[2].y),
				_uv_point(uv_points, blends[3].x, blends[3].y),
			]
			# Vertex positions
			var vertices: Array[Vector3] = [
				_evaluate_bezier_surface(cp_positions, blends[0].x, blends[0].y),
				_evaluate_bezier_surface(cp_positions, blends[1].x, blends[1].y),
				_evaluate_bezier_surface(cp_positions, blends[2].x, blends[2].y),
				_evaluate_bezier_surface(cp_positions, blends[3].x, blends[3].y),
			]
			var triangle1: Triangle = Triangle.new(vertices[0], vertices[1], vertices[3], \
					[uv_blends[0], uv_blends[1], uv_blends[3]])
			var triangle2: Triangle = Triangle.new(vertices[1], vertices[2], vertices[3], \
					[uv_blends[1], uv_blends[2], uv_blends[3]])
			if not triangle1.is_degenerate:
				triangles.append(triangle1)
			if not triangle2.is_degenerate:
				triangles.append(triangle2)		
	
	# Get texture and enable highlight if provided
	material_override.albedo_texture = TextureManager.get_texture(texture_name)
	material_override.albedo_color = HIGHLIGHT_COLOR if highlight else Color.WHITE
	
	# Create mesh
	var immediate_mesh := mesh as ImmediateMesh
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri: Triangle in triangles:
		immediate_mesh.surface_set_uv(tri.a.uv)
		immediate_mesh.surface_set_normal(tri.a.normal)
		immediate_mesh.surface_add_vertex(tri.a.pos)
		immediate_mesh.surface_set_uv(tri.b.uv)
		immediate_mesh.surface_set_normal(tri.b.normal)
		immediate_mesh.surface_add_vertex(tri.b.pos)
		immediate_mesh.surface_set_uv(tri.c.uv)
		immediate_mesh.surface_set_normal(tri.c.normal)
		immediate_mesh.surface_add_vertex(tri.c.pos)
	immediate_mesh.surface_end()


static func _triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Variant:
	var _b := (b - a).normalized()
	var _c := (c - a).normalized()
	var cross = _c.cross(_b)
	if cross == Vector3.ZERO:
		return null
	return cross


static func _uv_point(UVs: PackedVector2Array, x: float, y: float) -> Vector2:
	# Quadrilateral interpolation
	var a = UVs[0].lerp(UVs[2], x)
	var b = UVs[1].lerp(UVs[3], x)
	var c = a.lerp(b, y)
	return c


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


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = HIGHLIGHT_COLOR
	material_override = mat
	mesh = ImmediateMesh.new()


class Vertex:
	var pos: Vector3
	var normal: Vector3
	var uv: Vector2
	func _init(_pos: Vector3, _normal: Vector3 = Vector3.ZERO) -> void:
		pos = _pos
		normal = _normal
		
class Triangle:
	var a: Vertex
	var b: Vertex
	var c: Vertex
	var is_degenerate: bool
	func _init(_a: Vector3, _b: Vector3, _c: Vector3, uvs: Array[Vector2]) -> void:
		var normal = TexturedMesh._triangle_normal(_a, _b, _c)
		if not normal:
			is_degenerate = true
			return
		a = Vertex.new(_a, normal)
		b = Vertex.new(_b, normal)
		c = Vertex.new(_c, normal)
		assert(uvs.size() == 3)
		a.uv = uvs[0]
		b.uv = uvs[1]
		c.uv = uvs[2]
		
		
