extends Node


const DISTANCE_FROM_CAMERA = 10

@export var camera: Camera3D


func _ready() -> void:
	ObjectManager.patch_object_creation_requested.connect(_on_create_object_request)


func _on_create_object_request(_object_to_copy: PatchObject):
	var inst := PatchObject.new()
	add_child(inst)
	inst.position = camera.position + camera.basis.z * -DISTANCE_FROM_CAMERA
	if _object_to_copy:
		inst.create_copy()
	else:	
		inst.create_default()
