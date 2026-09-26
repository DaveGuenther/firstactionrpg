# world_state.gd
# Autoload "WorldState": what has changed in the game world, so levels
# look the same when the player comes back to them.
extends Node

# World items (mushrooms, etc.) already picked up, and enemies already
# defeated, keyed by get_node_key(), so they stay gone when a level reloads.
var collected_items: Dictionary = {}
var defeated_enemies: Dictionary = {}

# Stable per-instance identifier: which level file + which node in it.
# Lets us remember this specific mushroom/slime, without confusing it with
# other instances of the same scene. Only stable for nodes placed in the
# level in the editor (renaming or moving the node changes its key).
func get_node_key(node: Node) -> String:
	return node.get_tree().current_scene.scene_file_path + "::" + str(node.get_path())

func mark_item_collected(key: String):
	collected_items[key] = true

func is_item_collected(key: String) -> bool:
	return collected_items.has(key)

func mark_enemy_defeated(key: String):
	defeated_enemies[key] = true

func is_enemy_defeated(key: String) -> bool:
	return defeated_enemies.has(key)
