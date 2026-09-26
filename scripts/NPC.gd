extends CharacterBody2D

@export var npc_id: String
@export var npc_name: String



func _physics_process(delta: float) -> void:
	$AnimatedSprite2D.play('idle')

# Dialog vars
@export var dialog_resource: Dialog
@onready var dialog_manager: Node2D = $DialogManager
var current_state = "start"
var current_branch_index=0

# Quest Vars
@export var quests: Array[Quest] = []
var quest_manager: Node=null


func _ready():
	dialog_resource.load_from_json("res://Resource/Dialog/dialog_data.json")
	# init npc reference
	dialog_manager.npc = self
	#Get Quest Manager
	quest_manager = QuestManager
	print("NPC Ready.  Quests loaded: ", quests.size())

func start_dialog():
	var npc_dialogs = dialog_resource.get_npc_dialog(npc_id)
	if npc_dialogs.is_empty():
		return
	dialog_manager.show_dialog(self)
	
# Get current branch dialog
func get_current_dialog():
	var npc_dialogs = dialog_resource.get_npc_dialog(npc_id)
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
		if quest.quest_id == quest_id and not quest_manager.has_quest(quest_id):
			quest_manager.accept_quest(quest)
			return
		
	print ("Quest not found or started already")

# Returns quest_dialog
func get_quest_dialog() -> Dictionary:
	var active_quests = quest_manager.get_active_quests()
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_id == npc_id and objective.target_type == Objectives.Type.TALK_TO and not objective.is_completed:
				if current_state == "start":
					return {"text": objective.objective_dialog, "options": {}}
	return {"text":"", "options":{}}					
		
