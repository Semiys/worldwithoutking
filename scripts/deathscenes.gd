extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	# Сначала снимаем паузу
	var tree = get_tree()
	if tree and not tree.is_queued_for_deletion():
		tree.paused = false
		# Используем call_deferred для безопасной смены сцены
		tree.call_deferred("change_scene_to_file", "res://scenes/game.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
