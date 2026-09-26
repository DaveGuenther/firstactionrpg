# Objectives.gd

extends Resource

class_name Objectives

@export var id: String
@export var description: String

# objective type
@export var target_id: String
@export var target_type: String

# Talk to objective
@export var objective_dialog: String = ""

# Collection Objective
@export var required_quantity: int = 0
@export var collected_quantity: int = 0

# objective state
@export var is_completed: bool = false

# Text shown in the quest log and HUD tracker, e.g. "Collect 10 mushrooms (4/10)"
func get_display_text() -> String:
	if target_type == "collection":
		return description + " (" + str(collected_quantity) + "/" + str(required_quantity) + ")"
	return description
