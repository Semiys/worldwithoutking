extends Area2D

@export var artifact_name: String
var item_texture: Texture2D

func _ready():
	var item_resource = get_node("/root/ItemDatabase").get_item(artifact_name)
	if item_resource:
		item_texture = item_resource.icon
		$Sprite2D.texture = item_texture
		
		# Добавляем эффект свечения
		var glow = create_glow_effect()
		add_child(glow)

func create_glow_effect():
	var light = PointLight2D.new()
	light.texture = item_texture
	light.energy = 0.5
	light.color = Color(1, 1, 0.8, 0.5)
	
	# Создаем анимацию пульсации
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(light, "energy", 0.8, 1.0)
	tween.tween_property(light, "energy", 0.5, 1.0)
	
	return light

func _on_body_entered(body):
	if body.is_in_group("player"):
		var inventory = body.get_node("player_ui/Inventory")
		if inventory.add_item(artifact_name):
			# Анимация подбора
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
			tween.tween_callback(queue_free) 