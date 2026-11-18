extends Node2D

## Prototype auto-battle: Braxor + Nixara vs Stonekin + Shadewolf.
## Side-view, layered BG, interactive ult HUD. Android-first visual demo.

@onready var braxor: Fighter = $Fighters/Braxor
@onready var nixara: Fighter = $Fighters/Nixara
@onready var stonekin: Fighter = $Fighters/Stonekin
@onready var shadewolf: Fighter = $Fighters/Shadewolf
@onready var hud = $HUD
@onready var parallax: Node2D = $ParallaxRoot
@onready var speed_label: Label = $HUD/TopBar/Margin/VBox/SpeedRow/SpeedLabel
@onready var auto_label: Label = $HUD/TopBar/Margin/VBox/SpeedRow/AutoLabel
@onready var wave_label: Label = $HUD/TopBar/Margin/VBox/Row1/WaveLabel
@onready var timer_label: Label = $HUD/TopBar/Margin/VBox/Row1/TimerLabel
@onready var log_label: Label = $HUD/LogLabel

var players: Array[Fighter] = []
var enemies: Array[Fighter] = []
var battle_speed: float = 1.0
var auto_mode: bool = true
var elapsed: float = 0.0
var turn_cooldown: float = 0.0
var demo_time: float = 0.0
var screenshot_done: bool = false
var ended: bool = false

func _ready() -> void:
	players = [braxor, nixara]
	enemies = [stonekin, shadewolf]
	for f in players + enemies:
		f.died.connect(_on_fighter_died)
		f.energy_changed.connect(_on_energy_changed)
		f.ult_ready.connect(_on_ult_ready)
	hud.setup(players)
	hud.ult_pressed.connect(_on_ult_pressed)
	hud.speed_changed.connect(_on_speed_changed)
	hud.auto_toggled.connect(_on_auto_toggled)
	wave_label.text = "WAVE 1/1"
	_log("Бой начался. Auto ON. Тап портрета = ульт.")
	# Soft parallax drift
	var tw := create_tween().set_loops()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", -18.0, 8.0).as_relative()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", 18.0, 8.0).as_relative()

func _process(delta: float) -> void:
	var d := delta * battle_speed
	elapsed += d
	demo_time += delta
	timer_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	# Light parallax on trees
	$ParallaxRoot/Trees.position.x = sin(elapsed * 0.4) * 10.0

	if not screenshot_done and demo_time >= 2.2:
		_take_screenshot()
		screenshot_done = true

	if ended:
		return

	turn_cooldown -= d
	if turn_cooldown > 0.0:
		return

	# Passive energy trickle
	for f in players + enemies:
		if f.alive:
			f.gain_energy(6.0 * d)

	if auto_mode:
		_try_auto_ults()

	var actor := _pick_attacker()
	var target := _pick_target(actor)
	if actor and target:
		turn_cooldown = 1.15
		_perform_attack(actor, target)
	else:
		_check_end()

	# Occasional personality beats
	if int(elapsed * 10) % 47 == 0:
		_maybe_personality()

	# Auto-quit after demo window if requested
	if OS.get_environment("BASH_DEMO_QUIT") == "1" and demo_time >= 16.0:
		get_tree().quit()

func _pick_attacker() -> Fighter:
	var pool: Array[Fighter] = []
	for f in players + enemies:
		if f.alive and not f.busy:
			pool.append(f)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]

func _pick_target(actor: Fighter) -> Fighter:
	if actor == null:
		return null
	var pool: Array[Fighter] = players if actor.team == "enemy" else enemies
	var living: Array[Fighter] = []
	for f in pool:
		if f.alive:
			living.append(f)
	if living.is_empty():
		return null
	# Prefer front-row targets
	var fronts: Array[Fighter] = []
	for f in living:
		if f.is_front_row:
			fronts.append(f)
	if not fronts.is_empty():
		return fronts[randi() % fronts.size()]
	return living[randi() % living.size()]

