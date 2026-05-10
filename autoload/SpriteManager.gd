extends Node


# Backgrounds (full-screen)
const BG_DEFAULT: String        = "res://assets/background.png"
const BG_TITLE: String          = "res://assets/sprites/backgrounds/title.png"
const BG_ELEVATOR: String       = "res://assets/sprites/backgrounds/elevator.png"
const BG_CHARM_CO: String       = "res://assets/sprites/backgrounds/charm_co.png"
const BG_BATTLE_PIT: String     = "res://assets/sprites/backgrounds/battle_pit.png"
const BG_BATTLE_HIGH_ROLLERS: String = "res://assets/sprites/backgrounds/battle_high_rollers.png"
const BG_BATTLE_PENTHOUSE: String = "res://assets/sprites/backgrounds/battle_penthouse.png"
const BG_BATTLE_DEVIL: String   = "res://assets/sprites/backgrounds/battle_devil.png"
const BG_REWARD: String         = "res://assets/sprites/backgrounds/reward.png"
const BG_GAME_OVER: String      = "res://assets/sprites/backgrounds/game_over.png"
const BG_VICTORY: String        = "res://assets/sprites/backgrounds/victory.png"

# HP bar
const UI_HP_FRAME: String         = "res://assets/healthbar.png"
const UI_HP_FILL_PLAYER: String   = "res://assets/healthbarplayer.png"
const UI_HP_FILL_ENEMY: String    = "res://assets/healthbarenemy.png"

# Coin (Coinflip)
const UI_COIN_HEADS: String   = "res://assets/sprites/ui/coin_heads.png"
const UI_COIN_TAILS: String   = "res://assets/sprites/ui/coin_tails.png"
const UI_COIN_UNKNOWN: String = "res://assets/sprites/ui/coin_unknown.png"

# Dice
const UI_DIE_1: String = "res://assets/sprites/ui/die_1.png"
const UI_DIE_2: String = "res://assets/sprites/ui/die_2.png"
const UI_DIE_3: String = "res://assets/sprites/ui/die_3.png"
const UI_DIE_4: String = "res://assets/sprites/ui/die_4.png"
const UI_DIE_5: String = "res://assets/sprites/ui/die_5.png"
const UI_DIE_6: String = "res://assets/sprites/ui/die_6.png"

# Slot symbols
const UI_SLOT_CHERRY: String = "res://assets/sprites/ui/slot_cherry.png"
const UI_SLOT_BELL: String   = "res://assets/sprites/ui/slot_bell.png"
const UI_SLOT_SEVEN: String  = "res://assets/sprites/ui/slot_seven.png"
const UI_SLOT_SKULL: String  = "res://assets/sprites/ui/slot_skull.png"
const UI_SLOT_DEVIL: String  = "res://assets/sprites/ui/slot_devil.png"

# Cards (Blackjack)
const UI_CARD_BACK: String  = "res://assets/sprites/ui/card_back.png"
const UI_CARD_FRONT: String = "res://assets/sprites/ui/card_front.png"

# Elevator panel
const UI_BUTTON_FACE: String           = "res://assets/sprites/ui/button_face.png"
const UI_BUTTON_FACE_LIT: String       = "res://assets/sprites/ui/button_face_lit.png"
const UI_BUTTON_FACE_LOCKED: String    = "res://assets/sprites/ui/button_face_locked.png"
const UI_BUTTON_FACE_CLEARED: String   = "res://assets/sprites/ui/button_face_cleared.png"
const UI_BUTTON_FACE_SELECTED: String  = "res://assets/sprites/ui/button_face_selected.png"
const UI_ICON_BASEMENT: String         = "res://assets/sprites/ui/icon_basement.png"
const UI_ICON_MYSTERY: String          = "res://assets/sprites/ui/icon_mystery.png"
const UI_ICON_ALARM: String            = "res://assets/sprites/ui/icon_alarm.png"

# LCD / panel chrome
const UI_LCD_BG: String       = "res://assets/sprites/ui/lcd_bg.png"
const UI_PANEL_FRAME: String  = "res://assets/sprites/ui/panel_frame.png"
const UI_INTERCOM_BG: String  = "res://assets/sprites/ui/intercom_bg.png"
const UI_VIGNETTE: String     = "res://assets/sprites/ui/vignette.png"

# Result-screen decorations
const UI_MEDAL_BOSS: String       = "res://assets/sprites/ui/medal_boss.png"
const UI_MEDAL_CLEAR: String      = "res://assets/sprites/ui/medal_clear.png"
const UI_CROWN: String            = "res://assets/sprites/ui/crown.png"
const UI_DEVIL_SILHOUETTE: String = "res://assets/sprites/ui/devil_silhouette.png"

# Effects
const FX_HIT: String        = "res://assets/sprites/effects/hit.png"
const FX_HEAL: String       = "res://assets/sprites/effects/heal.png"
const FX_GLOW_GOLD: String  = "res://assets/sprites/effects/glow_gold.png"
const FX_GLOW_PINK: String  = "res://assets/sprites/effects/glow_pink.png"
const FX_GLOW_CYAN: String  = "res://assets/sprites/effects/glow_cyan.png"
const FX_PARTICLE_COIN: String = "res://assets/sprites/effects/particle_coin.png"

