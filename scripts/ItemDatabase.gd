extends Node

var items = {
	"sword": preload("res://items/sword.tres"),
	"health_potion": preload("res://items/health_potion.tres"),
	"leather_armor": preload("res://items/leather_armor.tres")
}

func get_item(item_name: String) -> ItemResource:
	if items.has(item_name):
		return items[item_name]
	return null
