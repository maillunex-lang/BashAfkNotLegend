extends Resource
class_name CharacterVisualDef

## Swappable visual package for a character (VISUAL-APPROVAL-001).
## Combat logic never hardcodes PNG paths or frame counts.

enum Facing { LEFT, RIGHT }

@export var visual_id: String = ""
@export var display_name: String = ""
@export var sprite_folder: String = "" # under res://assets/sprites/
@export var portrait_path: String = ""
@export var source_facing: Facing = Facing.RIGHT
@export var sprite_scale: float = 0.5
@export var foot_offset_y: float = 0.0
@export var personal_space: float = 70.0

## Attach points in local body space (unflipped). X is mirrored when flipped.
@export var attach_weapon: Vector2 = Vector2(40, -70)
@export var attach_shield: Vector2 = Vector2(35, -55)
@export var attach_vfx: Vector2 = Vector2(0, -90)
@export var attach_hit: Vector2 = Vector2(0, -80)

## Animation contract — shared names for all 54 heroes / mobs.
## Missing files fall back to idle.png inside Fighter.
const ANIM_CONTRACT: PackedStringArray = [
	"idle", "walk", "run",
	"attack1", "attack2",
	"skill1", "skill2", "ultimate",
	"hit", "stagger", "death", "victory",
	"block", "personality",
]

func needs_flip(desired_right: bool) -> bool:
	var authored_right := source_facing == Facing.RIGHT
	return authored_right != desired_right

func sprite_base_path() -> String:
	return "res://assets/sprites/%s/" % sprite_folder

func attach_point(kind: String) -> Vector2:
	match kind:
		"weapon":
			return attach_weapon
		"shield":
			return attach_shield
		"vfx":
			return attach_vfx
		"hit":
			return attach_hit
		_:
			return Vector2.ZERO
