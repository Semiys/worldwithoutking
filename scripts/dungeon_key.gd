extends Area2D

func _ready():
	# Добавляем анимацию появления
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Обновляем прогресс квеста
		QuestManager.update_quest_progress("prepare_dungeon", 1, "prepare_dungeon")
		
		# Анимация подбора
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free) 