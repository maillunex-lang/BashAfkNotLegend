extends RefCounted
class_name AbilityCatalog

## Maps ability_id → AbilityDef. Combat code looks up by ID only.

static func get_ability(ability_id: String) -> AbilityDef:
	match ability_id:
		"braxor_bash":
			return _def("braxor_bash", "Удар топором", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 85.0, 0.38, 0.32, 18.0, 0.0, Color(1.0, 0.85, 0.35, 0.95), "melee")
		"braxor_shield":
			return _def("braxor_shield", "Удар щитом", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.2, 0.0, 85.0, 0.38, 0.32, 18.0, 5.0, Color(0.95, 0.8, 0.4, 0.95), "melee")
		"braxor_spine":
			return _def("braxor_spine", "Хребет не сдаётся", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.7, 0.0, 90.0, 0.35, 0.35, 0.0, 0.0, Color(1.0, 0.8, 0.3, 1.0), "ult")
		"nixara_slash":
			return _def("nixara_slash", "Теневой рывок", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.7, 0.85, 60.0, 0.26, 0.28, 16.0, 0.0, Color(0.9, 0.3, 1.0, 0.9), "slash")
		"nixara_dash":
			return _def("nixara_slash", "Теневой рывок", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.7, 0.85, 60.0, 0.26, 0.28, 16.0, 0.0, Color(0.9, 0.3, 1.0, 0.9), "slash")
		"nixara_night":
			return _def("nixara_night", "Ночь без свидетелей", AbilityDef.Kit.ULT_MULTI_MARK, "run", "attack2", "attack1", 1.45, 0.0, 55.0, 0.2, 0.3, 0.0, 0.0, Color(0.85, 0.25, 1.0, 1.0), "ult")
		"stonekin_slam":
			return _def("stonekin_slam", "Каменный удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.4, 0.0, 95.0, 0.45, 0.4, 14.0, 0.0, Color(0.8, 0.7, 0.45, 0.95), "slam")
		"shadewolf_bite":
			return _def("shadewolf_bite", "Прыжок-укус", AbilityDef.Kit.LEAP_BITE, "run", "attack2", "attack1", 1.05, 0.0, 55.0, 0.24, 0.3, 13.0, 0.0, Color(0.6, 0.2, 0.7, 0.95), "bite")
		"basic":
			return _def("basic", "Базовая атака", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.0, 0.0, 70.0, 0.35, 0.3, 12.0, 0.0, Color(1, 1, 1, 0.9), "melee")
		_:
			push_warning("Unknown ability_id=%s — using basic" % ability_id)
			return get_ability("basic")

static func _def(
	id: String, name: String, kit: AbilityDef.Kit,
	windup: String, strike: String, follow: String,
	mult: float, mult_b: float, gap: float, approach: float, ret: float,
	energy: float, cd: float, color: Color, kind: String
) -> AbilityDef:
	var a := AbilityDef.new()
	a.ability_id = id
	a.display_name = name
	a.kit = kit
	a.anim_windup = windup
	a.anim_strike = strike
	a.anim_follow = follow
	a.power_mult = mult
	a.power_mult_b = mult_b
	a.contact_gap = gap
	a.approach_time = approach
	a.return_time = ret
	a.energy_gain = energy
	a.skill_cooldown = cd
	a.vfx_color = color
	a.vfx_kind = kind
	return a
