# teleporter.gd
# Area2D that sends the player to another level when they walk into it.
# Add a CollisionShape2D child for the trigger area, then set the target
# level and the spawn marker to arrive at in the Inspector.
class_name Teleporter
extends Area2D

@export_file("*.tscn") var target_scene: String
# Name of a Marker2D under the target level's Spawns node
@export var target_spawn: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneManager.change_level(target_scene, target_spawn)
