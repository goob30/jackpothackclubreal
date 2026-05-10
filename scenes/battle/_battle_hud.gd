class_name BattleHUD
extends Control


@onready var enemy_portrait: Label = $EnemyHalf/EnemyPortrait
@onready var enemy_portrait_sprite: TextureRect = $EnemyHalf/EnemyPortrait/Sprite
@onready var background: TextureRect = $Background
@onready var enemy_name: Label = $EnemyHalf/EnemyName
@onready var enemy_hp_bar: TextureProgressBar = $EnemyHalf/EnemyHPContainer/EnemyHPBar
@onready var enemy_hp_value: Label = $EnemyHalf/EnemyHPContainer/HPValue
@onready var queue_container: HBoxContainer = $EnemyHalf/QueueContainer
@onready var next_attack_value: Label = $EnemyHalf/NextAttackBox/NextAttackValue
@onready var floor_label: Label = $EnemyHalf/FloorLabel
@onready var game_area: Control = $PlayerHalf/GameAreaContainer
@onready var player_hp_bar: TextureProgressBar = $PlayerHalf/PlayerHPContainer/PlayerHPBar
@onready var player_hp_value: Label = $PlayerHalf/PlayerHPContainer/HPValue
@onready var button_hints: Label = $PlayerHalf/ButtonHints
@onready var damage_layer: Control = $DamageNumberLayer
@onready var charm_strip: HBoxContainer = $PlayerHalf/CharmStrip


func _ready():
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.new_enemy_appeared.connect(_on_new_enemy)
	GameManager.enemy_defeated.connect(_on_enemy_defeated)
	SpriteManager.apply_or_keep(background, SpriteManager.bg_for_district(GameManager.get_district(), GameManager.is_final_floor()))


func update_all():
	update_enemy()
	update_queue()
	update_player_hp(GameManager.player_hp, GameManager.player_max_hp)
	update_floor()
	update_charm_strip()


func update_enemy():
	if GameManager.current_enemy.is_empty():
		enemy_name.text = ""
		enemy_portrait.text = ""
		SpriteManager.apply(enemy_portrait_sprite, "", enemy_portrait)
		enemy_hp_bar.max_value = 1
		enemy_hp_bar.value = 0
		enemy_hp_value.text = "-"
		next_attack_value.text = "-"
		return
	var e = GameManager.current_enemy
	enemy_name.text = String(e.get("name", "?")).to_upper()
	enemy_portrait.text = e.get("portrait_emoji", "😈")
	SpriteManager.apply(enemy_portrait_sprite, String(e.get("portrait", "")), enemy_portrait)
	var hp = int(e.get("hp", 0))
	var max_hp = int(e.get("max_hp", hp))
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = hp
	enemy_hp_value.text = "%d/%d" % [hp, max_hp]
	next_attack_value.text = str(e.get("next_attack", 0))


func update_queue():
	for child in queue_container.get_children():
		child.queue_free()
	for enemy in GameManager.enemies_remaining:
		var lbl = Label.new()
		lbl.text = enemy.get("portrait_emoji", "👻")
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.custom_minimum_size = Vector2(40, 40)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		queue_container.add_child(lbl)

		var sprite = TextureRect.new()
		sprite.name = "Sprite"
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.visible = false
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture_filter = TEXTURE_FILTER_NEAREST
		lbl.add_child(sprite)
		SpriteManager.apply(sprite, String(enemy.get("icon", "")), lbl)


func update_player_hp(new_hp: int, max_hp: int):
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = new_hp
	player_hp_value.text = "%d/%d" % [new_hp, max_hp]


func update_floor():
	floor_label.text = "FLOOR %d — %s" % [GameManager.current_floor, GameManager.get_district_display_name().to_upper()]


func update_charm_strip():
	for child in charm_strip.get_children():
		child.queue_free()
	for charm in GameManager.equipped_charms:
		if charm.is_empty():
			continue
		var lbl = Label.new()
		lbl.text = String(charm.get("name", "?"))
		lbl.add_theme_color_override("font_color", CharmsData.get_rarity_color(charm.get("rarity", "common")))
		lbl.add_theme_font_size_override("font_size", 14)
		charm_strip.add_child(lbl)


func set_button_hints(text: String):
	button_hints.text = text


func spawn_damage_number(amount: int, target_pos: Vector2, color: Color = Color.WHITE):
	var lbl = Label.new()
	lbl.text = str(amount) if amount >= 0 else "+" + str(-amount)
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = target_pos
	damage_layer.add_child(lbl)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", target_pos.y - 80, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lbl.queue_free)


func flash_enemy(color: Color = Color(1, 0.4, 0.4)):
	var tw = create_tween()
	tw.tween_property(enemy_portrait, "modulate", color, 0.08)
	tw.tween_property(enemy_portrait, "modulate", Color.WHITE, 0.18)


func _on_hp_changed(new_hp: int, max_hp: int):
	update_player_hp(new_hp, max_hp)


func _on_new_enemy(_enemy):
	update_enemy()
	update_queue()


func _on_enemy_defeated(_enemy):
	flash_enemy(Color(1.4, 1.4, 0.4))


func get_enemy_center() -> Vector2:
	return $EnemyHalf.size * 0.5


func get_player_center() -> Vector2:
	return Vector2($PlayerHalf.size.x * 0.5, $PlayerHalf.position.y + $PlayerHalf.size.y * 0.5)
