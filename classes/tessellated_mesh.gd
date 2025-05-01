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
# Blend distance between the 7 vertices. Multiplied by 7 should give ~1.
const BLEND_DISTANCE = 0.142857 

var _control_points: PackedVector3Array # Bus to transfer to _ready. clear after use.
var _texture: Texture2D
var _uv_points: PackedVector2Array
var _is_wireframe = false

func _init(control_points: PackedVector3Array, texture_name: String, \
		p_uv_points: PackedVector2Array, wireframe: bool = false ):
	_control_points = control_points.duplicate()
	_texture = TextureManager.get_texture(texture_name)
	_uv_points = p_uv_points
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _texture
	material_override = mat
	_is_wireframe = wireframe


func _ready() -> void:
	update(_control_points)
	_control_points.clear()
	_uv_points.clear()


func update(control_points: PackedVector3Array, uv_points: PackedVector2Array = []):
	if _is_wireframe:
		_update_wireframe(control_points)
		return
	
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	vertices.resize(64)
	normals.resize(64)
	uvs.resize(64)
	
	# Populate Vertices and UV points
	for y in 8:
		for x in 8:
			var index = y * 8 + x
			var blend = Vector2(x/7.0, y/7.0)
			vertices[index] = _evaluate_bezier_surface(control_points, blend.x, blend.y)
			uvs[index] = _uv_point(_uv_points, blend.x, blend.y)

	# Generate default normals
	# Checks the 4 neighbouring vertices next to the vertex being iterated on.
	# It gets the cross product of the 4 combinations between it's neighbours,
	# and then gets the average normal of all the available combinations.
	for i in 64:
		# Skip if its a corner or edge
		var is_edge = false
		for edge in EDGES.values():
			if i in edge:
				is_edge = true
				break
		if is_edge or i in CORNERS.values():
			continue
		
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
		normals[i] = neighbouring_normals.reduce(sum).normalized() # average
	
	# Generate corner normals
	var corner_cross = func(main_cp: int, cp_a: int, cp_b: int):
		var a = (control_points[cp_a] - control_points[main_cp]).normalized()
		var b = (control_points[cp_b] - control_points[main_cp]).normalized()
		var cross = a.cross(b)
		return -cross
		
	normals[CORNERS["top-left"]] = corner_cross.call(0, 1, 4)
	normals[CORNERS["top-right"]] = corner_cross.call(3, 7, 2)
	normals[CORNERS["bottom-left"]] = corner_cross.call(12, 8, 13)
	normals[CORNERS["bottom-right"]] = corner_cross.call(15, 14, 11)

	# Generate edge normals
	
	# The tangent at the beginning and end of the edge curves.
	# For local use in the loops below.
	var start_tangent: Vector3
	var end_tangent: Vector3
	
	# Top
	for i in 6:
		var p0 = control_points[0]
		var p1 = control_points[1]
		var p2 = control_points[2]
		var p3 = control_points[3]
		var blend_factor := BLEND_DISTANCE + (i * BLEND_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, blend_factor)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-left"]].slerp(normals[CORNERS["top-right"]], blend_factor)
		n = n.normalized()
		var normal = n.slide(tangent).normalized()
		
		start_tangent = p0.bezier_derivative(p1, p2, p3, 0).normalized()
		end_tangent = p0.bezier_derivative(p1, p2, p3, 1).normalized()
		var t = start_tangent.slerp(end_tangent, blend_factor)
		t = t.normalized()
		if t.dot(tangent) < 0:
			normal = -normal
		
		normals[EDGES["top"][i]] = normal
	
	# Left
	for i in 6:
		var p0 = control_points[0]
		var p1 = control_points[4]
		var p2 = control_points[8]
		var p3 = control_points[12]
		var blend_factor := BLEND_DISTANCE + (i * BLEND_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, blend_factor)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-left"]].slerp(normals[CORNERS["bottom-left"]], blend_factor)
		n = n.normalized()
		var normal = n.slide(tangent).normalized()
		
		start_tangent = p0.bezier_derivative(p1, p2, p3, 0).normalized()
		end_tangent = p0.bezier_derivative(p1, p2, p3, 1).normalized()
		var t = start_tangent.slerp(end_tangent, blend_factor)
		t = t.normalized()
		if t.dot(tangent) < 0:
			normal = -normal
		
		normals[EDGES["left"][i]] = normal
	
	# Bottom
	for i in 6:
		var p0 = control_points[12]
		var p1 = control_points[13]
		var p2 = control_points[14]
		var p3 = control_points[15]
		var blend_factor := BLEND_DISTANCE + (i * BLEND_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, blend_factor)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["bottom-left"]].slerp(normals[CORNERS["bottom-right"]], blend_factor)
		n = n.normalized()
		var normal = n.slide(tangent).normalized()
		
		start_tangent = p0.bezier_derivative(p1, p2, p3, 0).normalized()
		end_tangent = p0.bezier_derivative(p1, p2, p3, 1).normalized()
		var t = start_tangent.slerp(end_tangent, blend_factor)
		t = t.normalized()
		if t.dot(tangent) < 0:
			normal = -normal
		
		normals[EDGES["bottom"][i]] = normal
	
	# Right
	for i in 6:
		var p0 = control_points[3]
		var p1 = control_points[7]
		var p2 = control_points[11]
		var p3 = control_points[15]
		var blend_factor := BLEND_DISTANCE + (i * BLEND_DISTANCE)
		var tangent = p0.bezier_derivative(p1, p2, p3, blend_factor)
		tangent = tangent.normalized()
		
		var n = normals[CORNERS["top-right"]].slerp(normals[CORNERS["bottom-right"]], blend_factor)
		n = n.normalized()
		var normal = n.slide(tangent).normalized()
		
		start_tangent = p0.bezier_derivative(p1, p2, p3, 0).normalized()
		end_tangent = p0.bezier_derivative(p1, p2, p3, 1).normalized()
		var t = start_tangent.slerp(end_tangent, blend_factor)
		t = t.normalized()
		if t.dot(tangent) < 0:
			normal = -normal
		
		normals[EDGES["right"][i]] = normal
	
	# Make lollipops
	"""
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
		"""

	# Make grid
	(mesh as ImmediateMesh).clear_surfaces()
	(mesh as ImmediateMesh).surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in 7:
		for x in 7:
			var indexes = [
				y * 8 + x, # top-left
				y * 8 + x + 1, # top-right
				y * 8 + x + 9, # bottom-right
				y * 8 + x + 8, # bottom-left
			]
			
			var add_vertex = func(index):
				(mesh as ImmediateMesh).surface_set_uv(uvs[indexes[index]])
				(mesh as ImmediateMesh).surface_set_normal(normals[indexes[index]])
				(mesh as ImmediateMesh).surface_add_vertex(vertices[indexes[index]])
			
			add_vertex.call(0)
			add_vertex.call(1)
			add_vertex.call(2)
			add_vertex.call(0)
			add_vertex.call(2)
			add_vertex.call(3)
	(mesh as ImmediateMesh).surface_end()
	


func _update_wireframe(control_points: PackedVector3Array):
	var vertices: Array[Vector3] = []
	vertices.resize(64)
	
	# Populate Vertices and UV points
	for y in 8:
		for x in 8:
			var blend = Vector2(x/7.0, y/7.0)
			vertices[y * 8 + x] = _evaluate_bezier_surface(control_points, blend.x, blend.y)

	# Make wireframe grid
	(mesh as ImmediateMesh).clear_surfaces()
	(mesh as ImmediateMesh).surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Vertical
	for y in 7:
		for x in 8:
			(mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x])
			(mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x + 8])
	# Horizontal
	for y in 8:
		for x in 7:
			(mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x])
			(mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x + 1])
	(mesh as ImmediateMesh).surface_end()


static func _uv_point(UVs: PackedVector2Array, x: float, y: float) -> Vector2:
	# Quadrilateral interpolation
	var a = UVs[0].lerp(UVs[2], x)
	var b = UVs[1].lerp(UVs[3], x)
	var c = a.lerp(b, y)
	return c


static func _evaluate_bezier_surface(control_points: PackedVector3Array, u:float, v:float) -> Vector3:
	# De casteljau's algorithm.
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

	
