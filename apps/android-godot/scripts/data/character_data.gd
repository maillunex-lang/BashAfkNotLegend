extends Resource
class_name CharacterData

## Logic / balance package — independent of sprites (VISUAL-APPROVAL-001).

enum RoleStyle { TANK, ASSASSIN, BRUTE, BEAST, SUPPORT, MAGE }

@export var character_id: String = ""
@export var display_name: String = ""
@export var faction_id: String = ""
@export var class_id: String = ""
@export var role_style: RoleStyle = RoleStyle.TANK
@export var is_hero: bool = true
@export var max_hp: float = 1000.0
@export var max_energy: float = 100.0
@export var attack_power: float = 120.0
@export var preferred_range: float = 110.0
@export var move_speed: float = 48.0
@export var is_front_row_default: bool = true

## Skill / ult IDs only — never bind to a PNG or frame count.
@export var basic_attack_id: String = "basic"
@export var skill1_id: String = "skill1"
@export var skill2_id: String = "skill2"
@export var ultimate_id: String = "ultimate"

@export var visual: CharacterVisualDef
