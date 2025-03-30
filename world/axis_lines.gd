extends MeshInstance3D


const BIG_NUMBER = 0xFFF


func _ready() -> void:
	var lines := SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_LINES)
	# X
	lines.set_color(Color.RED)
	lines.add_vertex(Vector3(-BIG_NUMBER,0,0))
	lines.add_vertex(Vector3(BIG_NUMBER,0,0))
	# Y
	lines.set_color(Color.GREEN)
	lines.add_vertex(Vector3(0, -BIG_NUMBER,0))
	lines.add_vertex(Vector3(0, BIG_NUMBER,0))
	# Z
	lines.set_color(Color.DODGER_BLUE)
	lines.add_vertex(Vector3(0, 0, -BIG_NUMBER))
	lines.add_vertex(Vector3(0, 0, BIG_NUMBER))
	mesh = lines.commit()
	
