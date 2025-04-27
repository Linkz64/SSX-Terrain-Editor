extends Node


signal patch_object_creation_requested(_object_to_copy: PatchObject)


## If an object is passed as an arugment, then it can be used to duplicate it.
## If not then create a default object with one segment and default properties.
func create_patch_object(object_to_copy: PatchObject = null):
	patch_object_creation_requested.emit(object_to_copy)
	
