extends Node


signal button_1_pressed
signal button_2_left_pressed
signal button_2_right_pressed
signal dice_rolled(face_value: int)


var _waiting_for_face: bool = false


func _input(event: InputEvent):
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
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
			_waiting_for_face = true
		KEY_1:
			dice_rolled.emit(1)
		KEY_2:
			dice_rolled.emit(2)
		KEY_3:
			dice_rolled.emit(3)
		KEY_4:
			dice_rolled.emit(4)
		KEY_5:
			dice_rolled.emit(5)
		KEY_6:
			dice_rolled.emit(6)


func _handle_face_key(keycode: int):
	_waiting_for_face = false
	if keycode >= KEY_1 and keycode <= KEY_6:
		var face = keycode - KEY_1 + 1
		dice_rolled.emit(face)
