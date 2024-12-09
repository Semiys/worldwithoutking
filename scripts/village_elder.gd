extends "res://scripts/npc.gd"

func _ready():
	npc_type = "village_elder"
	super._ready()

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

func start_dialog():
	# Сначала проверяем квест встречи
	for quest in QuestManager.active_quests:
		if quest.type == "meet_elder":
			QuestManager.update_quest_progress("meet_elder", 1, "meet_elder")
			break
	
	# Вызываем оригинальный метод для показа диалога и квестов
	super.start_dialog()

func can_take_quests() -> bool:
	# Проверяем, есть ли активные квесты
	if QuestManager.active_quests.size() > 0:
		for quest in QuestManager.active_quests:
			# Разрешаем брать новые квесты, если текущий квест - meet_elder
			if quest.type == "meet_elder":
				return true
		return false
	
	return true
