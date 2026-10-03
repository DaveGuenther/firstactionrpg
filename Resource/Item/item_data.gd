# item_data.gd
# An item definition (saved as a .tres in Resource/Item/Data/, set up in
# the editor). Inventory only stores item ids and quantities; look up what
# an item is (name, icon, stats) with ItemDB.get_item(id).

extends Resource

class_name ItemData

# Which inventory tab the item is listed under
enum Category { ITEM, WEAPON, ARMOR, MYSTERIAN }
# Where a weapon or armor piece is worn. Mysterians use the separate
# Mysterian slots instead (see Equipment).
enum Slot { NONE, HELMET, BREASTPLATE, BRACERS, LEGGINGS, SHOES, WEAPON }

@export var id: String = "" # must match the item_id used in Inventory
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.ITEM
@export var slot: Slot = Slot.NONE

# Added to the player's stats while equipped (or slotted, for Mysterians)
@export_group("Stat Bonuses")
@export var health_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0

func is_equippable() -> bool:
	return slot != Slot.NONE

func is_mysterian() -> bool:
	return category == Category.MYSTERIAN
