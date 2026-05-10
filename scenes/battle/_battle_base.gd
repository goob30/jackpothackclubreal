class_name BattleBase
extends Control


@onready var hud: BattleHUD = $BattleHUD


func _ready():
	if GameManager.current_enemy.is_empty():
		_setup_debug_battle()

	if not GameManager.player_died_normal.is_connected(_on_player_died):
		GameManager.player_died_normal.connect(_on_player_died)
	if not GameManager.player_died_baby.is_connected(_on_player_died_baby):
		GameManager.player_died_baby.connect(_on_player_died_baby)
	if not GameManager.floor_cleared.is_connected(_on_floor_cleared):
		GameManager.floor_cleared.connect(_on_floor_cleared)
	if not GameManager.new_enemy_appeared.is_connected(_on_new_enemy):
		GameManager.new_enemy_appeared.connect(_on_new_enemy)
	if not GameManager.inter_enemy_heal.is_connected(_on_inter_enemy_heal):
		GameManager.inter_enemy_heal.connect(_on_inter_enemy_heal)

	AudioController.play_district_music()
	hud.update_all()


func _setup_debug_battle():
	GameManager.start_new_run(GameManager.MODE_NORMAL)
	GameManager.start_floor_battle(FloorData.get_floor_enemies(1))


func _on_player_died():
	await get_tree().create_timer(0.6).timeout
	SceneManager.go_to_game_over()


func _on_player_died_baby():
	await get_tree().create_timer(0.6).timeout
	SceneManager.go_to_elevator()


func _on_floor_cleared():
	AudioController.play_sfx(AudioController.SFX_FLOOR_CLEARED)
	await get_tree().create_timer(1.0).timeout
	SceneManager.go_to_reward()


func _on_new_enemy(_enemy):
	hud.update_all()


func _on_inter_enemy_heal(amount: int):
	if hud:
		hud.spawn_damage_number(-amount, hud.get_player_center(), Color("#4cae6a"))
	AudioController.play_sfx(AudioController.SFX_HEAL)


func apply_damage_to_enemy(amount: int):
	if amount <= 0:
		return
	AudioController.play_sfx(AudioController.SFX_HIT)
	hud.spawn_damage_number(amount, hud.get_enemy_center(), Color("#e6164a"))
	hud.flash_enemy(Color(2, 0.4, 0.4))
	GameManager.current_enemy_take_damage(amount)
	hud.update_enemy()


func apply_damage_to_player(amount: int, block: int = 0):
	var net = max(0, amount - block)
	if net <= 0:
		hud.spawn_damage_number(amount, hud.get_player_center(), Color(0.6, 0.9, 1))
		return
	hud.spawn_damage_number(net, hud.get_player_center(), Color("#e6164a"))
	GameManager.take_damage(net)


func heal_player(amount: int):
	if amount <= 0:
		return
	AudioController.play_sfx(AudioController.SFX_HEAL)
	hud.spawn_damage_number(-amount, hud.get_player_center(), Color("#4cae6a"))
	GameManager.heal(amount)
