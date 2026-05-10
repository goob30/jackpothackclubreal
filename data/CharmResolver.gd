class_name CharmResolver
extends Node


static func _new_modifiers() -> Dictionary:
	return {
		"final_roll": 0,
		"damage_to_enemy": 0,
		"block": 0,
		"lifesteal": 0.0,
		"skip_enemy": false,
		"force_enemy_reroll": false,
		"bonus_gold": 0,
		"self_damage": 0,
		"force_six": false,
		"reroll_until_six": false,
		"reroll_better": false,
		"copy_enemy_roll": false,
		"value_bonus": 0,
		"flat_extra_damage": 0,
		"damage_multiplier": 1.0,
		"force_blackjack_max": false,
	}


# minigame: one of CharmsData.MG_COINFLIP/DICE/SLOTS/BLACKJACK, or "" to apply all
static func apply_charms(roll_value: int, base_damage: int, minigame: String = "") -> Dictionary:
	var mods = _new_modifiers()
	mods.final_roll = roll_value
	mods.damage_to_enemy = base_damage

	for charm in GameManager.equipped_charms:
		if charm.is_empty():
			continue
		if not CharmsData.charm_applies_to(charm, minigame):
			continue
		var effect = charm.get("effect", "")
		var value = charm.get("value", 0)

		match effect:
			"add_value":
				mods.value_bonus += int(value)
				mods.final_roll += int(value)
			"extra_damage":
				mods.flat_extra_damage += int(value)
			"block":
				mods.block += int(value)
			"bonus_gold":
				mods.bonus_gold += int(value)
			"lifesteal":
				mods.lifesteal = max(mods.lifesteal, float(value))
			"reroll_better":
				mods.reroll_better = true
			"skip_chance":
				if randf() < float(value):
					mods.skip_enemy = true
			"force_enemy_reroll":
				mods.force_enemy_reroll = true
			"double_damage_self_hurt":
				mods.damage_multiplier *= 2.0
				mods.self_damage += int(value)
			"skip_enemy":
				mods.skip_enemy = true
			"copy_enemy_roll":
				mods.copy_enemy_roll = true
			"reroll_until_six":
				mods.reroll_until_six = true
			"always_six":
				mods.force_six = true
				mods.force_blackjack_max = true
				mods.final_roll = 6

	mods.damage_to_enemy = int((base_damage + mods.flat_extra_damage) * mods.damage_multiplier)
	return mods


static func apply_post_win_rewards(mods: Dictionary, damage_dealt: int):
	if mods.bonus_gold > 0:
		GameManager.add_gold(mods.bonus_gold)
	if mods.lifesteal > 0 and damage_dealt > 0:
		GameManager.heal(int(damage_dealt * mods.lifesteal))
	if mods.self_damage > 0:
		GameManager.take_damage(mods.self_damage)
