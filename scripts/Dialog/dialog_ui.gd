### DialogUI.gd
extends Control

@onready var panel = $CanvasLayer/Panel
@onready var dialog_speaker = $CanvasLayer/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/Panel/DialogBox/DialogOptions

func _ready():
	hide_dialog()
	

# show dialog box
func show_dialog():
	panel.visible = true
	
# hide dialog box
func hide_dialog():
	panel.visible = false
	global.player.can_move = true


func _on_close_button_pressed() -> void:
	pass # Replace with function body.
