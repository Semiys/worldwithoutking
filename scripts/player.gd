extends CharacterBody2D

const SPEED = 100.0
var health = 100
var max_health = 100
var attack_power = 10
var defense = 1
var experience = 0
var level = 1

@onready var anim = $AnimatedSprite2D
@onready var inventory = $player_ui/Inventory 
@onready var equipment = {
	"weapon": null,
	"armor": null
}
@onready var item_database = get_node("/root/ItemDatabase")

func _ready():
	set_up_input_map()
	load_player_stats()
	update_ui()
	add_to_group("player")
	if inventory:
		inventory.add_item_to_first_slot("Меч")
		inventory.add_item_to_second_slot("Зелье здоровья")
	else:
		print("Ошибка: узел Inventory не найден")

func _physics_process(_delta: float) -> void:
	if not anim.is_playing() or (anim.animation == "Idle" or anim.animation == "run"):
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
			if anim.animation != "attack":
				anim.play("Idle")
	else:
		velocity=Vector2.ZERO
	move_and_slide()

func attack():
	print("Игрок атакует! Сила атаки:", attack_power)
	anim.play("attack")
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	
	if closest_enemy and closest_distance <= 50:
		closest_enemy.take_damage(attack_power)
	
	await anim.animation_finished
	anim.play("Idle")
	
func interact():
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
	var actual_damage = max(amount - defense, 0)
	health -= actual_damage
	print("Игрок получил", actual_damage, "урона. Осталось здоровья:", health)
	anim.play("hurt")
	update_ui()
	if health <= 0:
		die()

func die():
	print("Игрок умер")
	anim.play("die")
	set_physics_process(false)
	set_process_input(false)
	
	var death_screen = preload("res://scenes/deathscenes.tscn").instantiate()
	get_tree().current_scene.add_child(death_screen)
	
	await anim.animation_finished
	
	save_player_stats()
	
	await get_tree().create_timer(3.0).timeout
	
	get_tree().reload_current_scene()

func gain_experience(amount: int):
	experience += amount
	print("Получено", amount, "опыта. Всего опыта:", experience)
	check_level_up()
	update_ui()

func check_level_up():
	var experience_needed = level * 100
	if experience >= experience_needed:
		level_up()

func level_up():
	level += 1
	max_health += 10
	health = max_health
	attack_power += 2
	defense += 1
	print("Уровень повышен! Текущий уровень:", level)
	anim.play("level_up")
	update_ui()

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
func _input(event):
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("open_inventory"):
		print("Кнопка I нажата")
		var player_ui = $player_ui
		if player_ui:
			player_ui.toggle_inventory()
		else:
			print("Ошибка: узел Player_UI не найден")

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
		"attack_power": attack_power,
		"defense": defense,
		"experience": experience,
		"level": level,
		"position": {
			"x": position.x,
			"y": position.y
		},
		"equipment": {
			"weapon": equipment["weapon"].item_name if equipment["weapon"] else null,
			"armor": equipment["armor"].item_name if equipment["armor"] else null
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
	
	if "equipment" in data:
		if data["equipment"]["weapon"]:
			equip_weapon(item_database.get_item(data["equipment"]["weapon"]))
		if data["equipment"]["armor"]:
			equip_armor(item_database.get_item(data["equipment"]["armor"]))
	
	if "inventory" in data:
		inventory.load_inventory(data["inventory"])
	
	update_ui()

func equip_weapon(weapon_item):
	if equipment["weapon"]:
		inventory.add_item(equipment["weapon"].item_name)
	equipment["weapon"] = weapon_item
	attack_power += weapon_item.effect.get("attack", 0)
	update_ui()

func equip_armor(armor_item):
	if equipment["armor"]:
		inventory.add_item(equipment["armor"].item_name)
	equipment["armor"] = armor_item
	defense += armor_item.effect.get("defense", 0)
	update_ui()

func heal(amount):
	health = min(health + amount, max_health)
	
	update_ui()

func boost_attack(amount):
	attack_power += amount
	update_ui()

func boost_defense(amount):
	defense += amount
	update_ui()
