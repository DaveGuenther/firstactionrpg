# player_stats.gd
# Autoload "PlayerStats": the player's health and combat stats. Lives
# outside the player node so it survives scene changes. Each stat is a base
# value plus bonuses from Equipment (worn gear and slotted Mysterians).
extends Node

signal health_changed(health: int, max_health: int)
signal stats_changed
signal died

var base_max_health: int = 160
var base_attack: int = 18
var base_defense: int = 17
var base_speed: int = 10 # 10 = normal movement speed

var max_health: int = base_max_health
var health: int = max_health

func _ready():
	Equipment.equipment_changed.connect(_on_equipment_changed)

# Damage dealt by the player's attacks
func get_attack() -> int:
	return base_attack + Equipment.get_stat_bonus("attack_bonus")

func get_defense() -> int:
	return base_defense + Equipment.get_stat_bonus("defense_bonus")

func get_speed() -> int:
	return base_speed + Equipment.get_stat_bonus("speed_bonus")

# Movement speed relative to normal (base_speed), e.g. 1.2 with +2 speed
func get_speed_multiplier() -> float:
	return float(get_speed()) / base_speed

# A hit from an enemy: defense reduces the damage (17 defense takes ~85%,
# 100 defense takes half), always at least 1.
func take_hit(raw_damage: int) -> void:
	var damage = roundi(raw_damage * 100.0 / (100 + get_defense()))
	take_damage(max(damage, 1))

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

func _on_equipment_changed():
	# Gear can raise max health; current health is kept (but not above max)
	max_health = base_max_health + Equipment.get_stat_bonus("health_bonus")
	health = min(health, max_health)
	health_changed.emit(health, max_health)
	stats_changed.emit()
