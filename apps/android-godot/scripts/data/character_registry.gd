extends RefCounted
class_name CharacterRegistry

## Factory for CharacterData + CharacterVisualDef pairs.
## Swap visuals by replacing CharacterVisualDef / sprite_folder without touching combat.

static func get_character(character_id: String) -> CharacterData:
	match character_id:
		"braxor":
			return _braxor()
		"nixara":
			return _nixara()
		"stonekin":
			return _stonekin()
		"shadewolf":
			return _shadewolf()
		_:
			push_error("Unknown character_id: %s" % character_id)
			return null

static func _vis(id: String, folder: String, name: String, src_right: bool) -> CharacterVisualDef:
	var v := CharacterVisualDef.new()
	v.visual_id = id + "_v1"
	v.display_name = name
	v.sprite_folder = folder
	v.portrait_path = "res://assets/ui/portraits/%s.jpg" % id if id in ["braxor", "nixara"] else ""
	v.source_facing = CharacterVisualDef.Facing.RIGHT if src_right else CharacterVisualDef.Facing.LEFT
	return v

static func _braxor() -> CharacterData:
	var d := CharacterData.new()
	d.character_id = "braxor"
	d.display_name = "Браксор"
	d.faction_id = "ural_guards"
	d.class_id = "tank"
	d.role_style = CharacterData.RoleStyle.TANK
	d.is_hero = true
	d.max_hp = 1400.0
	d.attack_power = 140.0
	d.preferred_range = 135.0
	d.move_speed = 32.0
	d.is_front_row_default = true
	d.basic_attack_id = "braxor_bash"
	d.skill1_id = "braxor_shield"
	d.ultimate_id = "braxor_spine"
	d.visual = _vis("braxor", "braxor", "Браксор", true)
	d.visual.personal_space = 88.0
	d.visual.attach_shield = Vector2(42, -60)
	d.visual.attach_weapon = Vector2(-30, -75)
	return d

static func _nixara() -> CharacterData:
	var d := CharacterData.new()
	d.character_id = "nixara"
	d.display_name = "Никсара"
	d.faction_id = "dark_creations"
	d.class_id = "assassin"
	d.role_style = CharacterData.RoleStyle.ASSASSIN
	d.is_hero = true
	d.max_hp = 950.0
	d.attack_power = 160.0
	d.preferred_range = 110.0
	d.move_speed = 58.0
	d.is_front_row_default = false
	d.basic_attack_id = "nixara_slash"
	d.skill2_id = "nixara_dash"
	d.ultimate_id = "nixara_night"
	d.visual = _vis("nixara", "nixara", "Никсара", true)
	d.visual.personal_space = 64.0
	d.visual.attach_weapon = Vector2(36, -75)
	return d

static func _stonekin() -> CharacterData:
	var d := CharacterData.new()
	d.character_id = "stonekin"
	d.display_name = "Камнегрыз"
	d.faction_id = "mobs"
	d.class_id = "brute"
	d.role_style = CharacterData.RoleStyle.BRUTE
	d.is_hero = false
	d.max_hp = 1200.0
	d.attack_power = 110.0
	d.preferred_range = 140.0
	d.move_speed = 24.0
	d.is_front_row_default = true
	d.basic_attack_id = "stonekin_slam"
	# Mobs authored facing LEFT (VISUAL-APPROVAL-001)
	d.visual = _vis("stonekin", "enemies/stonekin", "Камнегрыз", false)
	d.visual.personal_space = 96.0
	# Current PNGs lean RIGHT — override to match on-disk art until batch re-author
	d.visual.source_facing = CharacterVisualDef.Facing.RIGHT
	return d

static func _shadewolf() -> CharacterData:
	var d := CharacterData.new()
	d.character_id = "shadewolf"
	d.display_name = "Теневолк"
	d.faction_id = "mobs"
	d.class_id = "beast"
	d.role_style = CharacterData.RoleStyle.BEAST
	d.is_hero = false
	d.max_hp = 900.0
	d.attack_power = 130.0
	d.preferred_range = 115.0
	d.move_speed = 62.0
	d.is_front_row_default = false
	d.basic_attack_id = "shadewolf_bite"
	d.visual = _vis("shadewolf", "enemies/shadewolf", "Теневолк", false)
	d.visual.personal_space = 70.0
	return d
