extends Control


@onready var state_label: Label = $Panel/Margin/VBox/StateLabel
@onready var sections: VBoxContainer = $Panel/Margin/VBox/Sections


const SECTIONS: Array = [
	{
		"title": "MODE",
		"buttons": [
			{"label": "Start NORMAL run", "fn": "_start_normal"},
			{"label": "Start BABY run", "fn": "_start_baby"},
			{"label": "Reset run (keep mode)", "fn": "_reset_run"},
		],
	},
	{
		"title": "RESOURCES",
		"buttons": [
			{"label": "+50 gold", "fn": "_gold50"},
			{"label": "+5 tokens", "fn": "_tokens5"},
			{"label": "Full heal", "fn": "_full_heal"},
			{"label": "Damage 5", "fn": "_dmg5"},
			{"label": "Damage MAX (kill)", "fn": "_kill"},
		],
	},
	{
		"title": "CHARMS",
		"buttons": [
			{"label": "+ Common", "fn": "_charm_common"},
			{"label": "+ Uncommon", "fn": "_charm_uncommon"},
			{"label": "+ Rare", "fn": "_charm_rare"},
			{"label": "+ Legendary", "fn": "_charm_legendary"},
			{"label": "+ All 14", "fn": "_charm_all"},
			{"label": "Clear charms", "fn": "_charm_clear"},
		],
	},
	{
		"title": "FLOOR",
		"buttons": [
			{"label": "Floor 1 (Pit)", "fn": "_floor1"},
			{"label": "Floor 5 BOSS", "fn": "_floor5"},
			{"label": "Floor 10 BOSS", "fn": "_floor10"},
			{"label": "Floor 15 BOSS", "fn": "_floor15"},
			{"label": "Floor 20 BOSS", "fn": "_floor20"},
			{"label": "Floor 25 BOSS", "fn": "_floor25"},
			{"label": "Floor 30 (Devil FINAL)", "fn": "_floor30"},
		],
	},
	{
		"title": "MINIGAME — pits you against a default enemy",
		"buttons": [
			{"label": "→ Coinflip (Imp)", "fn": "_test_coinflip"},
			{"label": "→ Dice (Croupier)", "fn": "_test_dice"},
			{"label": "→ Slots (VIP Wraith)", "fn": "_test_slots"},
			{"label": "→ Blackjack (Mistress)", "fn": "_test_blackjack"},
			{"label": "→ Underboss (HR boss, slots)", "fn": "_test_underboss"},
			{"label": "→ Arch Demon (Pent boss, dice)", "fn": "_test_archdemon"},
			{"label": "→ Devil (final, dice)", "fn": "_test_devil"},
		],
	},
	{
		"title": "SCENES — direct navigation",
		"buttons": [
			{"label": "Main Menu", "fn": "_go_menu"},
			{"label": "Elevator", "fn": "_go_elevator"},
			{"label": "Charm Co.", "fn": "_go_charm_co"},
			{"label": "Workshop", "fn": "_go_workshop"},
			{"label": "Reward", "fn": "_go_reward"},
			{"label": "Game Over", "fn": "_go_game_over"},
			{"label": "Victory", "fn": "_go_victory"},
		],
	},
]


func _ready():
	_build_sections()
	_refresh_state()
	GameManager.hp_changed.connect(func(_a, _b): _refresh_state())
	GameManager.gold_changed.connect(func(_g): _refresh_state())
	GameManager.tokens_changed.connect(func(_t): _refresh_state())
	GameManager.floor_changed.connect(func(_f): _refresh_state())
	GameManager.charm_added_to_inventory.connect(func(_c): _refresh_state())
	GameManager.charm_lost.connect(func(_c): _refresh_state())
	GameManager.charm_equipped.connect(func(_c): _refresh_state())
	GameManager.charm_unequipped.connect(func(_c): _refresh_state())


func _build_sections():
	for s in SECTIONS:
		var header = Label.new()
		header.text = s.title
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color("#f5c869"))
		sections.add_child(header)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		sections.add_child(row)

		for b in s.buttons:
			var btn = Button.new()
			btn.text = b.label
			btn.add_theme_font_size_override("font_size", 14)
			btn.custom_minimum_size = Vector2(0, 38)
			btn.pressed.connect(Callable(self, b.fn))
			row.add_child(btn)

		var sep = Control.new()
		sep.custom_minimum_size = Vector2(0, 12)
		sections.add_child(sep)


