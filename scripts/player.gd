extends CharacterBody2D

const BASE_SPEED = 100.0
const BASE_ATTACK_COOLDOWN = 0.5

var speed = BASE_SPEED
var health = 100
var max_health = 100
var base_attack_power = 10 # Базовая сила атаки
var attack_power = base_attack_power # Текущая сила атаки с учетом всех бонусов
var defense = 1
var experience = 0
var level = 1
var is_dead = false # Добавляем флаг смерти

# Переменные для способностей
var dodge_cooldown = 3.0
var aoe_attack_cooldown = 5.0
var line_attack_cooldown = 4.0
var invulnerability_cooldown = 15.0
var aura_damage_cooldown = 8.0

var current_dodge_cooldown = 0.0
var current_aoe_cooldown = 0.0
var current_line_cooldown = 0.0
var current_invuln_cooldown = 0.0
var current_aura_cooldown = 0.0

var is_invulnerable = false
var aura_damage_active = false

# Переменные для визуализации радиусов
var dodge_range = 100.0 # Уменьшен базовый радиус
var aoe_radius = 50.0 # Уменьшен базовый радиус
var line_width = 15.0 # Уменьшена базоая ши��ина
var line_length = 100.0 # Уменьшена базовая длина
var aura_radius = 75.0 # Уменьшен базовый радиус

# Переменные для отслеживания зажатых кнопок
var is_dodge_pressed = false
var is_aoe_pressed = false
var is_line_pressed = false
var is_aura_pressed = false

var is_aoe_targeting = false # Для отслеживания режима прицеливания АОЕ

@onready var anim = $AnimatedSprite2D
@onready var inventory = $player_ui/Inventory 
@onready var equipment = {
	"weapon": null,
	"armor": null,
	"damage_item": null # Добавляем слот для предмета урона
}
@onready var item_database = get_node("/root/ItemDatabase")
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
var can_deal_damage = false
var is_attacking = false
var attack_cooldown = BASE_ATTACK_COOLDOWN
var current_attack_cooldown = 0
var damage_number_scene = preload("res://scenes/damage_number.tscn")

func _ready():
	add_to_group("player")
	set_up_input_map()
	load_player_stats()
	update_ui()
	if inventory:
		inventory.add_item_to_first_slot("Меч", false)
		inventory.add_item_to_second_slot("Зелье здоровья")
	else:
		print("Ошибка: узе Inventory не найден")
	attack_collision.disabled = true
	attack_area.connect("body_entered", Callable(self, "_on_AttackArea_body_entered"))
	
	# Подключаемся к сигналам квестов
	QuestManager.connect("quest_completed", _on_quest_completed)
	
	if not InputMap.has_action("open_talents"):
		InputMap.add_action("open_talents")
		var event = InputEventKey.new()
		event.keycode = KEY_T
		InputMap.action_add_event("open_talents", event)
	
	# Добавляем регистрацию клавиши V для серийной атаки
	if not InputMap.has_action("serial_attack"):
		InputMap.add_action("serial_attack")
		var event = InputEventKey.new()
		event.keycode = KEY_V
		InputMap.action_add_event("serial_attack", event)

func _physics_process(_delta: float) -> void:
	if is_dead: # Если персонаж мертв, не обрабатываем движение и атаки
		return
		
	# Обновление кулдаунов способностей
	current_dodge_cooldown = max(0, current_dodge_cooldown - _delta)
	current_aoe_cooldown = max(0, current_aoe_cooldown - _delta)
	current_line_cooldown = max(0, current_line_cooldown - _delta)
	current_invuln_cooldown = max(0, current_invuln_cooldown - _delta)
	current_aura_cooldown = max(0, current_aura_cooldown - _delta)
	
	current_attack_cooldown -= _delta
	if not anim.is_playing() or (anim.animation == "Idle" or anim.animation == "run"):
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = direction * speed # Используем обновленную скорость
			anim.play("run")
			if direction.x < 0:
				$AnimatedSprite2D.flip_h = true
				attack_area.scale.x = -1
			elif direction.x > 0:
				$AnimatedSprite2D.flip_h = false
				attack_area.scale.x = 1
		else:
			velocity = Vector2.ZERO
			if anim.animation != "attack":
				anim.play("Idle")
	else:
		velocity=Vector2.ZERO
	move_and_slide()
	attack_area.scale.x = -1 if $AnimatedSprite2D.flip_h else 1
	
	# Проверка периодического урона ауры
	if aura_damage_active:
		apply_aura_damage()
		
	queue_redraw() # Перерисовываем визуализацию радиусов

