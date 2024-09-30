extends TextureRect

var item_name: String
var item_quantity: int

func _ready():
	update_label()
	

func set_item(nm: String, qt: int):
	item_name = nm
	item_quantity = qt
	update_label()

func add_item_quantity(amount_to_add: int):
	item_quantity += amount_to_add
	update_label()

func decrease_item_quantity(amount_to_remove: int):
	item_quantity -= amount_to_remove
	update_label()

func update_label():
	if has_node("Label"):
		$Label.text = str(item_quantity)
