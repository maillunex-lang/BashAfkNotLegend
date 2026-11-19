extends Node2D

## Facing lab via CharacterRegistry (VISUAL-APPROVAL-001).
## LEFT-side→RIGHT and RIGHT-side→LEFT, walk/attack/turn — same authored sprites.

@onready var braxor: Fighter = $Braxor
@onready var dummy_a: Node2D = $DummyRight
@onready var dummy_b: Node2D = $DummyLeft
@onready var label: Label = $UI/Label
@onready var phase_label: Label = $UI/Phase

var phase: int = 0
var phase_t: float = 0.0
var wall0: int = 0
var shots: Dictionary = {}

func _ready() -> void:
	wall0 = Time.get_ticks_msec()
	Engine.time_scale = 1.0
	Engine.max_fps = 30
	braxor.apply_character_data(CharacterRegistry.get_character("braxor"))
	braxor.battle_side = Fighter.BattleSide.LEFT
	braxor.show_facing_debug = true
	braxor.move_speed = 70.0
	braxor._build_frames()
	braxor.hp = braxor.max_hp
	braxor._update_bars()
	braxor.name_label.text = braxor.display_name
	braxor.set_desired_facing(Fighter.Facing.RIGHT)
	braxor.play_anim("idle")
	label.text = "FACING TEST — registry visual source=%s" % (
		"RIGHT" if braxor.source_facing == Fighter.Facing.RIGHT else "LEFT"
	)
	_log_diag()

func _process(delta: float) -> void:
	phase_t += delta
	var _wall := (Time.get_ticks_msec() - wall0) / 1000.0
	match phase:
		0:
			phase_label.text = "1) LEFT side, face RIGHT (idle)"
			braxor.battle_side = Fighter.BattleSide.LEFT
			braxor.global_position = Vector2(280, 1100)
			braxor.set_desired_facing(Fighter.Facing.RIGHT)
			braxor.play_anim("idle")
			if phase_t > 1.6:
				_shot("face_right_idle")
				_next()
		1:
			phase_label.text = "2) Run RIGHT"
			braxor.face_towards(dummy_a.global_position)
			braxor.play_anim("run")
			braxor.global_position.x = move_toward(braxor.global_position.x, 520.0, 90.0 * delta)
			if phase_t > 1.8:
				_shot("run_right")
				_next()
		2:
			phase_label.text = "3) Attack RIGHT"
			braxor.face_towards(dummy_a.global_position)
			braxor.play_anim("attack1")
			if phase_t > 1.5:
				_shot("attack_right")
				_next()
		3:
			phase_label.text = "4) RIGHT side, face LEFT (idle)"
			braxor.battle_side = Fighter.BattleSide.RIGHT
			braxor.global_position = Vector2(780, 1100)
			braxor.set_desired_facing(Fighter.Facing.LEFT)
			braxor.play_anim("idle")
			if phase_t > 1.6:
				_shot("face_left_idle")
				_next()
		4:
			phase_label.text = "5) Run + attack LEFT"
			braxor.face_towards(dummy_b.global_position)
			if phase_t < 1.0:
				braxor.play_anim("run")
				braxor.global_position.x = move_toward(braxor.global_position.x, 560.0, 90.0 * delta)
			else:
				braxor.play_anim("attack2")
			if phase_t > 2.2:
				_shot("attack_left")
				_next()
		5:
			phase_label.text = "6) Turn toward new target"
			var tog := int(phase_t / 0.9) % 2
			var tgt := dummy_a if tog == 0 else dummy_b
			braxor.face_towards(tgt.global_position)
			braxor.play_anim("idle")
			if phase_t > 2.5:
				_shot("turn_targets")
				_next()
		6:
			phase_label.text = "DONE — check artifacts"
			if phase_t > 0.8:
				if OS.get_environment("BASH_DEMO_QUIT") == "1":
					get_tree().quit()

func _next() -> void:
	phase += 1
	phase_t = 0.0
	_log_diag()

func _shot(name: String) -> void:
	if shots.has(name):
		return
	shots[name] = true
	var img := get_viewport().get_texture().get_image()
	var base := OS.get_environment("BASH_FACING_OUT")
	if base == "":
		base = "/tmp/facing_test"
	DirAccess.make_dir_recursive_absolute(base)
	var path := "%s/%s.png" % [base, name]
	img.save_png(path)
	print("[FACING_TEST] saved ", path, " | ", braxor.debug_facing_report())

func _log_diag() -> void:
	print("[FACING_TEST] phase=", phase, " ", braxor.debug_facing_report())