func _draw():
	if is_dead: # Если персонаж мертв, не рисуем радиусы способностей
		return
		
	# Рисуем радиусы способностей только когда соответствующие кнопки зажаты
	if is_dodge_pressed and current_dodge_cooldown <= 0:
		draw_circle(Vector2.ZERO, dodge_range * (1 + level * 0.1), Color(0, 1, 0, 0.1))
		
	if is_aoe_pressed and current_aoe_cooldown <= 0:
		var mouse_pos = get_local_mouse_position()
		draw_circle(mouse_pos, aoe_radius * (1 + level * 0.1), Color(1, 0, 0, 0.2))
		
	if is_line_pressed and current_line_cooldown <= 0:
		var direction = Vector2.RIGHT if !$AnimatedSprite2D.flip_h else Vector2.LEFT
		var line_end = direction * (line_length * (1 + level * 0.1))
		draw_line(Vector2.ZERO, line_end, Color(0, 0, 1, 0.2), line_width * (1 + level * 0.05))
		
	if is_aura_pressed and aura_damage_active:
		draw_circle(Vector2.ZERO, aura_radius * (1 + level * 0.1), Color(1, 1, 0, 0.1))

func dodge():
	if current_dodge_cooldown <= 0:
		current_dodge_cooldown = dodge_cooldown
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT if !$AnimatedSprite2D.flip_h else Vector2.LEFT
		velocity = direction * (speed * (2 + level * 0.2)) # Увеличение скорости уклонения с уровнем
		move_and_slide()

func start_aoe_targeting():
	if current_aoe_cooldown <= 0:
		is_aoe_targeting = true

func aoe_attack():
	if is_aoe_targeting:
		current_aoe_cooldown = aoe_attack_cooldown
		var mouse_pos = get_global_mouse_position()
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var distance = mouse_pos.distance_to(enemy.global_position)
			if distance <= aoe_radius * (1 + level * 0.1):
				enemy.take_damage(attack_power * (0.8 + level * 0.1)) # Увеличение урона с уровнем
				spawn_damage_number(attack_power * (0.8 + level * 0.1), enemy.global_position + Vector2(0, -50))
		is_aoe_targeting = false

func line_attack():
	if current_line_cooldown <= 0:
		current_line_cooldown = line_attack_cooldown
		var direction = Vector2.RIGHT if !$AnimatedSprite2D.flip_h else Vector2.LEFT
		var enemies = get_tree().get_nodes_in_group("enemies")
		
		for enemy in enemies:
			var to_enemy = enemy.global_position - global_position
			if abs(to_enemy.angle_to(direction)) < 0.2:
				var distance = global_position.distance_to(enemy.global_position)
				if distance <= line_length * (1 + level * 0.1):
					enemy.take_damage(attack_power * (1 + level * 0.15)) # Увеличение урона с уровнем
					spawn_damage_number(attack_power * (1 + level * 0.15), enemy.global_position + Vector2(0, -50))

func activate_invulnerability():
	if current_invuln_cooldown <= 0:
		current_invuln_cooldown = invulnerability_cooldown
		is_invulnerable = true
		await get_tree().create_timer(2.0 + level * 0.3).timeout # Увеличение длительности с уровнем
		is_invulnerable = false

func activate_aura_damage():
	if current_aura_cooldown <= 0:
		current_aura_cooldown = aura_damage_cooldown
		aura_damage_active = true
		await get_tree().create_timer(3.0 + level * 0.2).timeout # Увеличение длительности с ровнем
		aura_damage_active = false

func apply_aura_damage():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= aura_radius * (1 + level * 0.1):
			enemy.take_damage(attack_power * (0.2 + level * 0.05)) # Увеличение урона с уровнем
			spawn_damage_number(attack_power * (0.2 + level * 0.05), enemy.global_position + Vector2(0, -50))
	await get_tree().create_timer(1.0).timeout

