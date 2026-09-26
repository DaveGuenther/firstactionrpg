# hud.gd
# On-screen HUD: coin counter and quest tracker. Only listens to the
# Inventory and QuestManager autoloads, so it doesn't depend on the player.
extends CanvasLayer

# Whether the player closed the quest tracker with its X button. Static so
# it survives scene changes, which recreate the HUD along with the player.
static var tracker_hidden: bool = false

@onready var coins_label: Label = %Amount
@onready var quest_tracker: ColorRect = %QuestTracker
@onready var title: Label = %Title
@onready var objectives: VBoxContainer = %Objectives

func _ready():
	Inventory.coins_changed.connect(_on_coins_changed)
	QuestManager.tracked_quest_changed.connect(_on_tracked_quest_changed)
	QuestManager.quest_updated.connect(_on_quest_changed)
	QuestManager.objective_updated.connect(_on_quest_changed.unbind(1))
	_on_coins_changed(Inventory.coins)
	update_quest_tracker()

func _process(_delta):
	# Bring back a manually-closed quest tracker
	if Input.is_action_just_pressed("quest_tracker_toggle"):
		tracker_hidden = false
		update_quest_tracker()

func _on_coins_changed(coins: int):
	coins_label.text = str(coins)

func _on_tracked_quest_changed(quest: Quest):
	# Tracking a new quest re-opens a manually-closed tracker
	if quest:
		tracker_hidden = false
	update_quest_tracker()

func _on_quest_changed(quest_id: String):
	var quest = QuestManager.tracked_quest
	if quest and quest.quest_id == quest_id:
		update_quest_tracker()

# Show the tracked quest's objectives, or hide the tracker if none
func update_quest_tracker():
	var quest = QuestManager.tracked_quest
	if quest == null:
		quest_tracker.visible = false
		return
	quest_tracker.visible = not tracker_hidden
	title.text = quest.quest_name

	for child in objectives.get_children():
		child.queue_free()

	for objective in quest.objectives:
		var label = Label.new()
		label.text = objective.get_display_text()

		if objective.is_completed:
			label.add_theme_color_override("font_color", Color(0,1,0))
		else:
			label.add_theme_color_override("font_color", Color(1,0,0))

		objectives.add_child(label)

func _on_close_button_pressed():
	tracker_hidden = true
	quest_tracker.visible = false
