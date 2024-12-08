extends "res://scripts/chest.gd"  # Наследуемся от базового скрипта сундука

func _ready():
	super._ready()  # Вызываем _ready() базового класса
	add_to_group("enemy_camp_chests")

func interact(player):
	if not is_open:
		is_open = true
		if sprite and sprite.sprite_frames:
			sprite.play("opened")
		
		items.clear()
		# Всегда добавляем факел
		items.append("Факел")
		
		# Добавляем 1-2 случайных предмета
		var item_count = randi() % 2 + 1
		
		# Список предметов для вражеского сундука
		var camp_possible_items = [
			["Зелье здоровья", 40],
			["Кожаная броня", 15],
			["Железный меч", 10],
			["Кольцо исцеления", 15]
		]
		
		for i in item_count:
			var total_weight = 0
			for item in camp_possible_items:
				total_weight += item[1]
			
			var roll = randi() % total_weight
			var current_weight = 0
			
			for item in camp_possible_items:
				current_weight += item[1]
				if roll < current_weight:
					items.append(item[0])
					break
		
		drop_items()
