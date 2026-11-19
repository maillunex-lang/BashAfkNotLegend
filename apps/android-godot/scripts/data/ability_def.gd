extends Resource
class_name AbilityDef

## Presentation + balance knobs for one ability ID.
## Never stores PNG paths or frame counts (VISUAL-APPROVAL-001).

enum Kit {
	MELEE_STEP, ## walk in → attack → home (tank/brute)
	DASH_COMBO, ## run in → double hit → home (assassin)
	LEAP_BITE, ## fast leap → single hit (beast)
	SHIELD_BASH, ## walk → block pose → slam
	ULT_AOE_STOMP,
	ULT_MULTI_MARK,
	GENERIC_BURST,
}

@export var ability_id: String = ""
@export var display_name: String = ""
@export var kit: Kit = Kit.MELEE_STEP
@export var anim_windup: String = "walk"
@export var anim_strike: String = "attack1"
@export var anim_follow: String = "attack2"
@export var power_mult: float = 1.0
@export var power_mult_b: float = 0.0 ## second hit (0 = none)
@export var contact_gap: float = 70.0
@export var approach_time: float = 0.35
@export var return_time: float = 0.3
@export var energy_gain: float = 14.0
@export var skill_cooldown: float = 0.0
@export var vfx_color: Color = Color(1.0, 0.85, 0.4, 0.95)
@export var vfx_kind: String = "melee" ## melee | slash | slam | bite | ult
