# level.gd
# Shared script for every level scene. Places the player at the spawn
# marker SceneManager asked for and applies this level's camera limits.
#
# Expected children:
#   player  - the player instance
#   Spawns  - Node2D holding Marker2D spawn points (e.g. "Start", "FromWorld")
extends Node2D

# Spawn used when the level is loaded directly (e.g. at game start)
@export var default_spawn: String = "Start"

@export_group("Camera Limits")
@export var camera_limit_left: int = -10000000
@export var camera_limit_top: int = -10000000
@export var camera_limit_right: int = 10000000
@export var camera_limit_bottom: int = 10000000

@onready var player = $player

func _ready() -> void:
	var spawn = SceneManager.spawn_name if SceneManager.spawn_name != "" else default_spawn
	SceneManager.spawn_name = ""
	var marker = get_node_or_null("Spawns/" + spawn)
	if marker:
		player.global_position = marker.global_position
	elif spawn != "":
		push_warning("Level '%s' has no spawn marker 'Spawns/%s'" % [name, spawn])

	player.set_camera_limits(camera_limit_left, camera_limit_top, camera_limit_right, camera_limit_bottom)
	player.get_node("MainCamera").reset_smoothing()
