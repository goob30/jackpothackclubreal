class_name CharmsData
extends Node


const RARITY_COMMON: String = "common"
const RARITY_UNCOMMON: String = "uncommon"
const RARITY_RARE: String = "rare"
const RARITY_LEGENDARY: String = "legendary"


# Trigger constants — when does the charm's effect activate?
const TRIGGER_ALWAYS: String      = "always"
const TRIGGER_WIN: String         = "win"
const TRIGGER_LOSS: String        = "loss"
const TRIGGER_ROLL: String        = "roll"
const TRIGGER_ENEMY_ROLL: String  = "enemy_roll"
const TRIGGER_POST_ROLL: String   = "post_roll"

# Minigame identifiers (match GameManager.get_current_minigame() output)
const MG_COINFLIP: String  = "coinflip"
const MG_DICE: String      = "dice"
const MG_SLOTS: String     = "slots"
const MG_BLACKJACK: String = "blackjack"
const MG_ALL: Array        = [MG_COINFLIP, MG_DICE, MG_SLOTS, MG_BLACKJACK]


static func _icon_path(charm_id: String) -> String:
	return "res://assets/sprites/charms/charm_%s.png" % charm_id


static func _make(id: String, name: String, rarity: String, effect: String, value, description: String, applies_to: Array, trigger: String, flavor: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"rarity": rarity,
		"icon": _icon_path(id),
		"effect": effect,
		"value": value,
		"description": description,
		"applies_to": applies_to,
		"trigger": trigger,
		"flavor": flavor,
	}


static func get_all_charms() -> Array:
	return [
		# ─── COMMON ───
		_make("plus_two", "+2 Token", RARITY_COMMON, "add_value", 2,
			"+2 to your roll value (dice) or hand total (blackjack).",
			[MG_DICE, MG_BLACKJACK], TRIGGER_ALWAYS,
			"Worn smooth from years of fingering."),

		_make("poison", "Venom Vial", RARITY_COMMON, "extra_damage", 3,
			"Deal +3 damage on every win.",
			MG_ALL, TRIGGER_WIN,
			"Smells worse than it tastes."),

		_make("shield", "Brass Shield", RARITY_COMMON, "block", 3,
			"Block 3 damage when you lose a round.",
			MG_ALL, TRIGGER_LOSS,
			"Dented in three places. Still holds."),

		_make("greedy", "Greedy Eye", RARITY_COMMON, "bonus_gold", 2,
			"+2 gold whenever you win.",
			MG_ALL, TRIGGER_WIN,
			"It blinks at coins."),

		# ─── UNCOMMON ───
		_make("vampire", "Vampiric Tooth", RARITY_UNCOMMON, "lifesteal", 0.5,
			"Heal 50% of the damage you deal.",
			MG_ALL, TRIGGER_WIN,
			"Old. Still warm."),

		_make("explode", "Loaded Reroll", RARITY_UNCOMMON, "reroll_better", 1,
			"Roll/spin/flip twice; keep the better outcome.",
			[MG_COINFLIP, MG_DICE, MG_SLOTS], TRIGGER_ROLL,
			"For when fate's first answer disappoints."),

		_make("shock", "Shock Coil", RARITY_UNCOMMON, "skip_chance", 0.5,
			"50% chance the enemy skips their attack on a loss.",
			MG_ALL, TRIGGER_LOSS,
			"It hums a key the demons can't sing in."),

		# ─── RARE ───
		_make("fire", "Hellfire", RARITY_RARE, "extra_damage", 4,
			"Deal +4 damage on every win.",
			MG_ALL, TRIGGER_WIN,
			"Stolen from a chef who forgot to bless the stove."),

		_make("lucky", "Loaded Dice", RARITY_RARE, "force_enemy_reroll", 1,
			"Force the enemy to reroll/redraw — keep the worse result.",
			[MG_DICE, MG_BLACKJACK], TRIGGER_ENEMY_ROLL,
			"They never check the dice."),

		_make("cursed", "Cursed Token", RARITY_RARE, "double_damage_self_hurt", 1,
			"Deal 2× damage on a win, but lose 1 HP every play.",
			MG_ALL, TRIGGER_ALWAYS,
			"You can feel it eating its way out."),

		# ─── LEGENDARY ───
		_make("freeze", "Frozen Heart", RARITY_LEGENDARY, "skip_enemy", 1,
			"The enemy skips their next attack, no matter what.",
			MG_ALL, TRIGGER_ALWAYS,
			"It was warm, once."),

		_make("mirror", "Devil's Mirror", RARITY_LEGENDARY, "copy_enemy_roll", 1,
			"Your roll/score copies the enemy's. Ties go to you.",
			[MG_DICE, MG_BLACKJACK], TRIGGER_POST_ROLL,
			"Don't look directly into it."),

		_make("infinity", "Infinite Loop", RARITY_LEGENDARY, "reroll_until_six", 6,
			"Keep rerolling the dice until you roll a 6.",
			[MG_DICE], TRIGGER_ROLL,
			"There is no losing. Only patience."),

		_make("devils_mark", "Devil's Mark", RARITY_LEGENDARY, "always_six", 6,
			"Your roll always counts as 6 (dice) or 21 (blackjack).",
			[MG_DICE, MG_BLACKJACK], TRIGGER_ALWAYS,
			"He signed it himself."),
	]


static func get_charms_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for charm in get_all_charms():
		if charm.rarity == rarity:
			result.append(charm)
	return result


static func get_random_charm_by_rarity(rarity: String) -> Dictionary:
	var pool = get_charms_by_rarity(rarity)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()].duplicate(true)


static func get_charm_by_id(charm_id: String) -> Dictionary:
	for charm in get_all_charms():
		if charm.id == charm_id:
			return charm.duplicate(true)
	return {}


static func charm_applies_to(charm: Dictionary, minigame: String) -> bool:
	if minigame == "":
		return true
	var applies = charm.get("applies_to", MG_ALL)
	return applies.has(minigame)


static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		RARITY_COMMON: return Color("#888888")
		RARITY_UNCOMMON: return Color("#4cae6a")
		RARITY_RARE: return Color("#00f0ff")
		RARITY_LEGENDARY: return Color("#ff2e88")
		_: return Color.WHITE


static func get_rarity_display_name(rarity: String) -> String:
	match rarity:
		RARITY_COMMON: return "Common"
		RARITY_UNCOMMON: return "Uncommon"
		RARITY_RARE: return "Rare"
		RARITY_LEGENDARY: return "Legendary"
		_: return "Unknown"


static func get_trigger_display_name(trigger: String) -> String:
	match trigger:
		TRIGGER_ALWAYS:     return "Passive"
		TRIGGER_WIN:        return "On Win"
		TRIGGER_LOSS:       return "On Loss"
		TRIGGER_ROLL:       return "On Roll"
		TRIGGER_ENEMY_ROLL: return "Enemy Roll"
		TRIGGER_POST_ROLL:  return "Post-Roll"
		_:                  return "—"


static func get_emoji_for_charm(charm_id: String) -> String:
	match charm_id:
		"plus_two":     return "➕"
		"poison":       return "🧪"
		"shield":       return "🛡"
		"greedy":       return "👁"
		"vampire":      return "🦇"
		"explode":      return "💣"
		"shock":        return "⚡"
		"fire":         return "🔥"
		"lucky":        return "🎲"
		"cursed":       return "💀"
		"freeze":       return "❄"
		"mirror":       return "🪞"
		"infinity":     return "♾"
		"devils_mark":  return "✡"
		_:              return "✦"
