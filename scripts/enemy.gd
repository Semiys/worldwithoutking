extends CharacterBody2D

var SPEED = 100.0  # базовая скорость
var DODGE_SPEED = 300.0  #  скорость уклонения
var BASE_HEALTH = 200  #  базовое здоровье
var BASE_ATTACK = 15   # базовая атака
var BASE_DEFENSE = 10  #  базовая защита

var health = BASE_HEALTH
var max_health = BASE_HEALTH
var attack_power = BASE_ATTACK
var defense = BASE_DEFENSE
var target = null
var is_aggro = false
var min_distance = 20.0
var knockback_strength = 5.0
var knockback_duration = 0.2
var knockback_timer = 0.0
var attack_cooldown = 1.0
var current_cooldown = 0.0
var is_dodging = false
var dodge_cooldown = 2.0
var current_dodge_cooldown = 0.0
var dodge_duration = 0.5
var current_dodge_duration = 0.0
var dodge_direction = Vector2.ZERO
var dodge_damage_reduction = 0.25

# Характеристики врага
var enemy_max_health = 100
var enemy_attack_damage = 10
var enemy_defense = 5
var enemy_speed = 100

# Базовые значения
var base_max_health = BASE_HEALTH
var base_attack_damage = BASE_ATTACK
var base_defense = BASE_DEFENSE
var base_speed = SPEED

@onready var anim = $AnimatedSprite2D
@onready var aggro_area = $AggroArea

func _ready():
	add_to_group("enemies")
	target = get_tree().get_nodes_in_group("player")[0]
	aggro_area.connect("body_entered", _on_aggro_area_body_entered)
	aggro_area.connect("body_exited", _on_aggro_area_body_exited)
	
	# Масштабируем характеристики в зависимости от уровня игрока
	scale_stats_to_player_level()
	base_max_health = enemy_max_health
	base_attack_damage = enemy_attack_damage
	base_defense = enemy_defense
	base_speed = enemy_speed
	health = enemy_max_health

func scale_stats_to_player_level():
	if target:
		var player_level = target.level
		var scaling_factor = 1.0 + (player_level - 1) * 0.1  # Увеличение на 10% за уровень
		
		# Масштабируем характеристики
		max_health = int(BASE_HEALTH * scaling_factor)
		health = max_health
		attack_power = int(BASE_ATTACK * scaling_factor)
		defense = int(BASE_DEFENSE * scaling_factor)

func adapt_to_player_level(player_level):
	# Значительно усиленные множители
	var health_multiplier = 2.0 * player_level  # Увеличен множитель здоровья
	var damage_multiplier = 1.8 * player_level  # Увеличен множитель урона
	var defense_multiplier = 1.5 * player_level # Увеличен множитель защиты
	var speed_multiplier = 1.3 * player_level   # Увеличен множитель скорости
	
	# Применяем усиление
	max_health = base_max_health * health_multiplier
	health = max_health  # Обновляем текущее здоровье
	
	attack_power = base_attack_damage * damage_multiplier
	defense = base_defense * defense_multiplier
	SPEED = base_speed * speed_multiplier
	
	# Увеличен лимит максимальной скорости
	SPEED = min(SPEED, base_speed * 5)  # Теперь может быть в 5 раз быстрее базовой
	
	print("Враг адаптирован под уровень игрока ", player_level)
	print("Здоровье: ", max_health)
	print("Урон: ", attack_power)
	print("Защита: ", defense)
	print("Скорость: ", SPEED)

func _physics_process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		anim.play("hurt")
		move_and_slide()
	elif is_aggro and target:
		# Проверяем, не мертв ли игрок
		if target.is_dead:
			is_aggro = false
			velocity = Vector2.ZERO
			return
			
		# Обработка движения
		var direction = (target.global_position - global_position).normalized()
		var distance = global_position.distance_to(target.global_position)
		
		if distance > min_distance:
			velocity = direction * SPEED
			anim.play("run")
			# Поворачиваем спрайт в зависимости от направления движения
			anim.flip_h = direction.x < 0
		else:
			velocity = Vector2.ZERO
			if current_cooldown <= 0:
				attack()
				current_cooldown = attack_cooldown
		
		current_cooldown -= delta
		move_and_slide()
	else:
		# Если не преследуем цель, останавливаемся
		velocity = Vector2.ZERO
		anim.stop()  # Останавливаем анимацию

