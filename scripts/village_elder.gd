extends "res://scripts/npc.gd"

func setup_quests():
	var main_quests = [
		Quest.new(
			"Зачистка территории",
			"Уничтожьте 3 лагеря монстров",
			"clear_camps",
			3,
			400
		),
		Quest.new(
			"Поиск артефактов",
			"Найдите 3 древних артефакта",
			"find_artifacts",
			3,
			500
		),
		Quest.new(
			"Подготовка к подземелью",
			"Соберите ключ от подземелья",
			"prepare_dungeon",
			1,
			600
		)
	]
	available_quests = main_quests
