class_name FloorData
extends Node


static func get_floor_enemies(floor_num: int) -> Array:
	var ids: Array = _floor_layout(floor_num)
	var result: Array = []
	for id in ids:
		var enemy = EnemiesData.get_enemy_by_id(id)
		if not enemy.is_empty():
			result.append(enemy)
	return result


static func _floor_layout(floor_num: int) -> Array:
	match floor_num:
		# ─── THE PIT (1-10) ───
		1: return ["imp", "imp", "lost_soul"]
		2: return ["imp", "lost_soul"]
		3: return ["lost_soul", "card_shark"]
		4: return ["card_shark", "drunk_gambler"]
		5: return ["croupier"]
		6: return ["snake_eyes_twin", "snake_eyes_twin"]
		7: return ["dealer_demon", "snake_eyes_twin"]
		8: return ["vip_wraith", "dealer_demon"]
		9: return ["lucky_devil", "vip_wraith"]
		10: return ["hellhound"]
		# ─── HIGH ROLLERS (11-20) ───
		11: return ["pit_boss", "pit_boss"]
		12: return ["dragon", "pit_boss"]
		13: return ["sin_avatar", "dragon"]
		14: return ["sin_avatar", "mistress"]
		15: return ["midnight_dealer"]
		16: return ["chip_specter", "chip_specter"]
		17: return ["dice_oracle", "chip_specter"]
		18: return ["velvet_thief", "dice_oracle"]
		19: return ["jackpot_wraith", "velvet_thief"]
		20: return ["underboss"]
		# ─── PENTHOUSE (21-30) ───
		21: return ["ash_courtier", "ash_courtier"]
		22: return ["golden_specter", "ash_courtier"]
		23: return ["wager_witch", "golden_specter"]
		24: return ["red_concierge", "wager_witch"]
		25: return ["arch_demon"]
		26: return ["void_courtier", "void_courtier"]
		27: return ["bone_dealer", "void_courtier"]
		28: return ["ruin_seraph", "bone_dealer"]
		29: return ["last_gambler", "ruin_seraph"]
		30: return ["devil"]
		_: return []
