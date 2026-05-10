extends Control


@onready var stats_label: Label = $StatsLabel
@onready var taunt_label: Label = $TauntLabel
@onready var play_again_button: Button = $PlayAgainButton
@onready var menu_button: Button = $MenuButton


@onready var devil_label: Label = $DevilEmoji
@onready var devil_sprite: TextureRect = $DevilEmoji/Sprite
@onready var background: TextureRect = $Background


func _ready():
	AudioController.play_music(AudioController.MUSIC_GAME_OVER)
	SpriteManager.apply_or_keep(background, SpriteManager.BG_GAME_OVER)
	SpriteManager.apply(devil_sprite, SpriteManager.UI_DEVIL_SILHOUETTE, devil_label)

	var taunts = [
		"The house always wins.",
		"You folded the moment you walked in.",
		"Don't take it personally. It's just business.",
		"Your luck ran out three floors ago.",
		"Better demons have lasted longer.",
	]
	taunt_label.text = taunts[randi() % taunts.size()]

	stats_label.text = "Floor reached: %d   |   Run #%d   |   Mode: %s" % [
		GameManager.current_floor,
		GameManager.run_number,
		GameManager.game_mode.to_upper(),
	]

	play_again_button.pressed.connect(_play_again)
	menu_button.pressed.connect(_menu)
	InputManager.button_2_left_pressed.connect(_play_again)
	InputManager.button_2_right_pressed.connect(_menu)
	InputManager.button_1_pressed.connect(_play_again)


func _play_again():
	GameManager.start_new_run(GameManager.game_mode)
	SceneManager.go_to_elevator()


func _menu():
	SceneManager.go_to_main_menu()
