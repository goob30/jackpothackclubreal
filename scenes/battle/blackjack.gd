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
	var face_up = _draw_card_from_deck()
	var hole = _draw_card_from_deck()
	hole["hidden"] = true
	enemy_hand = [face_up, hole]
	_redraw_hands()
	hud.set_button_hints("[←] HIT    [→] STAND")


func _on_hit():
	if not round_active:
		return
	var new_card = _draw_card_from_deck()
	player_hand.append(new_card)
	AudioController.play_sfx(AudioController.SFX_CARD_DEAL)
	player_hand_box.add_child(_make_card_node(new_card))
	_update_totals()
	if _hand_total(player_hand) > 21:
		await get_tree().create_timer(0.5).timeout
		_resolve_round()


func _on_stand():
	if not round_active:
		return
	await _reveal_hole_cards()
	while _hand_total(enemy_hand) < 17:
		var new_card = _draw_card_from_deck()
		enemy_hand.append(new_card)
		AudioController.play_sfx(AudioController.SFX_CARD_DEAL)
		enemy_hand_box.add_child(_make_card_node(new_card))
		_update_totals()
		await get_tree().create_timer(0.3).timeout
	_resolve_round()


func _reveal_hole_cards():
	for i in range(enemy_hand.size()):
		if enemy_hand[i].get("hidden", false):
			await _flip_card_at_index(i)


func _flip_card_at_index(idx: int):
	if idx < 0 or idx >= enemy_hand_box.get_child_count():
		return
	var panel: Panel = enemy_hand_box.get_child(idx)
	panel.pivot_offset = panel.size * 0.5
	AudioController.play_sfx(AudioController.SFX_CARD_DEAL)
	var tw = create_tween()
	tw.tween_property(panel, "scale:x", 0.0, 0.14).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	enemy_hand[idx]["hidden"] = false
	_set_panel_face(panel, false)
	var tw2 = create_tween()
	tw2.tween_property(panel, "scale:x", 1.0, 0.14).set_trans(Tween.TRANS_QUAD)
	await tw2.finished
	_update_totals()


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


func _hand_total(hand: Array, skip_hidden: bool = false) -> int:
	var total = 0
	var aces = 0
	for c in hand:
		if skip_hidden and c.get("hidden", false):
			continue
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
		enemy_hand_box.add_child(_make_card_node(c))
	for c in player_hand:
		player_hand_box.add_child(_make_card_node(c))
	_update_totals()


func _update_totals():
	var dealer_str: String
	var has_hidden = false
	for c in enemy_hand:
		if c.get("hidden", false):
			has_hidden = true
			break
	if has_hidden:
		dealer_str = "%d + ?" % _hand_total(enemy_hand, true)
	else:
		dealer_str = str(_hand_total(enemy_hand))
	totals_label.text = "Player: %d   |   Dealer: %s" % [_hand_total(player_hand), dealer_str]


func _make_card_node(card: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(54, 76)
	panel.clip_contents = false
	panel.set_meta("card", card)

	var front = _build_card_front(card)
	front.name = "Front"
	panel.add_child(front)

	var back = _build_card_back()
	back.name = "Back"
	panel.add_child(back)

	_set_panel_face(panel, card.get("hidden", false))
	return panel


func _set_panel_face(panel: Panel, hidden: bool):
	var front = panel.get_node_or_null("Front")
	var back = panel.get_node_or_null("Back")
	if front == null or back == null:
		return
	if hidden:
		front.visible = false
		back.visible = true
		panel.add_theme_stylebox_override("panel", _card_back_style())
	else:
		front.visible = true
		back.visible = false
		panel.add_theme_stylebox_override("panel", _card_front_style())


func _build_card_back() -> Control:
	var holder = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var back_sprite = TextureRect.new()
	back_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	back_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_sprite.visible = false
	holder.add_child(back_sprite)
	SpriteManager.apply(back_sprite, SpriteManager.UI_CARD_BACK, null)

	var back_mark = Label.new()
	back_mark.text = "✦"
	back_mark.add_theme_font_size_override("font_size", 34)
	back_mark.add_theme_color_override("font_color", Color("#d4a542"))
	back_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(back_mark)

	return holder


func _build_card_front(card: Dictionary) -> Control:
	var holder = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var front_sprite = TextureRect.new()
	front_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	front_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	front_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_sprite.visible = false
	holder.add_child(front_sprite)
	SpriteManager.apply(front_sprite, SpriteManager.UI_CARD_FRONT, null)

	var color = Color("#1a0610")
	if card.suit == "♥" or card.suit == "♦":
		color = Color("#b8082c")

	var rank_text = String(card.display).replace(String(card.suit), "")

	var top = Label.new()
	top.text = rank_text
	top.add_theme_font_size_override("font_size", 14)
	top.add_theme_color_override("font_color", color)
	top.position = Vector2(3, 1)
	top.size = Vector2(24, 18)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(top)

	var top_suit = Label.new()
	top_suit.text = card.suit
	top_suit.add_theme_font_size_override("font_size", 11)
	top_suit.add_theme_color_override("font_color", color)
	top_suit.position = Vector2(3, 17)
	top_suit.size = Vector2(24, 14)
	top_suit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(top_suit)

	var center = Label.new()
	center.text = card.suit
	center.add_theme_font_size_override("font_size", 26)
	center.add_theme_color_override("font_color", color)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(center)

	var bot = Label.new()
	bot.text = rank_text
	bot.add_theme_font_size_override("font_size", 14)
	bot.add_theme_color_override("font_color", color)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bot.offset_left = -26
	bot.offset_top = -34
	bot.offset_right = -3
	bot.offset_bottom = -18
	bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bot)

	var bot_suit = Label.new()
	bot_suit.text = card.suit
	bot_suit.add_theme_font_size_override("font_size", 11)
	bot_suit.add_theme_color_override("font_color", color)
	bot_suit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bot_suit.offset_left = -26
	bot_suit.offset_top = -16
	bot_suit.offset_right = -3
	bot_suit.offset_bottom = -2
	bot_suit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bot_suit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bot_suit)

	return holder


func _card_front_style() -> StyleBoxFlat:
	var b = StyleBoxFlat.new()
	b.bg_color = Color("#f0e6d2")
	b.border_color = Color("#1a0610")
	b.border_width_left = 2
	b.border_width_top = 2
	b.border_width_right = 2
	b.border_width_bottom = 2
	b.corner_radius_top_left = 6
	b.corner_radius_top_right = 6
	b.corner_radius_bottom_right = 6
	b.corner_radius_bottom_left = 6
	b.shadow_color = Color(0, 0, 0, 0.4)
	b.shadow_size = 4
	return b


func _card_back_style() -> StyleBoxFlat:
	var b = StyleBoxFlat.new()
	b.bg_color = Color("#3a0e1a")
	b.border_color = Color("#d4a542")
	b.border_width_left = 2
	b.border_width_top = 2
	b.border_width_right = 2
	b.border_width_bottom = 2
	b.corner_radius_top_left = 6
	b.corner_radius_top_right = 6
	b.corner_radius_bottom_right = 6
	b.corner_radius_bottom_left = 6
	b.shadow_color = Color(0, 0, 0, 0.4)
	b.shadow_size = 4
	return b
