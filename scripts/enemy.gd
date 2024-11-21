extends CharacterBody2D

const SPEED = 40.0
const DODGE_SPEED = 150.0  # Скорость уворота
var health = 50
var attack_power = 5
var defense = 2
var target = null
var is_aggro = false
var min_distance = 20.0
var knockback_strength = 5.0
var knockback_duration = 0.2
var knockback_timer = 0.0
var attack_cooldown = 1.0
var current_cooldown = 0.0
var is_dodging = false
var dodge_cooldown = 2.0  # Перезарядка уворота
var current_dodge_cooldown = 0.0
var dodge_duration = 0.5  # Длительность уворота
var current_dodge_duration = 0.0
var dodge_direction = Vector2.ZERO
var dodge_damage_reduction = 0.25  # Уменьшение урона при уклонении на 75%

@onready var anim = $AnimatedSprite2D
@onready var aggro_area = $AggroArea

func _ready():
	add_to_group("enemies")
	target = get_tree().get_nodes_in_group("player")[0]
	aggro_area.connect("body_entered", _on_aggro_area_body_entered)
	aggro_area.connect("body_exited", _on_aggro_area_body_exited)

func _physics_process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		move_and_slide()
	elif is_aggro and target:
		# Проверяем, не мертв ли игрок
		if target.is_dead:
			is_aggro = false
			velocity = Vector2.ZERO
			return
			
		# Обработка уворота
		if current_dodge_cooldown > 0:
			current_dodge_cooldown -= delta
			
		if is_dodging:
			current_dodge_duration -= delta
			velocity = dodge_direction * DODGE_SPEED
			if current_dodge_duration <= 0:
				is_dodging = false
		else:
			var direction = (target.global_position - global_position).normalized()
			var distance = global_position.distance_to(target.global_position)
			
			# Проверяем, нужно ли уворачиваться
			if should_dodge() and current_dodge_cooldown <= 0:
				start_dodge()
			elif distance > min_distance:
				velocity = direction * SPEED
				anim.play("run")
				if direction.x < 0:
					$AnimatedSprite2D.flip_h = true
				else:
					$AnimatedSprite2D.flip_h = false
			else:
				velocity = Vector2.ZERO
				anim.play("run")
				if current_cooldown <= 0:
					attack()
					current_cooldown = attack_cooldown
			
			current_cooldown -= delta
	else:
		velocity = Vector2.ZERO
		anim.play("run")
	
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
	if target and target.has_method("take_damage"):
		target.take_damage(attack_power)

func take_damage(amount: int):
	# Если враг уворачивается, значительно уменьшаем получаемый урон
	var damage_multiplier = dodge_damage_reduction if is_dodging else 1.0
	var actual_damage = max(int((amount - defense) * damage_multiplier), 0)
	health -= actual_damage
	print("Враг получил", actual_damage, "урона. Осталось здоровья:", health)
	
	if target:
		var knockback_direction = (position - target.position).normalized()
		velocity = knockback_direction * knockback_strength * 1
		knockback_timer = knockback_duration * 1.5
	
	if health <= 0:
		die()

func die():
	print("Враг умер")
	queue_free()
	var player = get_tree().get_nodes_in_group("player")[0]
	if player and player.has_method("gain_experience"):
		player.gain_experience(10)
		print("Награда получена: +10 опыта")
	anim.play("death")
	self.collision_layer = 0
	self.collision_mask = 0
