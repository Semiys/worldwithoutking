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
