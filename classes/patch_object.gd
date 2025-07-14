extends StaticBody3D
class_name PatchObject
## Patch objects represent a bezier surface. It's a parent to all the data needed to make
## an interactive and renderable surface. This script however only holds data 
## that the patch object specifically needs - or to mediate communication between
## child nodes, like the tilemap database for control point neighbor detection.
## Everything else is a node as a child of this one, that includes Collision mesh,
## control points, segments, textured mesh, wireframe mesh, and control grid.


func highlight(value: bool) -> void:
	for segment: PatchSegment in get_node("PatchSegments").get_children():
		segment.selected = value
		segment.update()

func show_grid(value: bool) -> void:
	for segment: PatchSegment in get_node("PatchSegments").get_children():
		segment.show_grid(value)


	
func _ready() -> void:
	await get_tree().process_frame
	var faces: PackedVector3Array
	for m in get_node("PatchSegments").get_children():
		faces.append_array(m.get_node("Meshes/TexturedMesh").mesh.get_faces())
	get_node("CollisionMesh").shape.set_faces(faces)



	
func _on_mesh_changed(tex_mesh: TexturedMesh) -> void:
	get_node("CollisionMesh").shape.set_faces(tex_mesh.mesh.get_faces())
	
	
