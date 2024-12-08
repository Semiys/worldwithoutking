extends CharacterBody2D

signal dialog_finished

var dialog_active = false
var current_quest = null
var available_quests = []
var player = null
var dialog_index = 0
var current_dialog = []
var completed_quests = []
var given_quests = []
var npc_type = "base"

@onready var dialog_box = $DialogBox
@onready var dialog_text = $DialogBox/DialogText
@onready var interaction_area = $InteractionArea
@onready var interaction_prompt = $InteractionPrompt

func can_take_quests() -> bool:
	# Проверяем, есть ли уже активные квесты
	if QuestManager.active_quests.size() > 0:
		return false
		
	# Проверяем тип NPC и необходимые условия
	match npc_type:
		"village_elder":
			# Проверяем, завершены ли все квесты tutorial_master
			var tutorial_quests = ["kill_dummy", "kill_weak", "reach_village"]
			for quest_type in tutorial_quests:
				if not quest_type in completed_quests:
					return false
					
		"dungeon_keeper":
			# Проверяем, завершены ли все квесты tutorial_master и village_elder
			var required_quests = [
				"kill_dummy", "kill_weak", "reach_village",  # Tutorial quests
				"clear_camps", "find_artifacts", "prepare_dungeon"  # Village Elder quests
			]
			for quest_type in required_quests:
				if not quest_type in completed_quests:
					return false
	
	return true

func _ready():
	add_to_group("npcs")
	interaction_area.connect("body_entered", _on_interaction_area_entered)
	interaction_area.connect("body_exited", _on_interaction_area_exited)
	setup_quests()
	dialog_box.hide()
	interaction_prompt.hide()

func setup_quests():
	var destroy_camps_quest = Quest.new(
		"Уничтожение лагерей",
		"Уничтожьте 4 вражеских лагеря, чтобы ослабить силы противника",
		"destroy_camp",
		4,
		200
	)
	available_quests.append(destroy_camps_quest)

func _input(event):
	if event.is_action_pressed("interact") and player and not dialog_active:
		start_dialog()
	elif event.is_action_pressed("interact") and dialog_active:
		advance_dialog()

func _on_interaction_area_entered(body):
	if body.is_in_group("player"):
		player = body
		show_interaction_prompt()

func _on_interaction_area_exited(body):
	if body.is_in_group("player"):
		player = null
		hide_interaction_prompt()
		end_dialog()

func start_dialog():
	dialog_active = true
	dialog_index = 0
	
	# Проверяем завершенные квесты
	for quest in QuestManager.active_quests:
		if quest.is_completed() and not quest in completed_quests:
			current_quest = quest
			current_dialog = [
				"Я вижу, ты выполнил моё задание!",
				"Хочешь получить награду?"
			]
			show_dialog()
			return
	
	# Проверяем возможность взять новые квесты
	if available_quests.size() > 0:
		if can_take_quests():
			current_dialog = [
				"Приветствую тебя, путник!",
				"У меня есть важное задание для тебя.",
				"Хочешь ли ты помочь мне?"
			]
		else:
			if QuestManager.active_quests.size() > 0:
				current_dialog = ["Сначала заверши текущее задание."]
			elif npc_type == "village_elder":
				current_dialog = ["Сначала заверши все задания наставника."]
			elif npc_type == "dungeon_keeper":
				current_dialog = ["Сначала заверши все задания наставника и старейшины."]
	else:
		current_dialog = ["У меня пока нет заданий для тебя."]
	
	show_dialog()

func advance_dialog():
	dialog_index += 1
	if dialog_index < current_dialog.size():
		dialog_text.text = current_dialog[dialog_index]
	else:
		if current_quest and current_quest.is_completed():
			complete_current_quest()
		elif available_quests.size() > 0:
			give_quest()
		end_dialog()

func show_dialog():
	dialog_box.show()
	dialog_text.text = current_dialog[dialog_index]

func end_dialog():
	dialog_active = false
	dialog_box.hide()
	interaction_prompt.show()

func give_quest():
	if available_quests.size() > 0 and can_take_quests():
		var quest = available_quests[0]
		if not quest in given_quests:
			available_quests.pop_front()
			given_quests.append(quest)
			QuestManager.add_quest(quest)
			print("Выдан квест:", quest.title)

func show_interaction_prompt():
	interaction_prompt.show()

func hide_interaction_prompt():
	interaction_prompt.hide()

func complete_current_quest():
	if current_quest:
		completed_quests.append(current_quest)
		QuestManager.complete_quest(current_quest)
		current_quest = null
