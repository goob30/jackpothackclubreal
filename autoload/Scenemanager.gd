extends Node


const FADE_DURATION: float = 0.4

const PATH_MAIN_MENU: String = "res://scenes/main_menu.tscn"
const PATH_ELEVATOR: String = "res://scenes/elevator.tscn"
const PATH_BATTLE: String = "res://scenes/battle.tscn"
const PATH_CHARM_CO: String = "res://scenes/charm_co.tscn"
const PATH_WORKSHOP: String = "res://scenes/workshop.tscn"
const PATH_GAME_OVER: String = "res://scenes/game_over.tscn"
const PATH_VICTORY: String = "res://scenes/victory.tscn"


var _is_transitioning: bool = false


func change_scene(scene_path: String, fade: bool = true):
	if _is_transitioning:
		return
	_is_transitioning = true
	
	if fade:
		await _fade_out()
		get_tree().change_scene_to_file(scene_path)
		await _fade_in()
	else:
		get_tree().change_scene_to_file(scene_path)
	
	_is_transitioning = false


func go_to_main_menu():
	change_scene(PATH_MAIN_MENU)


func go_to_elevator():
	change_scene(PATH_ELEVATOR)


func go_to_battle():
	change_scene(PATH_BATTLE)


func go_to_charm_co():
	change_scene(PATH_CHARM_CO)


func go_to_workshop():
	change_scene(PATH_WORKSHOP)


func go_to_game_over():
	change_scene(PATH_GAME_OVER)


func go_to_victory():
	change_scene(PATH_VICTORY)


func _fade_out():
	var fade_layer = _create_fade_layer()
	get_tree().root.add_child(fade_layer)
	fade_layer.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(fade_layer, "color:a", 1.0, FADE_DURATION)
	await tween.finished


func _fade_in():
	for child in get_tree().root.get_children():
		if child.name == "FadeLayer":
			var tween = create_tween()
			tween.tween_property(child, "color:a", 0.0, FADE_DURATION)
			await tween.finished
			child.queue_free()
			return


func _create_fade_layer() -> ColorRect:
	var rect = ColorRect.new()
	rect.name = "FadeLayer"
	rect.color = Color(0.04, 0.016, 0.031, 0)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.z_index = 1000
	return rect
