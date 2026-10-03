# inventory_ui.gd
# Autoload "InventoryUI": the inventory and character equipment screen
# (open/close with I, close with Esc). Shows worn gear, stats, Mysterian
# slots and the inventory grid. It only displays Inventory, Equipment and
# PlayerStats and asks them to make changes -- the rules live there.
#
# Clicking an item in the grid equips/unequips it (or slots/unslots a
# Mysterian). Clicking a worn item or slotted Mysterian takes it off.
extends CanvasLayer

const ITEM_SLOT = preload("res://scenes/UI/item_slot.tscn")
const BONUS_COLOR = "#1f4fa3"
# Value that fills a stat bar completely
const STAT_BAR_MAX = { "attack": 50, "defense": 50, "speed": 20 }
# Player preview: front_idle frames from player.png (48x48, first row).
# The AtlasTexture's region in the scene crops the first frame.
const PREVIEW_FRAME_COUNT = 6
const PREVIEW_FPS = 5.0
const PREVIEW_FRAME_SIZE = 48

@onready var gear_slots: Dictionary = {
	ItemData.Slot.HELMET: %HelmetSlot,
	ItemData.Slot.BREASTPLATE: %BreastplateSlot,
	ItemData.Slot.BRACERS: %BracersSlot,
	ItemData.Slot.LEGGINGS: %LeggingsSlot,
	ItemData.Slot.SHOES: %ShoesSlot,
	ItemData.Slot.WEAPON: %WeaponSlot,
}
@onready var tabs: Dictionary = {
	%ItemsTab: ItemData.Category.ITEM,
	%WeaponsTab: ItemData.Category.WEAPON,
	%ArmorTab: ItemData.Category.ARMOR,
	%MysteriansTab: ItemData.Category.MYSTERIAN,
}
@onready var item_grid: GridContainer = %ItemGrid
@onready var details: RichTextLabel = %Details
@onready var preview_texture: AtlasTexture = %PlayerPreview.texture

# One row per Mysterian slot: the ItemSlot and its Fused toggle
var mysterian_slots: Array[ItemSlot] = []
var fused_buttons: Array[CheckButton] = []
var current_category: ItemData.Category = ItemData.Category.ITEM
var _preview_time: float = 0.0
var _preview_x: float

func _ready():
	_preview_x = preview_texture.region.position.x

	for tab in tabs:
		tab.pressed.connect(_on_tab_pressed.bind(tabs[tab]))

	for slot_type in gear_slots:
		var slot: ItemSlot = gear_slots[slot_type]
		slot.pressed.connect(Equipment.unequip.bind(slot_type))
		slot.mouse_entered.connect(func(): _show_details(slot.item))

	for i in %MysterianRows.get_child_count():
		var row = %MysterianRows.get_child(i)
		var slot: ItemSlot = row.get_node("Slot")
		var fused: CheckButton = row.get_node("Fused")
		mysterian_slots.append(slot)
		fused_buttons.append(fused)
		slot.pressed.connect(Equipment.unslot_mysterian.bind(i))
		slot.mouse_entered.connect(func(): _show_details(slot.item))
		fused.toggled.connect(func(on): Equipment.set_fused(i, on))

	%CloseButton.pressed.connect(MenuManager.close_menu)

	Inventory.item_changed.connect(_on_data_changed.unbind(2))
	Equipment.equipment_changed.connect(_on_data_changed)
	Equipment.mysterians_enabled_changed.connect(_on_data_changed.unbind(1))
	PlayerStats.stats_changed.connect(_on_data_changed)
	PlayerStats.health_changed.connect(_on_data_changed.unbind(2))

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		MenuManager.toggle_menu(self)
		get_viewport().set_input_as_handled()

# Called by MenuManager -- open/close with MenuManager.toggle_menu(InventoryUI)
func open_menu():
	visible = true
	details.text = ""
	refresh()

func close_menu():
	visible = false

func _process(delta):
	if not visible:
		return
	# Animate the player picture through the idle frames
	_preview_time += delta
	var frame = int(_preview_time * PREVIEW_FPS) % PREVIEW_FRAME_COUNT
	preview_texture.region.position.x = _preview_x + frame * PREVIEW_FRAME_SIZE

func _on_data_changed():
	if visible:
		refresh()

