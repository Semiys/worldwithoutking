extends Node2D

# Базовое разрешение
var base_width = 1280
var base_height = 720

# Настройки масштабирования
var min_scale = 0.5
var max_scale = 2.0
var current_scale = 1.0

# Ссылки на узлы
@onready var button_container = $CanvasLayer/ButtonContainer
@onready var background = $CanvasLayer/Background

func _ready():
	# Инициализация окна
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Настройка масштабирования
	update_ui_scale()
	get_viewport().size_changed.connect(update_ui_scale)
	
	# Настройка анимации кнопок
	setup_button_animations()

func setup_button_animations():
	for button in button_container.get_children():
		if button is Button:
			# Подключаем сигналы кнопок только один раз
			if not button.pressed.is_connected(_on_play_pressed) and button.name == "Play":
				button.pressed.connect(_on_play_pressed)
			elif not button.pressed.is_connected(_on_settings_pressed) and button.name == "Settings":
				button.pressed.connect(_on_settings_pressed)
			elif not button.pressed.is_connected(_on_quit_pressed) and button.name == "Quit":
				button.pressed.connect(_on_quit_pressed)
				
			button.mouse_entered.connect(
				func(): animate_button_hover(button, true))
			button.mouse_exited.connect(
				func(): animate_button_hover(button, false))

func animate_button_hover(button: Button, is_hover: bool):
	var tween = create_tween()
	var target_scale = 1.1 if is_hover else 1.0
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.1)

func update_ui_scale():
	var window_size = DisplayServer.window_get_size()
	var scale_factor = min(
		window_size.x / base_width,
		window_size.y / base_height
	)
	
	# Ограничиваем масштаб
	scale_factor = clamp(scale_factor, min_scale, max_scale)
	current_scale = scale_factor
	
	# Обновляем размеры шрифта
	update_font_sizes(scale_factor)
	
	# Обновляем размеры контейнера
	update_container_sizes(scale_factor)

func update_font_sizes(scale_factor: float):
	for button in button_container.get_children():
		if button is Button:
			var base_size = 32
			var scaled_size = int(base_size * scale_factor)
			button.add_theme_font_size_override("font_size", scaled_size)
			button.add_theme_font_size_override("hover_font_size", 
				int(scaled_size * 1.1))

func update_container_sizes(scale_factor: float):
	var base_container_size = Vector2(300, 400)
	var scaled_size = base_container_size * scale_factor
	button_container.custom_minimum_size = scaled_size
	
	for button in button_container.get_children():
		if button is Button:
			var base_button_size = Vector2(200, 50)
			button.custom_minimum_size = base_button_size * scale_factor

func _on_play_pressed():
	# Добавляем анимацию перехода
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(
		func(): get_tree().change_scene_to_file("res://scenes/game.tscn"))

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
	# Добавляем анимацию выхода
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().quit())
	
