extends "res://scripts/enemy.gd"

# Фазы босса
enum BossPhase {PHASE_1, PHASE_2, PHASE_3}
var current_phase = BossPhase.PHASE_1

# Характеристики босса
var boss_speed = 60.0
const PHASE_THRESHOLD = 0.66  # 66% и 33% здоровья для смены фаз

# Способности
var dash_cooldown = 4.0
var current_dash_cooldown = 0.0
var is_dashing = false
var dash_speed = 300.0

var summon_cooldown = 8.0
var current_summon_cooldown = 0.0
var minion_scene = preload("res://scenes/enemy.tscn")

var aoe_attack_cooldown = 6.0
var current_aoe_cooldown = 0.0
var aoe_radius = 100.0

var shield_cooldown = 15.0
var current_shield_cooldown = 0.0
var shield_duration = 3.0
var has_shield = false

var knockback_distance = 150.0  # Расстояние отталкивания от игрока

# Новые переменные для способностей
var teleport_cooldown = 10.0
var current_teleport_cooldown = 0.0
var can_teleport = true

var flame_trail_cooldown = 7.0
var current_flame_trail_cooldown = 0.0
var flame_damage = 5

var rage_mode = false
var rage_duration = 8.0
var rage_cooldown = 20.0
var current_rage_cooldown = 0.0

# Добавляем новые переменные для эффектов
var effect_particles: CPUParticles2D
var aoe_circle: Node2D

# В начале файла добавим новые переменные
var minion_spawn_particles: CPUParticles2D
var aoe_particles: CPUParticles2D
var flame_particles: CPUParticles2D

func _ready():
	# Инициализация базовых характеристик
	max_health = 1200
	health = max_health
	attack_power = 15
	defense = 5
	min_distance = 30.0
	
	# Увеличиваем размер босса и его области агро
	scale = Vector2(2, 2)
	$AggroArea/CollisionShape2D.scale = Vector2(3, 3)  # Увеличиваем радиус агро
	
	# Сразу находим и устанавливаем цель (игрока)
	target = get_tree().get_nodes_in_group("player")[0]
	is_aggro = true  # Сразу активируем агро
	
	# Добавляем босса в группу
	add_to_group("boss")
	add_to_group("enemies")
	
	# Создаём частицы для эффектов
	setup_particles()
	setup_aoe_circle()
	setup_rage_particles()
	setup_all_particles()
	
	# Сразу проверяем призыв миньонов
	check_minion_spawn()

func setup_particles():
	effect_particles = CPUParticles2D.new()
	effect_particles.emitting = false
	effect_particles.amount = 20
	effect_particles.lifetime = 0.5
	effect_particles.explosiveness = 0.5
	effect_particles.direction = Vector2(0, -1)
	effect_particles.spread = 180
	effect_particles.gravity = Vector2(0, 0)
	effect_particles.initial_velocity_min = 50
	effect_particles.initial_velocity_max = 100
	add_child(effect_particles)

func setup_aoe_circle():
	aoe_circle = Node2D.new()
	add_child(aoe_circle)
	aoe_circle.visible = false

func setup_rage_particles():
	var rage_particles = CPUParticles2D.new()
	rage_particles.name = "RageParticles"
	rage_particles.emitting = false
	rage_particles.amount = 30
	rage_particles.lifetime = 0.5
	rage_particles.explosiveness = 0.2
	rage_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	rage_particles.emission_sphere_radius = 30.0
	rage_particles.direction = Vector2(0, -1)
	rage_particles.spread = 180
	rage_particles.gravity = Vector2(0, 0)
	rage_particles.initial_velocity_min = 50
	rage_particles.initial_velocity_max = 100
	rage_particles.color = Color(1, 0, 0, 0.5)  # Красные частицы для ярости
	add_child(rage_particles)

func setup_all_particles():
	# Частицы для призыва ми��ьонов (фиолетовые)
	minion_spawn_particles = CPUParticles2D.new()
	minion_spawn_particles.amount = 30
	minion_spawn_particles.lifetime = 0.5
	minion_spawn_particles.explosiveness = 0.8
	minion_spawn_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	minion_spawn_particles.emission_sphere_radius = 50.0
	minion_spawn_particles.color = Color(0.7, 0, 1, 1)
	add_child(minion_spawn_particles)
	
	# Частицы для АОЕ атаки (красные)
	aoe_particles = CPUParticles2D.new()
	aoe_particles.amount = 40
	aoe_particles.lifetime = 0.3
	aoe_particles.explosiveness = 1.0
	aoe_particles.spread = 180
	aoe_particles.color = Color(1, 0, 0, 1)
	add_child(aoe_particles)
	
	# Частицы для огненного следа (оранжевые)
	flame_particles = CPUParticles2D.new()
	flame_particles.amount = 20
	flame_particles.lifetime = 0.8
	flame_particles.color = Color(1, 0.5, 0, 1)
	add_child(flame_particles)

