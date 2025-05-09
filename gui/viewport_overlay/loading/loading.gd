extends Control


@onready var loading_icon: TextureRect = $Icon
@onready var label: Label = $Label

var _count: float = 0


func _process(delta: float) -> void:
	if not visible:
		return
	
	loading_icon.rotation += 1 * delta
	_count += delta
	
	if _count > 1:
		label.text = "Loading."
	if _count > 2:
		label.text = "Loading.."
	if _count > 3:
		label.text = "Loading..."
		_count = 0
		
		
