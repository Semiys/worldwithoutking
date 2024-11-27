extends Control

var talent_points = 0
var talents = {
	"health": {
		"name": "Здоровье",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.max_health += 20
	},
	"attack": {
		"name": "Сила атаки",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.base_attack_power += 5
	},
	"defense": {
		"name": "Защита",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.defense += 2
	},
	"speed": {
		"name": "Скорость",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.speed += 10
	},
	"crit_chance": {
		"name": "Шанс крита",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.crit_chance += 5
	},
	"crit_damage": {
		"name": "Урон крита",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.crit_damage += 10
	},
	"dodge_chance": {
		"name": "Уклонение",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.dodge_chance += 3
	},
	"life_steal": {
		"name": "Вампиризм",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.life_steal += 2
	},
	"cooldown_reduction": {
		"name": "Сокращение перезарядки",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.cooldown_reduction += 4
	},
	"mana_regen": {
		"name": "Восст. маны",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.mana_regen += 1
	},
	"armor_penetration": {
		"name": "Пробивание брони",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.armor_penetration += 3
	},
	"magic_resistance": {
		"name": "Маг. сопротивление",
		"level": 0,
		"max_level": 5,
		"cost": 1,
		"effect": func(player): player.magic_resistance += 3
	}
}

@onready var points_label = $Panel/VBoxContainer/PointsLabel
@onready var talent_grid = $Panel/VBoxContainer/ScrollContainer/TalentGrid

func _ready():
	create_talent_buttons()
	update_points_label()

func create_talent_buttons():
	for talent_id in talents.keys():
		var talent = talents[talent_id]
		
		# Создаём контейнер для кнопки
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(500, 60)
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Создаём кнопку
		var button = Button.new()
		button.custom_minimum_size = Vector2(120, 40)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Настраиваем стиль кнопки
		var normal_style = StyleBoxFlat.new()
		
		normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
		normal_style.border_width_left = 1
		normal_style.border_width_right = 1
		
		normal_style.border_width_top = 1
		normal_style.border_width_bottom = 1
		
		normal_style.border_color = Color(0.5, 0.5, 0.5)
		normal_style.corner_radius_top_left = 3
		normal_style.corner_radius_top_right = 3
		
		normal_style.corner_radius_bottom_left = 3
		normal_style.corner_radius_bottom_right = 3
		
		button.add_theme_stylebox_override("normal", normal_style)
		
		# Создаём метки
		var info_container = VBoxContainer.new()
		info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_container.custom_minimum_size = Vector2(350, 0)
		
		# Добавляем отступы для контейнера с информацией
		var margin_container = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 20)  # Отступ слева
		margin_container.add_theme_constant_override("margin_right", 10) # Отступ справа
		margin_container.add_theme_constant_override("margin_top", 5)    # Отступ сверху
		margin_container.add_theme_constant_override("margin_bottom", 5) # Отступ снизу
		
		var name_label = Label.new()
		name_label.text = talent.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		name_label.add_theme_font_size_override("font_size", 16)
		
		var level_label = Label.new()
		level_label.text = "Уровень: %d/%d" % [talent.level, talent.max_level]
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		level_label.add_theme_font_size_override("font_size", 14)
		
		# Добавляем элементы в контейнеры
		info_container.add_child(name_label)
		info_container.add_child(level_label)
		
		margin_container.add_child(info_container)  # Помещаем info_container внутрь margin_container
		container.add_child(margin_container)       # Добавляем margin_container вместо info_container
		container.add_child(button)
		
		# Добавляем контейнер в сетку
		talent_grid.add_child(container)
		
		# Подключаем сигнал нажатия
		button.connect("pressed", Callable(self, "_on_talent_button_pressed").bind(talent_id))
		button.text = "Улучшить"

func _on_talent_button_pressed(talent_id):
	var talent = talents[talent_id]
	if talent_points > 0 and talent.level < talent.max_level:
		talent.level += 1
		talent_points -= talent.cost
		update_talent_button(talent_id)
		update_points_label()
		apply_talent_effect(talent_id)

func update_talent_button(talent_id):
	var talent = talents[talent_id]
	var container = talent_grid.get_child(get_talent_button_index(talent_id))
	
	# Находим VBoxContainer с метками внутри MarginContainer
	var margin_container = container.get_child(0)  # Первый ребенок - MarginContainer
	var info_container = margin_container.get_child(0)  # Первый ребенок MarginContainer - VBoxContainer
	var level_label = info_container.get_child(1)  # Второй ребенок VBoxContainer - метка уровня
	
	level_label.text = "Уровень: %d/%d" % [talent.level, talent.max_level]

func get_talent_button_index(talent_id):
	var index = talents.keys().find(talent_id)
	return index if index != -1 else 0

func update_points_label():
	points_label.text = "Доступные очки талантов: %d" % talent_points

func apply_talent_effect(talent_id):
	var talent = talents[talent_id]
	var player = get_tree().get_first_node_in_group("player")
	if player:
		talent.effect.call(player)
		player.update_ui()

func toggle_visibility():
	visible = !visible

func add_talent_point():
	talent_points += 1
	update_points_label() 
