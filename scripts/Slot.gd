extends Panel

var ItemClass = preload("res://scenes/Item.tscn")
var item = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func can_drop_data(_position, data):
	return data is TextureRect and data.get_parent() == get_parent().get_parent()

func pickFromSlot():
	if item:
		var temp_item = item
		remove_child(item)
		item = null
		return temp_item
	return null

func putIntoSlot(new_item):
	if new_item:
		if new_item.get_parent():
			new_item.get_parent().remove_child(new_item)
		add_child(new_item)
		item = new_item
		item.position = Vector2.ZERO
		item.z_index = 1
func drop_data(_position, data):
	if item:
		var temp_item = item
		item = null
		var inventory = find_parent("Inventory")
		inventory.holding_item = temp_item
	if data.get_parent():
		data.get_parent().remove_child(data)
	add_child(data)
	item = data
	item.position = Vector2.ZERO
