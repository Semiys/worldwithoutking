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
	call_deferred("add_item_to_first_slot", "sword")

func add_item_to_first_slot(item_name: String):
	var item_resource = item_database.get_item(item_name)
	if item_resource:
		var first_slot = inventory_slots.get_child(0)
		if first_slot and not first_slot.item:
			var new_item = create_item_from_resource(item_resource)
			first_slot.putIntoSlot(new_item)
			print("Предмет добавлен в первый слот: ", item_name)
		else:
			print("Первый слот занят или не найден")
	else:
		print("Предмет не найден в базе данных: ", item_name)
		
func create_item_from_resource(item_resource: ItemResource) -> Node:
	var item_instance = ItemClass.instantiate()
	item_instance.texture = item_resource.icon
	item_instance.set_item(item_resource.item_name, 1)
	return item_instance
	
func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if holding_item:
				if !slot.item:
					slot.putIntoSlot(holding_item)
					holding_item = null
				else:
					var temp_item = slot.pickFromSlot()
					slot.putIntoSlot(holding_item)
					holding_item = temp_item
			elif slot.item:
				holding_item = slot.pickFromSlot()
				add_child(holding_item)
				holding_item.global_position = get_global_mouse_position()

func _input(_event):
	if holding_item:
		holding_item.global_position = get_global_mouse_position()

func _process(_delta):
	if holding_item:
		holding_item.global_position = get_global_mouse_position() - holding_item.size / 2

func get_slot_under_mouse():
	var mouse_pos = get_global_mouse_position()
	for slot in inventory_slots.get_children():
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null
