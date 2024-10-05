extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var experience_bar: ProgressBar = $ExperienceBar
@onready var level_label: Label = $LevelLabel
@onready var stats_label: Label = $StatsLabel
@onready var health_label: Label = $HealthLabel
@onready var experience_label: Label = $ExperienceLabel
@onready var inventory = $Inventory

func _ready():
	if inventory:
		inventory.visible = false
	else:
		print("Ошибка: узел Inventory не найден в Player_UI")

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
		print("Видимость инвентаря изменена на: ", inventory.visible)
	else:
		print("Ошибка: узел инвентаря не найден в Player_UI")

func show_tooltip(item):
	var tooltip = $Tooltip
	tooltip.text = item.description
	tooltip.visible = true
	tooltip.position = get_viewport().get_mouse_position() + Vector2(10, 10)

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