func spawn_damage_number(damage: int, pos: Vector2):
	var damage_number = damage_number_scene.instantiate()
	var label = damage_number.get_node("Label")
	label.text = str(damage)
	damage_number.global_position = pos
	get_tree().current_scene.add_child(damage_number)
	var anim_player = damage_number.get_node("AnimationPlayer")
	anim_player.play("showDamage")

func _check_for_hit():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(attack_power)
			spawn_damage_number(attack_power, body.global_position + Vector2(0, -50))
			print("Урон нанесен врагу на кадре", anim.frame)
		elif body.is_in_group("target") and body.has_method("take_damage"):
			print("Попадание по мишени")  # Отладочный вывод
			body.take_damage(attack_power)
			spawn_damage_number(attack_power, body.global_position + Vector2(0, -50))
			print("Урон нанесен мишени на кадре", anim.frame)

func _on_AttackArea_body_entered(body):
	if body.is_in_group("enemies") and can_deal_damage:
		if body.has_method("take_damage"):
			body.take_damage(attack_power)
			spawn_damage_number(attack_power, body.global_position + Vector2(0, -50))

func interact():
	if is_dead: # Если персонаж мертв, не обрабатываем взаимодействие
		return
		
	print("Игрок взаимодействует с предметом")
	anim.play("interact")
	
	var interactables = get_tree().get_nodes_in_group("interactables")
	var closest_interactable = null
	var closest_distance = INF
	
	for interactable in interactables:
		var distance = global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest_interactable = interactable
			closest_distance = distance
	
	if closest_interactable and closest_distance <= 50:
		closest_interactable.interact(self)
	
	await anim.animation_finished

func take_damage(amount: int):
	if is_dead or is_invulnerable: # Если персонаж мертв или неуязвим, не получаем урон
		return
		
	var actual_damage = max(amount - defense, 0)
	health -= actual_damage
	print("Игрок получил", actual_damage, "урона. Осталось здоровья:", health)
	anim.play("hurt")
	update_ui()
	if health <= 0:
		die()

func die():
	if is_dead: # Если персонаж уже мертв, не выполняем повторно
		return
		
	is_dead = true # Устанавливаем флаг мертви
	print("Игрок умер")
	anim.play("die")
	set_physics_process(false)
	set_process_input(false)
	
	# Отключаем коллизии
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	var death_screen = preload("res://scenes/deathscenes.tscn").instantiate()
	get_tree().current_scene.add_child(death_screen)
	
	await anim.animation_finished
	
	save_player_stats()
	
	await get_tree().create_timer(3.0).timeout
	
	get_tree().reload_current_scene()

func gain_experience(amount: int):
	if is_dead: # Если персонаж метв, не получаем опыт
		return
		
	experience += amount
	print("Получено", amount, "опыта. Всего опыта:", experience)
	check_level_up()
	update_ui()

func check_level_up():
	var experience_needed = level * 100
	if experience >= experience_needed:
		experience -= experience_needed  # Вычитаем опыт, необходимый для текущего уровня
		level_up()

func level_up():
	level += 1
	# Увеличение здоровья
	max_health += 10 + level * 2
	health = max_health
	
	# Увеличение базового урона (квадратичная формула с округлением)
	base_attack_power = round(10 + pow(level, 1.5))
	update_total_attack_power() # Обновляем общий урон
	
	# Увеличение защиты (логарифмическая формула)
	defense = 1 + floor(3 * log(level + 1))
	
	# Увеличение скорости (линейная формула с замедлением роста)
	speed = BASE_SPEED * (1 + (level * 0.1) / (1 + level * 0.05))
	
	# Уменьшение времени перезарядки атаки (экспоненциальная формула с ограничением)
	attack_cooldown = max(BASE_ATTACK_COOLDOWN * pow(0.95, level - 1), 0.1)
	
	print("Уровень повышен! Текущий уровень:", level)
	print("Новые характеристики:")
	print("Здоровье:", max_health)
	print("Урон:", attack_power)
	print("Защита:", defense)
	print("Скорость:", speed)
	print("Вре��я перезарядки атаки:", attack_cooldown)
	#anim.play("level_up")
	update_ui()
	
	# Добавляем очко таланта каждый третий уровень
	if int(level) % 3 == 0:  # Добавляем преобразование в целое число
		var talent_tree = $player_ui/TalentTree
		if talent_tree and talent_tree.has_node("Control"):
			talent_tree.get_node("Control").add_talent_point()
		else:
			print("Ошибка: не найден узел Control в дереве талантов")

