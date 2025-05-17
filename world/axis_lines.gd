extends MeshInstance3D



const BIG = 0xBBBBB

@export var main_camera: Camera3D


func _ready() -> void:
	var lines := SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_LINES)
	# X
	lines.set_color(Color.RED)
	lines.add_vertex(Vector3(-BIG,0,0))
	lines.add_vertex(Vector3(BIG,0,0))
	# Y
	lines.set_color(Color.GREEN)
	lines.add_vertex(Vector3(0, -BIG,0))
	lines.add_vertex(Vector3(0, BIG,0))
	# Z
	lines.set_color(Color.DODGER_BLUE)
	lines.add_vertex(Vector3(0, 0, -BIG))
	lines.add_vertex(Vector3(0, 0, BIG))
	mesh = lines.commit()

func _process(_delta: float) -> void:
	visible = main_camera.position != Vector3.ZERO
