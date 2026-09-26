# player_stats.gd
# Autoload "PlayerStats": the player's health. Lives outside the player
# node so it survives scene changes.
extends Node

signal health_changed(health: int, max_health: int)
signal died

var max_health: int = 160
var health: int = max_health

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func is_alive() -> bool:
	return health > 0
