extends StaticBody2D

signal target_destroyed

@export var health: int = 3
@onready var collision = $CollisionShape2D
@onready var particles = $DestroyParticles
@onready var tilemap = $TileMapLayer
@onready var hitbox = $HitBox

func _ready():
	add_to_group("target")
	particles.emitting = false
	# Настраиваем коллизии
	collision_layer = 1  # Слой 1 для физической коллизии с игроком
	collision_mask = 1   # Маска 1 для физической коллизии с игроком
	
	# Настраиваем маску коллизии для получения атак
	hitbox.collision_layer = 4  # layer 3 для атак
	hitbox.collision_mask = 2   # layer 2 для атак игрока
	hitbox.monitorable = true   # Включаем мониторинг
	hitbox.monitoring = true    # Включаем мониторинг

func take_damage(damage: int):
	print("Мишень получила урон:", damage)  # Отладочный вывод
	health -= damage
	
	# Анимация получения урона
	var tween = create_tween()
	tween.tween_property(tilemap, "modulate", Color.RED, 0.1)
	tween.tween_property(tilemap, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		destroy()

func destroy():
	print("Мишень уничтожена")  # Отладочный вывод
	# Отключаем коллизию
	collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	
	# Запускаем частицы
	particles.emitting = true
	
	# Сигналим о уничтожении
	emit_signal("target_destroyed")
	
	# Обновляем прогресс квеста
	if QuestManager:
		QuestManager.update_quest_progress("kill_dummy", 1, "kill_dummy")
		print("Прогресс квеста обновлен")  # Отладочный вывод
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(tilemap, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_area_entered(area):
	var player = area.get_parent()
	if player.is_in_group("player"):
		print("Атака игрока попала в мишень")  # Отладочный вывод
		var damage = 1  # Значение по умолчанию
		if player.has_method("get_attack_power"):
			damage = player.get_attack_power()
		take_damage(damage)
