extends CanvasLayer

var health_bar: ProgressBar
var experience_bar: ProgressBar
var level_label: Label
var stats_label: Label
var health_label: Label
var experience_label: Label

func _ready():
	create_ui_elements()

func create_ui_elements():
	health_bar = create_progress_bar(Vector2(10, 10), Vector2(200, 20), Color.RED)
	experience_bar = create_progress_bar(Vector2(10, 40), Vector2(200, 10), Color.BLUE)
	
	level_label = create_label(Vector2(220, 10))
	stats_label = create_label(Vector2(10, 60))
	health_label = create_label(Vector2(10, 30))
	experience_label = create_label(Vector2(10, 50))

func create_progress_bar(position: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	add_child(bar)
	bar.set_position(position)
	bar.set_size(size)
	bar.set("theme_override_styles/fill", StyleBoxFlat.new())
	bar.get("theme_override_styles/fill").set_bg_color(color)
	return bar

func create_label(position: Vector2) -> Label:
	var label = Label.new()
	add_child(label)
	label.set_position(position)
	return label

func update_ui(player_data: Dictionary):
	health_bar.value = player_data.health
	health_bar.max_value = player_data.max_health
	
	var experience_needed = player_data.level * 100
	experience_bar.value = player_data.experience
	experience_bar.max_value = experience_needed
	
	level_label.text = "Уровень: " + str(player_data.level)
	stats_label.text = "Атака: " + str(player_data.attack_power) + " | Защита: " + str(player_data.defense)
	health_label.text = str(player_data.health) + " / " + str(player_data.max_health)
	experience_label.text = str(player_data.experience) + " / " + str(experience_needed)
