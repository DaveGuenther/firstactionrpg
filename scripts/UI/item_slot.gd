# item_slot.gd
# One clickable square that shows an item. Used for the equipment slots,
# the Mysterian slots and the inventory grid. Items that don't have an
# icon yet show their name instead.
extends Button

class_name ItemSlot

# The item shown, or null for an empty slot
var item: ItemData = null

@onready var icon_rect: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var badge: Label = $Badge
@onready var quantity_label: Label = $Quantity
@onready var lock_icon: TextureRect = $Lock

# Show an item (null to empty the slot) and how many the player has
func set_item(new_item: ItemData, quantity: int = 1):
	item = new_item
	icon_rect.texture = item.icon if item else null
	name_label.text = item.display_name if item and item.icon == null else ""
	quantity_label.text = "x%d" % quantity if item and quantity > 1 else ""

# Small label in the top-right corner, e.g. "E" or "FUSED" ("" hides it)
func set_badge(text: String):
	badge.text = text
	badge.visible = text != ""

func set_locked(locked: bool):
	disabled = locked
	lock_icon.visible = locked
