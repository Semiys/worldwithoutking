extends Area2D

var item_name: String
var item_texture: Texture2D
var pickup_delay: float = 0.5
var can_pickup: bool = false

func _ready():
    $Sprite2D.texture = item_texture
    # Добавляем небольшую задержку перед возможностью подбора
    await get_tree().create_timer(pickup_delay).timeout
    can_pickup = true
    
    # Добавляем анимацию "прыжка" при появлении
    var tween = create_tween()
    tween.tween_property(self, "position", position + Vector2(0, -20), 0.3)
    tween.tween_property(self, "position", position, 0.2)

func _on_body_entered(body):
    if body.is_in_group("player") and can_pickup:
        var inventory = body.get_node("player_ui/Inventory")
        if inventory.add_item(item_name):
            # Анимация подбора
            var tween = create_tween()
            tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
            tween.tween_callback(queue_free) 