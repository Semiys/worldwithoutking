extends CharacterBody2D

const SPEED = 40.0
const DODGE_SPEED = 150.0
const BASE_HEALTH = 50  # Базовое здоровье
const BASE_ATTACK = 5   # Базовая атака
const BASE_DEFENSE = 2  # Базовая защита

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

@onready var anim = $AnimatedSprite2D
@onready var aggro_area = $AggroArea

func _ready():
	add_to_group("enemies")
	target = get_tree().get_nodes_in_group("player")[0]
	aggro_area.connect("body_entered", _on_aggro_area_body_entered)
	aggro_area.connect("body_exited", _on_aggro_area_body_exited)
	
	# Масштабируем характеристики в зависимости от уровня игрока
	scale_stats_to_player_level()

func scale_stats_to_player_level():
	if target:
		var player_level = target.level
		var scaling_factor = 1.0 + (player_level - 1) * 0.1  # Увеличение на 10% за уровень
		
		# Масштабируем характеристики
		max_health = int(BASE_HEALTH * scaling_factor)
		health = max_health
		attack_power = int(BASE_ATTACK * scaling_factor)
		defense = int(BASE_DEFENSE * scaling_factor)
		
		print("Враг усилен до уровня игрока ", player_level)
		print("Здоровье: ", max_health)
		print("Атака: ", attack_power)
		print("Защита: ", defense)

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
		
		# Проверяем столкновение с игроком и добавляем отталкивание
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("player"):
				# Отталкиваем врага от игрока
				var push_vector = (global_position - collider.global_position).normalized()
				velocity = push_vector * SPEED * 2
				move_and_slide()
				# Также слегка отталкиваем игрока
				collider.velocity = -push_vector * SPEED
				break
		
		move_and_slide()

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
	# Предполагая, что у нас 10 кадров анимации атаки, ждем 5-й кадр
	await get_tree().create_timer(0.25).timeout  # Подождем четверть секунды
	
	# Наносим урон
	if target and target.has_method("take_damage"):
		target.take_damage(attack_power)
	
	# Ждем окончания анимации и возвращаем нормальную скорость
	await anim.animation_finished
	anim.speed_scale = 1.0

func take_damage(amount: int):
	# Если враг уворачивается, значительно уменьшаем получаемый урон
	var damage_multiplier = dodge_damage_reduction if is_dodging else 1.0
	var actual_damage = max(int((amount - defense) * damage_multiplier), 0)
	health -= actual_damage
	
	# Проигрываем анимацию получения урона с увеличенной скоростью
	anim.speed_scale = 2.0  # Увеличиваем скорость анимации
	anim.play("hurt")
	
	print("Враг получил", actual_damage, "урона. Осталось здоровья:", health)
	
	if target:
		var knockback_direction = (position - target.position).normalized()
		velocity = knockback_direction * knockback_strength * 1
		knockback_timer = knockback_duration * 1.5
	
	if health <= 0:
		die()
	else:
		# Ждем окончания анимации получения урона и возвращаем нормальную скорость
		await anim.animation_finished
		anim.speed_scale = 1.0

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
	
	var player = get_tree().get_nodes_in_group("player")[0]
	if player and player.has_method("gain_experience"):
		player.gain_experience(10)
		print("Награда получена: +10 опыта")
	
	# Добавляем выпадение предметов
	drop_loot()
	
	# Важно: устанавливаем loop = false для анимации смерти
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
