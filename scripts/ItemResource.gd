extends Resource
class_name ItemResource

@export var item_name: String
@export var icon: Texture
@export_enum("Weapon", "Armor", "Consumable") var type: String
@export var description: String
@export var stackable: bool = false
@export var max_stack_size: int = 1
@export var effect: Dictionary = {}

func use(player):
	match type:
		"Weapon":
			player.equip_weapon(self)
		"Armor":
			player.equip_armor(self)
		"Consumable":
			apply_effect(player)

func apply_effect(player):
	for effect_type in effect:
		match effect_type:
			"health":
				player.heal(effect["health"])
			"attack":
				player.boost_attack(effect["attack"])
			"defense":
				player.boost_defense(effect["defense"])
