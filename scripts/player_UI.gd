extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var experience_bar: TextureProgressBar = $ExperienceBar
@onready var level_label: Label = $LevelContainer/LevelLabel
@onready var stats_label: Label = $StatsLabel
@onready var health_label: Label = $HealthLabel
@onready var experience_label: Label = $ExperienceLabel
@onready var coordinates_label: Label = $LocationsContainer/CoordinatesLabel
@onready var inventory = $Inventory
@onready var quest_list = $QuestUI/QuestList
@onready var quest_details = $QuestUI/QuestDetails
@onready var small_village_label: Label = $LocationsContainer/SmallVillageLabel
@onready var middle_village_label: Label = $LocationsContainer/MiddleVillageLabel
@onready var dungeon_label: Label = $LocationsContainer/DungeonLabel


func _ready():
	if inventory:
		inventory.visible = false
	else:
		print("Ошибка: узел Inventory не найден в Player_UI")
	
	get_tree().root.connect("size_changed", Callable(self, "_on_window_resize"))
	_on_window_resize()
	QuestManager.connect("quest_updated", _on_quest_updated)
	QuestManager.connect("quest_completed", _on_quest_completed)
	update_quest_list()
	
	# Ждем один кадр, чтобы убедиться что WorldGenerator инициализирован
	await get_tree().process_frame
	
	# Используем более гибкий поиск WorldGenerator
	var world_generator = find_world_generator()
	if world_generator:
		# Безопасное подключение сигнала
		if world_generator.has_signal("locations_updated"):
			world_generator.locations_updated.connect(update_locations_coordinates)
		# Обновляем текущие координаты
		update_locations_coordinates(
			world_generator.small_village_position,
			world_generator.middle_village_position,
			world_generator.walls_position
		)
	else:
		print("WorldGenerator не найден")

