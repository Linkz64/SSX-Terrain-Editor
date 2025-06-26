extends Node3D
class_name PatchSegment
## Patch segments represent a single surface/patch from a Patch object.
## It keeps a list of 16 cells from the Patch object's tilemap, each of those is a Control point
## for rendering the meshes, and the collision shapes.


signal mesh_changed(segment: TexturedMesh)

# Must call update after changing any of these values
var surface_type: Enum.SurfaceType = Enum.SurfaceType.SNOW_MAIN
var texture_filename: String = "0001.png"
var showoff_only: bool = false
var uv_points: Dictionary = {
	"top-left": Vector2.ZERO,
	"top-right": Vector2(1, 0),
	"bottom-left": Vector2(0, 1),
	"bottom-right": Vector2(1, 1),
}
var lightmap_point: Rect2 = Rect2(0, 0, 0.0625, 0.0625)
var lightmap_id: int = 0
var selected: bool = false # Set for highlighting
var tilemap_cells: Array[Vector2i]

var _textured_mesh: TexturedMesh
var _wireframe_mesh: WireframeMesh
var _control_grid_mesh: ControlGridMesh
var _control_point_ref: Array[ControlPoint]


func show_grid():
	_control_grid_mesh.show()
	update()


func hide_grid():
	_control_grid_mesh.hide()
	

func update():
	_control_point_moved()


func _init(control_point_cells: Array[Vector2i]) -> void:
	tilemap_cells = control_point_cells


func _ready() -> void:
	_textured_mesh = TexturedMesh.new()
	_textured_mesh.name = "TexturedMesh"
	_wireframe_mesh = WireframeMesh.new()
	_wireframe_mesh.name = "WireframeMesh"
	_control_grid_mesh = ControlGridMesh.new()
	_control_grid_mesh.name = "ControlGridMesh"
	_control_grid_mesh.hide()
	var mesh_parent := Node3D.new()
	add_child(mesh_parent)
	mesh_parent.name = "Meshes"
	mesh_parent.add_child(_textured_mesh)
	mesh_parent.add_child(_wireframe_mesh)
	mesh_parent.add_child(_control_grid_mesh)
	
	# Get control point references for easy access
	for cell in tilemap_cells:
		var cp := _tilemap_get_cp_from_cell(cell)
		assert(cp)
		_control_point_ref.append(cp)
	update()


func _control_point_moved():
	_textured_mesh.update(_control_point_ref, texture_filename, uv_points.values(), selected)
	_wireframe_mesh.update(_control_point_ref)
	_control_grid_mesh.update(_control_point_ref)
	mesh_changed.emit(_textured_mesh) # Call at the end of the function


func _control_point_selection_changed(_select: bool):
	_control_grid_mesh.update(_control_point_ref)


func _tilemap_get_cp_from_cell(cell: Vector2i) -> ControlPoint:
	var control_points = get_parent().get_parent().get_node("ControlPoints").get_children()
	for cp in control_points:
		if cell == cp.tilemap_cell:
			return cp
	return null
