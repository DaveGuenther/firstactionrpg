# scene_manager.gd
# Autoload "SceneManager": moves the player between levels. The new level
# (level.gd) reads spawn_name to decide where to place the player.
extends Node

# Name of the Marker2D (under the level's Spawns node) to place the player at
var spawn_name: String = ""
var _changing: bool = false

func change_level(scene_path: String, spawn: String) -> void:
	if _changing:
		return
	_changing = true
	spawn_name = spawn
	# Deferred: this is usually called from a physics signal (body_entered),
	# where the current level can't be freed yet
	_do_change.call_deferred(scene_path)

func _do_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	_changing = false