# Добавляем функцию для поиска WorldGenerator
func find_world_generator():
	# Пробуем разные пути
	var possible_paths = [
		"/root/World/WorldGenerator",
		"/root/Game/World/WorldGenerator",
		# Поиск по всем узлам в сцене
		"/root"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			if path == "/root":
				# Если ищем от корня, перебираем все узлы
				var world_gen = find_generator_in_children(node)
				if world_gen:
					return world_gen
			elif node.has_method("generate_world_data"):  # Проверяем что это точно WorldGenerator
				return node
	
	return null

# Рекурсивный поиск WorldGenerator среди всех узлов
func find_generator_in_children(node: Node) -> Node:
	for child in node.get_children():
		if child.has_method("generate_world_data"):
			return child
		var result = find_generator_in_children(child)
		if result:
			return result
	return null

func _process(_delta):
	# Обновляем координаты каждый кадр
	if get_parent():
		var pos = get_parent().position
		var tile_size = 32  # Размер одного тайла в пикселях
		var tile_x = int(pos.x / tile_size)
		var tile_y = int(pos.y / tile_size)
		if coordinates_label:
			coordinates_label.text = "Текущая позиция: (%d, %d)" % [tile_x, tile_y]

func _on_window_resize():
	# Получаем размер окна
	var window_size = get_viewport().get_visible_rect().size
	
	# Настраиваем позиции элементов UI относительно размера окна
	if health_bar:
		health_bar.position = Vector2(20, window_size.y - 120)
		health_bar.size.x = window_size.x * 0.25
	
	if experience_bar:
		experience_bar.position = Vector2(20, window_size.y - 60)
		experience_bar.size.x = window_size.x * 0.25
	
	# Размещаем статистику справа от хитбара с учетом масштаба
	if stats_label and health_bar:
		stats_label.position = Vector2(
			health_bar.position.x + (health_bar.size.x * 1.5) + 50,
			health_bar.position.y
		)
	
	# Остальные лейблы справа от соответствующих баро��
	if health_label and health_bar:
		health_label.position = Vector2(
			health_bar.position.x + (health_bar.size.x * 1.5) + 50,
			health_bar.position.y + 30
		)
	
	if experience_label and experience_bar:
		experience_label.position = Vector2(
			experience_bar.position.x + (experience_bar.size.x * 1.5) + 50,
			experience_bar.position.y + 20
		)
	
	# Обновляем позицию контейнера с координатами
	var locations_container = $LocationsContainer
	if locations_container:
		locations_container.position = Vector2(
			window_size.x - locations_container.size.x - 20,
			window_size.y - locations_container.size.y - 20
		)
	
	# Существующий код для инвентаря
	if inventory and inventory.visible:
		inventory.position = Vector2(
			(window_size.x - inventory.size.x) / 2,
			(window_size.y - inventory.size.y) / 2
		)

func update_ui(player_data: Dictionary):
	animate_value(health_bar, player_data.health)
	health_bar.max_value = player_data.max_health
	
	var experience_needed = player_data.level * 100
	animate_value(experience_bar, player_data.experience)
	experience_bar.max_value = experience_needed
	
	level_label.text = str(player_data.level)
	stats_label.text = "Атака: " + str(player_data.attack_power) + " | Защита: " + str(player_data.defense)
	health_label.text = str(player_data.health) + " / " + str(player_data.max_health)
	experience_label.text = str(player_data.experience) + " / " + str(experience_needed)

func animate_value(progress_bar: TextureProgressBar, target_value: float):
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func toggle_inventory():
	if inventory:
		inventory.visible = !inventory.visible
		if inventory.visible:
			_on_window_resize() # Обновляем позицию инвентаря при открытии
		print("идимость инвентаря изменена на: ", inventory.visible)
	else:
		print("Ошибка: узел инвентаря не найден в Player_UI")

func show_tooltip(item):
	var tooltip = $Tooltip
	tooltip.text = item.description
	tooltip.visible = true
	# Адаптивное позиционирование подсказки
	var mouse_pos = get_viewport().get_mouse_position()
	var window_size = get_viewport().get_visible_rect().size
	var tooltip_pos = mouse_pos + Vector2(10, 10)
	
	# Проверяем, не выхо��ит ли подсказка за пределы экрана
	if tooltip_pos.x + tooltip.size.x > window_size.x:
		tooltip_pos.x = mouse_pos.x - tooltip.size.x - 10
	if tooltip_pos.y + tooltip.size.y > window_size.y:
		tooltip_pos.y = mouse_pos.y - tooltip.size.y - 10
		
	tooltip.position = tooltip_pos

func hide_tooltip():
	$Tooltip.visible = false

func _on_inventory_item_used(item_name):
	var player = get_parent()
	player.use_item(item_name)

func _on_inventory_item_equipped(item_name, slot):
	var player = get_parent()
	var item_resource = player.item_database.get_item(item_name)
	if item_resource:
		if slot == "weapon":
			player.equip_weapon(item_resource)
		elif slot == "armor":
			player.equip_armor(item_resource)

func update_quest_list():
	quest_list.clear()
	for quest in QuestManager.active_quests:
		quest_list.add_item(quest.title)

func _on_quest_updated(quest):
	update_quest_list()
	update_quest_details(quest)

func _on_quest_completed(quest):
	update_quest_list()
	# Показываем уведомление о завершении квеста
	show_completion_notification(quest)

func update_quest_details(quest):
	var details_text = """
	{title}
	
	{description}
	
	Прогресс: {progress}
	Награда: {reward} опыта
	""".format({
		"title": quest.title,
		"description": quest.description,
		"progress": quest.get_progress_text(),
		"reward": quest.reward_exp
	})
	
	quest_details.text = details_text

func show_completion_notification(quest):
	# Здесь можно добавить анимацию или всплывающее окно
	print("Квест выполнен:", quest.title)

func toggle_talents():
	var talent_tree = $TalentTree
	if talent_tree:
		talent_tree.get_node("Control").toggle_visibility()
	else:
		print("Ошибка: окно талантов не найдено")

func update_locations_coordinates(small_village: Vector2, middle_village: Vector2, dungeon: Vector2):
	var tile_size = 32  # Размер тайла
	
	if small_village_label:
		var small_pos = Vector2(int(small_village.x / tile_size), int(small_village.y / tile_size))
		small_village_label.text = "Маленькая деревня: (%d, %d)" % [small_pos.x, small_pos.y]
	
	if middle_village_label:
		var middle_pos = Vector2(int(middle_village.x / tile_size), int(middle_village.y / tile_size))
		middle_village_label.text = "Средняя деревня: (%d, %d)" % [middle_pos.x, middle_pos.y]
	
	if dungeon_label:
		# Если координаты не установлены (0,0), используем значения по умолчанию
		var dungeon_pos = Vector2(512, 512)
		if dungeon != Vector2.ZERO:
			dungeon_pos = Vector2(int(dungeon.x / tile_size), int(dungeon.y / tile_size))
		dungeon_label.text = "Подземелье: (%d, %d)" % [dungeon_pos.x, dungeon_pos.y]
