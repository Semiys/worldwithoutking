extends CharacterBody2D

const SPEED = 1000.0
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
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
var can_deal_damage = false
var is_attacking = false
var attack_cooldown = 0.5
var current_attack_cooldown = 0

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
	attack_collision.disabled = true
	attack_area.connect("body_entered", Callable(self, "_on_AttackArea_body_entered"))

func _physics_process(_delta: float) -> void:
	current_attack_cooldown -= _delta
	if not anim.is_playing() or (anim.animation == "Idle" or anim.animation == "run"):
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if direction:
			velocity = direction * SPEED
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
func attack():
	if not is_attacking and current_attack_cooldown <= 0:
		is_attacking = true
		current_attack_cooldown = attack_cooldown
		print("Игрок атакует! Сила атаки:", attack_power)
		anim.play("attack")
		attack_collision.disabled = false
		# Регистрация урона происходит на определенных кадрах анимации
		var damage_frames = [3, 7, 12]  # Кадры, на которых будет наноситься урон
		# Регистрация урона происходит на определенном кадре анимации
		
		while anim.animation == "attack":
			
			await anim.frame_changed
			if anim.frame in damage_frames:
				_check_for_hit()
			if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
				break
			
				
		
		attack_collision.disabled = true
		is_attacking = false
		
		anim.play("Idle")
func _check_for_hit():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(attack_power)
			print("Урон нанесен врагу на кадре", anim.frame)
func _on_AttackArea_body_entered(body):
	if body.is_in_group("enemies") and can_deal_damage:
		if body.has_method("take_damage"):
			body.take_damage(attack_power)
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
		attack_power -= equipment["weapon"].effect.get("attack", 0)
		inventory.add_item(equipment["weapon"].item_name)
	equipment["weapon"] = weapon_item
	if "attack" in weapon_item.effect:
		attack_power += weapon_item.effect["attack"]
		print("Экипирован меч. Бонус к атаке:", weapon_item.effect["attack"])
		print("Новая сила атаки:", attack_power)
	else:
		print("У оружия нет эффекта атаки")
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
		inventory.remove_item(item_name, 1)
		update_ui()
	else:
		print("Предмет не найден в базе данных: ", item_name)
