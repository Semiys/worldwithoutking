extends Node2D

signal camp_destroyed

@export var enemy_scene: PackedScene
const MAX_ENEMIES = 4
const SPAWN_INTERVAL = 5.0
const SPAWN_RADIUS = 50.0

var is_destroyed = false
var enemies_spawned = []
var barrel_count = 0
var spawn_timer = 0.0

func _ready():
    # Подключаем сигналы от всех бочек
    for barrel in get_tree().get_nodes_in_group("barrels"):
        if barrel.get_parent() == self:  # Проверяем, что бочка принадлежит этому лагерю
            barrel.connect("barrel_exploded", _on_barrel_exploded)
            barrel_count += 1
    
    spawn_timer = SPAWN_INTERVAL

func _process(delta):
    if not is_destroyed and enemies_spawned.size() < MAX_ENEMIES:
        spawn_timer -= delta
        if spawn_timer <= 0:
            spawn_enemy()
            spawn_timer = SPAWN_INTERVAL

func spawn_enemy():
    if enemy_scene and enemies_spawned.size() < MAX_ENEMIES:
        var enemy = enemy_scene.instantiate()
        
        # Генерируем случайную позицию в круге
        var random_angle = randf() * 2 * PI
        var random_radius = randf() * SPAWN_RADIUS
        var spawn_pos = Vector2(
            cos(random_angle) * random_radius,
            sin(random_angle) * random_radius
        )
        
        enemy.position = position + spawn_pos
        get_parent().add_child(enemy)
        
        # Добавляем врага в список и подключаем сигнал его уничтожения
        enemies_spawned.append(enemy)
        enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy):
    enemies_spawned.erase(enemy)

func _on_barrel_exploded():
    barrel_count -= 1
    if barrel_count <= 0:
        destroy_camp()

func destroy_camp():
    if not is_destroyed:
        is_destroyed = true
        
        # Уничтожаем всех врагов
        for enemy in enemies_spawned:
            if is_instance_valid(enemy):
                enemy.queue_free()
        
        # Обновляем прогресс квеста
        QuestManager.update_quest_progress("destroy_camp")
        
        # Запускаем эффекты уничтожения
        var tween = create_tween()
        tween.tween_property(self, "modulate", Color(1,1,1,0), 2.0)
        await tween.finished
        
        emit_signal("camp_destroyed")
        queue_free() 