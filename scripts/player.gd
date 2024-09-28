extends CharacterBody2D

const SPEED = 100.0
var health = 100
var max_health = 100
var attack_power = 10
var defense = 5
var experience = 0
var level = 1

<<<<<<< HEAD
@onready var anim=$AnimatedSprite2D
func _ready():
	set_up_input_map()
=======
@onready var anim = $AnimatedSprite2D

func _ready():
	set_up_input_map()
	load_player_stats()  # Добавляем загрузку данных при старте
>>>>>>> parent of d1fbfc2 (UI update)

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
		anim.play("run")
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		elif direction.x > 0:
			$AnimatedSprite2D.flip_h = false
	else:
		velocity = Vector2.ZERO
		anim.play("Idle")
	move_and_slide()

func attack():
	print("Игрок атакует! Сила атаки:", attack_power)
	# Здесь можно добавить логику поиска ближайшего врага и нанесения ему урона

func interact():
	print("Игрок взаимодействует с предметом")
	# Здесь можно добавить логику взаимодействия с предметами на уровне

func take_damage(amount: int):
	var actual_damage = max(amount - defense, 0)
	health -= actual_damage
	print("Игрок получил", actual_damage, "урона. Осталось здоровья:", health)
<<<<<<< HEAD
=======
	anim.play("hurt")
	update_ui()  # Обновляем UI после получения урона
>>>>>>> parent of d1fbfc2 (UI update)
	if health <= 0:
		die()

func die():
	print("Игрок умер")
	# Здесь можно добавить логику перезапуска уровня или игры

func gain_experience(amount: int):
	experience += amount
	print("Получено", amount, "опыта. Всего опыта:", experience)
	check_level_up()

func check_level_up():
	var experience_needed = level * 100  # Простая формула для необходимого опыта
	if experience >= experience_needed:
		level_up()

func level_up():
	level += 1
	max_health += 10
	health = max_health
	attack_power += 2
	defense += 1
	print("Уровень повышен! Текущий уровень:", level)

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
<<<<<<< HEAD
=======

func _input(event):
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("interact"):
		interact()

# Добавляем новую функцию для обновления UI
func update_ui():
	# Обновляем полоску здоровья
	$HealthBar.value = health
	$HealthBar.max_value = max_health
	
	# Обновляем полоску опыта
	var experience_needed = level * 100
	$ExperienceBar.value = experience
	$ExperienceBar.max_value = experience_needed
	
	# Обновляем текст уровня
	$LevelLabel.text = "Уровень: " + str(level)
	
	# Обновляем текст атаки и защиты
	$StatsLabel.text = "Атака: " + str(attack_power) + " | Защита: " + str(defense)
	
	# Обновляем текст здоровья
	$HealthLabel.text = str(health) + " / " + str(max_health)
	
	# Обновляем текст опыта
	$ExperienceLabel.text = str(experience) + " / " + str(experience_needed)

# Функция для сохранения данных игрока
func save_data():
	var save_dict = {
		"health": health,
		"max_health": max_health,
		"attack_power": attack_power,
		"defense": defense,
		"experience": experience,
		"level": level,
		"position": {
			"x": position.x,
			"y": position.y
		}
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

# Функция для загрузки данных игрока
func load_player_stats():
	var save_path = "user://saves/player_stats.json"
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		if json_string.is_empty():
			print("Файл сохранения пуст, используем начальные значения")
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
	health = data["health"]
	max_health = data["max_health"]
	attack_power = data["attack_power"]
	defense = data["defense"]
	experience = data["experience"]
	level = data["level"]
	position = Vector2(data["position"]["x"], data["position"]["y"])
	update_ui()
>>>>>>> parent of d1fbfc2 (UI update)
