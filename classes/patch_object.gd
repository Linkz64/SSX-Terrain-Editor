extends StaticBody3D
class_name PatchObject
## Patch objects represent a bezier surface. It's a parent to all the data needed to make
## an interactive and renderable surface. This script however only holds data 
## that the patch object specifically needs - or to mediate communication between
## child nodes, like the tilemap database for control point neighbor detection.
## Everything else is a node as a child of this one, that includes Collision mesh,
## control points, segments, textured mesh, wireframe mesh, and control grid.

enum {
	SOLO, # Only a segment on top
	LEFT_L, # Segments on top and left
	RIGHT_L, # Segments on top and right
	STRAIGHT, # Segments on top and bottom
	TEE, # Segments on top, left, and right
	HOLE, # Segments on top, right, bottom, and left
}

func highlight(value: bool) -> void:
	for segment: PatchSegment in get_node("PatchSegments").get_children():
		segment.selected = value
		segment.update()


func show_grid(value: bool) -> void:
	for segment: PatchSegment in get_node("PatchSegments").get_children():
		segment.show_grid(value)


func create_segment_from_handle(handle: ControlPoint) -> void:
	assert(handle.type == ControlPoint.HANDLE)

	var inners := handle.get_side_inners()
	if inners.size() == 2:
		AlertBus.create_side_alert("Cannot create segment on filled neighbors", Enum.SideAlertType.ERROR)
		return
	
	# Find the direction in which to create the new segment
	var handle_dir: Vector2i = handle.tilemap_cell - inners[0].tilemap_cell
	
	# Down
	if handle_dir.y == -1: 
		var top_left_corner: ControlPoint = handle.tilemap_get_cp_from_cell(handle.tilemap_cell - Vector2i(1, 0))
		assert(top_left_corner)
		if top_left_corner.type != ControlPoint.CORNER:
			top_left_corner = handle.tilemap_get_cp_from_cell(top_left_corner.tilemap_cell - Vector2i(1, 0))
		assert(top_left_corner and top_left_corner.type == ControlPoint.CORNER)
			
		var get_cp_relative_to_corner := func(offsetx: int, offsety: int) -> ControlPoint:
			return handle.tilemap_get_cp_from_cell(top_left_corner.tilemap_cell + Vector2i(offsetx, offsety))
		
		var create_new_point_at := func(type: int, cell: Vector2i, pos: Vector3) -> ControlPoint:
			var control_point := ControlPoint.new(type, cell)
			control_point.aligned = true
			get_node("ControlPoints").add_child(control_point)
			control_point.position = pos
			return control_point
		
		var create_segment := func(top_left_corner_cell: Vector2i) -> PatchSegment:
			var cells: Array[Vector2i]
			for y in 4:
				for x in 4:
					cells.append(top_left_corner_cell + Vector2i(x, -y))
			var segment = PatchSegment.new(cells)
			get_node("PatchSegments").add_child(segment)
			return segment
			
		var find_extrude_type := func() -> int:
			var left_exists = get_cp_relative_to_corner.call(0, -1)
			var right_exists = get_cp_relative_to_corner.call(3, -1)
			var bottom_exists = get_cp_relative_to_corner.call(1, -3)
			
			if left_exists and right_exists and bottom_exists:
				return HOLE
			if bottom_exists:
				return STRAIGHT
			if left_exists and right_exists:
				return TEE
			if left_exists:
				return LEFT_L
			if right_exists:
				return RIGHT_L
			return SOLO
		
		match find_extrude_type.call():
			SOLO:
				var top_left_opposite := get_cp_relative_to_corner.call(0, 1) as ControlPoint
				var handle4_position := (top_left_corner.position - top_left_opposite.position) + top_left_corner.position
				var handle8_position := (top_left_corner.position - top_left_opposite.position) + handle4_position
				var corner12_position := (top_left_corner.position - top_left_opposite.position) + handle8_position
				
				var top_right_corner := get_cp_relative_to_corner.call(3, 0) as ControlPoint
				var top_right_opposite := get_cp_relative_to_corner.call(3, 1) as ControlPoint
				var handle7_position := (top_right_corner.position - top_right_opposite.position) + top_right_corner.position
				var handle11_position := (top_right_corner.position - top_right_opposite.position) + handle7_position
				var corner15_position := (top_right_corner.position - top_right_opposite.position) + handle11_position
				
				var a := handle4_position - top_left_corner.position
				var b := (get_cp_relative_to_corner.call(1, 0) as ControlPoint).position - top_left_corner.position
				var inner5_position := (a + b) + top_left_corner.position
				a = handle7_position - top_right_corner.position
				b = (get_cp_relative_to_corner.call(2, 0) as ControlPoint).position - top_right_corner.position
				var inner6_position := (a + b) + top_right_corner.position
				
				var handle13_position = corner12_position.lerp(corner15_position, 0.33333)
				var handle14_position = corner12_position.lerp(corner15_position, 1 - 0.33333)
				
				a = handle8_position - corner12_position
				b = handle13_position - corner12_position
				var inner9_position := (a + b) + corner12_position
				
				a = handle14_position - corner15_position
				b = handle11_position - corner15_position
				var inner10_position := (a + b) + corner15_position
				
				var new_cps: Array[ControlPoint]
				new_cps.append(create_new_point_at.call(ControlPoint.CORNER, top_left_corner.tilemap_cell + Vector2i(0, -3), corner12_position))
				new_cps.append(create_new_point_at.call(ControlPoint.CORNER, top_left_corner.tilemap_cell + Vector2i(3, -3), corner15_position))
				
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(0, -1), handle4_position))
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(0, -2), handle8_position))
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(3, -1), handle7_position))
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(3, -2), handle11_position))
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(1, -3), handle13_position))
				new_cps.append(create_new_point_at.call(ControlPoint.HANDLE, top_left_corner.tilemap_cell + Vector2i(2, -3), handle14_position))
				
				new_cps.append(create_new_point_at.call(ControlPoint.INNER, top_left_corner.tilemap_cell + Vector2i(1, -1), inner5_position))
				new_cps.append(create_new_point_at.call(ControlPoint.INNER, top_left_corner.tilemap_cell + Vector2i(2, -1), inner6_position))
				new_cps.append(create_new_point_at.call(ControlPoint.INNER, top_left_corner.tilemap_cell + Vector2i(1, -2), inner9_position))
				new_cps.append(create_new_point_at.call(ControlPoint.INNER, top_left_corner.tilemap_cell + Vector2i(2, -2), inner10_position))
				
				await get_tree().process_frame
				var segment = create_segment.call(top_left_corner.tilemap_cell)
				segment.mesh_changed.connect(_on_mesh_changed)
				
				for cp in new_cps:
					cp.local_transform_changed.connect(segment._control_point_moved)
					cp.selection_changed.connect(segment._control_point_selection_changed)
				
				GizmoProxy.deselect_control_point()
				
				

#--------Private Functions-----------
func _ready() -> void:
	await get_tree().process_frame
	var faces: PackedVector3Array
	for m in get_node("PatchSegments").get_children():
		faces.append_array(m.get_node("Meshes/TexturedMesh").mesh.get_faces())
	get_node("CollisionMesh").shape.set_faces(faces)


func _on_mesh_changed(tex_mesh: TexturedMesh) -> void:
	get_node("CollisionMesh").shape.set_faces(tex_mesh.mesh.get_faces())
	
	
