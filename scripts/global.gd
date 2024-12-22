extends Node

func _ready():
	# Загружаем и устанавливаем курсор
	var cursor = load("res://assets/mouse_cursor/01.png")
	Input.set_custom_mouse_cursor(cursor) 
