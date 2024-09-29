extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var experience_bar: ProgressBar = $ExperienceBar
@onready var level_label: Label = $LevelLabel
@onready var stats_label: Label = $StatsLabel
@onready var health_label: Label = $HealthLabel
@onready var experience_label: Label = $ExperienceLabel

func _ready():
	# 1. Настройка HealthBar:
	#health_bar.set("theme_override_styles/fill", load("res://resources/health_bar_fg.tres"))
	#health_bar.set("theme_override_styles/background", load("res://resources/health_bar_bg.tres"))

	# 2. Настройка ExperienceBar:
	#experience_bar.set("theme_override_styles/fill", load("res://resources/exp_bar_fg.tres"))
	#experience_bar.set("theme_override_styles/background", load("res://resources/exp_bar_bg.tres"))

	# 3. Настройка меток:
	#var main_font = load("res://resources/main_font.tres")
	#level_label.set("theme_override_fonts/font", main_font)
	#stats_label.set("theme_override_fonts/font", main_font)
	#health_label.set("theme_override_fonts/font", main_font)
	#experience_label.set("theme_override_fonts/font", main_font)

	# 4. Добавление иконок:
	#var health_icon = TextureRect.new()
	#health_icon.texture = load("res://assets/icons/health_icon.png")
	#add_child(health_icon)
	#health_icon.position = Vector2(10, 10)  # Настройте позицию

	#var exp_icon = TextureRect.new()
	#exp_icon.texture = load("res://assets/icons/exp_icon.png")
	#add_child(exp_icon)
	#exp_icon.position = Vector2(10, 40)  # Настройте позицию
	pass

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
