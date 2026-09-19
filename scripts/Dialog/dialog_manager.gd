### Dialog_manager.gd


extends Node2D

@onready var dialog_ui: Control = $DialogUI

var npc: Node = null

# show dialog with data
func show_dialog(npc, text = "", options = {}):
	if text != "":
		# Show empty box
		dialog_ui.show_dialog(npc.npc_name, text, options)
	else:
		# Show quest related dialogs
		var quest_dialog = npc.get_quest_dialog()
		if quest_dialog["text"] != "":
			dialog_ui.show_dialog(npc.npc_name, quest_dialog["text"], quest_dialog["options"])

		else:
			# show non-quest related dialogs
			var dialog = npc.get_current_dialog()
			if dialog == null:
				return
			dialog_ui.show_dialog(npc.npc_name, dialog["text"], dialog["options"])

# hiode dialog		
func hide_dialog():
	dialog_ui.hide_dialog()

# Dialog Statem Management
func handle_dialog_choice(option):
	#get current dialog branch
	var current_dialog = npc.get_current_dialog()
	if current_dialog == null:
		return
	# update state
	var next_state = current_dialog["options"].get(option, "start")
	npc.set_dialog_state(next_state)
	#handle state transition
	if next_state == "end":
		if npc.current_branch_index < npc.dialog_resource.get_npc_dialog(npc.npc_id).size() -1:
			npc.set_dialog_branch(npc.current_branch_index +1)
		hide_dialog()
	elif next_state == "exit":
		npc.set_dialog_state("start")
		hide_dialog()
	elif next_state == "give_quests":
		if npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"] == "npc_default":
			offer_remaining_quests()
		else:
			offer_quests(npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"])
			show_dialog(npc)
		
	else: 
		show_dialog(npc)
	
# AT branch, offer all currently available quests
func offer_quests(branch_id: String):
	for quest in npc.quests:
		if quest.unlock_id == branch_id and quest.state == "not_started":
			npc.offer_quest(quest.quest_id)
			
# At default branch, offer all previously unaccepted quests
func offer_remaining_quests():
	for quest in npc.quests:
		if quest.state == "not_started":
			npc.offer_quest(quest.quest_id)

	
	
		
