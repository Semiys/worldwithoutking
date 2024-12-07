extends "res://scripts/npc.gd"

func _ready():
    npc_type = "tutorial_master"
    super._ready()

func setup_quests():
    var tutorial_quests = [
        Quest.new(
            "Основы боя",
            "Уничтожьте 5 тренировочных манекенов",
            "kill_dummy",
            5,
            100
        ),
        Quest.new(
            "Первая охота",
            "Победите 3 слабых монстров",
            "kill_weak",
            3,
            200
        ),
        Quest.new(
            "Путь в большую деревню",
            "Доберитесь до большой деревни",
            "reach_village",
            1,
            300
        )
    ]
    available_quests = tutorial_quests