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
		