func set_up_input_map():
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var event = InputEventKey.new()
		event.keycode = KEY_SPACE
		InputMap.action_add_event("attack", event)
	
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event = InputEventKey.new()
		event.keycode = KEY_E
		InputMap.action_add_event("interact", event)
	if not InputMap.has_action("count_health_potions"):
		InputMap.add_action("count_health_potions")
		var event = InputEventKey.new()
		event.keycode = KEY_C
		InputMap.action_add_event("count_health_potions", event)
		
	# Добавляем привязки клавиш для способностей
	for i in range(1, 6):
		if not InputMap.has_action("ability_" + str(i)):
			InputMap.add_action("ability_" + str(i))
			var event = InputEventKey.new()
			event.keycode = KEY_1 + i - 1  # KEY_1, KEY_2, etc.
			InputMap.action_add_event("ability_" + str(i), event)
			
	# Добавляем привязки WASD для движения
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var event = InputEventKey.new()
		event.keycode = KEY_A
		InputMap.action_add_event("move_left", event)
		
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var event = InputEventKey.new()
		event.keycode = KEY_D
		InputMap.action_add_event("move_right", event)
		
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var event = InputEventKey.new()
		event.keycode = KEY_W
		InputMap.action_add_event("move_up", event)
		
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var event = InputEventKey.new()
		event.keycode = KEY_S
		InputMap.action_add_event("move_down", event)
		
	if not InputMap.has_action("open_talents"):
		InputMap.add_action("open_talents")
		var event = InputEventKey.new()
		event.keycode = KEY_T
		InputMap.action_add_event("open_talents", event)

func _input(event):
	if is_dead: # Если персонаж мертв, не обрабатываем ввод
		return
		
	if event.is_action_pressed("attack"):
		single_attack()
	elif event.is_action_pressed("serial_attack"):
		serial_attack()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("open_inventory"):
		print("Кнопка I нажата")
		var player_ui = $player_ui
		if player_ui:
			player_ui.toggle_inventory()
		else:
			print("Ошибка: узел Player_UI не найден")
	elif event.is_action_pressed("open_talents"):
		var player_ui = $player_ui
		if player_ui:
			player_ui.toggle_talents()
		else:
			print("Ошибка: player_ui не найден")
	# Обработка способностей и их визуализации
	elif event.is_action_pressed("ability_1"):
		is_dodge_pressed = true
		queue_redraw()
	elif event.is_action_released("ability_1"):
		is_dodge_pressed = false
		queue_redraw()
		dodge()
	elif event.is_action_pressed("ability_2"):
		is_aoe_pressed = true
		queue_redraw()
		start_aoe_targeting()
	elif event.is_action_released("ability_2"):
		is_aoe_pressed = false
		queue_redraw()
	elif event.is_action_pressed("ability_3"):
		is_line_pressed = true
		queue_redraw()
	elif event.is_action_released("ability_3"):
		is_line_pressed = false
		queue_redraw()
		line_attack()
	elif event.is_action_pressed("ability_4"):
		activate_invulnerability()
	elif event.is_action_pressed("ability_5"):
		is_aura_pressed = true
		queue_redraw()
		activate_aura_damage()
	elif event.is_action_released("ability_5"):
		is_aura_pressed = false
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_aoe_targeting:
			aoe_attack()

func update_ui():
	var player_data = {
		"health": health,
		"max_health": max_health,
		"attack_power": attack_power,
		"defense": defense,
		"experience": experience,
		"level": level
	}
	$player_ui.update_ui(player_data)

