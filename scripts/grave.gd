extends Node2D

@export var enemy_scene: PackedScene
const SPAWN_INTERVAL = 10.0  # Интервал спавна врагов в секундах
const MAX_ENEMIES = 6  # Максимальное количество врагов
const SPAWN_RADIUS = 50  # Радиус спавна врагов вокруг надгробия

var current_enemies = 0
var spawn_timer = 0.0

# Ссылки на тайлмапы
@onready var ground_tilemap = $Ground
@onready var decoration_tilemap = $Decoration

func _ready():
	spawn_timer = SPAWN_INTERVAL
	
	# Добавляем коллизию под размер 5x5
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(160, 160)  # Для области 5x5 тайлов (32*5)
	collision.shape = shape
	add_child(collision)

func _process(delta):
	if current_enemies < MAX_ENEMIES:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_enemy()
			spawn_timer = SPAWN_INTERVAL

func spawn_enemy():
	if current_enemies >= MAX_ENEMIES:
		return
		
	var enemy = enemy_scene.instantiate()
	
	# Генерируем случайную позицию в круге вокруг надгробия
	var random_angle = randf() * 2 * PI
	var random_radius = randf() * SPAWN_RADIUS
	var spawn_pos = Vector2(
		cos(random_angle) * random_radius,
		sin(random_angle) * random_radius
	)
	
	enemy.position = position + spawn_pos
	get_parent().add_child(enemy)
	current_enemies += 1
	
	# Подключаем сигнал удаления врага
	enemy.tree_exiting.connect(_on_enemy_died)

func _on_enemy_died():
	current_enemies -= 1 
