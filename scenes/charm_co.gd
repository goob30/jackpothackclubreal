extends Control


@onready var brass_button: Button = $Machine/BrassButton
@onready var soul_button: Button = $Machine/SoulButton
@onready var lever: Label = $Machine/Lever
@onready var lever_sprite: TextureRect = $Machine/Lever/Sprite
@onready var rolling_capsule: Label = $Machine/RollingCapsule
@onready var rolling_capsule_sprite: TextureRect = $Machine/RollingCapsule/Sprite
@onready var capsule_start_y: float = 0.0
@onready var dialogue_label: Label = $DialogueBubble/Label
@onready var vendor_label: Label = $DialogueBubble/VendorEmoji
@onready var vendor_sprite: TextureRect = $DialogueBubble/VendorEmoji/Sprite
@onready var reveal_panel: Panel = $RevealPanel
@onready var reveal_charm_label: Label = $RevealPanel/ChargeIcon
@onready var reveal_charm_sprite: TextureRect = $RevealPanel/ChargeIcon/Sprite
@onready var reveal_name: Label = $RevealPanel/CharmName
@onready var reveal_desc: Label = $RevealPanel/CharmDesc
@onready var gold_label: Label = $HUDBar/GoldLabel
@onready var token_label: Label = $HUDBar/TokenLabel
@onready var inventory_label: Label = $HUDBar/InventoryLabel
@onready var back_button: Button = $BackButton
@onready var workshop_button: Button = $WorkshopButton
@onready var background: TextureRect = $Background


const BRASS_COST: int = 15
const SOUL_COST: int = 1


var is_pulling: bool = false


func _ready():
	AudioController.play_music(AudioController.MUSIC_CHARM_CO)

	brass_button.pressed.connect(_on_brass_pull)
	soul_button.pressed.connect(_on_soul_pull)
	back_button.pressed.connect(_back)
	workshop_button.pressed.connect(_go_workshop)

	InputManager.button_2_left_pressed.connect(_on_brass_pull)
	InputManager.button_2_right_pressed.connect(_on_soul_pull)
	InputManager.button_1_pressed.connect(_back_or_dismiss)

	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.tokens_changed.connect(_on_tokens_changed)
	GameManager.charm_added_to_inventory.connect(_on_charm_added)

	capsule_start_y = rolling_capsule.position.y
	rolling_capsule.hide()
	reveal_panel.hide()

	SpriteManager.apply_or_keep(background, SpriteManager.BG_CHARM_CO)
	SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_DEFAULT, vendor_label)
	SpriteManager.apply(lever_sprite, SpriteManager.MACHINE_LEVER, lever)

	_show_greeting()
	_update_buttons()
	_update_hud()


func _show_greeting():
	var greetings = [
		"Step right up! Charm Co. — your luck, our specialty.",
		"You look like a winner. Statistically, that's unlikely.",
		"Brass for hope. Souls for the real stuff.",
		"Spend it all. The Devil prefers his guests broke.",
		"Each pull is a small contract. You're fine with that, right?",
	]
	dialogue_label.text = greetings[randi() % greetings.size()]


func _on_gold_changed(_g):
	_update_buttons()
	_update_hud()


func _on_tokens_changed(_t):
	_update_buttons()
	_update_hud()


func _on_charm_added(_c):
	_update_hud()


func _update_buttons():
	brass_button.disabled = is_pulling or GameManager.gold < BRASS_COST
	soul_button.disabled = is_pulling or GameManager.tokens < SOUL_COST


func _update_hud():
	gold_label.text = "Gold: %d" % GameManager.gold
	token_label.text = "Tokens: %d" % GameManager.tokens
	inventory_label.text = "Stickers: %d/%d on card" % [
		GameManager.count_equipped(),
		GameManager.MAX_EQUIPPED_CHARMS,
	]
	if GameManager.has_pending_charm():
		inventory_label.text += "   ✦ pending"


func _on_brass_pull():
	if is_pulling:
		return
	if not GameManager.spend_gold(BRASS_COST):
		dialogue_label.text = "Need %d gold, friend." % BRASS_COST
		return
	await _execute_pull("brass")


func _on_soul_pull():
	if is_pulling:
		return
	if not GameManager.spend_tokens(SOUL_COST):
		dialogue_label.text = "Tokens, please. No tokens, no soul charms."
		return
	await _execute_pull("soul")


func _execute_pull(slot: String):
	is_pulling = true
	_update_buttons()

	dialogue_label.text = _get_pull_quote(slot)
	AudioController.play_sfx(AudioController.SFX_COIN_INSERT if slot == "brass" else AudioController.SFX_TOKEN_INSERT)
	await get_tree().create_timer(0.5).timeout

	AudioController.play_sfx(AudioController.SFX_LEVER_PULL)
	var lever_tw = create_tween()
	lever_tw.tween_property(lever, "rotation", deg_to_rad(-45), 0.4)
	lever_tw.tween_property(lever, "rotation", 0, 0.4)
	await lever_tw.finished

	var rarity = _determine_rarity(slot, GameManager.current_floor)
	var charm = CharmsData.get_random_charm_by_rarity(rarity)

	rolling_capsule.text = _capsule_emoji(rarity)
	rolling_capsule.modulate = CharmsData.get_rarity_color(rarity)
	SpriteManager.apply(rolling_capsule_sprite, SpriteManager.capsule_for_rarity(rarity), rolling_capsule)
	rolling_capsule.position.y = capsule_start_y
	rolling_capsule.show()
	AudioController.play_sfx(AudioController.SFX_CAPSULE_ROLL)

	var roll_tw = create_tween().set_parallel(true)
	roll_tw.tween_property(rolling_capsule, "position:y", capsule_start_y + 220.0, 1.6)
	roll_tw.tween_property(rolling_capsule, "rotation", deg_to_rad(720), 1.6)
	await roll_tw.finished

	AudioController.play_sfx(AudioController.SFX_CAPSULE_LAND)
	await get_tree().create_timer(0.4).timeout

	_show_reveal(charm)


