extends Node2D

## Wolf walks behind golem then in front — verifies foot-Y / YSort.

@onready var golem: Fighter = $Fighters/Stonekin
@onready var wolf: Fighter = $Fighters/Shadewolf
@onready var phase_label: Label = $UI/Phase

var t: float = 0.0
var wall0: int = 0
var shot_a := false
var shot_b := false

func _ready() -> void:
	wall0 = Time.get_ticks_msec()
	Engine.time_scale = 1.0
	golem.source_facing = Fighter.Facing.RIGHT
	golem.battle_side = Fighter.BattleSide.RIGHT
	golem.set_desired_facing(Fighter.Facing.LEFT)
	golem.show_facing_debug = false
	golem.global_position = Vector2(540, 1040)
	golem.play_anim("idle")

	wolf.source_facing = Fighter.Facing.LEFT
	wolf.battle_side = Fighter.BattleSide.RIGHT
	wolf.set_desired_facing(Fighter.Facing.LEFT)
	wolf.show_facing_debug = false
	wolf.global_position = Vector2(320, 980) # higher on screen = farther = behind
	wolf.play_anim("run")
	$Fighters.y_sort_enabled = true

func _process(delta: float) -> void:
	t += delta
	var wall := (Time.get_ticks_msec() - wall0) / 1000.0
	if t < 2.5:
		phase_label.text = "Wolf BEHIND golem (smaller Y)"
		wolf.global_position.x = move_toward(wolf.global_position.x, 700.0, 120.0 * delta)
		wolf.global_position.y = 980.0
		wolf.play_anim("run")
		if wall > 1.2 and not shot_a:
			shot_a = true
			_shot("wolf_behind")
	elif t < 5.0:
		phase_label.text = "Wolf IN FRONT of golem (larger Y)"
		wolf.global_position.x = move_toward(wolf.global_position.x, 400.0, 120.0 * delta)
		wolf.global_position.y = 1100.0
		wolf.play_anim("run")
		if wall > 3.5 and not shot_b:
			shot_b = true
			_shot("wolf_front")
	else:
		phase_label.text = "DONE"
		if OS.get_environment("BASH_DEMO_QUIT") == "1" and wall > 5.5:
			get_tree().quit()

func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var base := OS.get_environment("BASH_DEPTH_OUT")
	if base == "":
		base = "/tmp/depth_test"
	DirAccess.make_dir_recursive_absolute(base)
	img.save_png("%s/%s.png" % [base, name])
	print("[DEPTH] ", name, " wolf.y=", wolf.global_position.y, " golem.y=", golem.global_position.y)
