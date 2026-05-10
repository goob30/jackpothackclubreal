extends Node


signal button_1_pressed
signal button_2_left_pressed
signal button_2_right_pressed
signal dice_rolled(face_value: int)
signal dice_mode_changed(enabled: bool)


var dice_mode: bool = false  # false = keyboard 1-6, true = physical dice via DiceInputFoenem
var _waiting_for_face: bool = false

var _toast_layer: CanvasLayer
var _toast_label: Label


func _ready():
	_setup_toast()
	# Listen to the physical dice's settled-face signal. We only act on it
	# when dice_mode is on; otherwise the event is ignored.
	if has_node("/root/DiceInputFoenem"):
		DiceInputFoenem.face_settled.connect(_on_dice_face_settled)


func _setup_toast():
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 100
	add_child(_toast_layer)
	var bg = ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.039, 0.012, 0.024, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bg.offset_left = -260
	bg.offset_top = 24
	bg.offset_right = -24
	bg.offset_bottom = 64
	bg.modulate.a = 0.0
	_toast_layer.add_child(bg)
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.add_theme_color_override("font_color", Color("#f5c869"))
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.text = ""
	bg.add_child(_toast_label)


func _show_toast(text: String, color: Color):
	if _toast_layer == null:
		return
	var bg: ColorRect = _toast_layer.get_child(0)
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	bg.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(bg, "modulate:a", 1.0, 0.18)
	tw.tween_interval(2.0)
	tw.tween_property(bg, "modulate:a", 0.0, 0.35)


func _input(event: InputEvent):
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	# Ctrl+Shift+K — toggle physical dice / keyboard mode.
	if event.keycode == KEY_K and event.ctrl_pressed and event.shift_pressed:
		_toggle_dice_mode()
		return

	if _waiting_for_face:
		_handle_face_key(event.keycode)
		return

	match event.keycode:
		KEY_SPACE:
			button_1_pressed.emit()
		KEY_LEFT:
			button_2_left_pressed.emit()
		KEY_RIGHT:
			button_2_right_pressed.emit()
		KEY_F:
			if not dice_mode:
				_waiting_for_face = true
		KEY_1:
			if not dice_mode:
				dice_rolled.emit(1)
		KEY_2:
			if not dice_mode:
				dice_rolled.emit(2)
		KEY_3:
			if not dice_mode:
				dice_rolled.emit(3)
		KEY_4:
			if not dice_mode:
				dice_rolled.emit(4)
		KEY_5:
			if not dice_mode:
				dice_rolled.emit(5)
		KEY_6:
			if not dice_mode:
				dice_rolled.emit(6)


func _handle_face_key(keycode: int):
	_waiting_for_face = false
	if keycode >= KEY_1 and keycode <= KEY_6:
		var face = keycode - KEY_1 + 1
		if not dice_mode:
			dice_rolled.emit(face)


func _toggle_dice_mode():
	dice_mode = not dice_mode
	dice_mode_changed.emit(dice_mode)
	var connected = false
	var port = ""
	if has_node("/root/DiceInputFoenem"):
		connected = DiceInputFoenem.connected
		port = DiceInputFoenem.port_name
	if dice_mode:
		if connected:
			_show_toast("🎲  PHYSICAL DICE  (%s)" % port, Color("#f5c869"))
			print("[InputManager] Dice mode ON — port ", port)
		else:
			_show_toast("🎲  DICE MODE  ⚠ no serial", Color("#ff4422"))
			print("[InputManager] Dice mode ON — but no serial connected (", port, ")")
	else:
		_show_toast("⌨  KEYBOARD  (1-6 to roll)", Color("#00f0ff"))
		print("[InputManager] Dice mode OFF — keyboard 1-6 drives rolls.")


func _on_dice_face_settled(face: int):
	if not dice_mode:
		return
	if face < 1 or face > 6:
		return
	dice_rolled.emit(face)
