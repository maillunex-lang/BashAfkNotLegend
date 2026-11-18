extends RefCounted
class_name CharacterRegistry

## Factory for CharacterData + CharacterVisualDef pairs.
## Swap visuals by replacing CharacterVisualDef / sprite_folder without touching combat.

const MASS01_HEROES: PackedStringArray = [
	"velkor", "tarvex", "xorin", "elvirax", "liorel", "firnax", "mossar", "zefriel",
]

static func list_ids() -> PackedStringArray:
	var ids: PackedStringArray = ["braxor", "nixara"]
	ids.append_array(MASS01_HEROES)
	ids.append_array(PackedStringArray(["stonekin", "shadewolf"]))
	return ids

static func get_character(character_id: String) -> CharacterData:
	match character_id:
		"braxor":
			return _braxor()
		"nixara":
			return _nixara()
		"velkor":
			return _hero("velkor", "Велкор", "ural_wardens", "warrior", CharacterData.RoleStyle.WARRIOR, 1200.0, 150.0, 120.0, 44.0, true, "velkor_strike", "velkor_oreguard", "velkor_pass_thunder", 72.0)
		"tarvex":
			return _hero("tarvex", "Тарвекс", "ural_wardens", "support", CharacterData.RoleStyle.SUPPORT, 1050.0, 115.0, 130.0, 38.0, false, "tarvex_hammer", "tarvex_forge", "tarvex_bastion_seal", 70.0)
		"xorin":
			return _hero("xorin", "Ксорин", "ural_wardens", "mage", CharacterData.RoleStyle.MAGE, 900.0, 155.0, 160.0, 40.0, false, "xorin_stonebolt", "xorin_fault", "xorin_ridge_shift", 66.0)
		"elvirax":
			return _hero("elvirax", "Эльвиракс", "ural_wardens", "healer", CharacterData.RoleStyle.HEALER, 980.0, 100.0, 150.0, 42.0, false, "elvirax_spring", "elvirax_mend", "elvirax_mountain_heart", 68.0)
		"liorel":
			return _hero("liorel", "Лиорель", "forest_spirits", "healer", CharacterData.RoleStyle.HEALER, 1000.0, 110.0, 145.0, 43.0, false, "liorel_bloom", "liorel_regrowth", "liorel_second_bloom", 68.0)
		"firnax":
			return _hero("firnax", "Фирнакс", "forest_spirits", "assassin", CharacterData.RoleStyle.ASSASSIN, 920.0, 165.0, 105.0, 60.0, false, "firnax_cut", "firnax_vanish", "firnax_unseen", 62.0)
		"mossar":
			return _hero("mossar", "Моссар", "forest_spirits", "tank", CharacterData.RoleStyle.TANK, 1450.0, 125.0, 140.0, 28.0, true, "mossar_rootbash", "mossar_barkwall", "mossar_still_forest", 94.0)
		"zefriel":
			return _hero("zefriel", "Зефриэль", "forest_spirits", "mage", CharacterData.RoleStyle.MAGE, 880.0, 158.0, 155.0, 46.0, false, "zefriel_gust", "zefriel_crownstorm", "zefriel_canopy_tempest", 66.0)
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
	var portrait := "res://assets/ui/portraits/%s.jpg" % id
	v.portrait_path = portrait
	v.source_facing = CharacterVisualDef.Facing.RIGHT if src_right else CharacterVisualDef.Facing.LEFT
	return v

static func _hero(
	id: String, name: String, faction: String, class_id: String, role: CharacterData.RoleStyle,
	hp: float, atk: float, rng: float, spd: float, front: bool,
	basic: String, skill: String, ult: String, space: float
) -> CharacterData:
	var d := CharacterData.new()
	d.character_id = id
	d.display_name = name
	d.faction_id = faction
	d.class_id = class_id
	d.role_style = role
	d.is_hero = true
	d.max_hp = hp
	d.attack_power = atk
	d.preferred_range = rng
	d.move_speed = spd
	d.is_front_row_default = front
	d.basic_attack_id = basic
	d.skill1_id = skill
	d.ultimate_id = ult
	d.visual = _vis(id, id, name, true)
	d.visual.personal_space = space
	d.visual.attach_weapon = Vector2(36, -75)
	return d

static func _braxor() -> CharacterData:
	var d := CharacterData.new()
	d.character_id = "braxor"
	d.display_name = "Браксор"
	d.faction_id = "ural_wardens"
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
	d.faction_id = "dark_creatures"
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
	d.visual = _vis("stonekin", "enemies/stonekin", "Камнегрыз", false)
	d.visual.personal_space = 96.0
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
