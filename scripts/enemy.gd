extends CharacterBody2D

const SPEED = 40.0
var health = 50
var attack_power = 5
var defense = 2
var target = null
var is_aggro = false
var min_distance = 20.0  # Минимальное расстояние до игрока
var knockback_strength = 5.0  # Сила отталкивания
var knockback_duration = 0.2  # Длительность отталкивания в секундах
var knockback_timer = 0.0  # Таймер для отслеживания длительности отталкивания

@onready var anim = $AnimatedSprite2D
@onready var aggro_area = $AggroArea

func _ready():
	target = get_node("/root/Game/Player")  # Укажите путь до узла игрока
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
			anim.play("run")  # Добавьте анимацию "idle" для ожидания
			
			# Логика отталкивания при близком контакте
			var knockback_direction = (position - target.position).normalized()
			velocity = knockback_direction * knockback_strength
			knockback_timer = knockback_duration
	else:
		velocity = Vector2.ZERO
		anim.play("run")  # Используем анимацию "idle" по умолчанию
	
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
	# Добавьте логику атаки игрока

func take_damage(amount: int):
	var actual_damage = max(amount - defense, 0)
	health -= actual_damage
	print("Враг получил", actual_damage, "урона. Осталось здоровья:", health)
	if health <= 0:
		die()

func die():
	print("Враг умер")
	queue_free()
	# Добавьте логику награды или других действий
	var player = get_node("/root/Game/Player")
	player.score += 10
	print("Награда получена: +10 очков")
	anim.play("death")  # Используем анимацию "death" при смерти
	self.collision_layer = 0
	self.collision_mask = 0
