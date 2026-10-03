# debug_tools.gd
# Autoload "DebugTools": testing hotkeys for the equipment system until the
# inventory screen exists. Does nothing in release builds.
#   F1  give and equip the test gear set
#   F2  unequip all gear
#   F3  give the Sun Mysterian (reveals Mysterians) and slot it
#   F4  toggle mysterians_enabled
#   F5  print stats and equipment
#   F6  give the Rootlet Mysterian, unlock a Mysterian slot and slot it
extends Node

const TEST_GEAR = [
	"item_leather_helmet",
	"item_leather_breastplate",
	"item_leather_bracers",
	"item_leather_leggings",
	"item_leather_boots",
	"item_iron_sword",
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		set_process_unhandled_input(false)

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F1:
			for item_id in TEST_GEAR:
				if not Inventory.has_item(item_id):
					Inventory.add_item(item_id)
				Equipment.equip(item_id)
			print_stats()
		KEY_F2:
			for slot in Equipment.equipped.keys():
				Equipment.unequip(slot)
			print_stats()
		KEY_F3:
			if not Inventory.has_item("mysterian_sun"):
				Inventory.add_item("mysterian_sun")
			Equipment.slot_mysterian("mysterian_sun", 0)
			print_stats()
		KEY_F4:
			Equipment.set_mysterians_enabled(not Equipment.mysterians_enabled)
			print_stats()
		KEY_F5:
			print_stats()
		KEY_F6:
			if not Inventory.has_item("mysterian_rootlet"):
				Inventory.add_item("mysterian_rootlet")
			Equipment.unlock_mysterian_slot()
			var free_slot = Equipment.find_free_mysterian_slot()
			if free_slot != -1:
				Equipment.slot_mysterian("mysterian_rootlet", free_slot)
			print_stats()

func print_stats():
	print("--- Stats ---")
	print("Health:  %d / %d" % [PlayerStats.health, PlayerStats.max_health])
	print("Attack:  %d +%d" % [PlayerStats.base_attack, Equipment.get_stat_bonus("attack_bonus")])
	print("Defense: %d +%d" % [PlayerStats.base_defense, Equipment.get_stat_bonus("defense_bonus")])
	print("Speed:   %d +%d" % [PlayerStats.base_speed, Equipment.get_stat_bonus("speed_bonus")])
	print("Equipped: ", Equipment.equipped.values())
	print("Mysterians enabled: %s  slots: %s  fused: %s" % [Equipment.mysterians_enabled, Equipment.mysterian_slots, Equipment.fused_slots])
	print("Inventory: ", Inventory.items)
