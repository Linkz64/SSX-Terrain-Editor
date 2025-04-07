extends Control


const LOG_COLOR = Color.WHITE
const WARNING_COLOR = 0xffa800ff
const ERROR_COLOR = 0xff4435ff

var bounce_tween: Tween
var clicked_close: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var h_box: HBoxContainer = $WarningAlertBG/HBoxContainer
@onready var warning_alert_bg: ColorRect = $WarningAlertBG
@onready var message_label: Label = $WarningAlertBG/HBoxContainer/MessageLabel
@onready var free: Timer = $Free
@onready var fade_out: Timer = $FadeOut


func init(text: String, type: Enum.SideAlertType):
	message_label.text = text
	match type:
		Enum.SideAlertType.LOG:
			message_label.add_theme_color_override("font_color", LOG_COLOR)
		Enum.SideAlertType.WARNING:
			message_label.add_theme_color_override("font_color", Color.hex(WARNING_COLOR))
		Enum.SideAlertType.ERROR:
			message_label.add_theme_color_override("font_color", Color.hex(ERROR_COLOR))
			
			
func _ready():
	bounce_tween = create_tween()
	bounce_tween.tween_property(warning_alert_bg, "position", Vector2.ZERO, 0.9) \
			.set_trans(Tween.TRANS_BOUNCE) \
			.set_ease(Tween.EASE_OUT)
	animation_player.play("fade-in")
	
	
func _on_free_timeout() -> void:
	queue_free()


func _on_fade_out_timeout() -> void:
	animation_player.play("fade-out")


func _on_message_delete_pressed() -> void:
	if clicked_close:
		return
	clicked_close = true
	
	fade_out.stop()
	free.stop()
	free.wait_time = 0.5
	free.start()
	animation_player.play("fade-out")


func _on_message_copy_pressed() -> void:
	DisplayServer.clipboard_set(message_label.text)
