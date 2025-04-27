extends ImmediateMesh
class_name PatchMesh






func set_texture(texture: Texture2D):
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	surface_set_material(0, mat)
	


func uv_point(UVs: Array[Vector2], pos: Vector2) -> Vector2:
	var a = UVs[0].lerp(UVs[2], pos.x)
	var b = UVs[1].lerp(UVs[3], pos.x)
	var c = a.lerp(b, pos.y)
	return c
	

func set_points(control_points: Array[Vector3], UVs: Array[Vector2]):
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


	
