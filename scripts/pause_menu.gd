extends CanvasLayer

func _ready():
	hide()

func _unhandled_input(event):
	if event.is_action_pressed("пауза"):
		if not visible:
			show()
			get_tree().paused = true
		else:
			hide()
			get_tree().paused = false

func _on_resume_pressed():
	hide()
	get_tree().paused = false

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
