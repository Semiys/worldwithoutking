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

func update_quest_progress(quest_type: String, amount: int = 1):
	for quest in active_quests:
		if quest.type == quest_type:
			quest.current_progress += amount
			emit_signal("quest_updated", quest)
			print("Обновлен прогресс квеста:", quest.title, "-", quest.current_progress, "/", quest.objective_count)
			
			if quest.is_completed():
				complete_quest(quest)

func complete_quest(quest):
	if quest in active_quests:
		active_quests.erase(quest)
		emit_signal("quest_completed", quest)
		print("Квест выполнен:", quest.title)
		
		# Выдаём награду только при сдаче квеста NPC
		var player = get_tree().get_nodes_in_group("player")[0]
		if player:
			player.gain_experience(quest.reward_exp)
			print("Награда получена:", quest.reward_exp, "опыта")
	
	# Выдаём награду
	var player = get_tree().get_nodes_in_group("player")[0]
	if player:
		player.gain_experience(quest.reward_exp) 
