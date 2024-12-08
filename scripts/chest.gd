extends StaticBody2D

var items: Array[String] = []
var is_open = false
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")
@onready var item_database = get_node("/root/ItemDatabase")
@onready var sprite = $AnimatedSprite2D
@onready var interaction_area = $InteractionArea

var possible_items = [
	["Меч", 20],
	["Зелье здоровья", 40],
	["Кожаная броня", 15],
	["Железный меч", 10],
	["Кольцо исцеления", 15]
]

func _ready():
	add_to_group("interactables")
	if sprite and sprite.sprite_frames:
		sprite.play("closed")
	
	interaction_area.body_entered.connect(_on_interaction_area_entered)
	interaction_area.body_exited.connect(_on_interaction_area_exited)

func _on_interaction_area_entered(body):
	if body.is_in_group("player"):
		body.near_chest = true
		body.current_chest = self

func _on_interaction_area_exited(body):
	if body.is_in_group("player"):
		body.near_chest = false
		body.current_chest = null

func interact(player):
	if not is_open:
		is_open = true
		if sprite and sprite.sprite_frames:
				sprite.play("opened")
		
		items.clear()
		
		var item_count = randi() % 3 + 1
		print("Будет выпадать предметов: ", item_count)
		
		for i in item_count:
			var total_weight = 0
			for item in possible_items:
				total_weight += item[1]
			
			var roll = randi() % total_weight
			var current_weight = 0
			
			for item in possible_items:
				current_weight += item[1]
				if roll < current_weight:
					items.append(item[0])
					print("Добавлен предмет: ", item[0])
					break
		
		drop_items()

func drop_items():
	for i in items.size():
		var item_name = items[i]
		var item_resource = item_database.get_item(item_name)
		if item_resource:
			var dropped_item = dropped_item_scene.instantiate()
			dropped_item.item_name = item_name
			dropped_item.item_texture = item_resource.icon
			
			var drop_direction = Vector2(0, 1)
			
			var drop_distance = 15
			var random_spread = Vector2(
				randf_range(-20, 20),
				randf_range(0, 20)
			)
			
			var drop_position = position + (drop_direction * drop_distance) + random_spread
			
			await get_tree().create_timer(0.2).timeout
			
			dropped_item.position = drop_position
			
			get_parent().add_child(dropped_item)