func _refresh_state():
	var slot_names: Array = []
	for i in range(GameManager.equipped_charms.size()):
		var c = GameManager.equipped_charms[i]
		slot_names.append(String(c.get("name", "—")) if not c.is_empty() else "—")
	var pending_str = GameManager.pending_charm.get("name", "—") if GameManager.has_pending_charm() else "—"
	state_label.text = "Mode: %s   |   Floor: %d (%s)   |   HP: %d/%d   |   Gold: %d   |   Tokens: %d\nSlots (%d/%d): [1]%s  [2]%s  [3]%s  [4]%s  [5]%s\nPending: %s" % [
		GameManager.game_mode.to_upper(),
		GameManager.current_floor,
		GameManager.get_district_display_name(),
		GameManager.player_hp,
		GameManager.player_max_hp,
		GameManager.gold,
		GameManager.tokens,
		GameManager.count_equipped(),
		GameManager.MAX_EQUIPPED_CHARMS,
		slot_names[0], slot_names[1], slot_names[2], slot_names[3], slot_names[4],
		pending_str,
	]


# ─── Mode ───
func _start_normal():
	GameManager.start_new_run(GameManager.MODE_NORMAL)
	_refresh_state()


func _start_baby():
	GameManager.start_new_run(GameManager.MODE_BABY)
	_refresh_state()


func _reset_run():
	GameManager.reset_run()
	_refresh_state()


# ─── Resources ───
func _gold50(): GameManager.add_gold(50)
func _tokens5(): GameManager.add_tokens(5)
func _full_heal(): GameManager.heal(GameManager.player_max_hp)
func _dmg5(): GameManager.take_damage(5)
func _kill(): GameManager.take_damage(GameManager.player_max_hp)


# ─── Charms ───
func _charm_common():    GameManager.add_charm_to_inventory(CharmsData.get_random_charm_by_rarity("common"))
func _charm_uncommon():  GameManager.add_charm_to_inventory(CharmsData.get_random_charm_by_rarity("uncommon"))
func _charm_rare():      GameManager.add_charm_to_inventory(CharmsData.get_random_charm_by_rarity("rare"))
func _charm_legendary(): GameManager.add_charm_to_inventory(CharmsData.get_random_charm_by_rarity("legendary"))


func _charm_all():
	for c in CharmsData.get_all_charms():
		GameManager.add_charm_to_inventory(c.duplicate(true))


func _charm_clear():
	GameManager.clear_all_charms()
	_refresh_state()


# ─── Floor ───
func _set_floor(n: int):
	GameManager.current_floor = n
	GameManager.floor_changed.emit(n)


func _floor1():  _set_floor(1)
func _floor5():  _set_floor(5)
func _floor10(): _set_floor(10)
func _floor15(): _set_floor(15)
func _floor20(): _set_floor(20)
func _floor25(): _set_floor(25)
func _floor30(): _set_floor(30)


# ─── Minigame launchers ───
func _start_with(enemy_id: String):
	var enemy = EnemiesData.get_enemy_by_id(enemy_id)
	if enemy.is_empty():
		push_error("No enemy: %s" % enemy_id)
		return
	GameManager.start_floor_battle([enemy])
	SceneManager.go_to_current_minigame()


func _test_coinflip():  _start_with("imp")
func _test_dice():      _start_with("croupier")
func _test_slots():     _start_with("vip_wraith")
func _test_blackjack(): _start_with("mistress")
func _test_devil():     _start_with("devil")
func _test_underboss(): _start_with("underboss")
func _test_archdemon(): _start_with("arch_demon")


# ─── Scenes ───
func _go_menu():       SceneManager.go_to_main_menu()
func _go_elevator():   SceneManager.go_to_elevator()
func _go_charm_co():   SceneManager.go_to_charm_co()
func _go_workshop():   SceneManager.go_to_workshop()
func _go_reward():     SceneManager.go_to_reward()
func _go_game_over():  SceneManager.go_to_game_over()
func _go_victory():    SceneManager.go_to_victory()
