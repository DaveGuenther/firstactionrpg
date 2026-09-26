# inventory.gd
# Autoload "Inventory": the player's items and coins. Lives outside the
# player node so it survives scene changes. Always modify it through the
# functions below so the signals fire.
extends Node

signal item_changed(item_id: String, quantity: int)
signal coins_changed(coins: int)

# item_id -> quantity (e.g. {"item_mushroom": 3})
var items: Dictionary = {}
var coins: int = 0

func add_item(item_id: String, quantity: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + quantity
	item_changed.emit(item_id, items[item_id])

# Returns false (and removes nothing) if there aren't enough.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if get_item_count(item_id) < quantity:
		return false
	items[item_id] -= quantity
	if items[item_id] == 0:
		items.erase(item_id)
	item_changed.emit(item_id, get_item_count(item_id))
	return true

func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

# Returns false (and spends nothing) if there aren't enough.
func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true
