# objective.gd

extends Resource

class_name Objective

enum Type { TALK_TO, COLLECTION }

# --- Definition (set in the editor) ---
@export var id: String
@export var description: String

# objective type
@export var target_id: String
@export var target_type: Type = Type.TALK_TO

# Talk to objective
@export var objective_dialog: String = ""

# Collection Objective
@export var required_quantity: int = 0

# --- Progress (runtime only, not saved in the definition) ---
var collected_quantity: int = 0
var is_completed: bool = false

# Text shown in the quest log and HUD tracker, e.g. "Collect 10 mushrooms (4/10)"
func get_display_text() -> String:
	if target_type == Type.COLLECTION:
		return description + " (" + str(collected_quantity) + "/" + str(required_quantity) + ")"
	return description
