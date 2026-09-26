extends Node

var player: Node = null


var player_current_attack = false

# Tracks world items (mushrooms, etc.) already picked up, keyed by a
# stable per-instance key, so they stay gone when a scene is reloaded.
var collected_items: Dictionary = {}

func mark_item_collected(key: String):
	collected_items[key] = true

func is_item_collected(key: String) -> bool:
	return collected_items.has(key)
