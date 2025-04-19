extends Control


const LOG_COLOR = Color.WHITE
const WARNING_COLOR = 0xffa800ff
const ERROR_COLOR = 0xff4435ff
const MESSAGE_BG_PADDING = 10
const STARTING_OFFSET = 40


var _move_left_tween: Tween
var _move_up_tween: Tween
var _clicked_close: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var message: Label = $Hbox/Message
@onready var duration: Timer = $Duration
@onready var label_bg: ColorRect = $Hbox/Message/LabelBG


func init(text: String, type: Enum.SideAlertType):
	message.text = text
	label_bg.size.x += MESSAGE_BG_PADDING
	match type:
		Enum.SideAlertType.LOG:
			message.add_theme_color_override("font_color", LOG_COLOR)
		Enum.SideAlertType.WARNING:
			message.add_theme_color_override("font_color", Color.hex(WARNING_COLOR))
		Enum.SideAlertType.ERROR:
			message.add_theme_color_override("font_color", Color.hex(ERROR_COLOR))
	

func move_up():
	_move_up_tween = create_tween()
	_move_up_tween.tween_property (self, "position:y", self.position.y - 35, 0.9) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)


func _ready():
	self.position.x = STARTING_OFFSET
	_move_left_tween = create_tween()
	_move_left_tween.tween_property(self, "position:x", 0, 0.9) \
			.set_trans(Tween.TRANS_BOUNCE) \
			.set_ease(Tween.EASE_OUT)
	animation_player.play("fade-in")
	

func _on_message_delete_pressed() -> void:
	if _clicked_close:
		return
	_clicked_close = true
	duration.stop()
	animation_player.play("fade-out")


func _on_message_copy_pressed() -> void:
	DisplayServer.clipboard_set(message.text)


func _on_duration_timeout() -> void:
	animation_player.play("fade-out")
