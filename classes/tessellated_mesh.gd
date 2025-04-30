extends MeshInstance3D
class_name Tessellatedmesh
## The Bezier surface with the texture and lighting normals.
## 8x8 vertices, 7x7 faces

## Vertex Indices
const CORNERS = {
	"top-left": 0,
	"top-right": 7,
	"bottom-left": 56,
	"bottom-right": 63,
}
const EDGES = {
	"top": [1, 2, 3, 4, 5, 6],
	"right": [15, 23, 31, 39, 47, 55], 
	"left": [8, 16, 24, 32, 40, 48],
	"bottom": [57, 58, 59, 60, 61, 62],
}
const DELTA_DISTANCE = 0.142857

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
	var normals: Array[Vector3] = []
	vertices.resize(64)
	normals.resize(64)
	
	# Populate vertices
	for y in 8:
		for x in 8:
			vertices[y * 8 + x] = _evaluate_bezier_surface(control_points, x/7.0, y/7.0)

	# Set the default normals
	# Checks the 4 neighbouring vertices next to the vertex being iterated on.
	# It gets the cross product of the 4 combinations between it's neighbours,
	# and then gets the average normal of all the available combinations.
	for i in vertices.size():
		var top = null
		var left = null
		var bottom = null
		var right = null
		
		if i - 8 > 0:
			top = (vertices[i - 8] - vertices[i]).normalized()
		if i - 1 > 0 and i % 8 != 0:
			left = (vertices[i - 1] - vertices[i]).normalized()
		if i + 8 < vertices.size():
			bottom = (vertices[i + 8] - vertices[i]).normalized()
		if i + 1 < vertices.size() and i % 8 != 7:
			right = (vertices[i + 1] - vertices[i]).normalized()
		
		var neighbouring_normals: Array[Vector3] = []
		if top and left:
			neighbouring_normals.append(top.cross(left))
		if left and bottom:
			neighbouring_normals.append(left.cross(bottom))
		if bottom and right:
			neighbouring_normals.append(bottom.cross(right))
		if right and top:
			neighbouring_normals.append(right.cross(top))
		
		# Average algo by summing and then normalizing.
		var sum = func(accum: Vector3, vec: Vector3):
			return accum + vec
		var average: Vector3 = neighbouring_normals.reduce(sum).normalized()
		normals[i] = average
	
	# Override the corner normals
	var corner_cross = func(main_cp: int, cp_a: int, cp_b: int):
		var a = (control_points[cp_a] - control_points[main_cp]).normalized()
		var b = (control_points[cp_b] - control_points[main_cp]).normalized()
		var cross = a.cross(b)
		return -cross
		
	normals[CORNERS["top-left"]] = corner_cross.call(0, 1, 4)
	normals[CORNERS["top-right"]] = corner_cross.call(3, 7, 2)
	normals[CORNERS["bottom-left"]] = corner_cross.call(12, 8, 13)
	normals[CORNERS["bottom-right"]] = corner_cross.call(15, 14, 11)

	# Override the edge normals
	# Top
	for i in 6:
		var p0 = control_points[0]
		var p1 = control_points[1]
		var p2 = control_points[2]
		var p3 = control_points[3]
		var delta := DELTA_DISTANCE + (i * DELTA_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, delta)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-left"]].slerp(normals[CORNERS["top-right"]], delta)
		n = n.normalized()
		
		var normal = n.slide(tangent).normalized()
		normals[EDGES["top"][i]] = normal
	
	# Left
	for i in 6:
		var p0 = control_points[0]
		var p1 = control_points[4]
		var p2 = control_points[8]
		var p3 = control_points[12]
		var delta := DELTA_DISTANCE + (i * DELTA_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, delta)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-left"]].slerp(normals[CORNERS["bottom-left"]], delta)
		n = n.normalized()
		
		var normal = n.slide(tangent).normalized()
		normals[EDGES["left"][i]] = normal
	
	# Bottom
	for i in 6:
		var p0 = control_points[12]
		var p1 = control_points[13]
		var p2 = control_points[14]
		var p3 = control_points[15]
		var delta := DELTA_DISTANCE + (i * DELTA_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, delta)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["bottom-left"]].slerp(normals[CORNERS["bottom-right"]], delta)
		n = n.normalized()
		
		var normal = n.slide(tangent).normalized()
		normals[EDGES["bottom"][i]] = normal
	
	# Right
	for i in 6:
		var p0 = control_points[3]
		var p1 = control_points[7]
		var p2 = control_points[11]
		var p3 = control_points[15]
		var delta := DELTA_DISTANCE + (i * DELTA_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, delta)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-right"]].slerp(normals[CORNERS["bottom-right"]], delta)
		n = n.normalized()
		
		var normal = n.slide(tangent).normalized()
		normals[EDGES["right"][i]] = normal
	
	
	

	# Make lollipops
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
		(arrow.mesh as CylinderMesh).radial_segments = 8
		arrow.material_override = StandardMaterial3D.new()
		(arrow.material_override as StandardMaterial3D).albedo_color = Color.RED
		(arrow.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		inst.add_child(arrow)
		arrow.position = Vector3(0, 0, 1.5)
		arrow.rotate_x(TAU/4)
		inst.scale = Vector3.ONE * 0.4
		inst.look_at(inst.global_position - normals[i], Vector3(0, 0, 1))


#func get_bezier_normal_at(control_points: Array, ) -> Vector3:
	#return Vector3.ZERO




# TODO: Turn into a lambda
func uv_point(UVs: Array[Vector2], pos: Vector2) -> Vector2:
	var a = UVs[0].lerp(UVs[2], pos.x)
	var b = UVs[1].lerp(UVs[3], pos.x)
	var c = a.lerp(b, pos.y)
	return c


# TODO: Translate to ImmediateMesh
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
	# De casteljau's algorithm.
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


	
