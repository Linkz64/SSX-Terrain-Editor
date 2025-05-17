extends MeshInstance3D
class_name TessellatedMesh
"""
The Bezier surface with the texture, uv, and lighting normals.
8x8 vertices, 7x7 faces

When created, they require the control points, the texture, and the UV map.
As an optional it takes a bool telling it if it should render the wireframe overlay.
If true - It'll render The textured mesh, and the wireframe overlay.
If false - It'll only render the textured mesh.
In both cases the wireframe is created in memory, just not rendered if false. 
This is so its faster to enable/disable overlay at runtime with no lag, in exchange for 
memory usage.
"""


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

# Distance to offset from the textured vertices, towards the vertex normal.
const WIREFRAME_MARGIN = 0.5
const WIREFRAME_COLOR = Color.BLACK

# Initial parameters used to create the meshes. 
# Also used to propagate arguments from _init() to _ready().
# Overriten by _init() and update methods.
var _init_control_points: PackedVector3Array
var _init_uv_points: PackedVector2Array
var _init_texture_name: String
var _init_wireframe_overlay: bool

var _is_ready: bool = false
var _wireframe_instance: MeshInstance3D

#------Public-------
func update_all(control_points: PackedVector3Array, texture_name: String, \
		uv_points: PackedVector2Array, wireframe_overlay: bool = false):
	if not _is_ready:
		push_warning("Can't update when _ready hasn't ran yet. Changes will not take effect immediatly")
		return

	# Override initial data
	_init_control_points = control_points
	_init_uv_points = uv_points
	_init_texture_name = texture_name
	_init_wireframe_overlay = wireframe_overlay
	
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
			uvs[index] = _uv_point(uv_points, blend.x, blend.y)
	
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
		normals[i] = neighbouring_normals.reduce(sum, Vector3.ZERO).normalized() # average
	
	# Generate corner normals
	var corner_cross = func(main_cp: int, cp_a: int, cp_b: int, cp_c: int):
		var a = (control_points[cp_a] - control_points[main_cp]).normalized()
		var b = (control_points[cp_b] - control_points[main_cp]).normalized()
		var c = (control_points[cp_c] - control_points[main_cp]).normalized()
		var cross = a.cross(b) if a.cross(b) != Vector3.ZERO else a.cross(c)
		if cross == Vector3.ZERO:
			# If the corner's triangle is degenerate, then set it to the diagonal vertex;s normal 
			match main_cp:
				0:
					return normals[9]
				3:
					return normals[14]
				12:
					return normals[49]
				15:
					return normals[54]
		return -cross
		
	normals[CORNERS["top-left"]] = corner_cross.call(0, 1, 4, 5)
	normals[CORNERS["top-right"]] = corner_cross.call(3, 7, 2, 6)
	normals[CORNERS["bottom-left"]] = corner_cross.call(12, 8, 13, 9)
	normals[CORNERS["bottom-right"]] = corner_cross.call(15, 14, 11, 10)

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
		if tangent == Vector3.ZERO:
			normals[EDGES["top"][i]] = normals[CORNERS["top-left"]]
			continue
		
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
		
		if tangent == Vector3.ZERO:
			normals[EDGES["left"][i]] = normals[CORNERS["top-right"]]
			continue
		
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
				
		if tangent == Vector3.ZERO:
			normals[EDGES["bottom"][i]] = normals[CORNERS["bottom-left"]]
			continue
		
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
				
		if tangent == Vector3.ZERO:
			normals[EDGES["right"][i]] = normals[CORNERS["bottom-right"]]
			continue
		
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
		
	# Update textured grid mesh
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

	# Update wireframe mesh
	_update_wireframe_with_normals(control_points, normals)
	_wireframe_instance.visible = wireframe_overlay
	

func update_control_points(control_points: PackedVector3Array):
	_init_control_points = control_points
	update_all(control_points, _init_texture_name, _init_uv_points, _init_wireframe_overlay)
	
	
func update_uv_points(uv_points: PackedVector2Array):
	_init_uv_points = uv_points
	update_all(_init_control_points, _init_texture_name, uv_points, _init_wireframe_overlay)


func update_texture(texture_name: String):
	_init_texture_name = texture_name
	if not _is_ready:
		push_warning("Can't update when _ready hasn't ran yet. Changes will not take effect immediatly")
		return
	material_override.albedo_texture = TextureManager.get_texture(texture_name)


