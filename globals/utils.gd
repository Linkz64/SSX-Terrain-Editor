extends RefCounted
class_name Utils


static func ssx_to_godot_position(ssx_position: Vector3) -> Vector3:
	# Swapped Y and Z, then negated Z.
	return Vector3(ssx_position.x, ssx_position.z, -ssx_position.y)


static func godot_to_ssx_position(godot_position: Vector3) -> Vector3:
	# Swapped Y and Z, then negated Y.
	return Vector3(godot_position.x, -godot_position.y, godot_position.z)
	
