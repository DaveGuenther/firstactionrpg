### quest_item.gd
@tool
extends Area2D
@onready var sprite_2d = $Sprite2D

# Vars
@export var item_id: String = ""
@export var item_quantity: int = 1
@export var item_icon: Texture2D:
	set(value):
		item_icon = value
		if sprite_2d:
			sprite_2d.texture = value

func _ready():
	# Show texture in game
	if sprite_2d:
		sprite_2d.texture = item_icon

	# If this exact item was already picked up in a previous visit
	# to this scene, don't let it respawn.
	if not Engine.is_editor_hint() and WorldState.is_item_collected(get_instance_key()):
		queue_free()

# Key WorldState uses to remember this specific item was picked up
func get_instance_key() -> String:
	return WorldState.get_node_key(self)
