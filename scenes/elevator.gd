extends Control


const COLS: int = 5

const LAYOUT: Array = [
	{"label": "1",  "kind": "floor", "floor": 1},
	{"label": "2",  "kind": "floor", "floor": 2},
	{"label": "3",  "kind": "floor", "floor": 3},
	{"label": "4",  "kind": "floor", "floor": 4},
	{"label": "5",  "kind": "floor", "floor": 5},
	{"label": "6",  "kind": "floor", "floor": 6},
	{"label": "7",  "kind": "floor", "floor": 7},
	{"label": "8",  "kind": "floor", "floor": 8},
	{"label": "9",  "kind": "floor", "floor": 9},
	{"label": "10", "kind": "floor", "floor": 10},
	{"label": "11", "kind": "floor", "floor": 11},
	{"label": "12", "kind": "floor", "floor": 12},
	{"label": "13", "kind": "floor", "floor": 13},
	{"label": "14", "kind": "floor", "floor": 14},
	{"label": "15", "kind": "floor", "floor": 15},
	{"label": "16", "kind": "floor", "floor": 16},
	{"label": "17", "kind": "floor", "floor": 17},
	{"label": "18", "kind": "floor", "floor": 18},
	{"label": "19", "kind": "floor", "floor": 19},
	{"label": "20", "kind": "floor", "floor": 20},
	{"label": "21", "kind": "floor", "floor": 21},
	{"label": "22", "kind": "floor", "floor": 22},
	{"label": "23", "kind": "floor", "floor": 23},
	{"label": "24", "kind": "floor", "floor": 24},
	{"label": "25", "kind": "floor", "floor": 25},
	{"label": "26", "kind": "floor", "floor": 26},
	{"label": "27", "kind": "floor", "floor": 27},
	{"label": "28", "kind": "floor", "floor": 28},
	{"label": "29", "kind": "floor", "floor": 29},
	{"label": "30", "kind": "floor", "floor": 30},
	{"label": "",   "kind": "empty"},
	{"label": "B",  "kind": "basement"},
	{"label": "W",  "kind": "workshop"},
	{"label": "★",  "kind": "mystery"},
	{"label": "",   "kind": "empty"},
]

const GREETINGS: Array = [
	"Going up. Or down. Same thing.",
	"Mind the gap.",
	"This elevator was condemned in '74.",
	"Press a button. Any button. Not THAT one.",
	"Capacity: one soul. You qualify.",
	"Out-of-service floors are still occupied.",
	"Your floor is glowing. Take the hint.",
]


@onready var bg: TextureRect = $Background
@onready var cabin_root: Control = $Cabin
@onready var grid: GridContainer = $Cabin/PanelFrame/ButtonGrid
@onready var floor_number: Label = $Cabin/LCD/FloorNumber
@onready var district_name: Label = $Cabin/LCD/DistrictName
@onready var dialogue_label: Label = $Cabin/Intercom/DialogueLabel
@onready var hp_label: Label = $Cabin/StatusStrip/HPLabel
@onready var gold_label: Label = $Cabin/StatusStrip/GoldLabel
@onready var token_label: Label = $Cabin/StatusStrip/TokenLabel
@onready var charm_label: Label = $Cabin/StatusStrip/CharmLabel
@onready var event_banner: Label = $Cabin/EventBanner
@onready var help_hint: Label = $Cabin/HelpHint


var _cells: Array = []
var _selected: int = 0
var _is_busy: bool = false
var _mystery_used: bool = false
var _shake_tween: Tween


func _ready():
	AudioController.play_music(AudioController.MUSIC_ELEVATOR)
	SpriteManager.apply_or_keep(bg, SpriteManager.BG_ELEVATOR)
	_build_grid()
	_select_initial()
	_refresh_status()
	_refresh_lcd()
	_refresh_cells()
	_say(GREETINGS[randi() % GREETINGS.size()])
	event_banner.modulate.a = 0.0

	InputManager.button_2_left_pressed.connect(_on_left)
	InputManager.button_2_right_pressed.connect(_on_right)
	InputManager.button_1_pressed.connect(_on_press)
	InputManager.dice_rolled.connect(_on_dice)

	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.tokens_changed.connect(_on_tokens_changed)
	GameManager.charm_added_to_inventory.connect(_on_charms_changed)
	GameManager.charm_lost.connect(_on_charms_changed)
	GameManager.floor_changed.connect(_on_floor_changed)

	_start_idle_shake()


