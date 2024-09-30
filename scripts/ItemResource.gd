extends Resource
class_name ItemResource

@export var item_name: String
@export var icon: Texture
@export_enum("Weapon", "Armor", "Consumable") var type: String
@export var description: String
@export var stackable: bool = false
@export var max_stack_size: int = 1
