class_name EnemiesData
extends Node


static func _portrait_path(enemy_id: String) -> String:
	return "res://assets/sprites/enemies/enemy_%s.png" % enemy_id


static func _icon_path(enemy_id: String) -> String:
	return "res://assets/sprites/enemies/enemy_%s_icon.png" % enemy_id


static func _emoji_for(id: String) -> String:
	match id:
		"imp": return "👹"
		"lost_soul": return "👻"
		"card_shark": return "🎴"
		"drunk_gambler": return "🍺"
		"croupier": return "🎩"
		"snake_eyes_twin": return "🐍"
		"dealer_demon": return "🃏"
		"vip_wraith": return "💎"
		"lucky_devil": return "🍀"
		"hellhound": return "🐺"
		"pit_boss": return "🦹"
		"dragon": return "🐉"
		"sin_avatar": return "🔥"
		"mistress": return "💋"
		"midnight_dealer": return "🕴"
		"chip_specter": return "🪙"
		"dice_oracle": return "🎲"
		"velvet_thief": return "🎭"
		"jackpot_wraith": return "🎰"
		"underboss": return "💼"
		"ash_courtier": return "🥀"
		"golden_specter": return "👑"
		"wager_witch": return "🔮"
		"red_concierge": return "🛎"
		"arch_demon": return "🦇"
		"void_courtier": return "🌑"
		"bone_dealer": return "💀"
		"ruin_seraph": return "⚜"
		"last_gambler": return "🎯"
		"devil": return "😈"
		_: return "👻"


static func _make_enemy(id: String, name: String, floor_num: int, hp: int, minigame: String, next_attack: int, is_boss: bool, taunt: String, gold_reward: int) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"floor": floor_num,
		"hp": hp,
		"max_hp": hp,
		"minigame": minigame,
		"portrait": _portrait_path(id),
		"portrait_emoji": _emoji_for(id),
		"icon": _icon_path(id),
		"next_attack": next_attack,
		"is_boss": is_boss,
		"taunt": taunt,
		"gold_reward": gold_reward,
	}


static func get_all_enemies() -> Array:
	return [
		_make_enemy("imp", "Imp", 1, 5, "coinflip", 2, false, "Two-bit luck. You're mine.", 5),
		_make_enemy("lost_soul", "Lost Soul", 2, 7, "coinflip", 3, false, "Spare a coin for the damned?", 7),
		_make_enemy("card_shark", "Card Shark", 3, 8, "blackjack", 3, false, "Deal 'em or weep.", 9),
		_make_enemy("drunk_gambler", "Drunk Gambler", 4, 10, "slots", 4, false, "One more spin... I swear...", 11),
		_make_enemy("croupier", "The Croupier", 5, 15, "dice", 5, true, "House always wins.", 25),
		_make_enemy("snake_eyes_twin", "Snake-Eyes Twin", 6, 12, "dice", 4, false, "Hssss... double or nothing.", 14),
		_make_enemy("dealer_demon", "Dealer Demon", 7, 14, "blackjack", 5, false, "Twenty-one ways to die.", 16),
		_make_enemy("vip_wraith", "VIP Wraith", 8, 13, "slots", 5, false, "Money can't buy you out of this.", 17),
		_make_enemy("lucky_devil", "Lucky Devil", 9, 15, "coinflip", 6, false, "I love it when they call me lucky.", 19),
		_make_enemy("hellhound", "Hellhound", 10, 25, "dice", 7, true, "Sit. Stay. BLEED.", 50),
		_make_enemy("pit_boss", "Pit Boss", 11, 18, "blackjack", 6, false, "You don't belong on this floor.", 22),
		_make_enemy("dragon", "The Dragon", 12, 22, "dice", 7, false, "I'll roast your wager.", 25),
		_make_enemy("sin_avatar", "Sin Avatar", 13, 20, "slots", 6, false, "Indulge me, mortal.", 27),
		_make_enemy("mistress", "The Mistress", 14, 30, "blackjack", 8, false, "Hit me. I dare you.", 32),
		_make_enemy("midnight_dealer", "Midnight Dealer", 15, 35, "blackjack", 9, true, "House rule: midnight wins.", 80),
		_make_enemy("chip_specter", "Chip Specter", 16, 22, "slots", 7, false, "These chips remember every loser.", 18),
		_make_enemy("dice_oracle", "Dice Oracle", 17, 24, "dice", 8, false, "I already know your roll.", 20),
		_make_enemy("velvet_thief", "Velvet Thief", 18, 26, "blackjack", 8, false, "I deal from the bottom. Smile.", 22),
		_make_enemy("jackpot_wraith", "Jackpot Wraith", 19, 28, "slots", 9, false, "Three sevens and one regret.", 24),
		_make_enemy("underboss", "The Underboss", 20, 45, "slots", 11, true, "Pull the lever. I dare you.", 110),
		_make_enemy("ash_courtier", "Ash Courtier", 21, 30, "coinflip", 9, false, "All flips burn the same.", 26),
		_make_enemy("golden_specter", "Golden Specter", 22, 32, "dice", 10, false, "Gilded means weighted.", 28),
		_make_enemy("wager_witch", "Wager Witch", 23, 34, "blackjack", 11, false, "I cursed your hand twelve cards ago.", 30),
		_make_enemy("red_concierge", "Red Concierge", 24, 36, "slots", 11, false, "Welcome. Your room is the morgue.", 32),
		_make_enemy("arch_demon", "Arch Demon", 25, 55, "dice", 13, true, "Bow, mortal. Then bet.", 140),
		_make_enemy("void_courtier", "Void Courtier", 26, 40, "blackjack", 12, false, "Where I deal from, math doesn't apply.", 36),
		_make_enemy("bone_dealer", "Bone Dealer", 27, 42, "dice", 13, false, "Your bones, my dice.", 38),
		_make_enemy("ruin_seraph", "Ruin Seraph", 28, 44, "slots", 13, false, "Even angels fold sometimes.", 40),
		_make_enemy("last_gambler", "The Last Gambler", 29, 46, "coinflip", 14, false, "I haven't won since '63.", 44),
		_make_enemy("devil", "The Devil", 30, 65, "dice", 15, true, "All bets are final.", 0),
	]


static func get_enemy_for_floor(floor_num: int) -> Dictionary:
	for enemy in get_all_enemies():
		if enemy.floor == floor_num:
			return enemy.duplicate(true)
	return {}


static func get_enemies_for_floor(floor_num: int) -> Array:
	return FloorData.get_floor_enemies(floor_num)


static func get_enemy_by_id(enemy_id: String) -> Dictionary:
	for enemy in get_all_enemies():
		if enemy.id == enemy_id:
			return enemy.duplicate(true)
	return {}
