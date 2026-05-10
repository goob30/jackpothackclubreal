extends Control


@onready var background: TextureRect = $Background

@onready var pending_banner: Panel = $PendingBanner
@onready var pending_icon: Label = $PendingBanner/Icon
@onready var pending_icon_sprite: TextureRect = $PendingBanner/Icon/Sprite
@onready var pending_name: Label = $PendingBanner/CharmName
@onready var pending_desc: Label = $PendingBanner/Description

@onready var card_panel: Panel = $PlayerCard
@onready var card_bg: TextureRect = $PlayerCard/CardBg
@onready var card_frame: TextureRect = $PlayerCard/CardFrame
@onready var card_avatar: Label = $PlayerCard/Avatar
@onready var card_avatar_sprite: TextureRect = $PlayerCard/Avatar/Sprite
@onready var card_stats: Label = $PlayerCard/StatsLine
@onready var slots_row: HBoxContainer = $PlayerCard/SlotsRow

@onready var discard_card: Panel = $DiscardSlot
@onready var discard_label: Label = $DiscardSlot/Label

@onready var detail_panel: Panel = $DetailPanel
@onready var detail_rarity: Label = $DetailPanel/Rarity
@onready var detail_icon: Label = $DetailPanel/Icon
@onready var detail_icon_sprite: TextureRect = $DetailPanel/Icon/Sprite
@onready var detail_name: Label = $DetailPanel/CharmName
@onready var detail_description: Label = $DetailPanel/Description
@onready var detail_trigger: Label = $DetailPanel/Stats/TriggerRow/TriggerValue
@onready var detail_applies: Label = $DetailPanel/Stats/AppliesRow/AppliesValue
@onready var detail_flavor: Label = $DetailPanel/Flavor
@onready var detail_action: Label = $DetailPanel/ActionHint

@onready var title_label: Label = $Title
@onready var dialog: Label = $DialogLabel
@onready var help_hint: Label = $HelpHint
@onready var back_button: Button = $BackButton


var _slot_panels: Array = []
var _selected: int = 0
var _peel_armed: int = -1     # cursor index armed for destructive peel; -1 = none


func _ready():
	SpriteManager.apply_or_keep(background, SpriteManager.BG_CHARM_CO)
	SpriteManager.apply(card_bg, SpriteManager.UI_PLAYER_CARD_BG, null)
	SpriteManager.apply(card_frame, SpriteManager.UI_PLAYER_CARD_FRAME, null)
	SpriteManager.apply(card_avatar_sprite, SpriteManager.UI_PLAYER_AVATAR, card_avatar)

	back_button.pressed.connect(_back)
	InputManager.button_2_left_pressed.connect(_on_left)
	InputManager.button_2_right_pressed.connect(_on_right)
	InputManager.button_1_pressed.connect(_on_press)

	GameManager.slot_changed.connect(func(_i, _c): _rebuild())
	GameManager.pending_charm_set.connect(func(_c): _rebuild())
	GameManager.pending_charm_cleared.connect(_rebuild)

	_build_slot_panels()
	_rebuild()


func _build_slot_panels():
	for child in slots_row.get_children():
		child.queue_free()
	_slot_panels.clear()
	for i in range(GameManager.MAX_EQUIPPED_CHARMS):
		var slot = _make_slot_panel(i)
		slots_row.add_child(slot)
		_slot_panels.append(slot)


