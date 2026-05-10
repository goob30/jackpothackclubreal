extends BattleBase


@onready var enemy_hand_box: HBoxContainer = $BattleHUD/PlayerHalf/GameAreaContainer/EnemyHandBox
@onready var player_hand_box: HBoxContainer = $BattleHUD/PlayerHalf/GameAreaContainer/PlayerHandBox
@onready var totals_label: Label = $BattleHUD/PlayerHalf/GameAreaContainer/TotalsLabel
@onready var result_label: Label = $BattleHUD/PlayerHalf/GameAreaContainer/ResultLabel


const SUITS: Array = ["♠", "♥", "♦", "♣"]


var deck: Array = []
var player_hand: Array = []
var enemy_hand: Array = []
var round_active: bool = false


func _ready():
	super._ready()
	InputManager.button_2_left_pressed.connect(_on_hit)
	InputManager.button_2_right_pressed.connect(_on_stand)
	InputManager.button_1_pressed.connect(_start_round)
	hud.set_button_hints("[SPACE] DEAL    [←] HIT    [→] STAND")
	_start_round()


func _start_round():
	if round_active:
		return
	round_active = true
	result_label.text = ""
	deck = _make_deck()
	deck.shuffle()
	player_hand = [_draw_card_from_deck(), _draw_card_from_deck()]
	enemy_hand = [_draw_card_from_deck()]
	_redraw_hands()
	hud.set_button_hints("[←] HIT    [→] STAND")


func _on_hit():
	if not round_active:
		return
	player_hand.append(_draw_card_from_deck())
	AudioController.play_sfx(AudioController.SFX_CARD_DEAL)
	_redraw_hands()
	if _hand_total(player_hand) > 21:
		await get_tree().create_timer(0.5).timeout
		_resolve_round()


func _on_stand():
	if not round_active:
		return
	while _hand_total(enemy_hand) < 17:
		enemy_hand.append(_draw_card_from_deck())
		AudioController.play_sfx(AudioController.SFX_CARD_DEAL)
		_redraw_hands()
		await get_tree().create_timer(0.3).timeout
	_resolve_round()


func _resolve_round():
	round_active = false
	var p_total = _hand_total(player_hand)
	var e_total = _hand_total(enemy_hand)
	var mods = CharmResolver.apply_charms(p_total, 0, CharmsData.MG_BLACKJACK)
	if mods.force_blackjack_max:
		p_total = 21
	if mods.copy_enemy_roll:
		p_total = e_total
	p_total += mods.value_bonus

	if p_total > 21:
		if not mods.skip_enemy:
			var dmg = int(GameManager.current_enemy.get("next_attack", 4))
			apply_damage_to_player(dmg, mods.block)
		result_label.text = "BUST"
		result_label.add_theme_color_override("font_color", Color("#e6164a"))
	elif e_total > 21:
		var dmg2 = int((e_total + mods.flat_extra_damage) * mods.damage_multiplier)
		apply_damage_to_enemy(dmg2)
		CharmResolver.apply_post_win_rewards(mods, dmg2)
		result_label.text = "DEALER BUST"
		result_label.add_theme_color_override("font_color", Color("#4cae6a"))
	elif p_total > e_total:
		var diff = p_total - e_total
		var dmg3 = int((diff + mods.flat_extra_damage) * mods.damage_multiplier)
		apply_damage_to_enemy(dmg3)
		CharmResolver.apply_post_win_rewards(mods, dmg3)
		result_label.text = "WIN +%d" % diff
		result_label.add_theme_color_override("font_color", Color("#4cae6a"))
	elif e_total > p_total:
		if not mods.skip_enemy:
			var diff2 = e_total - p_total
			apply_damage_to_player(diff2, mods.block)
		result_label.text = "LOSE"
		result_label.add_theme_color_override("font_color", Color("#e6164a"))
	else:
		result_label.text = "PUSH"
		result_label.add_theme_color_override("font_color", Color("#d4a542"))

	await get_tree().create_timer(1.4).timeout
	hud.set_button_hints("[SPACE] DEAL")


func _make_deck() -> Array:
	var d: Array = []
	for suit in SUITS:
		for v in range(1, 14):
			d.append({"value": v, "suit": suit, "display": _card_display(v, suit)})
	return d


func _card_display(v: int, suit: String) -> String:
	var face: String = ""
	match v:
		1: face = "A"
		11: face = "J"
		12: face = "Q"
		13: face = "K"
		_: face = str(v)
	return "%s%s" % [face, suit]


func _draw_card_from_deck() -> Dictionary:
	if deck.is_empty():
		deck = _make_deck()
		deck.shuffle()
	return deck.pop_back()


func _hand_total(hand: Array) -> int:
	var total = 0
	var aces = 0
	for c in hand:
		var v = int(c.value)
		if v == 1:
			aces += 1
			total += 11
		elif v >= 10:
			total += 10
		else:
			total += v
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total


func _redraw_hands():
	for child in player_hand_box.get_children():
		child.queue_free()
	for child in enemy_hand_box.get_children():
		child.queue_free()
	for c in enemy_hand:
		enemy_hand_box.add_child(_make_card_label(c))
	for c in player_hand:
		player_hand_box.add_child(_make_card_label(c))
	totals_label.text = "Player: %d   |   Dealer: %d" % [_hand_total(player_hand), _hand_total(enemy_hand)]


func _make_card_label(card: Dictionary) -> Label:
	var lbl = Label.new()
	lbl.text = card.display
	lbl.add_theme_font_size_override("font_size", 36)
	var color = Color("#f0e6d2")
	if card.suit == "♥" or card.suit == "♦":
		color = Color("#e6164a")
	lbl.add_theme_color_override("font_color", color)
	lbl.custom_minimum_size = Vector2(64, 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl
