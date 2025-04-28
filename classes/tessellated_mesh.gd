extends MeshInstance3D
class_name Tessellatedmesh
## The Bezier surface with the texture and lighting normals.
## 8x8 vertices, 7x7 faces


var _control_points: Array[Vector3] # Bus to transfer to _ready. clear after use.
var _texture: Texture2D
var _uv_points: Dictionary


func _init(control_points: Array[Vector3], texture_name: String, p_uv_points: Dictionary):
	_control_points = control_points.duplicate()
	_texture = TextureManager.get_texture(texture_name)
	_uv_points = p_uv_points
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _texture
	material_override = mat


func _ready() -> void:
	update(_control_points)
	_control_points.clear()


func update(control_points: Array[Vector3]):
	var vertices: Array[Vector3] = []
	for y in 8:
		for x in 8:
			vertices.append(_evaluate_bezier_surface(control_points, x/7.0, y/7.0))

	for i in 8*8:
		var inst = MeshInstance3D.new()
		inst.mesh = SphereMesh.new()
		inst.mesh.radial_segments = 16
		inst.mesh.rings = 8
		add_child(inst)
		inst.position = vertices[i]
		
		var arrow = MeshInstance3D.new()
		arrow.mesh = CylinderMesh.new()
		(arrow.mesh as CylinderMesh).height = 3
		(arrow.mesh as CylinderMesh).top_radius = 0.1
		(arrow.mesh as CylinderMesh).bottom_radius = 0.1
		arrow.material_override = StandardMaterial3D.new()
		(arrow.material_override as StandardMaterial3D).albedo_color = Color.RED
		(arrow.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		inst.add_child(arrow)
		arrow.position = Vector3(0, 0, 1.5)
		arrow.rotate_x(TAU/4)
		inst.scale = Vector3.ONE * 0.4
		
		# top
		var top = null
		if i - 8 > 0:
			top = (vertices[i - 8] - vertices[i]).normalized()
		# left
		var left = null
		if i - 1 > 0 and i % 8 != 0:
			left = (vertices[i - 1] - vertices[i]).normalized()
		# bottom
		var bottom = null
		if i + 8 < vertices.size():
			bottom = (vertices[i + 8] - vertices[i]).normalized()
		# right
		var right = null
		if i + 1 < vertices.size() and i % 8 != 7:
			right = (vertices[i + 1] - vertices[i]).normalized()
		
		var normals: Array[Vector3] = []
		if top and left:
			normals.append(top.cross(left))
		if left and bottom:
			normals.append(left.cross(bottom))
		if bottom and right:
			normals.append(bottom.cross(right))
		if right and top:
			normals.append(right.cross(top))
		
		var sum = func(accum: Vector3, vec: Vector3):
			return accum + vec
		
		var average: Vector3 = normals.reduce(sum).normalized()
		inst.look_at(inst.global_position - average, Vector3(0, 0, 1))
		
	
	var corner_0 = get_child(0)
	var point0 = (control_points[1] - control_points[0]).normalized()
	var point1 = (control_points[4] - control_points[0]).normalized()
	var cross = point0.cross(point1)
	corner_0.look_at(corner_0.global_position + cross, Vector3(0, 0, 1))
		
		
		
		
		
	#(mesh as ImmediateMesh).clear_surfaces()
	#(mesh as ImmediateMesh).surface_begin(Mesh.PRIMITIVE_TRIANGLES)


func uv_point(UVs: Array[Vector2], pos: Vector2) -> Vector2:
	var a = UVs[0].lerp(UVs[2], pos.x)
	var b = UVs[1].lerp(UVs[3], pos.x)
	var c = a.lerp(b, pos.y)
	return c


func _set_points(control_points: Array[Vector3], UVs: Array[Vector2]):
	# Generate tesselated mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 7:
		for x in 7:
			var p = Vector2(x/7.0, z/7.0)
			surface.set_smooth_group(-1) # Smoothness
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			p = Vector2((x+1)/7.0, z/7.0)
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			p = Vector2((x+1)/7.0, (z+1)/7.0)
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			p = Vector2(x/7.0, z/7.0)
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			p = Vector2((x+1)/7.0, (z+1)/7.0)
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			p = Vector2(x/7.0, (z+1)/7.0)
			surface.set_uv(uv_point(UVs, p))
			surface.add_vertex(_evaluate_bezier_surface(control_points, p.x, p.y))
			
	surface.generate_normals()
	#surface.commit()


func _evaluate_bezier_surface(control_points: Array[Vector3], u:float, v:float) -> Vector3:
	# Compute 4 control points along the u direction
	var u_points: Array[Vector3] = []
	for i in 4:
		var curve_points: Array[Vector3] = []
		curve_points.resize(4)
		curve_points[0] = control_points[i*4]
		curve_points[1] = control_points[i*4 + 1]
		curve_points[2] = control_points[i*4 + 2]
		curve_points[3] = control_points[i*4 + 3]
		var point = curve_points[0].bezier_interpolate(curve_points[1], curve_points[2], curve_points[3], u)
		u_points.append(point)
	
	# Compute the final position on the surface using v
	return u_points[0].bezier_interpolate(u_points[1], u_points[2], u_points[3], v)


	
