extends Control


@onready var headline: Label = $Headline
@onready var floor_label: Label = $FloorLabel
@onready var gold_line: Label = $RewardsBox/GoldLine
@onready var token_line: Label = $RewardsBox/TokenLine
@onready var heal_line: Label = $RewardsBox/HealLine
@onready var continue_button: Button = $ContinueButton
@onready var skip_hint: Label = $SkipHint
@onready var medal: Label = $Medal
@onready var medal_sprite: TextureRect = $Medal/Sprite
@onready var background: TextureRect = $Background


const AUTO_ADVANCE_SECONDS: float = 2.6


var _gold_total: int = 0
var _gold_displayed: int = 0
var _advance_pending: bool = true


func _ready():
	AudioController.play_sfx(AudioController.SFX_FLOOR_CLEARED)

	var f = GameManager.current_floor
	var was_boss = (f > 0 and f % 5 == 0) or GameManager.current_enemy.get("is_boss", false)

	var gold_reward = 8 + f * 2
	var token_reward = 0

	SpriteManager.apply_or_keep(background, SpriteManager.BG_REWARD)

	if was_boss:
		gold_reward += 12
		token_reward = 1
		medal.text = "👑"
		SpriteManager.apply(medal_sprite, SpriteManager.UI_MEDAL_BOSS, medal)
	else:
		medal.text = "✦"
		SpriteManager.apply(medal_sprite, SpriteManager.UI_MEDAL_CLEAR, medal)
	if f >= 11:
		gold_reward += 4
	if f >= 21:
		gold_reward += 6

	_gold_total = gold_reward
	GameManager.add_gold(gold_reward)
	if token_reward > 0:
		GameManager.add_tokens(token_reward)

	headline.text = "FLOOR %d CLEARED" % f
	floor_label.text = GameManager.get_district_display_name().to_upper()
	gold_line.text = "+0 Gold"
	token_line.text = "+%d Token" % token_reward if token_reward > 0 else "—"
	heal_line.text = "♥ FULL HEAL ♥"
	heal_line.add_theme_color_override("font_color", Color("#4cae6a"))

	GameManager.advance_floor()

	continue_button.pressed.connect(_continue)
	InputManager.button_1_pressed.connect(_continue)
	InputManager.button_2_left_pressed.connect(_continue)
	InputManager.button_2_right_pressed.connect(_continue)

	_animate_gold_ticker()
	_schedule_auto_advance()


func _animate_gold_ticker():
	var steps = max(1, _gold_total)
	var per_step = max(0.02, 1.4 / float(steps))
	for i in range(steps + 1):
		_gold_displayed = i
		gold_line.text = "+%d Gold" % _gold_displayed
		await get_tree().create_timer(per_step).timeout


func _schedule_auto_advance():
	for remaining in range(int(AUTO_ADVANCE_SECONDS), 0, -1):
		skip_hint.text = "[SPACE] continue   ·   auto in %ds" % remaining
		await get_tree().create_timer(1.0).timeout
		if not _advance_pending:
			return
	if _advance_pending:
		_continue()


func _continue():
	if not _advance_pending:
		return
	_advance_pending = false
	if GameManager.current_floor > 30:
		SceneManager.go_to_victory()
	else:
		SceneManager.go_to_elevator()
