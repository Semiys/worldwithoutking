extends StaticBody2D

var is_open = false
var interaction_distance = 100  # Максимальное расстояние для взаимодействия

func _ready():
	print("Дверь инициализирована")
	# Подключаем сигнал для обработки правого клика по инвентарю
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory:
		inventory.connect("item_used", Callable(self, "_on_item_used"))
		print("Сигнал item_used подключен к двери")
	else:
		print("ОШИБКА: Инвентарь не найден!")

func _on_item_used(item_name: String, _global_mouse_pos: Vector2):
	print("Попытка использовать предмет на двери: ", item_name)
	if item_name == "Ключ от подземелья" and not is_open:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# Проверяем расстояние между игроком и дверью
			var distance = global_position.distance_to(player.global_position)
			print("Расстояние до игрока: ", distance)
			
			if distance <= interaction_distance:
				print("Игрок рядом с дверью, открываем...")
				open_door()
				return true
			else:
				print("Игрок слишком далеко от двери")
		else:
			print("Игрок не найден")
	return false

func open_door():
	if not is_open:
		print("Открываем дверь!")
		is_open = true
		# Анимация открытия двери
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): 
			$CollisionShape2D.set_deferred("disabled", true)
			print("Коллизия двери отключена")
		)
		
		# Воспроизводим звук открытия двери (если есть)
		if has_node("AudioStreamPlayer2D"):
			$AudioStreamPlayer2D.play()
