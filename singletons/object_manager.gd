extends Node
"""
Keeps track of object states, Name management, object-group relationships.
and their request signals for communication.
"""

signal patch_object_creation_requested(init_type: PatchObject.InitType, object_to_copy: PatchObject)
func request_patch_object_creation(init_type: PatchObject.InitType = PatchObject.InitType.DEFAULT, \
		object_to_copy: PatchObject = null):
	patch_object_creation_requested.emit(init_type, object_to_copy)
