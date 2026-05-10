extends BattleBase


@onready var player_die: Label = $BattleHUD/PlayerHalf/GameAreaContainer/DiceRow/PlayerDie
@onready var enemy_die: Label = $BattleHUD/PlayerHalf/GameAreaContainer/DiceRow/EnemyDie
@onready var versus_label: Label = $BattleHUD/PlayerHalf/GameAreaContainer/DiceRow/Versus


const FACES: Array = ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]


var is_rolling: bool = false


func _ready():
	super._ready()
	InputManager.button_1_pressed.connect(_on_roll)
	InputManager.dice_rolled.connect(_on_physical_roll)
	hud.set_button_hints("[SPACE] ROLL  /  press 1-6 to force a face")


func _on_physical_roll(face: int):
	if is_rolling:
		return
	_resolve_round(face)


func _on_roll():
	if is_rolling:
		return
	_resolve_round(0)


func _resolve_round(forced_face: int):
	is_rolling = true
	hud.set_button_hints("ROLLING…")
	AudioController.play_sfx(AudioController.SFX_DICE_ROLL)

	var player_roll = forced_face if forced_face > 0 else (randi() % 6 + 1)
	var enemy_roll = randi() % 6 + 1

	await _animate_die(player_die, player_roll)
	await _animate_die(enemy_die, enemy_roll)

	var mods = CharmResolver.apply_charms(player_roll, 0, CharmsData.MG_DICE)
	if mods.force_six:
		player_roll = 6
		player_die.text = FACES[5]
	if mods.copy_enemy_roll:
		player_roll = enemy_roll
		player_die.text = FACES[player_roll - 1]
	if mods.reroll_better:
		var alt = randi() % 6 + 1
		if alt > player_roll:
			player_roll = alt
			player_die.text = FACES[alt - 1]
	if mods.reroll_until_six and player_roll < 6:
		var attempts = 0
		while player_roll < 6 and attempts < 8:
			player_roll = randi() % 6 + 1
			attempts += 1
		player_die.text = FACES[player_roll - 1]
	if mods.force_enemy_reroll:
		var alt2 = randi() % 6 + 1
		if alt2 < enemy_roll:
			enemy_roll = alt2
			enemy_die.text = FACES[enemy_roll - 1]

	player_roll += mods.value_bonus
	GameManager.last_roll_value = player_roll

	await get_tree().create_timer(0.4).timeout

	if player_roll > enemy_roll:
		var diff = player_roll - enemy_roll
		var dmg = max(1, diff) + mods.flat_extra_damage
		dmg = int(dmg * mods.damage_multiplier)
		apply_damage_to_enemy(dmg)
		CharmResolver.apply_post_win_rewards(mods, dmg)
		versus_label.text = "WIN"
		versus_label.add_theme_color_override("font_color", Color("#4cae6a"))
	elif enemy_roll > player_roll:
		if not mods.skip_enemy:
			var diff2 = enemy_roll - player_roll
			apply_damage_to_player(diff2, mods.block)
		versus_label.text = "LOSE"
		versus_label.add_theme_color_override("font_color", Color("#e6164a"))
	else:
		versus_label.text = "TIE"
		versus_label.add_theme_color_override("font_color", Color("#d4a542"))

	await get_tree().create_timer(1.0).timeout

	versus_label.text = "VS"
	versus_label.add_theme_color_override("font_color", Color("#b8a98e"))
	hud.set_button_hints("[SPACE] ROLL  /  press 1-6 to force a face")
	is_rolling = false


func _animate_die(die_label: Label, final_face: int):
	var sprite: TextureRect = die_label.get_node_or_null("Sprite")
	for i in range(10):
		var face = (randi() % 6) + 1
		die_label.text = FACES[face - 1]
		if sprite:
			SpriteManager.apply(sprite, SpriteManager.die_for_face(face), die_label)
		await get_tree().create_timer(0.05).timeout
	var settled = clamp(final_face, 1, 6)
	die_label.text = FACES[settled - 1]
	if sprite:
		SpriteManager.apply(sprite, SpriteManager.die_for_face(settled), die_label)
	AudioController.play_sfx(AudioController.SFX_DICE_LAND)
	var tw = create_tween()
	tw.tween_property(die_label, "scale", Vector2(1.3, 1.3), 0.1)
	tw.tween_property(die_label, "scale", Vector2.ONE, 0.15)
	await tw.finished
