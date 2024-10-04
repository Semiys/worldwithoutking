extends TextureRect

var item_name: String
var item_quantity: int

signal quantity_changed(new_quantity)

func _ready():
	update_label()

func set_item(nm: String, qt: int):
	item_name = nm
	item_quantity = qt
	update_label()

func add_item_quantity(amount_to_add: int):
	item_quantity += amount_to_add
	update_label()
	emit_signal("quantity_changed", item_quantity)

func decrease_item_quantity(amount_to_remove: int):
	item_quantity -= amount_to_remove
	update_label()
	emit_signal("quantity_changed", item_quantity)

func update_label():
	if has_node("Label"):
		$Label.text = str(item_quantity)

func get_drag_data(_position):
	var data = {}
	data["origin_node"] = self
	data["origin_panel"] = get_parent()

	var drag_texture = TextureRect.new()
	drag_texture.expand = true
	drag_texture.texture = texture
	drag_texture.size = Vector2(50, 50)

	var control = Control.new()
	control.add_child(drag_texture)
	drag_texture.position = -drag_texture.size / 2  # Центрируем текстуру
	set_drag_preview(control)

	return data
