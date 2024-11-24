extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var experience_bar: ProgressBar = $ExperienceBar
@onready var level_label: Label = $LevelLabel
@onready var stats_label: Label = $StatsLabel
@onready var health_label: Label = $HealthLabel
@onready var experience_label: Label = $ExperienceLabel
@onready var inventory = $Inventory
@onready var quest_list = $QuestUI/QuestList
@onready var quest_details = $QuestUI/QuestDetails

func _ready():
	if inventory:
		inventory.visible = false
	else:
		print("Ошибка: узел Inventory не найден в Player_UI")
	# Подписываемся на изменение размера окна
	get_tree().root.connect("size_changed", Callable(self, "_on_window_resize"))
	# Инициализируем начальное положение UI
	_on_window_resize()
	QuestManager.connect("quest_updated", _on_quest_updated)
	QuestManager.connect("quest_completed", _on_quest_completed)
	update_quest_list()

func _on_window_resize():
	# Получаем размер окна
	var window_size = get_viewport().get_visible_rect().size
	
	# Настраиваем позиции элементов UI относительно размера окна
	health_bar.position = Vector2(20, window_size.y - 100)
	health_bar.size.x = window_size.x * 0.2
	
	experience_bar.position = Vector2(20, window_size.y - 60)
	experience_bar.size.x = window_size.x * 0.2
	
	level_label.position = Vector2(20, 20)
	stats_label.position = Vector2(window_size.x - 200, 20)
	health_label.position = Vector2(health_bar.position.x + health_bar.size.x + 10, health_bar.position.y)
	experience_label.position = Vector2(experience_bar.position.x + experience_bar.size.x + 10, experience_bar.position.y)
	
	if inventory and inventory.visible:
		# Центрируем инвентарь
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
	
	level_label.text = "Уровень: " + str(player_data.level)
	stats_label.text = "Атака: " + str(player_data.attack_power) + " | Защита: " + str(player_data.defense)
	health_label.text = str(player_data.health) + " / " + str(player_data.max_health)
	experience_label.text = str(player_data.experience) + " / " + str(experience_needed)

func animate_value(progress_bar: ProgressBar, target_value: float):
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func toggle_inventory():
	if inventory:
		inventory.visible = !inventory.visible
		if inventory.visible:
			_on_window_resize() # Обновляем позицию инвентаря при открытии
		print("Видимость инвентаря изменена на: ", inventory.visible)
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
	
	# Проверяем, не выходит ли подсказка за пределы экрана
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