func refresh():
	_refresh_gear()
	_refresh_mysterians()
	_refresh_stats()
	_refresh_grid()

func _refresh_gear():
	for slot_type in gear_slots:
		gear_slots[slot_type].set_item(_get_item_or_null(Equipment.get_equipped(slot_type)))

func _refresh_mysterians():
	var enabled = Equipment.mysterians_enabled
	%MysteriansColumn.visible = enabled
	%MysteriansTab.visible = enabled
	if not enabled and current_category == ItemData.Category.MYSTERIAN:
		current_category = ItemData.Category.ITEM
		%ItemsTab.button_pressed = true

	for i in mysterian_slots.size():
		var item_id = Equipment.mysterian_slots[i]
		mysterian_slots[i].set_item(_get_item_or_null(item_id))
		mysterian_slots[i].set_locked(Equipment.is_mysterian_slot_locked(i))
		# Only a slotted Mysterian can be fused
		fused_buttons[i].visible = item_id != ""
		fused_buttons[i].set_pressed_no_signal(Equipment.fused_slots[i])

func _refresh_stats():
	%HealthBar.max_value = PlayerStats.max_health
	%HealthBar.value = PlayerStats.health
	%HealthValue.text = "%d/%d" % [PlayerStats.health, PlayerStats.max_health]
	_show_stat(%AttackBar, %AttackValue, PlayerStats.base_attack, "attack")
	_show_stat(%DefenseBar, %DefenseValue, PlayerStats.base_defense, "defense")
	_show_stat(%SpeedBar, %SpeedValue, PlayerStats.base_speed, "speed")

# Bar shows the total; text shows "base +bonus" with the bonus colored
func _show_stat(bar: ProgressBar, label: RichTextLabel, base: int, stat: String):
	var bonus = Equipment.get_stat_bonus(stat + "_bonus")
	bar.max_value = STAT_BAR_MAX[stat]
	bar.value = base + bonus
	label.text = str(base)
	if bonus != 0:
		label.text += " [color=%s]%+d[/color]" % [BONUS_COLOR, bonus]

# Rebuild the grid with the current tab's items
func _refresh_grid():
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

	for item_id in Inventory.items:
		# Items without an ItemData .tres can't be shown
		if not ItemDB.has_item(item_id):
			continue
		var item = ItemDB.get_item(item_id)
		if item.category != current_category:
			continue
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		item_grid.add_child(slot)
		slot.set_item(item, Inventory.get_item_count(item_id))
		slot.set_badge(_get_badge(item))
		slot.pressed.connect(_on_grid_item_pressed.bind(item))
		slot.mouse_entered.connect(_show_details.bind(item))

	%EmptyLabel.visible = item_grid.get_child_count() == 0

func _get_badge(item: ItemData) -> String:
	if Equipment.is_fused(item.id):
		return "FUSED"
	if Equipment.is_equipped(item.id):
		return "E"
	return ""

func _on_tab_pressed(category: ItemData.Category):
	current_category = category
	_refresh_grid()

func _on_grid_item_pressed(item: ItemData):
	if item.is_equippable():
		if Equipment.get_equipped(item.slot) == item.id:
			Equipment.unequip(item.slot)
		else:
			Equipment.equip(item.id)
	elif item.is_mysterian():
		var index = Equipment.mysterian_slots.find(item.id)
		if index != -1:
			Equipment.unslot_mysterian(index)
		else:
			var free_slot = Equipment.find_free_mysterian_slot()
			if free_slot != -1:
				Equipment.slot_mysterian(item.id, free_slot)

# Name, description and stat bonuses of the hovered item
func _show_details(item: ItemData):
	if item == null:
		details.text = ""
		return
	var text = item.display_name
	if item.description != "":
		text += "\n" + item.description
	var bonuses = []
	for stat in ["health", "attack", "defense", "speed"]:
		var bonus = item.get(stat + "_bonus")
		if bonus != 0:
			bonuses.append("%s %+d" % [stat.capitalize(), bonus])
	if not bonuses.is_empty():
		text += "\n[color=%s]%s[/color]" % [BONUS_COLOR, ", ".join(bonuses)]
	details.text = text

func _get_item_or_null(item_id: String) -> ItemData:
	return ItemDB.get_item(item_id) if item_id != "" else null