func _perform_attack(actor: Fighter, target: Fighter) -> void:
	actor.busy = true
	var start := actor.position
	var dir := 1.0 if actor.team == "player" else -1.0
	var tw := create_tween()
	tw.tween_property(actor, "position:x", start.x + 55.0 * dir, 0.12)
	tw.tween_callback(func():
		actor.play_anim("attack")
		actor.flash_vfx(Color(1.0, 0.9, 0.4, 0.85) if actor.team == "player" else Color(1.0, 0.4, 0.35, 0.85))
		target.apply_damage(actor.attack_power * randf_range(0.85, 1.15))
		actor.gain_energy(18.0)
		_log("%s → %s" % [actor.display_name, target.display_name])
	)
	tw.tween_interval(0.28)
	tw.tween_property(actor, "position", start, 0.14)
	tw.tween_callback(func():
		if actor.alive:
			actor.busy = false
			actor.play_anim("idle")
		_check_end()
	)

func _perform_ultimate(actor: Fighter) -> void:
	if not actor.can_ult():
		return
	var target := _pick_target(actor)
	if target == null:
		return
	actor.energy = 0.0
	actor._update_bars()
	actor.busy = true
	actor.play_anim("ultimate")
	actor.flash_vfx(Color(0.5, 0.95, 1.0, 0.95))
	target.apply_damage(actor.attack_power * 2.2)
	for f in (enemies if actor.team == "player" else players):
		if f.alive and f != target:
			f.apply_damage(actor.attack_power * 0.55)
	_log("УЛЬТ: %s!" % actor.display_name)
	turn_cooldown = 0.9
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_callback(func():
		if actor.alive:
			actor.busy = false
			actor.play_anim("idle")
		_check_end()
	)

func _try_auto_ults() -> void:
	for f in players:
		if f.can_ult() and randf() < 0.35:
			_perform_ultimate(f)
			return

func _maybe_personality() -> void:
	for f in players:
		if f.alive and not f.busy and randf() < 0.5:
			f.play_anim("personality")
			_log("%s: *характер*" % f.display_name)
			return

func _on_ult_pressed(fighter_id: String) -> void:
	for f in players:
		if f.fighter_id == fighter_id:
			if auto_mode:
				_log("Ручной ульт (Auto выкл. не обязателен)")
			_perform_ultimate(f)
			return

func _on_speed_changed(mult: float) -> void:
	battle_speed = mult
	speed_label.text = "x%s" % str(mult).trim_suffix(".0")
	Engine.time_scale = 1.0 # keep engine stable; we scale locally
	_log("Скорость x%s" % str(mult))

func _on_auto_toggled(enabled: bool) -> void:
	auto_mode = enabled
	auto_label.text = "AUTO: ON" if enabled else "AUTO: OFF"

func _on_fighter_died(f: Fighter) -> void:
	_log("%s повержен" % f.display_name)
	_check_end()

func _on_energy_changed(f: Fighter, value: float, max_value: float) -> void:
	hud.update_energy(f.fighter_id, value, max_value)

func _on_ult_ready(f: Fighter) -> void:
	if f.team == "player":
		hud.set_ready(f.fighter_id, true)

func _check_end() -> void:
	var players_alive := false
	var enemies_alive := false
	for f in players:
		if f.alive:
			players_alive = true
	for f in enemies:
		if f.alive:
			enemies_alive = true
	if not players_alive or not enemies_alive:
		ended = true
		_log("Победа!" if players_alive else "Поражение...")
		for f in players:
			if f.alive:
				f.play_anim("personality")

func _log(msg: String) -> void:
	log_label.text = msg

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "user://battle_prototype_screenshot.png"
	img.save_png(path)
	var abs_path := OS.get_user_data_dir().path_join("battle_prototype_screenshot.png")
	#_log("Screenshot saved")
	# Also copy-friendly path via env
	var out := OS.get_environment("BASH_SCREENSHOT_PATH")
	if out != "":
		img.save_png(out)
