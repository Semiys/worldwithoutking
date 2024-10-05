extends Panel

var ItemClass = preload("res://scenes/Item.tscn")
var item = null

signal item_added(item)
signal item_removed(item)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func can_drop_data(_position, data):
	return data is TextureRect

func pickFromSlot():
	if item:
		var temp_item = item
		remove_child(item)
		item = null
		emit_signal("item_removed", temp_item)
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
		emit_signal("item_added", new_item)

func drop_data(_position, _data):
	var inventory = find_parent("Inventory")
	if inventory.holding_item:
		if item:
			var temp_item = item
			item = null
			inventory.holding_item = temp_item
			emit_signal("item_removed", temp_item)
		putIntoSlot(inventory.holding_item)
		inventory.holding_item = null
		inventory.update_holding_item()
func has_item() -> bool:
	return item != null
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if item:
				var inventory = find_parent("Inventory")
				inventory.use_item(self)

func _on_mouse_entered():
	if item:
		var inventory = find_parent("Inventory")
		inventory.show_item_tooltip(item)

func _on_mouse_exited():
	var inventory = find_parent("Inventory")
	inventory.hide_item_tooltip()
