# equipment.gd
# Autoload "Equipment": the gear the player is wearing and the Mysterians
# they have slotted. Equipped items stay in Inventory (the UI marks them as
# equipped) -- Equipment only records which ones are in use. If an equipped
# item leaves the inventory (e.g. used up by a quest), it is unequipped.
extends Node

signal equipment_changed
signal mysterians_enabled_changed(enabled: bool)

const MYSTERIAN_SLOT_COUNT = 7

# ItemData.Slot -> item_id
var equipped: Dictionary = {}

# The Mysterian system (and its UI) stays hidden until the player finds
# their first Mysterian.
var mysterians_enabled: bool = false
var unlocked_mysterian_slots: int = 1
# One entry per Mysterian slot: the item_id in it ("" when empty), and
# whether that Mysterian is fused.
var mysterian_slots: Array[String] = []
var fused_slots: Array[bool] = []

func _ready():
	mysterian_slots.resize(MYSTERIAN_SLOT_COUNT)
	mysterian_slots.fill("")
	fused_slots.resize(MYSTERIAN_SLOT_COUNT)
	fused_slots.fill(false)
	Inventory.item_changed.connect(_on_inventory_item_changed)

# --- Gear ---

# Wear a weapon/armor piece in its slot, replacing whatever was there.
# Returns false if it can't be worn or every copy the player has is in use.
func equip(item_id: String) -> bool:
	var item = ItemDB.get_item(item_id)
	if item == null or not item.is_equippable():
		return false
	if get_equipped(item.slot) == item_id:
		return true
	if not _has_spare(item_id):
		return false
	equipped[item.slot] = item_id
	equipment_changed.emit()
	return true

func unequip(slot: ItemData.Slot):
	if equipped.erase(slot):
		equipment_changed.emit()

# The item_id worn in a slot, or "" if it's empty
func get_equipped(slot: ItemData.Slot) -> String:
	return equipped.get(slot, "")

func is_equipped(item_id: String) -> bool:
	return _count_in_use(item_id) > 0

# --- Mysterians ---

func set_mysterians_enabled(enabled: bool):
	if mysterians_enabled == enabled:
		return
	mysterians_enabled = enabled
	mysterians_enabled_changed.emit(enabled)
	# Slotted Mysterians' bonuses only count while the system is enabled
	equipment_changed.emit()

func slot_mysterian(item_id: String, index: int) -> bool:
	if not mysterians_enabled or index < 0 or index >= unlocked_mysterian_slots:
		return false
	var item = ItemDB.get_item(item_id)
	if item == null or not item.is_mysterian():
		return false
	if mysterian_slots[index] == item_id:
		return true
	if not _has_spare(item_id):
		return false
	mysterian_slots[index] = item_id
	fused_slots[index] = false
	equipment_changed.emit()
	return true

func unslot_mysterian(index: int):
	if mysterian_slots[index] == "":
		return
	mysterian_slots[index] = ""
	fused_slots[index] = false
	equipment_changed.emit()

# Fusing has no gameplay effect yet -- it's only stored and shown in the UI
func set_fused(index: int, fused: bool):
	if mysterian_slots[index] == "":
		return
	fused_slots[index] = fused
	equipment_changed.emit()

# Whether this Mysterian is in a fused slot (for the inventory's FUSED badge)
func is_fused(item_id: String) -> bool:
	for i in MYSTERIAN_SLOT_COUNT:
		if mysterian_slots[i] == item_id and fused_slots[i]:
			return true
	return false

# First unlocked, empty Mysterian slot, or -1 if they're all full
func find_free_mysterian_slot() -> int:
	for i in unlocked_mysterian_slots:
		if mysterian_slots[i] == "":
			return i
	return -1

func is_mysterian_slot_locked(index: int) -> bool:
	return index >= unlocked_mysterian_slots

func unlock_mysterian_slot():
	if unlocked_mysterian_slots < MYSTERIAN_SLOT_COUNT:
		unlocked_mysterian_slots += 1
		equipment_changed.emit()

# --- Stats ---

# Items whose bonuses currently apply: worn gear plus slotted Mysterians
func get_active_items() -> Array[ItemData]:
	var ids: Array = equipped.values()
	if mysterians_enabled:
		ids.append_array(mysterian_slots)
	var result: Array[ItemData] = []
	for item_id in ids:
		if item_id != "" and ItemDB.has_item(item_id):
			result.append(ItemDB.get_item(item_id))
	return result

# Total of one ItemData bonus over active items, e.g. get_stat_bonus("attack_bonus")
func get_stat_bonus(stat: String) -> int:
	var total = 0
	for item in get_active_items():
		total += item.get(stat)
	return total

# --- Internals ---

# How many copies of an item are equipped or slotted
func _count_in_use(item_id: String) -> int:
	return equipped.values().count(item_id) + mysterian_slots.count(item_id)

func _has_spare(item_id: String) -> bool:
	return Inventory.get_item_count(item_id) > _count_in_use(item_id)

func _on_inventory_item_changed(item_id: String, quantity: int):
	if not ItemDB.has_item(item_id):
		return
	# Finding the first Mysterian reveals the Mysterian system
	if quantity > 0 and ItemDB.get_item(item_id).is_mysterian():
		set_mysterians_enabled(true)

	# Unequip copies the player no longer has
	var changed = false
	while _count_in_use(item_id) > quantity:
		_release_one(item_id)
		changed = true
	if changed:
		equipment_changed.emit()

# Free up one equipped/slotted copy of an item (gear first, then Mysterians)
func _release_one(item_id: String):
	for slot in equipped.keys():
		if equipped[slot] == item_id:
			equipped.erase(slot)
			return
	for i in range(MYSTERIAN_SLOT_COUNT - 1, -1, -1):
		if mysterian_slots[i] == item_id:
			mysterian_slots[i] = ""
			fused_slots[i] = false
			return
