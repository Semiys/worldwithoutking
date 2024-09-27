extends CharacterBody2D

const SPEED = 40.0
var health = 50
var attack_power = 5
var defense = 2
var target = null

@onready var anim = $AnimatedSprite2D

func _ready():
	target = get_node("/root/Game/Player")  # Укажите путь до узла игрока

func _physics_process(delta):
	if target:
		var direction = (target.position - position).normalized()
		velocity = direction * SPEED
		anim.play("run")
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		velocity = Vector2.ZERO
		if "Idle" in anim.get_animation_names():
			anim.play("Idle")
		else:
			anim.play("run")  # Используйте существующую анимацию в качестве резервной
	move_and_slide()

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
	if "run" in anim.get_animation_names():
		anim.play("run")
	else:
		print("Анимация 'run' отсутствует. Используется 'Idle' по умолчанию.")
		if "Idle" in anim.get_animation_names():
			anim.play("Idle")
		else:
			print("Анимация 'Idle' также отсутствует.")
			self.collision_layer = 0
			self.collision_mask = 0
