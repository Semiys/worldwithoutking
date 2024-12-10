extends "res://scripts/npc.gd"

func _ready():
	npc_type = "dungeon_keeper"
	super._ready()

func setup_quests():
	var dungeon_quests = [
		Quest.new(
			"Зал испытаний",
			"Уничтожьте 30 монстров в первом зале",
			"clear_first_hall",
			30,
			700
		),
		Quest.new(
			"Древние загадки",
			"Решите все загадки во втором зале",
			"solve_puzzles",
			3,
			800
		),
		Quest.new(
			"Финальная битва",
			"Победите босса подземелья",
			"kill_boss",
			1,
			1000
		)
	]
	
	available_quests = dungeon_quests

func can_take_quests() -> bool:
	# Проверяем, выполнил ли игрок все квесты старейшины
	var elder_quests_completed = true
	var required_quests = ["clear_camps", "find_artifacts", "prepare_dungeon"]
	
	for quest in QuestManager.active_quests:
		if quest.type in required_quests:
			elder_quests_completed = false
			break
	
	# Проверяем, есть ли активные квесты подземелья
	var has_active_dungeon_quests = false
	for quest in QuestManager.active_quests:
		if quest.type in ["clear_first_hall", "solve_puzzles", "kill_boss"]:
			has_active_dungeon_quests = true
			break
	
	# Разрешаем брать квесты только если выполнены квесты старейшины
	# и нет активных квестов подземелья
	return elder_quests_completed and not has_active_dungeon_quests

func start_dialog():
	if not can_take_quests():
		print("Сначала выполните все задания старейшины деревни.")
		return
	
	super.start_dialog()
