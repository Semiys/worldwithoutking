extends Node

var items = {
	"Меч": preload("res://items/sword.tres"),
	"Зелье здоровья": preload("res://items/health_potion.tres"),
	"Кожаная броня": preload("res://items/leather_armor.tres"),
	"Факел": preload("res://items/torch.tres"),
	"Железный меч": preload("res://items/iron_sword.tres"),
	"Кольцо исцеления": preload("res://items/healing_ring.tres"),
	"Артефакт силы": preload("res://items/artifact1.tres"),
	"Артефакт защиты": preload("res://items/artifact2.tres"),
	"Артефакт магии": preload("res://items/artifact3.tres"),
	"Ключ от подземелья": preload("res://items/dungeon_key.tres")
}

# Загружаем сцену ключа
var dungeon_key_scene = preload("res://scenes/items/dungeon_key.tscn")

func _ready():
	pass

# Функция для спавна ключа в указанной позиции
func spawn_dungeon_key(position: Vector2) -> Node2D:
	var key_instance = dungeon_key_scene.instantiate()
	key_instance.position = position
	return key_instance

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

func load_items_from_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var item_data = json.get_data()
			for item_name in item_data:
				var item_resource = ItemResource.new()
				item_resource.from_dictionary(item_data[item_name])
				add_item(item_name, item_resource)
		else:
			print("JSON Parse Error: ", json.get_error_message())
	else:
		print("Failed to open file: ", file_path)

func save_items_to_file(file_path: String):
	var item_data = {}
	for item_name in items:
		item_data[item_name] = items[item_name].to_dictionary()
	
	var json_string = JSON.stringify(item_data)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		print("Failed to save file: ", file_path)
