# Quests.gd
# A quest definition (saved as a .tres, set up in the editor). When the
# player accepts a quest, QuestManager stores a copy made by
# create_instance(), and all progress is tracked on that copy -- the
# definition itself is never modified.

extends Resource

class_name Quest

enum State { NOT_STARTED, IN_PROGRESS, COMPLETED }

# --- Definition (set in the editor) ---
@export var quest_id: String
@export var quest_name: String
@export var quest_description: String
@export var unlock_id: String
@export var objectives: Array[Objectives] = []
@export var rewards: Array[Rewards] = []

# --- Progress (runtime only, not saved in the definition) ---
var state: State = State.NOT_STARTED

# Copy of this quest with its own objectives, for tracking progress
func create_instance() -> Quest:
	var copy: Quest = duplicate()
	var objective_copies: Array[Objectives] = []
	for objective in objectives:
		objective_copies.append(objective.duplicate())
	copy.objectives = objective_copies
	return copy

# Check if quest is complete
func is_completed() -> bool:
	for objective in objectives:
		if not objective.is_completed:
			return false
	return true

# Update objective progress (QuestManager decides when the quest completes)
func complete_objective(objective_id: String, quantity: int = 1):
	for objective in objectives:
		if objective.id == objective_id:
			if objective.target_type == Objectives.Type.COLLECTION:
				objective.collected_quantity += quantity
				if objective.collected_quantity >= objective.required_quantity:
					objective.is_completed = true
			elif objective.target_type == Objectives.Type.TALK_TO:
				objective.is_completed = true
			break
