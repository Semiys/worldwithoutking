extends Node

var items = {
	"Меч": preload("res://items/sword.tres"),
	"Зелье здоровья": preload("res://items/health_potion.tres"),
	"leather_armor": preload("res://items/leather_armor.tres")
}

func get_item(item_name: String) -> ItemResource:
	if items.has(item_name):
		return items[item_name]
	return null

func add_item(item_name: String, item_resource: ItemResource):
	if not items.has(item_name):
		items[item_name] = item_resource

func remove_item(item_name: String):
	if items.has(item_name):
		items.erase(item_name)

func get_all_items() -> Dictionary:
	return items