# Vendor (Charm Co.)
const VENDOR_DEFAULT: String = "res://assets/sprites/ui/vendor.png"
const VENDOR_HAPPY: String   = "res://assets/sprites/ui/vendor_happy.png"
const VENDOR_ANGRY: String   = "res://assets/sprites/ui/vendor_angry.png"
const VENDOR_SHOCKED: String = "res://assets/sprites/ui/vendor_shocked.png"

# Charm Co. machine parts
const MACHINE_BODY: String  = "res://assets/sprites/ui/machine_body.png"
const MACHINE_GLASS: String = "res://assets/sprites/ui/machine_glass.png"
const MACHINE_LEVER: String = "res://assets/sprites/ui/machine_lever.png"
const MACHINE_TRAY: String  = "res://assets/sprites/ui/machine_tray.png"

# Capsules (rarity-coloured)
const CAPSULE_COMMON: String    = "res://assets/sprites/capsules/capsule_common.png"
const CAPSULE_UNCOMMON: String  = "res://assets/sprites/capsules/capsule_uncommon.png"
const CAPSULE_RARE: String      = "res://assets/sprites/capsules/capsule_rare.png"
const CAPSULE_LEGENDARY: String = "res://assets/sprites/capsules/capsule_legendary.png"
const CAPSULE_OPEN: String      = "res://assets/sprites/capsules/capsule_open.png"


# ─── Static helpers (path builders) ───

func enemy_portrait(enemy_id: String) -> String:
	return "res://assets/sprites/enemies/enemy_%s.png" % enemy_id


func enemy_icon(enemy_id: String) -> String:
	return "res://assets/sprites/enemies/enemy_%s_icon.png" % enemy_id


func charm_icon(charm_id: String) -> String:
	return "res://assets/sprites/charms/charm_%s.png" % charm_id


func capsule_for_rarity(rarity: String) -> String:
	match rarity:
		"common":    return CAPSULE_COMMON
		"uncommon":  return CAPSULE_UNCOMMON
		"rare":      return CAPSULE_RARE
		"legendary": return CAPSULE_LEGENDARY
		_:           return CAPSULE_COMMON


func die_for_face(face: int) -> String:
	match face:
		1: return UI_DIE_1
		2: return UI_DIE_2
		3: return UI_DIE_3
		4: return UI_DIE_4
		5: return UI_DIE_5
		6: return UI_DIE_6
		_: return UI_DIE_1


func bg_for_district(district: String, is_final: bool) -> String:
	if is_final:
		return BG_BATTLE_DEVIL
	match district:
		"the_pit":      return BG_BATTLE_PIT
		"high_rollers": return BG_BATTLE_HIGH_ROLLERS
		"penthouse":    return BG_BATTLE_PENTHOUSE
		_:              return BG_BATTLE_PIT


func slot_symbol_for(symbol: String) -> String:
	match symbol:
		"cherry": return UI_SLOT_CHERRY
		"bell":   return UI_SLOT_BELL
		"seven":  return UI_SLOT_SEVEN
		"skull":  return UI_SLOT_SKULL
		"devil":  return UI_SLOT_DEVIL
		_:        return UI_SLOT_CHERRY


func button_face_for(state: String) -> String:
	match state:
		"selected": return UI_BUTTON_FACE_SELECTED
		"lit":      return UI_BUTTON_FACE_LIT
		"locked":   return UI_BUTTON_FACE_LOCKED
		"cleared":  return UI_BUTTON_FACE_CLEARED
		_:          return UI_BUTTON_FACE


# ─── Loaders ───

func has(path: String) -> bool:
	return path != "" and ResourceLoader.exists(path)


func load_or_null(path: String) -> Texture2D:
	if not has(path):
		return null
	var tex = load(path)
	if tex is Texture2D:
		return tex
	return null


# Apply a sprite if it exists; otherwise fall back to a Label/Control.
# - rect: the TextureRect that gets the sprite
# - fallback: optional CanvasItem (usually a Label) whose text is masked when the sprite loads
# Uses self_modulate so the fallback can be the parent of the sprite without
# hiding the sprite (visibility/alpha cascade vs. self_modulate).
# Returns true when the sprite was applied.
func apply(rect: TextureRect, path: String, fallback: CanvasItem = null) -> bool:
	if rect == null:
		return false
	var tex = load_or_null(path)
	if tex:
		rect.texture = tex
		rect.visible = true
		if fallback:
			fallback.self_modulate = Color(1, 1, 1, 0)
		return true
	rect.texture = null
	rect.visible = false
	if fallback:
		fallback.self_modulate = Color(1, 1, 1, 1)
	return false


# Like apply() but if the sprite is missing, leave the rect's existing texture
# alone (so .tscn-set placeholder textures keep working).
func apply_or_keep(rect: TextureRect, path: String) -> bool:
	if rect == null:
		return false
	var tex = load_or_null(path)
	if tex:
		rect.texture = tex
		return true
	return false