func _make_slot_panel(idx: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(120, 150)

	var frame = TextureRect.new()
	frame.name = "SlotFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture_filter = TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false
	panel.add_child(frame)
	SpriteManager.apply(frame, SpriteManager.UI_STICKER_SLOT, null)

	var emoji = Label.new()
	emoji.name = "Emoji"
	emoji.add_theme_font_size_override("font_size", 56)
	emoji.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	emoji.offset_top = 14
	emoji.offset_bottom = 90
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(emoji)

	var sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.visible = false
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emoji.add_child(sprite)

	var nm = Label.new()
	nm.name = "Name"
	nm.add_theme_font_size_override("font_size", 12)
	nm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nm.offset_top = -52
	nm.offset_bottom = -28
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(nm)

	var slot_num = Label.new()
	slot_num.name = "SlotNum"
	slot_num.text = "SLOT %d" % (idx + 1)
	slot_num.add_theme_font_size_override("font_size", 9)
	slot_num.add_theme_color_override("font_color", Color("#7a7484"))
	slot_num.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	slot_num.offset_top = -22
	slot_num.offset_bottom = -6
	slot_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(slot_num)

	return panel


func _slot_box(charm: Dictionary, selected: bool, armed: bool) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	if charm.is_empty():
		box.bg_color = Color("#0a0810")
		box.border_color = Color("#3a3346")
	else:
		box.bg_color = Color("#0f0612")
		box.border_color = CharmsData.get_rarity_color(charm.rarity)
	if selected:
		box.border_width_left = 4
		box.border_width_top = 4
		box.border_width_right = 4
		box.border_width_bottom = 4
		box.border_color = Color("#f5c869") if not armed else Color("#e6164a")
		box.shadow_color = Color("#f5c869", 0.55) if not armed else Color("#e6164a", 0.7)
		box.shadow_size = 12
	return box


func _rebuild():
	_render_card()
	_render_pending()
	_render_discard()
	_refresh_selection()


func _render_card():
	card_stats.text = "HP %d/%d   ·   Floor %d   ·   Run #%d" % [
		GameManager.player_hp, GameManager.player_max_hp,
		GameManager.current_floor, GameManager.run_number,
	]


func _render_pending():
	if GameManager.has_pending_charm():
		var c = GameManager.pending_charm
		pending_banner.visible = true
		pending_icon.text = CharmsData.get_emoji_for_charm(c.id)
		pending_icon.add_theme_color_override("font_color", CharmsData.get_rarity_color(c.rarity))
		SpriteManager.apply(pending_icon_sprite, SpriteManager.charm_icon(c.id), pending_icon)
		pending_name.text = "%s  (%s)" % [String(c.name).to_upper(), CharmsData.get_rarity_display_name(c.rarity)]
		pending_name.add_theme_color_override("font_color", CharmsData.get_rarity_color(c.rarity))
		pending_desc.text = String(c.description)
		title_label.text = "PLACE NEW STICKER"
		help_hint.text = "[←][→] cycle to a slot or DISCARD    [SPACE] place / discard"
	else:
		pending_banner.visible = false
		title_label.text = "PLAYER CARD"
		help_hint.text = "[←][→] cycle slots or BACK    [SPACE] peel (destroys) / leave"


func _render_discard():
	# 6th cursor cell: DISCARD when there's a pending sticker, BACK when not.
	discard_card.visible = true
	if GameManager.has_pending_charm():
		discard_label.text = "DISCARD\n NEW \nSTICKER"
		discard_label.add_theme_color_override("font_color", Color("#ff4422"))
	else:
		discard_label.text = "← BACK\nELEVATOR"
		discard_label.add_theme_color_override("font_color", Color("#f5c869"))


func _navigation_size() -> int:
	# 5 slots + 1 extra (discard in place mode, back in view mode)
	return GameManager.MAX_EQUIPPED_CHARMS + 1


func _refresh_selection():
	if _selected >= _navigation_size():
		_selected = 0
	for i in range(_slot_panels.size()):
		var panel: Panel = _slot_panels[i]
		var charm = GameManager.get_slot(i)
		var is_selected = i == _selected
		var armed = is_selected and i == _peel_armed
		panel.add_theme_stylebox_override("panel", _slot_box(charm, is_selected, armed))
		panel.scale = Vector2(1.08, 1.08) if is_selected else Vector2.ONE
		panel.pivot_offset = panel.size * 0.5
		_paint_slot(panel, charm)

	# 6th cell highlight (DISCARD in place mode, BACK in view mode)
	var sel_extra = (_selected == GameManager.MAX_EQUIPPED_CHARMS)
	var has_pending = GameManager.has_pending_charm()
	var accent = Color("#ff4422") if has_pending else Color("#f5c869")
	var dim = Color("#6e0418") if has_pending else Color("#5a4520")
	var bg = Color("#1c0a02") if has_pending else Color("#1a1410")
	var box = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = accent if sel_extra else dim
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	box.border_width_left = 4 if sel_extra else 2
	box.border_width_top = 4 if sel_extra else 2
	box.border_width_right = 4 if sel_extra else 2
	box.border_width_bottom = 4 if sel_extra else 2
	if sel_extra:
		box.shadow_color = Color(accent.r, accent.g, accent.b, 0.6)
		box.shadow_size = 12
	discard_card.add_theme_stylebox_override("panel", box)
	discard_card.scale = Vector2(1.08, 1.08) if sel_extra else Vector2.ONE
	discard_card.pivot_offset = discard_card.size * 0.5

	_render_detail()


func _paint_slot(panel: Panel, charm: Dictionary):
	var emoji: Label = panel.get_node("Emoji")
	var sprite: TextureRect = panel.get_node("Emoji/Sprite")
	var nm: Label = panel.get_node("Name")
	if charm.is_empty():
		emoji.text = "—"
		emoji.add_theme_color_override("font_color", Color("#5a5563"))
		SpriteManager.apply(sprite, "", emoji)
		nm.text = "(empty)"
		nm.add_theme_color_override("font_color", Color("#7a7484"))
	else:
		emoji.text = CharmsData.get_emoji_for_charm(charm.id)
		emoji.add_theme_color_override("font_color", CharmsData.get_rarity_color(charm.rarity))
		SpriteManager.apply(sprite, SpriteManager.charm_icon(charm.id), emoji)
		nm.text = String(charm.name)
		nm.add_theme_color_override("font_color", CharmsData.get_rarity_color(charm.rarity))


func _render_detail():
	var has_pending = GameManager.has_pending_charm()
	if _selected == GameManager.MAX_EQUIPPED_CHARMS:
		if has_pending:
			_show_discard_detail()
		else:
			_show_back_detail()
		return
	var charm = GameManager.get_slot(_selected)
	if charm.is_empty():
		_show_empty_detail()
		return
	_show_charm_detail(charm)


func _show_charm_detail(charm: Dictionary):
	var rarity = String(charm.rarity)
	detail_rarity.text = "✦ %s ✦" % CharmsData.get_rarity_display_name(rarity).to_upper()
	detail_rarity.add_theme_color_override("font_color", CharmsData.get_rarity_color(rarity))

	detail_icon.text = CharmsData.get_emoji_for_charm(charm.id)
	detail_icon.add_theme_color_override("font_color", CharmsData.get_rarity_color(rarity))
	SpriteManager.apply(detail_icon_sprite, SpriteManager.charm_icon(charm.id), detail_icon)

	detail_name.text = String(charm.name).to_upper()
	detail_name.add_theme_color_override("font_color", CharmsData.get_rarity_color(rarity))
	detail_description.text = String(charm.description)
	detail_trigger.text = CharmsData.get_trigger_display_name(charm.get("trigger", ""))
	detail_applies.text = _format_applies(charm.get("applies_to", CharmsData.MG_ALL))
	detail_flavor.text = "“%s”" % charm.get("flavor", "")

	if GameManager.has_pending_charm():
		detail_action.text = "[SPACE] PLACE — destroys this sticker"
		detail_action.add_theme_color_override("font_color", Color("#e6164a"))
	else:
		if _peel_armed == _selected:
			detail_action.text = "[SPACE] CONFIRM PEEL — destroys this sticker"
			detail_action.add_theme_color_override("font_color", Color("#e6164a"))
		else:
			detail_action.text = "[SPACE] peel — sticker destroyed"
			detail_action.add_theme_color_override("font_color", Color("#a44058"))


func _show_empty_detail():
	detail_rarity.text = "EMPTY SLOT"
	detail_rarity.add_theme_color_override("font_color", Color("#7a7484"))
	detail_icon.text = "—"
	SpriteManager.apply(detail_icon_sprite, "", detail_icon)
	detail_name.text = "—"
	detail_description.text = "Nothing stuck here yet."
	detail_trigger.text = "—"
	detail_applies.text = "—"
	detail_flavor.text = ""
	if GameManager.has_pending_charm():
		detail_action.text = "[SPACE] PLACE pending sticker here"
		detail_action.add_theme_color_override("font_color", Color("#4cae6a"))
	else:
		detail_action.text = "Visit Charm Co. to find a sticker"
		detail_action.add_theme_color_override("font_color", Color("#7a7484"))


func _show_discard_detail():
	detail_rarity.text = "✦ DISCARD ✦"
	detail_rarity.add_theme_color_override("font_color", Color("#ff4422"))
	detail_icon.text = "🗑"
	SpriteManager.apply(detail_icon_sprite, "", detail_icon)
	detail_name.text = "THROW AWAY"
	detail_name.add_theme_color_override("font_color", Color("#ff4422"))
	detail_description.text = "Discard the new sticker. Your card stays exactly as it is."
	detail_trigger.text = "—"
	detail_applies.text = "—"
	detail_flavor.text = ""
	detail_action.text = "[SPACE] DISCARD"
	detail_action.add_theme_color_override("font_color", Color("#ff4422"))


func _show_back_detail():
	detail_rarity.text = "← BACK"
	detail_rarity.add_theme_color_override("font_color", Color("#f5c869"))
	detail_icon.text = "↩"
	SpriteManager.apply(detail_icon_sprite, "", detail_icon)
	detail_name.text = "ELEVATOR"
	detail_name.add_theme_color_override("font_color", Color("#f5c869"))
	detail_description.text = "Leave the workshop and head back up."
	detail_trigger.text = "—"
	detail_applies.text = "—"
	detail_flavor.text = ""
	detail_action.text = "[SPACE] return to elevator"
	detail_action.add_theme_color_override("font_color", Color("#f5c869"))


func _format_applies(applies: Array) -> String:
	if applies.size() == CharmsData.MG_ALL.size():
		return "ALL MINIGAMES"
	var pretty: Array = []
	for m in applies:
		pretty.append(String(m).capitalize())
	return ", ".join(pretty)


# ─── Input ───
func _on_left():
	_peel_armed = -1
	_selected = (_selected - 1 + _navigation_size()) % _navigation_size()
	AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
	_refresh_selection()


func _on_right():
	_peel_armed = -1
	_selected = (_selected + 1) % _navigation_size()
	AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
	_refresh_selection()


func _on_press():
	var has_pending = GameManager.has_pending_charm()

	if _selected == GameManager.MAX_EQUIPPED_CHARMS:
		if has_pending:
			# Discard the pending sticker
			var lost_name = GameManager.pending_charm.get("name", "?")
			GameManager.discard_pending_charm()
			dialog.text = "Discarded: %s" % lost_name
			AudioController.play_sfx(AudioController.SFX_HIT)
			_after_pending_resolved()
		else:
			# Back to elevator (only available in view mode)
			SceneManager.go_to_elevator()
		return

	if has_pending:
		# Place pending into the selected slot (replaces if occupied → destroys old)
		var existing = GameManager.get_slot(_selected)
		var new_name = GameManager.pending_charm.get("name", "?")
		GameManager.place_pending_at_slot(_selected)
		if existing.is_empty():
			dialog.text = "Stuck %s on slot %d." % [new_name, _selected + 1]
		else:
			dialog.text = "Peeled %s, replaced with %s." % [existing.get("name", "?"), new_name]
		AudioController.play_sfx(AudioController.SFX_REVEAL_RARE)
		_after_pending_resolved()
		return

	# View mode: confirm peel (two-press destruct)
	var charm = GameManager.get_slot(_selected)
	if charm.is_empty():
		dialog.text = "Empty slot — find a sticker at Charm Co."
		return

	if _peel_armed != _selected:
		_peel_armed = _selected
		dialog.text = "Press SPACE again to PEEL %s — it will be destroyed." % charm.name
		AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
		_refresh_selection()
		return

	# Second press → destroy
	GameManager.peel_slot(_selected)
	dialog.text = "Peeled %s. Gone for good." % charm.name
	AudioController.play_sfx(AudioController.SFX_HIT)
	_peel_armed = -1


func _after_pending_resolved():
	_peel_armed = -1
	_rebuild()


func _back():
	if GameManager.has_pending_charm():
		dialog.text = "Resolve the new sticker first — place it or discard it."
		return
	SceneManager.go_to_elevator()