func _physics_process(delta):
	# Обработка уворота
	if should_dodge() and current_dodge_cooldown <= 0:
		start_dodge()
	
	if is_dodging:
		velocity = dodge_direction * DODGE_SPEED
		current_dodge_duration -= delta
		if current_dodge_duration <= 0:
			is_dodging = false
	elif knockback_timer > 0:
		knockback_timer -= delta
	elif is_aggro and target and not target.is_dead and not is_dashing:
		# Обработка движения и атак
		var direction = (target.global_position - global_position).normalized()
		var distance = global_position.distance_to(target.global_position)
		
		if distance > min_distance:
			velocity = direction * boss_speed
			if anim:
				anim.play("run")
				anim.flip_h = direction.x < 0
				
			# Проверяем возможность рывка
			if distance < 200 and current_dash_cooldown <= 0:
				perform_dash()
		else:
			velocity = Vector2.ZERO
			if current_cooldown <= 0:
				attack()
				current_cooldown = attack_cooldown
	
	# Обновляем кулдауны
	if current_dodge_cooldown > 0:
		current_dodge_cooldown -= delta
	if current_dash_cooldown > 0:
		current_dash_cooldown -= delta
	if current_cooldown > 0:
		current_cooldown -= delta
	
	move_and_slide()
	
	# Проверка призыва миньонов
	check_minion_spawn()

func check_phase():
	var health_percent = float(health) / max_health
	if health_percent <= 0.33 and current_phase != BossPhase.PHASE_3:
		enter_phase_3()
	elif health_percent <= 0.66 and current_phase == BossPhase.PHASE_1:
		enter_phase_2()

func take_damage(amount: int):
	if has_shield:
		amount = int(amount * 0.5)  # Щит блокирует 50% урона
	
	# Вызываем родительский метод take_damage
	super.take_damage(amount)
	
	# Активируем агро при получении урона
	if not is_aggro and target:
		is_aggro = true

func die():
	# Удаляем всех оставшихся миньонов
	for minion in get_tree().get_nodes_in_group("enemies"):
		if minion != self:
			minion.queue_free()
	
	# Даём больше опыта игроку
	var player = get_tree().get_nodes_in_group("player")[0]
	if player and player.has_method("gain_experience"):
		player.gain_experience(100)
		print("Босс побеждён! Награда: +100 опыта")
	
	super.die()

func perform_dash():
	if not target:
		return
		
	is_dashing = true
	current_dash_cooldown = dash_cooldown
	
	# Направление рывка к игроку
	var dash_direction = (target.global_position - global_position).normalized()
	velocity = dash_direction * dash_speed
	
	# Создаём урон во время рывка
	var dash_damage = attack_power * 1.5  # Увеличиваем урон от рывка
	
	# Эффект рывка
	effect_particles.emitting = true
	
	# Таймер для окончания рывка
	await get_tree().create_timer(0.3).timeout
	is_dashing = false
	effect_particles.emitting = false
	
	# Наносим урон, если попали по игроку
	if target and global_position.distance_to(target.global_position) < 50:
		target.take_damage(dash_damage)

func summon_minions():
	current_summon_cooldown = summon_cooldown
	
	# Эффект призыва
	minion_spawn_particles.emitting = true
	
	# Создаём 4 миньона вокруг босса
	for i in range(4):
		var minion = minion_scene.instantiate()
		var angle = TAU * i / 4  # Равномерно распределяем по кругу
		var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * 100
		
		# Настройка миньона
		
		minion.position = spawn_pos
		minion.health = 50
		minion.max_health = 50
		minion.attack_power = 8
		minion.defense = 2
		minion.min_distance = 30.0
		minion.knockback_strength = 8.0
		minion.attack_cooldown = 0.8
		minion.is_aggro = true
		minion.target = target
		minion.add_to_group("minions")
		
		# Добавляем миньона на сцену
		get_parent().call_deferred("add_child", minion)
		
		# Эффект появления
		var spawn_effect = CPUParticles2D.new()
		spawn_effect.position = spawn_pos
		spawn_effect.emitting = true
		spawn_effect.one_shot = true
		spawn_effect.amount = 15
		spawn_effect.lifetime = 0.5
		spawn_effect.explosiveness = 1.0
		spawn_effect.color = Color(0.5, 0, 1)
		get_parent().call_deferred("add_child", spawn_effect)
		
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	minion_spawn_particles.emitting = false

