extends StaticBody2D

@export var items: Array[String] = ["Меч", "Зелье здоровья"]
var is_open = false
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")
@onready var item_database = get_node("/root/ItemDatabase")
@onready var sprite = $AnimatedSprite2D
@onready var interaction_area = $InteractionArea

func _ready():
	add_to_group("interactables")
	if sprite and sprite.sprite_frames:
		sprite.play("closed")
	
	# Подключаем сигнал для области взаимодействия
	interaction_area.body_entered.connect(_on_interaction_area_entered)
	interaction_area.body_exited.connect(_on_interaction_area_exited)

func _on_interaction_area_entered(body):
	if body.is_in_group("player"):
		# Игрок вошел в зону взаимодействия
		body.near_chest = true
		body.current_chest = self

func _on_interaction_area_exited(body):
	if body.is_in_group("player"):
		# Игрок вышел из зоны взаимодействия
		body.near_chest = false
		body.current_chest = null

func interact(player):
	if not is_open:
		is_open = true
		if sprite and sprite.sprite_frames:
				sprite.play("opened")
		drop_items()

func drop_items():
	for i in items.size():
		var item_name = items[i]
		var item_resource = item_database.get_item(item_name)
		if item_resource:
			var dropped_item = dropped_item_scene.instantiate()
			dropped_item.item_name = item_name
			dropped_item.item_texture = item_resource.icon
			
			# Определяем направление "перед сундуком"
			var drop_direction = Vector2(0, 1)  # По умолчанию вниз
			
			# Рассчитываем позицию выпадения
			var drop_distance = 15  # Расстояние от сундука
			var random_spread = Vector2(
				randf_range(-20, 20),  # Разброс по X
				randf_range(0, 20)     # Небольшой разброс по Y
			)
			
			# Финальная позиция = позиция сундука + направление*расстояние + случайный разброс
			var drop_position = position + (drop_direction * drop_distance) + random_spread
			
			await get_tree().create_timer(0.2).timeout
			
			dropped_item.position = drop_position
			
			get_parent().add_child(dropped_item)
