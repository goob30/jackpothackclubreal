extends Node


const MAX_EQUIPPED_CHARMS: int = 5

const MODE_NORMAL: String = "normal"
const MODE_BABY: String = "baby"


var game_mode: String = MODE_NORMAL

var player_hp: int = 20
var player_max_hp: int = 20
var gold: int = 0
var tokens: int = 0

var current_floor: int = 1
var run_number: int = 1
var current_enemy_data: Dictionary = {}

var equipped_charms: Array = []
var charm_inventory: Array = []

var last_roll_value: int = 0

var enemies_remaining: Array = []
var current_enemy: Dictionary = {}

signal hp_changed(new_hp: int, max_hp: int)
signal gold_changed(new_gold: int)
signal tokens_changed(new_tokens: int)
signal enemy_defeated(enemy: Dictionary)
signal floor_cleared
signal new_enemy_appeared(enemy: Dictionary)
signal floor_changed(new_floor: int)
signal charm_equipped(charm: Dictionary)
signal charm_unequipped(charm: Dictionary)
signal charm_added_to_inventory(charm: Dictionary)
signal charm_lost(charm: Dictionary)
signal player_died_normal
signal player_died_baby
signal game_won


func get_district() -> String:
	if current_floor <= 5:
		return "the_pit"
	elif current_floor <= 10:
		return "high_rollers"
	else:
		return "penthouse"


func get_district_display_name() -> String:
	match get_district():
		"the_pit": return "The Pit"
		"high_rollers": return "High Rollers"
		"penthouse": return "Penthouse"
	return "Unknown"


func is_boss_floor() -> bool:
	return current_floor == 5 or current_floor == 10 or current_floor == 15


func is_final_floor() -> bool:
	return current_floor == 15


func advance_floor():
	current_floor += 1
	floor_changed.emit(current_floor)
	if current_floor > 15:
		game_won.emit()


func take_damage(amount: int):
	if amount <= 0:
		return
	player_hp = max(0, player_hp - amount)
	hp_changed.emit(player_hp, player_max_hp)
	if player_hp <= 0:
		_handle_death()


func _handle_death():
	if game_mode == MODE_BABY:
		_handle_baby_death()
	else:
		_handle_normal_death()


func _handle_normal_death():
	player_died_normal.emit()


func _handle_baby_death():
	current_floor = max(1, current_floor - 1)
	floor_changed.emit(current_floor)
	
	gold = int(gold * 0.5)
	gold_changed.emit(gold)
	tokens = int(tokens * 0.5)
	tokens_changed.emit(tokens)
	
	if equipped_charms.size() > 0:
		var lost_index = randi() % equipped_charms.size()
		var lost_charm = equipped_charms[lost_index]
		equipped_charms.remove_at(lost_index)
		charm_lost.emit(lost_charm)
	elif charm_inventory.size() > 0:
		var lost_index = randi() % charm_inventory.size()
		var lost_charm = charm_inventory[lost_index]
		charm_inventory.remove_at(lost_index)
		charm_lost.emit(lost_charm)
	
	player_hp = player_max_hp
	hp_changed.emit(player_hp, player_max_hp)
	
	player_died_baby.emit()


func heal(amount: int):
	if amount <= 0:
		return
	player_hp = min(player_max_hp, player_hp + amount)
	hp_changed.emit(player_hp, player_max_hp)


func set_max_hp(new_max: int):
	player_max_hp = new_max
	player_hp = min(player_hp, player_max_hp)
	hp_changed.emit(player_hp, player_max_hp)


func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func add_tokens(amount: int):
	tokens += amount
	tokens_changed.emit(tokens)


func spend_tokens(amount: int) -> bool:
	if tokens >= amount:
		tokens -= amount
		tokens_changed.emit(tokens)
		return true
	return false


func can_equip_more_charms() -> bool:
	return equipped_charms.size() < MAX_EQUIPPED_CHARMS


func equip_charm(charm: Dictionary) -> bool:
	if equipped_charms.size() >= MAX_EQUIPPED_CHARMS:
		return false
	equipped_charms.append(charm)
	charm_inventory.erase(charm)
	charm_equipped.emit(charm)
	return true


func unequip_charm(charm: Dictionary):
	if charm in equipped_charms:
		equipped_charms.erase(charm)
		charm_inventory.append(charm)
		charm_unequipped.emit(charm)


func add_charm_to_inventory(charm: Dictionary):
	if can_equip_more_charms():
		equipped_charms.append(charm)
		charm_equipped.emit(charm)
	else:
		charm_inventory.append(charm)
	charm_added_to_inventory.emit(charm)


func get_equipped_charms() -> Array:
	return equipped_charms


func has_charm_equipped(charm_id: String) -> bool:
	for c in equipped_charms:
		if c.get("id") == charm_id:
			return true
	return false


func start_new_run(mode: String):
	game_mode = mode
	reset_run()


func reset_run():
	player_hp = 20
	player_max_hp = 20
	gold = 0
	tokens = 0
	current_floor = 1
	run_number += 1
	equipped_charms.clear()
	charm_inventory.clear()
	last_roll_value = 0
	current_enemy_data = {}
	hp_changed.emit(player_hp, player_max_hp)
	gold_changed.emit(gold)
	tokens_changed.emit(tokens)
	floor_changed.emit(current_floor)


func is_baby_mode() -> bool:
	return game_mode == MODE_BABY


func is_normal_mode() -> bool:
	return game_mode == MODE_NORMAL



func start_floor_battle(enemies: Array):
	enemies_remaining = enemies.duplicate()
	_advance_to_next_enemy()


func _advance_to_next_enemy():
	if enemies_remaining.is_empty():
		current_enemy = {}
		floor_cleared.emit()
		return
	current_enemy = enemies_remaining.pop_front()
	new_enemy_appeared.emit(current_enemy)


func current_enemy_defeated():
	if current_enemy.is_empty():
		return
	enemy_defeated.emit(current_enemy)
	_advance_to_next_enemy()


func current_enemy_take_damage(amount: int):
	if current_enemy.is_empty():
		return
	current_enemy["hp"] = max(0, current_enemy.get("hp", 0) - amount)
	if current_enemy["hp"] <= 0:
		current_enemy_defeated()


func get_current_minigame() -> String:
	return current_enemy.get("minigame", "dice")


func get_enemies_count() -> int:
	return enemies_remaining.size() + (1 if not current_enemy.is_empty() else 0)


func debug_give_resources():
	add_gold(100)
	add_tokens(5)
	heal(20)


func debug_print_state():
	print("=== GameManager State ===")
	print("Mode: ", game_mode.to_upper())
	print("HP: %d/%d" % [player_hp, player_max_hp])
	print("Gold: %d, Tokens: %d" % [gold, tokens])
	print("Floor: %d (%s)" % [current_floor, get_district_display_name()])
	print("Equipped charms (%d/%d):" % [equipped_charms.size(), MAX_EQUIPPED_CHARMS])
	for c in equipped_charms:
		print("  - ", c.get("name", "?"))
	print("Inventory: %d charms" % charm_inventory.size())
