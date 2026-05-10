extends Control


@onready var stats_label: Label = $StatsLabel
@onready var new_run_button: Button = $NewRunButton
@onready var menu_button: Button = $MenuButton


@onready var crown_label: Label = $Crown
@onready var crown_sprite: TextureRect = $Crown/Sprite
@onready var background: TextureRect = $Background


func _ready():
	AudioController.play_music(AudioController.MUSIC_VICTORY)
	SpriteManager.apply_or_keep(background, SpriteManager.BG_VICTORY)
	SpriteManager.apply(crown_sprite, SpriteManager.UI_CROWN, crown_label)

	stats_label.text = "Run #%d   |   Mode: %s   |   Charms held: %d" % [
		GameManager.run_number,
		GameManager.game_mode.to_upper(),
		GameManager.count_equipped(),
	]

	new_run_button.pressed.connect(_new_run)
	menu_button.pressed.connect(_menu)
	InputManager.button_2_left_pressed.connect(_new_run)
	InputManager.button_2_right_pressed.connect(_menu)
	InputManager.button_1_pressed.connect(_new_run)


func _new_run():
	GameManager.start_new_run(GameManager.game_mode)
	SceneManager.go_to_elevator()


func _menu():
	SceneManager.go_to_main_menu()
