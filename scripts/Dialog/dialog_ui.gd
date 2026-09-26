### DialogUI.gd
extends Control

@onready var panel = $CanvasLayer/Panel
@onready var dialog_speaker = $CanvasLayer/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/Panel/DialogBox/DialogOptions

func _ready():
	hide_dialog()


# show dialog box with speaker, text and one button per option
func show_dialog(speaker, text, options):
	panel.visible = true
	dialog_speaker.text = speaker
	dialog_text.text = text

	# Remove old option buttons
	for child in dialog_options.get_children():
		dialog_options.remove_child(child)
		child.queue_free()

	# Populate with new option buttons
	for option in options.keys():
		var button = Button.new()
		button.add_theme_font_size_override("font_size", 20)
		button.text = option
		button.pressed.connect(_on_option_selected.bind(option))
		dialog_options.add_child(button)

# hide dialog box (DialogManager.hide_dialog also emits dialog_ended)
func hide_dialog():
	panel.visible = false

# Pass chosen option to the DialogManager
func _on_option_selected(option):
	get_parent().handle_dialog_choice(option)

func _on_close_button_pressed() -> void:
	get_parent().hide_dialog()
