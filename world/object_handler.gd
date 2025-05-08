extends Node

"""
Spawn, delete, and modify objects on the 3D world.
"""


# Distance from the camera to spawn an object
const DISTANCE_FROM_CAMERA = 10

@export var camera: Camera3D


func _ready() -> void:
	ObjectManager.patch_object_creation_requested.connect(_on_create_object_request)


func _on_create_object_request(init_type: PatchObject.InitType, object_to_copy: PatchObject):
	var inst := PatchObject.new(init_type, object_to_copy)
	add_child(inst)
	inst.position = camera.position + camera.basis.z * -DISTANCE_FROM_CAMERA