func should_dodge() -> bool:
	if not target:
		return false
		
	# Проверяем, атакует ли игрок и близко ли он
	var distance = global_position.distance_to(target.global_position)
	var is_player_attacking = target.get("is_attacking") if target.has_method("get") else false
	
	return distance < 40.0 and is_player_attacking

func start_dodge():
	is_dodging = true
	current_dodge_duration = dodge_duration
	current_dodge_cooldown = dodge_cooldown
	
	# Выбираем случайное направление для уворота
	var to_player = (target.global_position - global_position).normalized()
	var perpendicular = Vector2(-to_player.y, to_player.x)
	dodge_direction = (perpendicular if randf() > 0.5 else -perpendicular) + to_player * 0.5
	dodge_direction = dodge_direction.normalized()

func _on_aggro_area_body_entered(body):
	if body == target:
		is_aggro = true
		print("Враг заметил игрока!")

func _on_aggro_area_body_exited(body):
	if body == target:
		is_aggro = false
		print("Враг потерял игрока из виду.")

func attack():
	print("Враг атакует! Сила атаки:", attack_power)
	
	# Ускоряем анимацию атаки
	anim.speed_scale = 2.0
	anim.play("attack")
	
	# Ждем середины анимации для нанесения урона
	# При speed = 10 fps и speed_scale = 2.0, один кадр = 0.05 секунды
	# У нас 10 кадров, значит до 5-го кадра нужно ждать 0.1 секунды
	await get_tree().create_timer(0.1).timeout
	
	# Наносим урон
	if target and target.has_method("take_damage"):
		target.take_damage(attack_power)
	
	# Ждем окончания анимации и возвращаем нормальную скорость
	await anim.animation_finished
	anim.speed_scale = 1.0

func take_damage(amount: int):
	# Если враг уже мертв, не обрабатываем урон
	if health <= 0:
		return
		
	var damage_multiplier = dodge_damage_reduction if is_dodging else 1.0
	var actual_damage = max(int((amount - defense) * damage_multiplier), 0)
	health -= actual_damage
	
	# Прерываем текущую анимацию
	anim.stop()
	
	# Проигрываем анимацию получения урона с увеличенной скоростью
	anim.speed_scale = 2.0
	anim.play("hurt")
	
	print("Враг получил", actual_damage, "урона. Осталось здоровья:", health)
	
	if target:
		var knockback_direction = (position - target.position).normalized()
		velocity = knockback_direction * knockback_strength * 1
		knockback_timer = knockback_duration * 1.5
	
	if health <= 0:
		die()
	else:
		# Ждем окончания анимации получения урона
		await anim.animation_finished
		
		# Возвращаем нормальную скорость и сбрасываем анимацию
		anim.speed_scale = 1.0
		
		# Если все еще есть цель, возвращаемся к анимации движения
		if target and is_aggro:
			var direction = (target.global_position - global_position).normalized()
			anim.play("run")
			anim.flip_h = direction.x < 0

func die():
	print("Враг умер")
	# Отключаем коллизии сразу
	self.collision_layer = 0
	self.collision_mask = 0
	
	# Останавливаем все текущие анимации и проигрываем смерть
	anim.stop()
	anim.speed_scale = 1.0
	anim.play("death")
	
	# Отключаем физику и движение
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	# Обновляем квесты и выдаем награду
	QuestManager.update_quest_progress("kill")
	QuestManager.update_quest_progress("kill_weak", 1, "kill_weak")
	QuestManager.update_quest_progress("clear_first_hall", 1, "clear_first_hall")
	
	var player = get_tree().get_nodes_in_group("player")[0]
	if player and player.has_method("gain_experience"):
		player.gain_experience(10)
		print("Награда получена: +10 опыта")
	
	# Добавляем выпадение предметов
	drop_loot()
	
	
	anim.sprite_frames.set_animation_loop("death", false)
	
	# Ждем завершения анимации смерти перед удалением
	await anim.animation_finished
	queue_free()

func drop_loot():
	var dropped_item_scene = preload("res://scenes/dropped_item.tscn")
	var item_database = get_node("/root/ItemDatabase")
	
	# Шанс выпадения предметов
	if randf() < 0.3: # 30% шанс
		var possible_items = ["Зелье здоровья"]
		var item_name = possible_items[randi() % possible_items.size()]
		var item_resource = item_database.get_item(item_name)
		
		if item_resource:
			var dropped_item = dropped_item_scene.instantiate()
			dropped_item.item_name = item_name
			dropped_item.item_texture = item_resource.icon
			
			# Добавляем случайное смещение при выпадении
			var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			dropped_item.position = position + offset
			
			get_parent().add_child(dropped_item)
