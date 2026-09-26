# quest.gd
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
# If true, each objective only counts once all objectives above it are done
# (e.g. collect the carrot, THEN talk to Bobby Joe)
@export var objectives_in_order: bool = false
@export var objectives: Array[Objective] = []
@export var rewards: Array[Reward] = []

# --- Progress (runtime only, not saved in the definition) ---
var state: State = State.NOT_STARTED

# Copy of this quest with its own objectives, for tracking progress
func create_instance() -> Quest:
	var copy: Quest = duplicate()
	var objective_copies: Array[Objective] = []
	for objective in objectives:
		objective_copies.append(objective.duplicate())
	copy.objectives = objective_copies
	return copy

# Whether an objective can progress right now. Always true unless
# objectives_in_order is set, in which case every earlier one must be done.
func is_objective_active(objective: Objective) -> bool:
	if not objectives_in_order:
		return true
	for other in objectives:
		if other == objective:
			return true
		if not other.is_completed:
			return false
	return false

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
			if objective.target_type == Objective.Type.COLLECTION:
				objective.collected_quantity += quantity
				if objective.collected_quantity >= objective.required_quantity:
					objective.is_completed = true
			elif objective.target_type == Objective.Type.TALK_TO:
				objective.is_completed = true
			break
