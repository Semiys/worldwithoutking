extends CharacterBody2D

signal dialog_finished

var dialog_active = false
var current_quest = null
var available_quests = []
var player = null
var dialog_index = 0
var current_dialog = []
var completed_quests = []

@onready var dialog_box = $DialogBox
@onready var dialog_text = $DialogBox/DialogText
@onready var interaction_area = $InteractionArea
@onready var interaction_prompt = $InteractionPrompt

func _ready():
	add_to_group("npcs")
	interaction_area.connect("body_entered", _on_interaction_area_entered)
	interaction_area.connect("body_exited", _on_interaction_area_exited)
	setup_quests()
	dialog_box.hide()
	interaction_prompt.hide()

func setup_quests():
	# Пример создания квеста
	var kill_quest = Quest.new(
		"Зачистка территории",
		"Убейте 5 врагов, чтобы обезопасить территорию",
		"kill",
		5,
		100
	)
	available_quests.append(kill_quest)

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
			return
	
	# Если нет завершенных квестов, предлагаем новые
	if available_quests.size() > 0:
		current_dialog = [
			"Приветствую тебя, путник!",
			"У меня есть важное задание для тебя.",
			"Хочешь ли ты помочь мне?"
		]
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
	if available_quests.size() > 0:
		var quest = available_quests.pop_front()
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
		# Удаляем квест из активных
		QuestManager.active_quests.erase(current_quest)
