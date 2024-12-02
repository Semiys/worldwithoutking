extends Control

const SlotClass = preload("res://scripts/Slot.gd")
const ItemClass = preload("res://scenes/Item.tscn")
@onready var inventory_slots = $GridContainer
var holding_item = null
@onready var item_database = get_node("/root/ItemDatabase")

func _ready():
	print("Инвентарь инициализирован")
	for inv_slot in inventory_slots.get_children():
		inv_slot.connect("gui_input", Callable(self, "slot_gui_input").bind(inv_slot))
		inv_slot.connect("item_added", Callable(self, "_on_item_added"))
		inv_slot.connect("item_removed", Callable(self, "_on_item_removed"))
	call_deferred("add_item_to_first_slot", "Меч")
	call_deferred("add_item_to_second_slot", "Зелье здоровья")
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))
func _on_item_added(item):
	print("Предмет добавлен в слот: ", item.item_name)

func _on_item_removed(item):
	print("Предмет удален из слота: ", item.item_name)

func add_item_to_first_slot(item_name: String, auto_equip: bool = false):
	var item_resource = item_database.get_item(item_name)
	if item_resource:
		var first_slot = inventory_slots.get_child(0)
		if first_slot and not first_slot.item:
			var new_item = create_item_from_resource(item_resource)
			first_slot.putIntoSlot(new_item)
			print("Предмет добавлен в первый слот: ", item_name)
			if auto_equip:
				get_parent().get_parent().use_item(item_name)
		else:
			print("Первый слот занят или не найден")
	else:
		print("Предмет не найден в базе данных: ", item_name)
func add_item_to_second_slot(item_name: String):
	var item_resource = item_database.get_item(item_name)
	if item_resource:
		var second_slot = inventory_slots.get_child(1)
		if second_slot and not second_slot.item:
			var new_item = create_item_from_resource(item_resource)
			second_slot.putIntoSlot(new_item)
			print("Предмет добавлен во второй слот: ", item_name)
		else:
			print("Второй слот занят или не найден")
	else:
		print("Предмет не найден в базе данных: ", item_name)
func create_item_from_resource(item_resource: ItemResource) -> Node:
	var item_instance = ItemClass.instantiate()
	item_instance.texture = item_resource.icon
	item_instance.set_item(item_resource.item_name, 1)
	item_instance.connect("quantity_changed", Callable(self, "_on_item_quantity_changed"))
	return item_instance
func _on_item_quantity_changed(new_quantity):
	print("Количество предмета изменилось: ", new_quantity)
func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Начало перетаскивания
				if !holding_item and slot.item:
					holding_item = slot.pickFromSlot()
					holding_item.global_position = get_global_mouse_position() - holding_item.size / 2
					if holding_item.get_parent() != self:
						add_child(holding_item)
			else:
				# Конец перетаскивания
				if holding_item:
					var target_slot = get_slot_under_mouse()
					if target_slot:
						if target_slot.item:
							var temp_item = target_slot.pickFromSlot()
							target_slot.putIntoSlot(holding_item)
							slot.putIntoSlot(temp_item)
						else:
							target_slot.putIntoSlot(holding_item)
						holding_item = null
					else:
						slot.putIntoSlot(holding_item)
					if holding_item and holding_item.get_parent() == self:
						remove_child(holding_item)
					holding_item = null
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if slot.item and slot.item.item_name == "Зелье здоровья":
				use_health_potion(slot)
				print("Попытка использовать зелье здоровья")
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			if slot.item:
				delete_item(slot)


func _process(_delta):
	if holding_item:
		holding_item.global_position = get_global_mouse_position() - holding_item.size / 2

func get_slot_under_mouse() -> SlotClass:
	var mouse_pos = get_global_mouse_position()
	for slot in inventory_slots.get_children():
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null
func get_empty_slot() -> SlotClass:
	for slot in inventory_slots.get_children():
		if not slot.item:
			return slot
	return null
