extends Control


@onready var enemy_portrait: Label = $EnemyHalf/EnemyPortrait
@onready var enemy_portrait_sprite: TextureRect = $EnemyHalf/EnemyPortrait/Sprite
@onready var enemy_name: Label = $EnemyHalf/EnemyName
@onready var enemy_hp_bar: TextureProgressBar = $EnemyHalf/EnemyHPContainer/EnemyHPBar
@onready var enemy_hp_value: Label = $EnemyHalf/EnemyHPContainer/HPValue
@onready var next_attack_value: Label = $EnemyHalf/NextAttackBox/NextAttackValue
@onready var queue_icons: HBoxContainer = $EnemyHalf/QueueIcons
@onready var coin: Label = $PlayerHalf/GamemodeArea/Coin
@onready var coin_sprite: TextureRect = $PlayerHalf/GamemodeArea/Coin/Sprite
@onready var background: TextureRect = $Background
@onready var player_hp_bar: TextureProgressBar = $PlayerHalf/PlayerHPContainer/PlayerHPBar
@onready var player_hp_value: Label = $PlayerHalf/PlayerHPContainer/HPValue
@onready var button_hints: Label = $PlayerHalf/ButtonHints


var player_choice: String = ""
var is_flipping: bool = false
const DAMAGE: int = 2


func _ready():
	if GameManager.current_enemy.is_empty():
		GameManager.start_new_run(GameManager.MODE_NORMAL)
		GameManager.start_floor_battle(FloorData.get_floor_enemies(1))
	
	InputManager.button_2_left_pressed.connect(_on_heads)
	InputManager.button_2_right_pressed.connect(_on_tails)
	InputManager.button_1_pressed.connect(_on_flip)
	
	GameManager.hp_changed.connect(_update_player_hp)
	GameManager.new_enemy_appeared.connect(_on_new_enemy)
	GameManager.floor_cleared.connect(_on_floor_cleared)
	GameManager.player_died_normal.connect(_on_player_died)
	GameManager.player_died_baby.connect(_on_player_died_baby)

	SpriteManager.apply_or_keep(background, SpriteManager.bg_for_district(GameManager.get_district(), GameManager.is_final_floor()))
	_set_coin("?")

	_update_all()


func _update_all():
	_update_enemy()
	_update_queue()
	_update_player_hp(GameManager.player_hp, GameManager.player_max_hp)


func _update_queue():
	for child in queue_icons.get_children():
		child.queue_free()
	for enemy in GameManager.enemies_remaining:
		var lbl = Label.new()
		lbl.text = enemy.get("portrait_emoji", "👻")
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.custom_minimum_size = Vector2(40, 40)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		queue_icons.add_child(lbl)

		var sprite = TextureRect.new()
		sprite.name = "Sprite"
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.visible = false
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
		lbl.add_child(sprite)
		SpriteManager.apply(sprite, String(enemy.get("icon", "")), lbl)


func _update_enemy():
	if GameManager.current_enemy.is_empty():
		return
	var e = GameManager.current_enemy
	enemy_name.text = String(e.get("name", "?")).to_upper()
	enemy_portrait.text = e.get("portrait_emoji", "😈")
	SpriteManager.apply(enemy_portrait_sprite, String(e.get("portrait", "")), enemy_portrait)
	var hp = e.get("hp", 0)
	var max_hp = e.get("max_hp", hp)
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = hp
	enemy_hp_value.text = "%d/%d" % [hp, max_hp]
	next_attack_value.text = str(e.get("next_attack", 0))


func _set_coin(face_text: String):
	coin.text = face_text
	var path := ""
	match face_text:
		"H", "H?":
			path = SpriteManager.UI_COIN_HEADS
		"T", "T?":
			path = SpriteManager.UI_COIN_TAILS
		"?":
			path = SpriteManager.UI_COIN_UNKNOWN
		_:
			path = ""
	SpriteManager.apply(coin_sprite, path, coin)


func _update_player_hp(new_hp: int, max_hp: int):
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = new_hp
	player_hp_value.text = "%d/%d" % [new_hp, max_hp]


func _on_heads():
	if is_flipping:
		return
	player_choice = "heads"
	_set_coin("H?")


func _on_tails():
	if is_flipping:
		return
	player_choice = "tails"
	_set_coin("T?")


func _on_flip():
	if is_flipping or player_choice == "":
		return
	is_flipping = true
	button_hints.text = "FLIPPING..."
	
	for i in range(8):
		_set_coin("H" if i % 2 == 0 else "T")
		await get_tree().create_timer(0.1).timeout

	var result = "heads" if randi() % 2 == 0 else "tails"
	_set_coin(result.substr(0, 1).to_upper())
	
	await get_tree().create_timer(0.4).timeout
	
	var mods = CharmResolver.apply_charms(0, DAMAGE, CharmsData.MG_COINFLIP)
	if player_choice == result:
		var dealt = mods.damage_to_enemy
		GameManager.current_enemy_take_damage(dealt)
		_update_enemy()
		CharmResolver.apply_post_win_rewards(mods, dealt)
	else:
		if not mods.skip_enemy:
			var dmg = GameManager.current_enemy.get("next_attack", DAMAGE)
			var net = max(0, dmg - mods.block)
			GameManager.take_damage(net)
	
	await get_tree().create_timer(0.6).timeout
	
	player_choice = ""
	is_flipping = false
	_set_coin("?")
	button_hints.text = "[←] HEADS     [→] TAILS     [SPACE] FLIP"


func _on_new_enemy(_enemy):
	_update_enemy()
	_update_queue()


func _on_floor_cleared():
	_set_coin("WIN")
	button_hints.text = "FLOOR CLEARED!"
	await get_tree().create_timer(2.0).timeout
	SceneManager.go_to_reward()


func _on_player_died():
	_set_coin("X")
	button_hints.text = "YOU DIED"
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_game_over()


func _on_player_died_baby():
	_set_coin("💀")
	button_hints.text = "BABY DEATH — RETREATING"
	await get_tree().create_timer(1.2).timeout
	SceneManager.go_to_elevator()
