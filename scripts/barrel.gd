extends StaticBody2D

signal barrel_exploded

@onready var tilemap = $TileMapLayer

@onready var interaction_area = $InteractionArea
@onready var explosion_particles = $ExplosionParticles

var can_be_ignited = true

func _ready():
	add_to_group("barrels")

func ignite():
	if can_be_ignited:
		can_be_ignited = false
		
		# Запускаем эффекты взрыва
		explosion_particles.emitting = true
		
		# Наносим урон всем врагам в радиусе
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 100: # Радиус взрыва
				enemy.queue_free()
		
		# Наносим урон игроку если он в радиусе взрыва
		var current_player = get_tree().get_first_node_in_group("player")
		if current_player:
			var distance = global_position.distance_to(current_player.global_position)
			if distance < 100: # Тот же радиус взрыва
				var damage = int(current_player.max_health * 0.3) # 30% от максимального здоровья
				current_player.take_damage(damage)
		
		# Анимация исчезновения бочки
		var tween = create_tween()
		tween.tween_property(tilemap, "modulate", Color(1,1,1,0), 0.5)
		
		# Сигнализируем о взрыве
		emit_signal("barrel_exploded")
		
		# Создаём эффект встряски камеры
		var camera_player = get_tree().get_first_node_in_group("player")
		if camera_player:
			var camera = camera_player.get_node("Camera2D")
			if camera:
				# Используем встроенные свойства камеры для тряски
				var shake_tween = create_tween()
				shake_tween.tween_property(camera, "offset", Vector2(15, 15), 0.1)
				shake_tween.tween_property(camera, "offset", Vector2(-15, -15), 0.1)
				shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
			
		# Ждем окончания партиклей и удаляем бочку
		await get_tree().create_timer(1.0).timeout
		queue_free() 
