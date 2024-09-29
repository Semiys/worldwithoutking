extends CharacterBody2D

const SPEED = 40.0
var health = 50
var attack_power = 5
var defense = 2
var target = null
var is_aggro = false
var min_distance = 20.0
var knockback_strength = 5.0
var knockback_duration = 0.2
var knockback_timer = 0.0
var attack_cooldown = 1.0  # Время между атаками
var current_cooldown = 0.0  # Текущее время до следующей атаки

@onready var anim = $AnimatedSprite2D
@onready var aggro_area = $AggroArea

func _ready():
	target = get_node("/root/Game/Player")
	aggro_area.connect("body_entered", _on_aggro_area_body_entered)
	aggro_area.connect("body_exited", _on_aggro_area_body_exited)

func _physics_process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		move_and_slide()
	elif is_aggro and target:
		var direction = (target.position - position).normalized()
		var distance = position.distance_to(target.position)
		
		if distance > min_distance:
			velocity = direction * SPEED
			anim.play("run")
			if direction.x < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false
		else:
			velocity = Vector2.ZERO
			anim.play("run")
			
			var knockback_direction = (position - target.position).normalized()
			velocity = knockback_direction * knockback_strength
			knockback_timer = knockback_duration
			
			# Атака игрока
			if current_cooldown <= 0:
				attack()
				current_cooldown = attack_cooldown
		
		# Уменьшаем время до следующей атаки
		current_cooldown -= delta
	else:
		velocity = Vector2.ZERO
		anim.play("run")
	
	move_and_slide()

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
	if target:
		target.take_damage(attack_power)

func take_damage(amount: int):
	var actual_damage = max(amount - defense, 0)
	health -= actual_damage
	print("Враг получил", actual_damage, "урона. Осталось здоровья:", health)
	if health <= 0:
		die()

func die():
	print("Враг умер")
	queue_free()
	var player = get_node("/root/Game/Player")
	player.gain_experience(10)
	print("Награда получена: +10 опыта")
	anim.play("death")
	self.collision_layer = 0
	self.collision_mask = 0