func save_data():
	var save_dict = {
		"health": health,
		"max_health": max_health,
		"base_attack_power": base_attack_power,
		"attack_power": attack_power,
		"defense": defense,
		"experience": experience,
		"level": level,
		"speed": speed,
		"attack_cooldown": attack_cooldown,
		"position": {
			"x": position.x,
			"y": position.y
		},
		"equipment": {
			"weapon": equipment["weapon"].item_name if equipment["weapon"] else null,
			"armor": equipment["armor"].item_name if equipment["armor"] else null,
			"damage_item": equipment["damage_item"].item_name if equipment["damage_item"] else null
		},
		"inventory": inventory.save_inventory()
	}
	return save_dict
	
func save_player_stats():
	var save_dir = "user://saves/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(save_dir):
		dir.make_dir(save_dir)
	
	var save_path = save_dir + "player_stats.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data())
		file.store_string(json_string)
		file.close()
		print("Статистика игрока сохранена в: " + save_path)
	else:
		print("Ошибка при сохранении статистики игрока")

func load_player_stats():
	var save_path = "user://saves/player_stats.json"
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		if json_string.is_empty():
			print("Файл сохранения уст, используем начальные значения")
			return
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			load_data(data)
			print("Статистика игрока загружена из: " + save_path)
		else:
			print("Ошибка при разборе JSON: ", json.get_error_message())
		file.close()
	else:
		print("Файл сохранения не найден, используем начальные значения")

func load_data(data):
	# Устанавливаем значения с проверками
	max_health = data.get("max_health", 100)  # Сначала max_health
	health = data.get("health", max_health)   # Затем health
	
	# Проверяем корректность здоровья
	if health <= 0 or health > max_health:
		health = max_health  # Сбрасываем на максимум если значение некорректное
	
	# Остальные параметры тоже с проверками
	base_attack_power = data.get("base_attack_power", 10)
	attack_power = data.get("attack_power", base_attack_power)
	defense = data.get("defense", 1)
	experience = data.get("experience", 0)
	level = data.get("level", 1)
	speed = data.get("speed", BASE_SPEED)
	attack_cooldown = data.get("attack_cooldown", BASE_ATTACK_COOLDOWN)
	position = Vector2(
		data.get("position", {}).get("x", 0),
		data.get("position", {}).get("y", 0)
	)
	
	# Загрузка экипировки
	if "equipment" in data:
		if data["equipment"]["weapon"]:
			equip_weapon(item_database.get_item(data["equipment"]["weapon"]))
		if data["equipment"]["armor"]:
			equip_armor(item_database.get_item(data["equipment"]["armor"]))
		if data["equipment"]["damage_item"]:
			equip_damage_item(item_database.get_item(data["equipment"]["damage_item"]))
	
	# Загрузка инвентаря
	if "inventory" in data:
		inventory.load_inventory(data["inventory"])
	
	update_ui()

func update_total_attack_power():
	attack_power = base_attack_power
	if equipment["weapon"]:
		attack_power += equipment["weapon"].effect.get("attack", 0)
	if equipment["damage_item"]:
		attack_power += equipment["damage_item"].effect.get("attack", 0)
	attack_power = round(attack_power) # Округляем итоговое значение атаки

func equip_weapon(weapon_item):
	if equipment["weapon"]:
		inventory.add_item(equipment["weapon"].item_name)
	equipment["weapon"] = weapon_item
	update_total_attack_power()
	print("Экипирован меч. Бонус к таке:", weapon_item.effect.get("attack", 0))
	print("Новая сила атаки:", attack_power)
	update_ui()

func equip_damage_item(damage_item):
	if equipment["damage_item"]:
		inventory.add_item(equipment["damage_item"].item_name)
	equipment["damage_item"] = damage_item
	update_total_attack_power()
	print("Экипирован предмет урона. Бонус к атаке:", damage_item.effect.get("attack", 0))
	print("Новая сила атаки:", attack_power)
	update_ui()

func equip_armor(armor_item):
	if equipment["armor"]:
		inventory.add_item(equipment["armor"].item_name)
	equipment["armor"] = armor_item
	defense += armor_item.effect.get("defense", 0)
	update_ui()

func heal(amount):
	var healing_bonus = 1.0
	if equipment["damage_item"] and equipment["damage_item"].effect.get("healing_bonus"):
		healing_bonus += equipment["damage_item"].effect.get("healing_bonus") / 100.0
	
	var final_healing = amount * healing_bonus
	health = min(health + final_healing, max_health)
	update_ui()