func _capsule_emoji(rarity: String) -> String:
	match rarity:
		"common": return "⚪"
		"uncommon": return "🟢"
		"rare": return "🔵"
		"legendary": return "🟣"
		_: return "🟡"


func _determine_rarity(slot: String, floor_num: int) -> String:
	var roll = randi() % 100
	if slot == "brass":
		if floor_num <= 5:
			if roll < 70: return "common"
			elif roll < 95: return "uncommon"
			else: return "rare"
		elif floor_num <= 10:
			if roll < 50: return "common"
			elif roll < 85: return "uncommon"
			elif roll < 98: return "rare"
			else: return "legendary"
		else:
			if roll < 30: return "common"
			elif roll < 70: return "uncommon"
			elif roll < 95: return "rare"
			else: return "legendary"
	else:
		if floor_num <= 5:
			if roll < 40: return "uncommon"
			elif roll < 90: return "rare"
			else: return "legendary"
		elif floor_num <= 10:
			if roll < 25: return "uncommon"
			elif roll < 80: return "rare"
			else: return "legendary"
		else:
			if roll < 10: return "uncommon"
			elif roll < 60: return "rare"
			else: return "legendary"


func _show_reveal(charm: Dictionary):
	reveal_panel.show()
	reveal_panel.modulate.a = 0.0
	AudioController.play_sfx(AudioController.SFX_CAPSULE_OPEN)

	reveal_charm_label.text = _capsule_emoji(charm.rarity)
	reveal_charm_label.modulate = CharmsData.get_rarity_color(charm.rarity)
	SpriteManager.apply(reveal_charm_sprite, SpriteManager.charm_icon(charm.id), reveal_charm_label)
	reveal_name.text = "%s  (%s)" % [String(charm.name).to_upper(), CharmsData.get_rarity_display_name(charm.rarity)]
	reveal_name.add_theme_color_override("font_color", CharmsData.get_rarity_color(charm.rarity))
	reveal_desc.text = String(charm.description)

	var fade_in = create_tween()
	fade_in.tween_property(reveal_panel, "modulate:a", 1.0, 0.3)

	AudioController.play_sfx(AudioController.get_reveal_sfx_for_rarity(charm.rarity))

	GameManager.add_charm_to_inventory(charm)
	var card_full = GameManager.has_pending_charm()

	if card_full:
		dialogue_label.text = "Your card is full. Pick a slot to peel — that one's gone for good."
		SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_SHOCKED, vendor_label)
	elif charm.rarity == "legendary":
		dialogue_label.text = _get_legendary_quote()
		SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_SHOCKED, vendor_label)
	elif charm.rarity == "rare":
		dialogue_label.text = "Now THAT'S worth something."
		SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_HAPPY, vendor_label)
	elif charm.rarity == "uncommon":
		dialogue_label.text = "Not bad. Not bad at all."
		SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_DEFAULT, vendor_label)
	else:
		dialogue_label.text = _get_common_quote()
		SpriteManager.apply(vendor_sprite, SpriteManager.VENDOR_ANGRY, vendor_label)

	await get_tree().create_timer(2.5).timeout
	var fade_out = create_tween()
	fade_out.tween_property(reveal_panel, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	reveal_panel.hide()
	rolling_capsule.hide()
	if card_full:
		SceneManager.go_to_workshop()
		return
	is_pulling = false
	_update_buttons()


func _get_pull_quote(slot: String) -> String:
	if slot == "brass":
		var q = ["Brass it is.", "A copper for the cosmos.", "Cheap. Honest. Mostly."]
		return q[randi() % q.size()]
	var q2 = ["A SOUL? Bold of you.", "Quality buyer. Quality risk.", "The Devil tracks every soul slot."]
	return q2[randi() % q2.size()]


func _get_legendary_quote() -> String:
	var q = [
		"Oh. OH. That's actually good.",
		"Don't tell the boss I let you have that.",
		"You broke the machine. Statistically.",
	]
	return q[randi() % q.size()]


func _get_common_quote() -> String:
	var q = [
		"Eh. Better luck next time.",
		"You get what you pay for.",
		"Brass tax. The Devil thanks you.",
	]
	return q[randi() % q.size()]


func _back_or_dismiss():
	if is_pulling:
		return
	_back()


func _back():
	if is_pulling:
		return
	SceneManager.go_to_elevator()


func _go_workshop():
	if is_pulling:
		return
	SceneManager.go_to_workshop()
