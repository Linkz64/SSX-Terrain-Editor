extends Node3D


@export var world: Node3D
@onready var cam_pivot: Node3D = $AxisCamPivot


func _process(_delta: float) -> void:
	cam_pivot.rotation = world.get_camera().rotation