func enable_wireframe_overlay():
	_init_wireframe_overlay = true
	if not _is_ready:
		push_warning("Can't update when _ready hasn't ran yet. Changes will not take effect immediatly")
		return
	_wireframe_instance.show()
	

func disable_wireframe_overlay():
	_init_wireframe_overlay = false
	if not _is_ready:
		push_warning("Can't update when _ready hasn't ran yet. Changes will not take effect immediatly")
		return
	_wireframe_instance.hide()


#----------Private------------
func _init(control_points: PackedVector3Array, texture_name: String, \
		uv_points: PackedVector2Array, wireframe_overlay: bool = false ):
	_init_control_points = control_points
	_init_uv_points = uv_points
	_init_texture_name = texture_name
	_init_wireframe_overlay = wireframe_overlay


func _ready() -> void:
	_is_ready = true
	
	# Create textured material
	var texture := TextureManager.get_texture(_init_texture_name)
	var textured_material := StandardMaterial3D.new()
	textured_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	textured_material.albedo_texture = texture
	#textured_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Create wireframe overlay material
	var wireframe_material := StandardMaterial3D.new()
	wireframe_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wireframe_material.vertex_color_use_as_albedo = true
	
	# Create Textured mesh
	mesh = ImmediateMesh.new()
	material_override = textured_material
	 
	# Create Wireframe overlay mesh instance and mesh
	_wireframe_instance = MeshInstance3D.new()
	add_child(_wireframe_instance)
	_wireframe_instance.visibility_range_end = 100_000
	_wireframe_instance.visibility_range_end_margin = 10000
	_wireframe_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_wireframe_instance.mesh = ImmediateMesh.new()
	_wireframe_instance.material_override = wireframe_material
	
	update_all(_init_control_points, _init_texture_name, _init_uv_points, _init_wireframe_overlay)


func _update_wireframe_with_normals(control_points: PackedVector3Array,
		normals: PackedVector3Array):
	var vertices: Array[Vector3] = []
	vertices.resize(64)
	
	# Populate Vertices
	for y in 8:
		for x in 8:
			var blend = Vector2(x/7.0, y/7.0)
			vertices[y * 8 + x] = _evaluate_bezier_surface(control_points, blend.x, blend.y)

	# Make wireframe grid
	(_wireframe_instance.mesh as ImmediateMesh).clear_surfaces()
	(_wireframe_instance.mesh as ImmediateMesh).surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Wireframe overlays have two sides, offseted by the normal of a vertex. This is so it doesn't
	# overlay the textured mesh and create uneven lines.
	
	var side = ["front", "back"]
	for i in 2:
		# Vertical
		for y in 7:
			for x in 8:
				var normal_a = normals[y * 8 + x]
				#normal_a += normal_a * WIREFRAME_MARGIN
				normal_a *= WIREFRAME_MARGIN
				if side[i] == "front":
					normal_a *= -1
				(_wireframe_instance.mesh as ImmediateMesh).surface_set_color(WIREFRAME_COLOR)
				(_wireframe_instance.mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x] + normal_a)
				
				var normal_b = normals[y * 8 + x + 8]
				normal_b *= WIREFRAME_MARGIN
				#normal_b += normal_b * WIREFRAME_MARGIN
				if side[i] == "front":
					normal_b *= -1
				(_wireframe_instance.mesh as ImmediateMesh).surface_set_color(WIREFRAME_COLOR)
				(_wireframe_instance.mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x + 8] + normal_b)
		# Horizontal
		for y in 8:
			for x in 7:
				var normal_a = normals[y * 8 + x]
				#normal_a += normal_a * WIREFRAME_MARGIN
				normal_a *= WIREFRAME_MARGIN
				if side[i] == "front":
					normal_a *= -1
				(_wireframe_instance.mesh as ImmediateMesh).surface_set_color(WIREFRAME_COLOR)
				(_wireframe_instance.mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x] + normal_a)
				
				var normal_b = normals[y * 8 + x + 1]
				normal_b *= WIREFRAME_MARGIN
				#normal_b += normal_b * WIREFRAME_MARGIN
				if side[i] == "front":
					normal_b *= -1
				(_wireframe_instance.mesh as ImmediateMesh).surface_set_color(WIREFRAME_COLOR)
				(_wireframe_instance.mesh as ImmediateMesh).surface_add_vertex(vertices[y * 8 + x + 1] + normal_b)
			
	(_wireframe_instance.mesh as ImmediateMesh).surface_end()


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

	
