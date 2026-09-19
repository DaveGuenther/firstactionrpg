### DialogUI.gd
extends Control

@onready var panel = $CanvasLayer/Panel
@onready var dialog_speaker = $CanvasLayer/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/Panel/DialogBox/DialogOptions

func _ready():
	hide_dialog()
	

# show dialog box
func show_dialog(speaker, text, options):
	panel.visible = true
	dialog_speaker.text = speaker
	dialog_text.text = text
	
	
	# remove existing options
	for option in dialog_options.get_children():
		dialog_options.remove_child(option)
		
	# populate options
	for option in options.keys():
		var button = Button.new()
		button.text = option
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(_on_option_selected.bind(option))
		dialog_options.add_child(button)
		
# Handle Response Selection
func _on_option_selected(option):
	get_parent().handle_dialog_choice(option)
	
	
# hide dialog box
func hide_dialog():
	panel.visible = false
	global.player.can_move = true


func _on_close_button_pressed() -> void:
	hide_dialog()
