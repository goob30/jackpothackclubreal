extends Node


func _ready():
	print("\n========== STAGE 1 TEST ==========")

	GameManager.start_new_run(GameManager.MODE_BABY)
	GameManager.add_gold(50)
	GameManager.add_tokens(3)
	GameManager.add_charm_to_inventory(CharmsData.get_charm_by_id("fire"))
	GameManager.add_charm_to_inventory(CharmsData.get_charm_by_id("vampire"))
	GameManager.start_floor_battle(FloorData.get_floor_enemies(1))
	GameManager.debug_print_state()

	print("\n--- Floor 1 enemies: ---")
	for enemy in FloorData.get_floor_enemies(1):
		print("  %s (hp=%d, minigame=%s)" % [enemy.name, enemy.hp, enemy.minigame])

	print("\n--- Current enemy: ---")
	print("  ", GameManager.current_enemy.get("name", "(none)"))
	print("  Minigame: ", GameManager.get_current_minigame())

	print("\n--- Charm rarity sanity: ---")
	for rarity in [CharmsData.RARITY_COMMON, CharmsData.RARITY_UNCOMMON, CharmsData.RARITY_RARE, CharmsData.RARITY_LEGENDARY]:
		var pool = CharmsData.get_charms_by_rarity(rarity)
		print("  %s: %d charms" % [CharmsData.get_rarity_display_name(rarity), pool.size()])

	print("\n--- Districts by floor: ---")
	for f in [1, 5, 6, 10, 11, 15]:
		GameManager.current_floor = f
		print("  Floor %d -> %s (boss=%s, final=%s)" % [
			f, GameManager.get_district_display_name(),
			str(GameManager.is_boss_floor()), str(GameManager.is_final_floor())
		])
	GameManager.current_floor = 1

	print("\n--- Input signal hookup: ---")
	InputManager.button_1_pressed.connect(func(): print("  >> button_1_pressed (SPACE)"))
	InputManager.button_2_left_pressed.connect(func(): print("  >> button_2_left_pressed (LEFT)"))
	InputManager.button_2_right_pressed.connect(func(): print("  >> button_2_right_pressed (RIGHT)"))
	InputManager.dice_rolled.connect(func(face): print("  >> dice_rolled: ", face))
	print("  Press SPACE / LEFT / RIGHT / 1-6 / F+1-6 to test")

	print("\n========== STAGE 1 TEST READY ==========\n")
