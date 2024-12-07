extends "res://scripts/chest.gd"  # Наследуемся от базового скрипта сундука

func _ready():
	super._ready()  # Вызываем _ready() базового класса
	add_to_group("enemy_camp_chests")
	# Добавляем факел в список предметов
	items.append("Факел")

func interact(player):
	if not is_open:
		is_open = true
		if sprite and sprite.sprite_frames:
			sprite.play("opened")
		drop_items()
