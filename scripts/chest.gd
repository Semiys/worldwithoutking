extends StaticBody2D

@export var items: Array[String] = ["Меч", "Зелье здоровья"]
var is_open = false
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")
@onready var item_database = get_node("/root/ItemDatabase")
@onready var sprite = $AnimatedSprite2D

func _ready():
	add_to_group("interactables")
	if sprite and sprite.sprite_frames:
		sprite.play("closed")

func interact(player):
	if not is_open:
		is_open = true
		if sprite and sprite.sprite_frames:
			sprite.play("opened")
		drop_items()

func drop_items():
	for i in items.size():
		var item_name = items[i]
		var item_resource = item_database.get_item(item_name)
		if item_resource:
			var dropped_item = dropped_item_scene.instantiate()
			dropped_item.item_name = item_name
			dropped_item.item_texture = item_resource.icon
			
			var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
			dropped_item.position = position + offset
			
			await get_tree().create_timer(0.2).timeout
			get_parent().add_child(dropped_item) 
