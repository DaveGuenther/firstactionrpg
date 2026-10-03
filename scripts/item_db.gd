# item_db.gd
# Autoload "ItemDB": every item definition (ItemData), loaded from
# Resource/Item/Data/ at startup. To add an item, drop a new ItemData .tres
# into that folder -- no code changes needed.
extends Node

const ITEM_DIR = "res://Resource/Item/Data/"

# item_id -> ItemData
var items: Dictionary = {}

func _ready():
	# list_directory also works in exported builds, where .tres files are remapped
	for file in ResourceLoader.list_directory(ITEM_DIR):
		if file.ends_with("/"):
			continue
		var item = load(ITEM_DIR + file) as ItemData
		if item == null:
			push_warning("ItemDB: %s is not an ItemData" % file)
			continue
		if items.has(item.id):
			push_warning("ItemDB: duplicate item id '%s' in %s" % [item.id, file])
		items[item.id] = item

# Returns null (with a warning) for ids that have no definition
func get_item(item_id: String) -> ItemData:
	if not items.has(item_id):
		push_warning("ItemDB: no ItemData for '%s'" % item_id)
		return null
	return items[item_id]

func has_item(item_id: String) -> bool:
	return items.has(item_id)
