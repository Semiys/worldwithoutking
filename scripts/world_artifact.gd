extends Area2D

@export var artifact_name: String
var item_texture: Texture2D

func _ready():
	var item_resource = get_node("/root/ItemDatabase").get_item(artifact_name)
	if item_resource:
		item_texture = item_resource.icon
		$Sprite2D.texture = item_texture
		
		# Добавляем эффект свечения
		var glow = create_glow_effect()
		add_child(glow)
		
		# Создаем ключ на 3 клетки выше артефакта
		if artifact_name in ["Артефакт силы", "Артефакт защиты", "Артефакт магии"]:
			create_dungeon_key()

func create_dungeon_key():
	var key_scene = preload("res://scenes/items/dungeon_key.tscn")
	var key = key_scene.instantiate()
	# Устанавливаем позицию на 3 клетки (192 пикселя) выше артефакта
	key.position = Vector2(0, -192)  # 64 * 3 = 192 пикселя (размер клетки 64x64)
	add_child(key)
	print("Ключ создан выше артефакта")

func create_glow_effect():
	var light = PointLight2D.new()
	light.texture = item_texture
	light.energy = 0.5
	light.color = Color(1, 1, 0.8, 0.5)
	
	# Создаем анимацию пульсации
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(light, "energy", 0.8, 1.0)
	tween.tween_property(light, "energy", 0.5, 1.0)
	
	return light

func _on_body_entered(body):
	if body.is_in_group("player"):
		var inventory = body.get_node("player_ui/Inventory")
		if inventory.add_item(artifact_name):
			print("Артефакт добавлен в инвентарь: ", artifact_name)
			# Анимация подбора
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
			tween.tween_callback(queue_free)

func _on_item_used(item_name: String, global_mouse_pos: Vector2):
	# Проверяем, что используется именно ключ
	if item_name == "Ключ от подземелья":
		# Ищем ближайшую дверь
		var doors = get_tree().get_nodes_in_group("dungeon_doors")
		for door in doors:
			# Проверяем, находится ли курсор над дверью
			var door_rect = door.get_node("CollisionShape2D").shape.get_rect()
			door_rect.position += door.global_position
			if door_rect.has_point(global_mouse_pos):
				# Открываем дверь
				door.open_door()
				# Удаляем ключ из инвентаря
				var inventory = get_tree().get_first_node_in_group("inventory")
				if inventory:
					inventory.remove_item("Ключ от подземелья")
				break