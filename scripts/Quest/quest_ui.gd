### Quest_ui.gd
extends Control

@onready var panel = $CanvasLayer/Panel
@onready var quest_list = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description: Label = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards
@onready var track_button: Button = $CanvasLayer/Panel/Contents/Details/QuestDetails/TrackButton

# Quest whose details are shown on the right. Viewing a quest does not
# track it -- the tracked quest lives in global.selected_quest.
var selected_quest: Quest = null
var quest_manager

func _ready():
	panel.visible = false
	clear_quest_details()

	# Quest Manager/UI Connection
	quest_manager = get_parent()
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objectives_updated)

func show_hide_log():
	panel.visible = !panel.visible
	refresh()

# Rebuild the quest list and the details of the viewed quest
func refresh():
	update_quest_list()
	if selected_quest:
		_on_quest_selected(selected_quest)
	else:
		clear_quest_details()

# Populate quest list with every quest the player has
func update_quest_list():
	# Remove all items
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()

	var quests = quest_manager.get_all_quests()
	# Forget the viewed quest if it is no longer in the log
	if selected_quest and not selected_quest in quests:
		selected_quest = null

	# Populate with new items
	for quest in quests:
		var button = Button.new()
		button.add_theme_font_size_override("font_size", 20)
		button.text = get_quest_label(quest)
		button.pressed.connect(_on_quest_selected.bind(quest))
		quest_list.add_child(button)

func get_quest_label(quest: Quest) -> String:
	if quest == global.selected_quest:
		return "(Tracked) " + quest.quest_name
	if quest.state == "completed":
		return quest.quest_name + " (Completed)"
	return quest.quest_name

# Show quest details (does not track the quest)
func _on_quest_selected(quest: Quest):
	selected_quest = quest
	# Populate details
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description

	# Populate objectives
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		child.queue_free()

	for objective in quest.objectives:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 20)
		if objective.target_type == "collection":
			label.text = objective.description + "("+str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else:
			label.text = objective.description

		if objective.is_completed:
			label.add_theme_color_override("font_color", Color (0,1,0))
		else:
			label.add_theme_color_override("font_color", Color (1,0,0))

		quest_objectives.add_child(label)

	# Populate rewards
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
		child.queue_free()

	for reward in quest.rewards:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color (0,0.84,0))
		label.text = "Rewards:" + reward.reward_type.capitalize() + ": " + str(reward.reward_amount)
		quest_rewards.add_child(label)

	# Track button: only for in-progress quests that aren't already tracked
	track_button.visible = true
	track_button.disabled = quest == global.selected_quest or quest.state != "in_progress"

# Trigger to clear quest details
func clear_quest_details():
	quest_title.text = ""
	quest_description.text = ""
	track_button.visible = false

	# Clear objectives
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		child.queue_free()

	# Clear rewards
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
		child.queue_free()

# Track the viewed quest in the HUD quest tracker
func _on_track_button_pressed():
	if selected_quest == null:
		return
	global.selected_quest = selected_quest
	global.quest_tracker_hidden = false
	if global.player:
		global.player.update_quest_tracker(selected_quest)
	refresh()

# Trigger to update quest list
func _on_quest_updated(_quest_id: String):
	refresh()

# Trigger to update quest details
func _on_objectives_updated(_quest_id: String, _objectives_id: String):
	refresh()

func _on_close_button_pressed():
	show_hide_log()
