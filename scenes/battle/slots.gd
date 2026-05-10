extends BattleBase


@onready var reel1: Label = $BattleHUD/PlayerHalf/GameAreaContainer/SlotRow/Reel1
@onready var reel2: Label = $BattleHUD/PlayerHalf/GameAreaContainer/SlotRow/Reel2
@onready var reel3: Label = $BattleHUD/PlayerHalf/GameAreaContainer/SlotRow/Reel3
@onready var result_label: Label = $BattleHUD/PlayerHalf/GameAreaContainer/ResultLabel


const SYMBOLS: Array = ["🍒", "🔔", "7️⃣", "💀", "😈"]
const SYMBOL_KEYS: Array = ["cherry", "bell", "seven", "skull", "devil"]
const TRIPLE_DAMAGE: int = 10
const DOUBLE_DAMAGE: int = 4


func _sprite_for(symbol: String) -> String:
	var idx = SYMBOLS.find(symbol)
	if idx < 0:
		return ""
	return SpriteManager.slot_symbol_for(SYMBOL_KEYS[idx])


var is_spinning: bool = false


func _ready():
	super._ready()
	InputManager.button_1_pressed.connect(_on_spin)
	hud.set_button_hints("[SPACE] SPIN")


func _on_spin():
	if is_spinning:
		return
	is_spinning = true
	hud.set_button_hints("SPINNING…")
	result_label.text = ""
	AudioController.play_sfx(AudioController.SFX_SLOTS_SPIN)

	var s1 = SYMBOLS[randi() % SYMBOLS.size()]
	var s2 = SYMBOLS[randi() % SYMBOLS.size()]
	var s3 = SYMBOLS[randi() % SYMBOLS.size()]

	await _animate_reel(reel1, s1, 0.8)
	await _animate_reel(reel3, s3, 0.7)
	await _animate_reel(reel2, s2, 0.6)

	var mods = CharmResolver.apply_charms(0, 0, CharmsData.MG_SLOTS)

	var matches = 0
	if s1 == s2 and s2 == s3:
		matches = 3
	elif s1 == s2 or s2 == s3 or s1 == s3:
		matches = 2

	await get_tree().create_timer(0.3).timeout

	if matches == 3:
		var dmg = (TRIPLE_DAMAGE + mods.flat_extra_damage) * mods.damage_multiplier
		var d = int(dmg)
		apply_damage_to_enemy(d)
		CharmResolver.apply_post_win_rewards(mods, d)
		result_label.text = "JACKPOT!"
		result_label.add_theme_color_override("font_color", Color("#ff2e88"))
	elif matches == 2:
		var dmg2 = (DOUBLE_DAMAGE + mods.flat_extra_damage) * mods.damage_multiplier
		var d2 = int(dmg2)
		apply_damage_to_enemy(d2)
		CharmResolver.apply_post_win_rewards(mods, d2)
		result_label.text = "PAIR"
		result_label.add_theme_color_override("font_color", Color("#4cae6a"))
	else:
		if not mods.skip_enemy:
			var enemy_atk = int(GameManager.current_enemy.get("next_attack", 2))
			apply_damage_to_player(enemy_atk, mods.block)
		result_label.text = "BUST"
		result_label.add_theme_color_override("font_color", Color("#e6164a"))

	await get_tree().create_timer(1.0).timeout
	hud.set_button_hints("[SPACE] SPIN")
	is_spinning = false


func _animate_reel(reel: Label, final_symbol: String, duration: float):
	var sprite: TextureRect = reel.get_node_or_null("Sprite")
	var elapsed = 0.0
	var step = 0.06
	while elapsed < duration:
		var sym = SYMBOLS[randi() % SYMBOLS.size()]
		reel.text = sym
		if sprite:
			SpriteManager.apply(sprite, _sprite_for(sym), reel)
		await get_tree().create_timer(step).timeout
		elapsed += step
	reel.text = final_symbol
	if sprite:
		SpriteManager.apply(sprite, _sprite_for(final_symbol), reel)
	AudioController.play_sfx(AudioController.SFX_SLOTS_STOP)
	var tw = create_tween()
	tw.tween_property(reel, "scale", Vector2(1.2, 1.2), 0.08)
	tw.tween_property(reel, "scale", Vector2.ONE, 0.12)