func _build_grid():
	grid.columns = COLS
	for child in grid.get_children():
		child.queue_free()
	_cells.clear()
	for entry in LAYOUT:
		var cell = _make_cell(entry)
		grid.add_child(cell)
		_cells.append(cell)


func _make_cell(entry: Dictionary) -> Panel:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(68, 68)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.set_meta("entry", entry)

	if entry.get("kind", "") == "empty":
		# Invisible spacer — keeps grid alignment, cursor skips it.
		var blank = StyleBoxEmpty.new()
		cell.add_theme_stylebox_override("panel", blank)
		cell.modulate.a = 0.0
		return cell

	var face = TextureRect.new()
	face.name = "FaceSprite"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.visible = false
	cell.add_child(face)

	var icon = TextureRect.new()
	icon.name = "IconSprite"
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.custom_minimum_size = Vector2(46, 46)
	icon.size = Vector2(46, 46)
	icon.position = Vector2(-23, -32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.visible = false
	cell.add_child(icon)

	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = String(entry.label)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color("#f0e6d2"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_bottom = -14
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(lbl)

	var caption = Label.new()
	caption.name = "Caption"
	caption.add_theme_font_size_override("font_size", 9)
	caption.add_theme_color_override("font_color", Color("#b8a98e"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -14
	caption.offset_bottom = -3
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(caption)

	cell.add_theme_stylebox_override("panel", _make_box(entry, false))
	return cell


func _make_box(entry: Dictionary, selected: bool) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 22
	box.corner_radius_top_right = 22
	box.corner_radius_bottom_right = 22
	box.corner_radius_bottom_left = 22
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.border_width_left = 2
	box.border_width_right = 2

	var kind = entry.get("kind", "dud")
	match kind:
		"floor":
			var f = int(entry.floor)
			if f == GameManager.current_floor:
				box.bg_color = Color("#3a1408")
				box.border_color = Color("#f5c869")
			elif f < GameManager.current_floor:
				box.bg_color = Color("#0e1a10")
				box.border_color = Color("#4cae6a")
			else:
				box.bg_color = Color("#190406")
				box.border_color = Color("#6e0418")
		"basement":
			box.bg_color = Color("#08161e")
			box.border_color = Color("#00f0ff")
		"workshop":
			box.bg_color = Color("#0a1c0e")
			box.border_color = Color("#4cae6a")
		"mystery":
			if _mystery_used:
				box.bg_color = Color("#100810")
				box.border_color = Color("#3a2030")
			else:
				box.bg_color = Color("#1f0518")
				box.border_color = Color("#ff2e88")
		_:
			box.bg_color = Color("#0f0a14")
			box.border_color = Color("#3a3346")

	if selected:
		box.border_width_top = 4
		box.border_width_bottom = 4
		box.border_width_left = 4
		box.border_width_right = 4
		box.border_color = Color("#f5c869")
		box.shadow_color = Color("#f5c869", 0.5)
		box.shadow_size = 8
	return box


func _refresh_cells():
	for i in range(_cells.size()):
		var cell: Panel = _cells[i]
		var entry: Dictionary = LAYOUT[i]
		if entry.get("kind", "") == "empty":
			continue
		var is_selected = i == _selected
		cell.add_theme_stylebox_override("panel", _make_box(entry, is_selected))

		var caption: Label = cell.get_node("Caption")
		var lbl: Label = cell.get_node("Label")
		var face: TextureRect = cell.get_node("FaceSprite")
		var icon: TextureRect = cell.get_node("IconSprite")
		caption.text = ""

		var face_state := "lit"
		var icon_path := ""

		match entry.kind:
			"floor":
				var f = int(entry.floor)
				if f == GameManager.current_floor:
					caption.text = "GO"
					lbl.add_theme_color_override("font_color", Color("#f5c869"))
					face_state = "lit"
				elif f < GameManager.current_floor:
					caption.text = "✓"
					lbl.add_theme_color_override("font_color", Color("#4cae6a"))
					face_state = "cleared"
				else:
					caption.text = "✕"
					lbl.add_theme_color_override("font_color", Color("#a44058"))
					face_state = "locked"
			"basement":
				caption.text = "CHARM"
				lbl.add_theme_color_override("font_color", Color("#00f0ff"))
				icon_path = SpriteManager.UI_ICON_BASEMENT
			"workshop":
				caption.text = "CARD"
				lbl.add_theme_color_override("font_color", Color("#4cae6a"))
				if GameManager.has_pending_charm():
					caption.text = "PENDING!"
					lbl.add_theme_color_override("font_color", Color("#ff2e88"))
			"mystery":
				caption.text = "USED" if _mystery_used else "?"
				lbl.add_theme_color_override("font_color", Color("#ff2e88") if not _mystery_used else Color("#5a3a4a"))
				icon_path = SpriteManager.UI_ICON_MYSTERY
			_:
				lbl.add_theme_color_override("font_color", Color("#7a7484"))

		if is_selected:
			SpriteManager.apply(face, SpriteManager.button_face_for("selected"), null)
		else:
			SpriteManager.apply(face, SpriteManager.button_face_for(face_state), null)

		if icon_path != "":
			SpriteManager.apply(icon, icon_path, lbl)
		else:
			icon.visible = false
			icon.texture = null
			lbl.visible = true

	_pulse_selected()


func _pulse_selected():
	if _cells.is_empty():
		return
	for i in range(_cells.size()):
		var cell: Panel = _cells[i]
		var entry: Dictionary = LAYOUT[i]
		if entry.get("kind", "") == "empty":
			continue
		cell.scale = Vector2.ONE
		cell.pivot_offset = cell.size * 0.5
	if LAYOUT[_selected].get("kind", "") == "empty":
		return
	var sel: Panel = _cells[_selected]
	sel.pivot_offset = sel.size * 0.5
	var tw = create_tween()
	tw.tween_property(sel, "scale", Vector2(1.18, 1.18), 0.08)
	tw.tween_property(sel, "scale", Vector2(1.08, 1.08), 0.12)


func _select_initial():
	for i in range(LAYOUT.size()):
		var entry = LAYOUT[i]
		if entry.kind == "floor" and int(entry.floor) == GameManager.current_floor:
			_selected = i
			return
	_selected = 0


func _on_left():
	if _is_busy:
		return
	var n = LAYOUT.size()
	for _step in range(n):
		_selected = (_selected - 1 + n) % n
		if LAYOUT[_selected].get("kind", "") != "empty":
			break
	AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
	_refresh_cells()


func _on_right():
	if _is_busy:
		return
	var n = LAYOUT.size()
	for _step in range(n):
		_selected = (_selected + 1) % n
		if LAYOUT[_selected].get("kind", "") != "empty":
			break
	AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
	_refresh_cells()


func _on_dice(face: int):
	if _is_busy:
		return
	for i in range(LAYOUT.size()):
		var entry = LAYOUT[i]
		if entry.kind == "floor" and int(entry.floor) == face:
			_selected = i
			AudioController.play_sfx(AudioController.SFX_DICE_LAND)
			_say("Dice says floor %d." % face)
			_refresh_cells()
			return


func _on_press():
	if _is_busy:
		return
	var entry: Dictionary = LAYOUT[_selected]
	match entry.kind:
		"floor":
			_try_floor(int(entry.floor))
		"basement":
			_press_basement()
		"workshop":
			_press_workshop()
		"mystery":
			_press_mystery()
		_:
			AudioController.play_sfx(AudioController.SFX_BUTTON_CLICK)
			_buzz()


func _try_floor(f: int):
	if f == GameManager.current_floor:
		_is_busy = true
		_say("Floor %d. Brace yourself." % f)
		AudioController.play_sfx(AudioController.SFX_DICE_LAND)
		await _slam_close()
		GameManager.start_floor_battle(FloorData.get_floor_enemies(f))
		SceneManager.go_to_current_minigame()
	elif f < GameManager.current_floor:
		_say("Already drained floor %d. No refunds." % f)
		_buzz()
	else:
		_say("Locked. Earn your way up.")
		_buzz()


func _press_basement():
	_is_busy = true
	_say("Charm Co. Basement level. Mind the static.")
	await get_tree().create_timer(0.4).timeout
	SceneManager.go_to_charm_co()


func _press_workshop():
	_is_busy = true
	if GameManager.has_pending_charm():
		_say("New sticker waiting. Place it or peel one.")
	else:
		_say("Player card. Stick 'em or peel 'em.")
	await get_tree().create_timer(0.3).timeout
	SceneManager.go_to_workshop()


func _press_mystery():
	if _mystery_used:
		_say("Already pulled that lever this trip.")
		_buzz()
		return
	_mystery_used = true
	var rolls = [
		"heal", "heal",
		"damage",
		"gold_gain", "gold_gain",
		"gold_loss",
		"token",
		"free_charm",
		"nothing", "nothing",
	]
	var pick = rolls[randi() % rolls.size()]
	match pick:
		"heal":
			GameManager.heal(5)
			_banner("✦ STRAY GOOD LUCK — +5 HP", Color("#4cae6a"))
		"damage":
			GameManager.take_damage(2)
			_banner("✦ ELECTRIC SHOCK — −2 HP", Color("#e6164a"))
		"gold_gain":
			GameManager.add_gold(7)
			_banner("✦ COINS IN THE COUCH — +7 GOLD", Color("#f5c869"))
		"gold_loss":
			var drop = min(GameManager.gold, 4)
			GameManager.gold -= drop
			GameManager.gold_changed.emit(GameManager.gold)
			_banner("✦ POCKET HOLE — −%d GOLD" % drop, Color("#e6164a"))
		"token":
			GameManager.add_tokens(1)
			_banner("✦ ANONYMOUS DONATION — +1 TOKEN", Color("#ff2e88"))
		"free_charm":
			var charm = CharmsData.get_random_charm_by_rarity("uncommon")
			GameManager.add_charm_to_inventory(charm)
			_banner("✦ FOUND CHARM — %s" % String(charm.name).to_upper(), CharmsData.get_rarity_color("uncommon"))
		"nothing":
			_banner("✦ ★ ... NOTHING HAPPENED.", Color("#b8a98e"))

	AudioController.play_sfx(AudioController.SFX_REVEAL_RARE)
	_refresh_cells()


func _buzz():
	var cell: Panel = _cells[_selected]
	cell.pivot_offset = cell.size * 0.5
	var tw = create_tween()
	tw.tween_property(cell, "position:x", cell.position.x - 6, 0.04)
	tw.tween_property(cell, "position:x", cell.position.x + 6, 0.06)
	tw.tween_property(cell, "position:x", cell.position.x, 0.05)


func _say(text: String):
	dialogue_label.text = "“%s”" % text


func _banner(text: String, color: Color):
	event_banner.text = text
	event_banner.add_theme_color_override("font_color", color)
	event_banner.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(event_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.6)
	tw.tween_property(event_banner, "modulate:a", 0.0, 0.4)


func _slam_close():
	var tw = create_tween()
	tw.tween_property(cabin_root, "modulate", Color(0.2, 0.05, 0.05), 0.4)
	tw.tween_property(cabin_root, "modulate", Color(1, 1, 1), 0.0)
	await tw.finished


func _screen_shake(intensity: float, duration: float):
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var origin = cabin_root.position
	_shake_tween = create_tween()
	var elapsed = 0.0
	while elapsed < duration:
		var dx = randf_range(-intensity, intensity)
		var dy = randf_range(-intensity, intensity)
		_shake_tween.tween_property(cabin_root, "position", origin + Vector2(dx, dy), 0.04)
		elapsed += 0.04
	_shake_tween.tween_property(cabin_root, "position", origin, 0.05)


func _start_idle_shake():
	var bright = bg.modulate
	var dim = Color(bright.r * 0.85, bright.g * 0.85, bright.b * 0.85, bright.a)
	var tw = create_tween().set_loops()
	tw.tween_property(bg, "modulate", bright, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bg, "modulate", dim, 1.4).set_trans(Tween.TRANS_SINE)


func _refresh_status():
	hp_label.text = "HP %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	gold_label.text = "%d g" % GameManager.gold
	token_label.text = "%d t" % GameManager.tokens
	charm_label.text = "%d/%d stickers" % [GameManager.count_equipped(), GameManager.MAX_EQUIPPED_CHARMS]
	if GameManager.has_pending_charm():
		charm_label.text += "  ✦ pending"


func _refresh_lcd():
	floor_number.text = "%02d" % GameManager.current_floor
	var district = GameManager.get_district_display_name().to_upper()
	if GameManager.is_final_floor():
		district += " · FINAL"
	elif GameManager.is_boss_floor():
		district += " · BOSS"
	district_name.text = district


func _on_hp_changed(_h, _m):
	_refresh_status()


func _on_gold_changed(_g):
	_refresh_status()


func _on_tokens_changed(_t):
	_refresh_status()


func _on_charms_changed(_c):
	_refresh_status()


func _on_floor_changed(_f):
	if GameManager.current_floor > 30:
		SceneManager.go_to_victory()
		return
	_refresh_lcd()
	_select_initial()
	_refresh_cells()
