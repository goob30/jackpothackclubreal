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

var equipped_charms: Array = [{}, {}, {}, {}, {}]
var charm_inventory: Array = []  # legacy / unused — stickers no longer go in a bag
var pending_charm: Dictionary = {}

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
signal slot_changed(slot_index: int, charm: Dictionary)
signal pending_charm_set(charm: Dictionary)
signal pending_charm_cleared
signal player_died_normal
signal player_died_baby
signal game_won


func get_district() -> String:
	if current_floor <= 10:
		return "the_pit"
	elif current_floor <= 20:
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
	return current_floor > 0 and current_floor % 5 == 0


func is_final_floor() -> bool:
	return current_floor == 30


func advance_floor():
	current_floor += 1
	floor_changed.emit(current_floor)
	if current_floor > 30:
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
	
	var filled_slots: Array = []
	for i in range(equipped_charms.size()):
		if not equipped_charms[i].is_empty():
			filled_slots.append(i)
	if filled_slots.size() > 0:
		var pick = filled_slots[randi() % filled_slots.size()]
		var lost_charm = equipped_charms[pick]
		equipped_charms[pick] = {}
		charm_lost.emit(lost_charm)
		slot_changed.emit(pick, {})
	
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


func count_equipped() -> int:
	var n = 0
	for c in equipped_charms:
		if not c.is_empty():
			n += 1
	return n


func first_empty_slot() -> int:
	for i in range(equipped_charms.size()):
		if equipped_charms[i].is_empty():
			return i
	return -1


func is_slot_empty(idx: int) -> bool:
	if idx < 0 or idx >= equipped_charms.size():
		return true
	return equipped_charms[idx].is_empty()


func get_slot(idx: int) -> Dictionary:
	if idx < 0 or idx >= equipped_charms.size():
		return {}
	return equipped_charms[idx]


func can_equip_more_charms() -> bool:
	return first_empty_slot() >= 0


# Place a sticker at a specific slot. If the slot already has a sticker,
# it is destroyed (charm_lost emitted). Returns the destroyed sticker, or {} if empty.
func place_charm_at_slot(charm: Dictionary, idx: int) -> Dictionary:
	if idx < 0 or idx >= equipped_charms.size():
		return {}
	var old = equipped_charms[idx]
	equipped_charms[idx] = charm
	if not old.is_empty():
		charm_lost.emit(old)
	if not charm.is_empty():
		charm_equipped.emit(charm)
	slot_changed.emit(idx, charm)
	return old


# Peel sticker off a slot — destroys it permanently.
func peel_slot(idx: int) -> bool:
	if idx < 0 or idx >= equipped_charms.size():
		return false
	var old = equipped_charms[idx]
	if old.is_empty():
		return false
	equipped_charms[idx] = {}
	charm_lost.emit(old)
	charm_unequipped.emit(old)
	slot_changed.emit(idx, {})
	return true


func equip_charm(charm: Dictionary) -> bool:
	var idx = first_empty_slot()
	if idx < 0:
		return false
	equipped_charms[idx] = charm
	charm_equipped.emit(charm)
	slot_changed.emit(idx, charm)
	return true


func unequip_charm(charm: Dictionary):
	# In the sticker model, unequip = peel = destroy. Find the slot and peel it.
	for i in range(equipped_charms.size()):
		if equipped_charms[i].get("id") == charm.get("id"):
			peel_slot(i)
			return


# Pull-time entry point. If a slot is free, the sticker auto-applies.
# Otherwise it becomes a pending sticker that the player must place
# (replacing an existing one) or discard, via the Workshop / Player Card scene.
func add_charm_to_inventory(charm: Dictionary):
	var idx = first_empty_slot()
	if idx >= 0:
		equipped_charms[idx] = charm
		charm_equipped.emit(charm)
		slot_changed.emit(idx, charm)
		charm_added_to_inventory.emit(charm)
	else:
		set_pending_charm(charm)


func get_equipped_charms() -> Array:
	# Returns only filled slots (skips empties) — convenience for resolvers/UI.
	var filled: Array = []
	for c in equipped_charms:
		if not c.is_empty():
			filled.append(c)
	return filled


func has_charm_equipped(charm_id: String) -> bool:
	for c in equipped_charms:
		if c.is_empty():
			continue
		if c.get("id") == charm_id:
			return true
	return false


# ─── Pending sticker (just-pulled, awaiting placement) ───
func set_pending_charm(charm: Dictionary):
	if not pending_charm.is_empty():
		# Replacing an unresolved pending sticker — the old one is destroyed.
		charm_lost.emit(pending_charm)
	pending_charm = charm
	pending_charm_set.emit(charm)


func clear_all_charms():
	for i in range(equipped_charms.size()):
		equipped_charms[i] = {}
		slot_changed.emit(i, {})
	discard_pending_charm()


func discard_pending_charm():
	if pending_charm.is_empty():
		return
	var lost = pending_charm
	pending_charm = {}
	charm_lost.emit(lost)
	pending_charm_cleared.emit()


func place_pending_at_slot(idx: int) -> bool:
	if pending_charm.is_empty():
		return false
	var charm = pending_charm
	pending_charm = {}
	place_charm_at_slot(charm, idx)
	pending_charm_cleared.emit()
	return true


func has_pending_charm() -> bool:
	return not pending_charm.is_empty()


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
	equipped_charms = [{}, {}, {}, {}, {}]
	charm_inventory.clear()
	pending_charm = {}
	last_roll_value = 0
	current_enemy_data = {}
	hp_changed.emit(player_hp, player_max_hp)
	gold_changed.emit(gold)
	tokens_changed.emit(tokens)
	floor_changed.emit(current_floor)
	pending_charm_cleared.emit()
	for i in range(equipped_charms.size()):
		slot_changed.emit(i, {})


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
	print("Sticker slots (%d/%d):" % [count_equipped(), MAX_EQUIPPED_CHARMS])
	for i in range(equipped_charms.size()):
		var c = equipped_charms[i]
		if c.is_empty():
			print("  [%d] —" % (i + 1))
		else:
			print("  [%d] %s" % [i + 1, c.get("name", "?")])
	if has_pending_charm():
		print("Pending sticker: %s" % pending_charm.get("name"))