func boost_attack(amount):
	base_attack_power += amount
	update_total_attack_power()
	update_ui()

func boost_defense(amount):
	defense += amount
	update_ui()

func use_item(item_name: String):
	var item_resource = item_database.get_item(item_name)
	if item_resource:
		match item_resource.type:
			"Consumable":
				item_resource.apply_effect(self)
			"Weapon":
				equip_weapon(item_resource)
			"Armor":
				equip_armor(item_resource)
			"DamageItem":
				equip_damage_item(item_resource)
		inventory.remove_item(item_name, 1)
		update_ui()
	else:
		print("Предмет не найден в базе данных: ", item_name)

func _on_quest_completed(quest):
	gain_experience(quest.reward_exp)
	print("Получена награда за квест:", quest.reward_exp, "опыта")

# Обновляем функцию die() врага, чтобы учитывать прогресс квестов

func _on_enemy_died(enemy_type: String):
	match enemy_type:
		"dummy":
			QuestManager.update_quest_progress("kill_dummy", 1, "kill_dummy")
		"weak_enemy":
			QuestManager.update_quest_progress("kill_weak", 1, "kill_weak")
		"dungeon_monster":
			QuestManager.update_quest_progress("clear_first_hall", 1, "clear_first_hall")
		"boss":
			QuestManager.update_quest_progress("kill_boss", 1, "kill_boss")

func _on_area_entered(area: Area2D):
	if area.is_in_group("village"):
		QuestManager.update_quest_progress("reach_village", 1, "reach_village")
	elif area.is_in_group("camp"):
		QuestManager.update_quest_progress("clear_camps", 1)
	elif area.is_in_group("artifact"):
		QuestManager.update_quest_progress("find_artifacts", 1)
	elif area.is_in_group("puzzle"):
		QuestManager.update_quest_progress("solve_puzzles", 1)



func shake(duration = 0.2, strength = 15, decay = 8):
	var camera = $Camera2D
	if not camera:
		return
		
	var timer = 0.0
	while timer < duration:
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		camera.offset = offset
		
		strength = strength * exp(-decay * timer)
		
		timer += get_process_delta_time()
		await get_tree().process_frame
	
	camera.offset = Vector2.ZERO

# Новая функция для одиночной атаки
func single_attack():
	if not is_attacking and current_attack_cooldown <= 0:
		is_attacking = true
		current_attack_cooldown = attack_cooldown
		print("Игрок выполняет одиночную атаку! Сила атаки:", attack_power)
		anim.play("attack1")
		attack_collision.disabled = false
		attack_area.monitoring = true
		
		# Ждем определенный кадр для нанесения урона
		while anim.animation == "attack1":
			await anim.frame_changed
			if anim.frame == 5:  # Урон наносится на 5-м кадре
				_check_single_hit()
			if anim.frame == anim.sprite_frames.get_frame_count("attack1") - 1:
				break
		
		attack_collision.disabled = true
		attack_area.monitoring = false
		is_attacking = false
		anim.play("Idle")

# Переименовываем существующую функцию attack() в serial_attack()
func serial_attack():
	if not is_attacking and current_attack_cooldown <= 0:
		is_attacking = true
		current_attack_cooldown = attack_cooldown
		print("Игрок выполняет серийную атаку! Сила атаки:", attack_power)
		anim.play("attack")
		attack_collision.disabled = false
		attack_area.monitoring = true
		
		var damage_frames = [3, 7, 12]
		
		while anim.animation == "attack":
			await anim.frame_changed
			if anim.frame in damage_frames:
				_check_for_hit()
			if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
				break
		
		attack_collision.disabled = true
		attack_area.monitoring = false
		is_attacking = false
		anim.play("Idle")

# Новая функция проверки попадания для одиночной атаки
func _check_single_hit():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(attack_power * 1) # Увеличенный урон для одиночной атаки
			spawn_damage_number(attack_power * 1, body.global_position + Vector2(0, -50))
			print("Урон нанесен врагу одиночной атакой")
		elif body.is_in_group("target") and body.has_method("take_damage"):
			body.take_damage(attack_power * 1)
			spawn_damage_number(attack_power * 1, body.global_position + Vector2(0, -50))
			print("Урон нанесен мишени одиночной атакой")
