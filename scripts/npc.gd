extends CharacterBody2D

@export var npc_id: String
@export var npc_name: String



func _physics_process(delta: float) -> void:
	$AnimatedSprite2D.play('idle')

# Dialog vars (dialog text lives in the DialogManager autoload)
var current_state = "start"
var current_branch_index=0

# Quest definitions this NPC can give
@export var quests: Array[Quest] = []


func _ready():
	print("NPC Ready.  Quests loaded: ", quests.size())

func start_dialog():
	DialogManager.start_dialog(self)
	
# Get current branch dialog
func get_current_dialog():
	var npc_dialogs = DialogManager.get_npc_dialog(npc_id)
	if current_branch_index<npc_dialogs.size():
		for dialog in npc_dialogs[current_branch_index]["dialogs"]:
			if dialog["state"] == current_state:
				return dialog
	return null
			
# Update dialog branch			
func set_dialog_branch(branch_index):
	current_branch_index = branch_index
	current_state = "start"

# Update dialog state
func set_dialog_state(state):
	current_state=state

# Offer Quest at required branch
func offer_quest(quest_id: String):
	print("attemping to offer quest:", quest_id)
	
	for quest in quests:
		if quest.quest_id == quest_id and not QuestManager.has_quest(quest_id):
			QuestManager.accept_quest(quest)
			return
		
	print ("Quest not found or started already")

# Returns quest_dialog
func get_quest_dialog() -> Dictionary:
	var active_quests = QuestManager.get_active_quests()
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_id == npc_id and objective.target_type == Objective.Type.TALK_TO and not objective.is_completed and quest.is_objective_active(objective):
				if current_state == "start":
					return {"text": objective.objective_dialog, "options": {}}
	return {"text":"", "options":{}}					
		