func perform_aoe_attack():
	current_aoe_cooldown = aoe_attack_cooldown
	
	# Создаём предупреждающий круг
	var warning_circle = Node2D.new()
	add_child(warning_circle)
	
	# Рисуем предупреждающий круг
	warning_circle.draw.connect(func():
		warning_circle.draw_circle(Vector2.ZERO, aoe_radius, Color(1, 0, 0, 0.3))
		warning_circle.draw_arc(Vector2.ZERO, aoe_radius, 0, TAU, 32, Color(1, 0, 0, 0.7), 2.0)
	)
	
	# Ждём перед атакой
	await get_tree().create_timer(0.5).timeout
	
	# Наносим урон
	if target and target.global_position.distance_to(global_position) < aoe_radius:
		target.take_damage(attack_power * 2)  # Увеличенный урон
	
	# Создаём эффект взрыва
	var explosion = CPUParticles2D.new()
	explosion.emitting = true
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.amount = 30
	explosion.lifetime = 0.5
	explosion.spread = 180
	explosion.initial_velocity_min = 100
	explosion.initial_velocity_max = 200
	explosion.color = Color(1, 0, 0)
	add_child(explosion)
	
	await get_tree().create_timer(0.5).timeout
	warning_circle.queue_free()
	explosion.queue_free()

func create_flame_trail():
	current_flame_trail_cooldown = flame_trail_cooldown
	
	for i in range(5):  # Создаём 5 точек огня
		var flame = Node2D.new()
		var pos = global_position - velocity.normalized() * (i * 30)  # Расстояние между точками
		flame.position = pos
		get_parent().add_child(flame)
		
		# Добавляем частицы огня
		var particles = CPUParticles2D.new()
		particles.amount = 20
		particles.lifetime = 0.8
		particles.explosiveness = 0.2
		particles.direction = Vector2.UP
		particles.spread = 180
		particles.initial_velocity_min = 50
		particles.initial_velocity_max = 80
		particles.color = Color(1, 0.5, 0)
		particles.emitting = true
		flame.add_child(particles)
		
		# Область повреждения
		var area = Area2D.new()
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20
		collision.shape = shape
		area.add_child(collision)
		flame.add_child(area)
		
		# Таймер для удаления
		await get_tree().create_timer(3.0).timeout
		flame.queue_free()

func activate_shield():
	current_shield_cooldown = shield_cooldown
	has_shield = true
	defense *= 3
	
	await get_tree().create_timer(shield_duration).timeout
	has_shield = false
	defense /= 3

func enter_phase_2():
	current_phase = BossPhase.PHASE_2
	attack_power *= 1.1
	boss_speed *= 1.2
	summon_minions()
	perform_aoe_attack()

func enter_phase_3():
	current_phase = BossPhase.PHASE_3
	attack_power *= 1.2
	boss_speed *= 1.3
	activate_shield()
	activate_rage()

func teleport_behind_player():
	if not target:
		return
		
	current_teleport_cooldown = teleport_cooldown
	var behind_position = target.global_position + (target.global_position - global_position).normalized() * 50
	global_position = behind_position
	perform_aoe_attack()  # Сразу делаем АОЕ атаку после телепорта

func activate_rage():
	current_rage_cooldown = rage_cooldown
	rage_mode = true
	attack_power *= 1.5
	boss_speed *= 1.3
	
	# Включаем частицы ярости
	$RageParticles.emitting = true
	
	# Призываем миньонов при входе в ярость
	if health < max_health * 0.5:
		summon_minions()
	
	await get_tree().create_timer(rage_duration).timeout
	rage_mode = false
	attack_power /= 1.5
	boss_speed /= 1.3
	$RageParticles.emitting = false

func check_minion_spawn():
	# Проверяем количество существующих миньонов
	var existing_minions = get_tree().get_nodes_in_group("minions").size()
	if existing_minions < 3 and current_summon_cooldown <= 0:
		call_deferred("summon_minions")  # Используем call_deferred