func add_item(item_name: String, quantity: int = 1):
	var item_resource = item_database.get_item(item_name)
	if item_resource:
		var new_item = create_item_from_resource(item_resource)
		new_item.set_item(item_name, quantity)
		
		for slot in inventory_slots.get_children():
			if not slot.item:
				slot.putIntoSlot(new_item)
				return true
	return false

func remove_item(item_name: String, quantity: int = 1):
	for slot in inventory_slots.get_children():
		if slot.item and slot.item.item_name == item_name:
			if slot.item.item_quantity <= quantity:
				slot.pickFromSlot()
				return true
			else:
				slot.item.decrease_item_quantity(quantity)
				return true
	return false

func has_item(item_name: String, quantity: int = 1):
	var total_quantity = 0
	for slot in inventory_slots.get_children():
		if slot.item and slot.item.item_name == item_name:
			total_quantity += slot.item.item_quantity
			if total_quantity >= quantity:
				return true
	return false

func get_item_count(item_name: String):
	var total_quantity = 0
	for slot in inventory_slots.get_children():
		if slot.item and slot.item.item_name == item_name:
			total_quantity += slot.item.item_quantity
	return total_quantity
func use_health_potion(slot):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.heal(45)  # Предположим, что зелье восстанавливает 45 единиц здоровья
		slot.item.decrease_item_quantity(1)
		if slot.item.item_quantity <= 0:
			slot.pickFromSlot()
		print("Использовано зелье здоровья")
	else:
		print("Игрок не найден")

func delete_item(slot):
	if slot.item:
		var item_name = slot.item.item_name
		slot.pickFromSlot()
		print("Премет удален: ", item_name)

func show_item_count(item_name: String):
	var count = get_item_count(item_name)
	print("Количество предметов '", item_name, "': ", count)

# Добавьте эту функцию для обработки нажатия клавиши 'C'
func _unhandled_input(event):
	if event.is_action_pressed("count_health_potions"):
		show_item_count("Зелье здоровья")
func _on_visibility_changed():
	if not visible and holding_item:
		var target_slot = get_slot_under_mouse()
		if target_slot and not target_slot.item:
			target_slot.putIntoSlot(holding_item)
		else:
			var empty_slot = find_empty_slot()
			if empty_slot:
				empty_slot.putIntoSlot(holding_item)
			else:
				add_item(holding_item.item_name, holding_item.item_quantity)
		if holding_item.get_parent() == self:
			remove_child(holding_item)
		holding_item = null
func find_empty_slot() -> SlotClass:
	for slot in inventory_slots.get_children():
		if not slot.item:
			return slot
	return null
# Добавьте эту функцию для поиска оригинального слота предмета
func get_original_slot() -> SlotClass:
	for slot in inventory_slots.get_children():
		if not slot.item:
			return slot
	return null
func save_inventory():
	var inventory_data = []
	for slot in inventory_slots.get_children():
		if slot.item:
			inventory_data.append({
				"item_name": slot.item.item_name,
				"quantity": slot.item.item_quantity
			})
	return inventory_data
func load_inventory(inventory_data):
	for slot in inventory_slots.get_children():
		if slot.item:
			slot.pickFromSlot()
	
	for item_data in inventory_data:
		add_item(item_data["item_name"], item_data["quantity"])

func update_holding_item():
	if holding_item:
		holding_item.global_position = get_global_mouse_position() - holding_item.size / 2
func show_item_tooltip(item):
	var tooltip = get_node("Tooltip")
	if tooltip:
		tooltip.set_item_info(item)
		tooltip.show()
		tooltip.global_position = get_global_mouse_position() + Vector2(10, 10)

func hide_item_tooltip():
	var tooltip = get_node("Tooltip")
	if tooltip:
		tooltip.hide()
func use_item(slot):
	if slot.item:
		var item_name = slot.item.item_name
		var item_resource = item_database.get_item(item_name)
		if item_resource:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				item_resource.use(player)
				slot.item.decrease_item_quantity(1)
				if slot.item.item_quantity <= 0:
					slot.pickFromSlot()
				print("Использован предмет: ", item_name)
			else:
				print("Игрок не найден")
		else:
			print("Предмет не найден в базе данных: ", item_name)
