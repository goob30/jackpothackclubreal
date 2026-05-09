extends Control


@onready var enemy_portrait: Label = $EnemyHalf/EnemyPortrait
@onready var enemy_name: Label = $EnemyHalf/EnemyName
@onready var enemy_hp_bar: ProgressBar = $EnemyHalf/EnemyHPContainer/EnemyHPBar
@onready var enemy_hp_value: Label = $EnemyHalf/EnemyHPContainer/HPValue
@onready var next_attack_value: Label = $EnemyHalf/NextAttackBox/NextAttackValue
@onready var coin: Label = $PlayerHalf/GamemodeArea/Coin
@onready var player_hp_bar: ProgressBar = $PlayerHalf/PlayerHPContainer/PlayerHPBar
@onready var player_hp_value: Label = $PlayerHalf/PlayerHPContainer/HPValue
@onready var button_hints: Label = $PlayerHalf/ButtonHints


var player_choice: String = ""
var is_flipping: bool = false
const DAMAGE: int = 2


func _ready():
	if GameManager.current_enemy.is_empty():
		GameManager.start_new_run(GameManager.MODE_NORMAL)
		GameManager.start_floor_battle([
			{"id": "imp", "name": "Imp", "hp": 5, "max_hp": 5, "minigame": "coinflip", "next_attack": 3, "portrait": "😈"},
			{"id": "shark", "name": "Card Shark", "hp": 8, "max_hp": 8, "minigame": "coinflip", "next_attack": 4, "portrait": "🎴"},
			{"id": "soul", "name": "Lost Soul", "hp": 6, "max_hp": 6, "minigame": "coinflip", "next_attack": 2, "portrait": "👻"}
		])
	
	InputManager.button_2_left_pressed.connect(_on_heads)
	InputManager.button_2_right_pressed.connect(_on_tails)
	InputManager.button_1_pressed.connect(_on_flip)
	
	GameManager.hp_changed.connect(_update_player_hp)
	GameManager.new_enemy_appeared.connect(_on_new_enemy)
	GameManager.floor_cleared.connect(_on_floor_cleared)
	GameManager.player_died_normal.connect(_on_player_died)
	GameManager.player_died_baby.connect(_on_player_died)
	
	_update_all()


func _update_all():
	_update_enemy()
	_update_player_hp(GameManager.player_hp, GameManager.player_max_hp)


func _update_enemy():
	if GameManager.current_enemy.is_empty():
		return
	enemy_name.text = GameManager.current_enemy.name.to_upper()
	enemy_portrait.text = GameManager.current_enemy.get("portrait", "😈")
	var hp = GameManager.current_enemy.get("hp", 0)
	var max_hp = GameManager.current_enemy.get("max_hp", hp)
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = hp
	enemy_hp_value.text = "%d/%d" % [hp, max_hp]
	next_attack_value.text = str(GameManager.current_enemy.get("next_attack", 0))


func _update_player_hp(new_hp: int, max_hp: int):
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = new_hp
	player_hp_value.text = "%d/%d" % [new_hp, max_hp]


func _on_heads():
	if is_flipping:
		return
	player_choice = "heads"
	coin.text = "H?"


func _on_tails():
	if is_flipping:
		return
	player_choice = "tails"
	coin.text = "T?"


func _on_flip():
	if is_flipping or player_choice == "":
		return
	is_flipping = true
	button_hints.text = "FLIPPING..."
	
	for i in range(8):
		coin.text = "H" if i % 2 == 0 else "T"
		await get_tree().create_timer(0.1).timeout
	
	var result = "heads" if randi() % 2 == 0 else "tails"
	coin.text = result.substr(0, 1).to_upper()
	
	await get_tree().create_timer(0.4).timeout
	
	if player_choice == result:
		GameManager.current_enemy_take_damage(DAMAGE)
		_update_enemy()
	else:
		var dmg = GameManager.current_enemy.get("next_attack", DAMAGE)
		GameManager.take_damage(dmg)
	
	await get_tree().create_timer(0.6).timeout
	
	player_choice = ""
	is_flipping = false
	coin.text = "?"
	button_hints.text = "[←] HEADS     [→] TAILS     [SPACE] FLIP"


func _on_new_enemy(_enemy):
	_update_enemy()


func _on_floor_cleared():
	coin.text = "WIN"
	button_hints.text = "FLOOR CLEARED!"
	await get_tree().create_timer(2.0).timeout


func _on_player_died():
	coin.text = "X"
	button_hints.text = "YOU DIED"
