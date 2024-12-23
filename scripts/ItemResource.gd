@tool
extends Resource
class_name ItemResource

@export var item_name: String
@export var icon: Texture2D
@export var type: String
@export var description: String
@export var stackable: bool = true
@export var max_stack_size: int = 99
@export var effect: Dictionary
@export var is_equipped: bool = false

func apply_effect(player):
	match type:
		"Consumable":
			if effect.has("health"):
				player.heal(effect["health"])
			if effect.has("attack"):
				player.boost_attack(effect["attack"])
				print("Артефакт добавил атаку:", effect["attack"])
			if effect.has("defense"):
				player.boost_defense(effect["defense"])
				print("Артефакт добавил защиту:", effect["defense"])
			if effect.has("magic"):
				# Здесь можно добавить обработку магических эффектов
				pass
		"Weapon":
			if effect.has("attack"):
				pass
		"Armor":
			if effect.has("defense"):
				player.boost_defense(effect["defense"])
		"DamageItem":
			if effect.has("attack"):
				pass

func remove_effect(player):
	match type:
		"Armor":
			if effect.has("defense"):
				player.boost_defense(-effect["defense"])

func use(player):
	match type:
		"Weapon":
			player.equip_weapon(self)
		"Armor":
			player.equip_armor(self)
		"Consumable":
			apply_effect(player)

func to_dictionary() -> Dictionary:
	return {
		"item_name": item_name,
		"icon": icon.resource_path if icon else "",
		"type": type,
		"description": description,
		"stackable": stackable,
		"max_stack_size": max_stack_size,
		"effect": effect
	}

func from_dictionary(data: Dictionary):
	item_name = data["item_name"]
	icon = load(data["icon"]) if data["icon"] else null
	type = data["type"]
	description = data["description"]
	stackable = data["stackable"]
	max_stack_size = data["max_stack_size"]
	effect = data["effect"]
