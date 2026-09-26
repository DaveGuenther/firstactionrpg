# quest_manager
# Autoload "QuestManager": owns the player's quests, the rules for
# progressing and completing them, and which quest is tracked in the HUD.
# Other nodes report what happened (e.g. check_quest_objectives("npc_2",
# Objective.Type.TALK_TO)) and listen to the signals below.
#
# NPCs hold quest definitions (.tres). Accepting one stores a copy here
# (Quest.create_instance), and all progress lives on that copy.

extends Node2D

@onready var quest_ui = $QuestUI

# Signals
signal quest_updated(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String)
signal quest_list_updated()
signal tracked_quest_changed(quest: Quest) # quest is null when nothing is tracked

var quests = {} # quest_id -> accepted Quest instance
var tracked_quest: Quest = null

func _ready():
	Inventory.item_changed.connect(_on_inventory_changed)

# Accept a quest from its definition. Does nothing if already accepted.
func accept_quest(definition: Quest):
	if has_quest(definition.quest_id):
		return
	var quest = definition.create_instance()
	quest.state = Quest.State.IN_PROGRESS
	quests[quest.quest_id] = quest
	quest_updated.emit(quest.quest_id)
	# Count items the player was already holding
	update_collection_objectives()

func remove_quest(quest_id: String):
	quests.erase(quest_id)
	quest_list_updated.emit()


func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id, null)

# Whether the player has accepted this quest (in progress or completed)
func has_quest(quest_id: String) -> bool:
	return quests.has(quest_id)


func update_quest(quest_id: String, state: Quest.State):
	var quest = get_quest(quest_id)
	if quest:
		quest.state = state
		quest_updated.emit(quest_id)

# All quests the player has accepted, including completed ones
func get_all_quests() -> Array:
	return quests.values()


func get_active_quests() -> Array:
	var active_quests = []
	for quest in quests.values():
		if quest.state == Quest.State.IN_PROGRESS:
			active_quests.append(quest)
	return active_quests


func complete_objective(quest_id: String, objective_id: String, quantity: int = 1):
	var quest = get_quest(quest_id)
	if quest:
		quest.complete_objective(objective_id, quantity)
		objective_updated.emit(quest_id, objective_id)

# Show a quest (or null for none) in the HUD quest tracker
func set_tracked_quest(quest: Quest):
	tracked_quest = quest
	tracked_quest_changed.emit(quest)

# Progress matching (non-collection) objectives on every in-progress quest,
# e.g. check_quest_objectives("npc_2", Objective.Type.TALK_TO)
func check_quest_objectives(target_id: String, target_type: Objective.Type, quantity: int = 1):
	for quest in get_active_quests():
		for objective in quest.objectives:
			if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed and quest.is_objective_active(objective):
				print("Completing objective for quest: ", quest.quest_name)
				complete_objective(quest.quest_id, objective.id, quantity)
				if quest.is_completed():
					complete_quest(quest)
				else:
					# In ordered quests this may unlock a collection objective
					# for items the player is already holding
					update_collection_objectives()
				break

# Collection objectives mirror the inventory: progress is however many of
# the item the player is holding, so items picked up before the quest was
# accepted count too. Runs on every in-progress quest, tracked or not.
# In ordered quests the count still shows for a locked objective, but it
# only completes once the objectives before it are done.
func update_collection_objectives():
	for quest in get_active_quests():
		# An earlier quest in this loop may have completed and used up items
		if quest.state != Quest.State.IN_PROGRESS:
			continue
		var changed = false
		for objective in quest.objectives:
			if objective.target_type != Objective.Type.COLLECTION:
				continue
			var held = min(Inventory.get_item_count(objective.target_id), objective.required_quantity)
			var done = held >= objective.required_quantity and quest.is_objective_active(objective)
			if held != objective.collected_quantity or done != objective.is_completed:
				objective.collected_quantity = held
				objective.is_completed = done
				changed = true
		if changed:
			objective_updated.emit(quest.quest_id, "")
			if quest.is_completed():
				complete_quest(quest)

func _on_inventory_changed(_item_id: String, _quantity: int):
	update_collection_objectives()

# Give rewards, stop tracking, and use up the collected items
func complete_quest(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == Reward.Type.COINS:
			Inventory.add_coins(reward.reward_amount)
	# Stop tracking the finished quest (it stays in the quest log)
	if quest == tracked_quest:
		set_tracked_quest(null)
	# Mark completed before using up items, so the inventory change
	# doesn't re-open this quest's collection objectives
	update_quest(quest.quest_id, Quest.State.COMPLETED)
	for objective in quest.objectives:
		if objective.target_type == Objective.Type.COLLECTION:
			Inventory.remove_item(objective.target_id, objective.required_quantity)

func show_hide_log():
	quest_ui.show_hide_log()
