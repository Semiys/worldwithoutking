extends CanvasLayer

func _ready():
	hide()

func _unhandled_input(event):
	if event.is_action_pressed("пауза"):
		if not visible:
			show()
			if get_tree():
				get_tree().paused = true
		else:
			hide()
			if get_tree():
				get_tree().paused = false

func _on_resume_pressed():
	hide()
	if get_tree():
		get_tree().paused = false

func _on_quit_pressed():
	if get_tree():
		get_tree().paused = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")

func restart_game():
	if get_tree():
		get_tree().paused = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game.tscn")

func _exit_tree():
	if get_tree():
		get_tree().paused = false
