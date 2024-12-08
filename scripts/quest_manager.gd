extends Node

signal quest_updated(quest)
signal quest_completed(quest)

var active_quests = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_quest(quest):
	active_quests.append(quest)
	emit_signal("quest_updated", quest)
	print("Добавлен новый квест:", quest.title)

func update_quest_progress(quest_type: String, amount: int = 1, specific_target: String = ""):
	for quest in active_quests:
		if quest.type == quest_type:
			match quest.type:
				"kill_dummy":
					if specific_target == quest.type:
						quest.current_progress += amount
						print("Обновлен прогресс квеста манекенов:", quest.current_progress, "/", quest.objective_count)
				"kill_weak", "clear_first_hall", "kill_boss":
					if specific_target == quest.type:
						quest.current_progress += amount
				"clear_camps":
					quest.current_progress += amount
					print("Обновлен прогресс уничтожения лагерей:", quest.current_progress, "/", quest.objective_count)
				"find_artifacts", "solve_puzzles":
					quest.current_progress += amount
				"reach_village", "prepare_dungeon":
					if specific_target == quest.type:
						quest.current_progress = quest.objective_count
			
			emit_signal("quest_updated", quest)
			if quest.check_completed():
				complete_quest(quest)

func complete_quest(quest):
	if quest in active_quests:
		active_quests.erase(quest)
		emit_signal("quest_completed", quest)
		print("Квест выполнен:", quest.title)
		

		# Выдаём награду только один раз

		# Выдаём награду

		var player = get_tree().get_nodes_in_group("player")[0]
		if player:
			player.gain_experience(quest.reward_exp)
			print("Награда получена:", quest.reward_exp, "опыта")
	
	# Удаляем дублирующийся код выдачи награды
