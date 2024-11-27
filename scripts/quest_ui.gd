extends Control

@onready var quest_list = $QuestList
@onready var quest_details = $QuestDetails

func _ready():
	QuestManager.connect("quest_updated", _on_quest_updated)
	QuestManager.connect("quest_completed", _on_quest_completed)
	update_quest_list()

func update_quest_list():
	quest_list.clear()
	for quest in QuestManager.active_quests:
		quest_list.add_item(quest.title)

func _on_quest_updated(quest):
	update_quest_list()
	update_quest_details(quest)

func _on_quest_completed(quest):
	update_quest_list()
	# Показываем уведомление о завершении квеста
	show_completion_notification(quest)

func update_quest_details(quest):
	var details_text = """
	{title}
	
	{description}
	
	Прогресс: {progress}
	Награда: {reward} опыта
	""".format({
		"title": quest.title,
		"description": quest.description,
		"progress": quest.get_progress_text(),
		"reward": quest.reward_exp
	})
	
	quest_details.text = details_text 
