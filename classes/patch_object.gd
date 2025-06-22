extends StaticBody3D
class_name PatchObject
## Patch objects represent a bezier surface. It's a parent to all the data needed to make
## an interactive and renderable surface. This script however only holds data 
## that the patch object specifically needs - or to mediate communication between
## child nodes, like the tilemap database for control point neighbor detection.
## Everything else is a node as a child of this one, that includes Collision mesh,
## control points, segments, textured mesh, wireframe mesh, and control grid.


var _tilemap: Dictionary[ControlPoint, Vector2i]


func tilemap_get_cell_from_control_point(cp: ControlPoint) -> Vector2i:
	var cell = _tilemap.get(cp)
	assert(cell)
	return cell


func tilemap_get_control_point_from_cell(cell: Vector2i) -> ControlPoint:
	var cp = _tilemap.find_key(cell)
	assert(cp)
	return cp
	

func tilemap_set_control_point_at_cell(cp: ControlPoint, cell: Vector2i) -> void:
	if cp in _tilemap.keys():
		if _tilemap[cp] == cell:
			return # Its ok if the cp is on the same cell as the argument
		else:
			assert(false, "Cell already in use")
	assert(cell not in _tilemap.values(), "Cell already in use")
	_tilemap[cp] = cell

	
func _on_mesh_changed(tex_mesh: TexturedMesh) -> void:
	get_node("CollisionMesh").shape.set_faces(tex_mesh.mesh.get_faces())
	
	
