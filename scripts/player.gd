extends CharacterBody2D

const SPEED = 100.0
var health = 100
var max_health = 100
var attack_power = 10
var defense = 5
var experience = 0
var level = 1

func _ready():
	set_up_input_map()

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
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
