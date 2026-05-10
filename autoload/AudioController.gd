extends Node


const MUSIC_MAIN_MENU: String = "res://assets/audio/music/main_menu.ogg"
const MUSIC_ELEVATOR: String = "res://assets/audio/music/elevator.ogg"
const MUSIC_THE_PIT: String = "res://assets/audio/music/the_pit.ogg"
const MUSIC_HIGH_ROLLERS: String = "res://assets/audio/music/high_rollers.ogg"
const MUSIC_PENTHOUSE: String = "res://assets/audio/music/penthouse.ogg"
const MUSIC_DEVIL: String = "res://assets/audio/music/devil.ogg"
const MUSIC_CHARM_CO: String = "res://assets/audio/music/charm_co.ogg"
const MUSIC_VICTORY: String = "res://assets/audio/music/victory.ogg"
const MUSIC_GAME_OVER: String = "res://assets/audio/music/game_over.ogg"

const SFX_BUTTON_CLICK: String = "res://assets/audio/sfx/button_click.ogg"
const SFX_HIT: String = "res://assets/audio/sfx/hit.ogg"
const SFX_HEAL: String = "res://assets/audio/sfx/heal.ogg"
const SFX_COIN_FLIP: String = "res://assets/audio/sfx/coin_flip.ogg"
const SFX_COIN_LAND: String = "res://assets/audio/sfx/coin_land.ogg"
const SFX_DICE_ROLL: String = "res://assets/audio/sfx/dice_roll.ogg"
const SFX_DICE_LAND: String = "res://assets/audio/sfx/dice_land.ogg"
const SFX_SLOTS_SPIN: String = "res://assets/audio/sfx/slots_spin.ogg"
const SFX_SLOTS_STOP: String = "res://assets/audio/sfx/slots_stop.ogg"
const SFX_CARD_DEAL: String = "res://assets/audio/sfx/card_deal.ogg"
const SFX_COIN_INSERT: String = "res://assets/audio/sfx/coin_insert.ogg"
const SFX_TOKEN_INSERT: String = "res://assets/audio/sfx/token_insert.ogg"
const SFX_LEVER_PULL: String = "res://assets/audio/sfx/lever_pull.ogg"
const SFX_CAPSULE_ROLL: String = "res://assets/audio/sfx/capsule_roll.ogg"
const SFX_CAPSULE_LAND: String = "res://assets/audio/sfx/capsule_land.ogg"
const SFX_CAPSULE_OPEN: String = "res://assets/audio/sfx/capsule_open.ogg"
const SFX_REVEAL_COMMON: String = "res://assets/audio/sfx/reveal_common.ogg"
const SFX_REVEAL_UNCOMMON: String = "res://assets/audio/sfx/reveal_uncommon.ogg"
const SFX_REVEAL_RARE: String = "res://assets/audio/sfx/reveal_rare.ogg"
const SFX_REVEAL_LEGENDARY: String = "res://assets/audio/sfx/reveal_legendary.ogg"
const SFX_ENEMY_DEFEATED: String = "res://assets/audio/sfx/enemy_defeated.ogg"
const SFX_FLOOR_CLEARED: String = "res://assets/audio/sfx/floor_cleared.ogg"

const FADE_DURATION: float = 1.0
const FADE_DB_QUIET: float = -40.0
const FADE_DB_LOUD: float = 0.0


var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var current_track: String = ""


func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)


func play_music(path: String, fade: bool = true):
	if path == current_track and music_player.playing:
		return
	if not ResourceLoader.exists(path):
		return

	var stream = load(path)
	if stream == null:
		return

	if fade and music_player.playing:
		var fade_out = create_tween()
		fade_out.tween_property(music_player, "volume_db", FADE_DB_QUIET, FADE_DURATION * 0.5)
		await fade_out.finished
		music_player.stop()

	music_player.stream = stream
	current_track = path

	if fade:
		music_player.volume_db = FADE_DB_QUIET
		music_player.play()
		var fade_in = create_tween()
		fade_in.tween_property(music_player, "volume_db", FADE_DB_LOUD, FADE_DURATION)
	else:
		music_player.volume_db = FADE_DB_LOUD
		music_player.play()


func stop_music(fade: bool = true):
	if not music_player.playing:
		return
	if fade:
		var fade_out = create_tween()
		fade_out.tween_property(music_player, "volume_db", FADE_DB_QUIET, FADE_DURATION * 0.5)
		await fade_out.finished
	music_player.stop()
	current_track = ""


func play_district_music():
	if GameManager.is_final_floor():
		play_music(MUSIC_DEVIL)
		return
	match GameManager.get_district():
		"the_pit": play_music(MUSIC_THE_PIT)
		"high_rollers": play_music(MUSIC_HIGH_ROLLERS)
		"penthouse": play_music(MUSIC_PENTHOUSE)
		_: play_music(MUSIC_THE_PIT)


func play_sfx(path: String):
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	var oneshot = AudioStreamPlayer.new()
	oneshot.stream = stream
	oneshot.bus = "Master"
	add_child(oneshot)
	oneshot.finished.connect(oneshot.queue_free)
	oneshot.play()


func get_reveal_sfx_for_rarity(rarity: String) -> String:
	match rarity:
		"common": return SFX_REVEAL_COMMON
		"uncommon": return SFX_REVEAL_UNCOMMON
		"rare": return SFX_REVEAL_RARE
		"legendary": return SFX_REVEAL_LEGENDARY
		_: return SFX_REVEAL_COMMON
