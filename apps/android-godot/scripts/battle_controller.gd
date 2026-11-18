extends Node2D

## Simultaneous side-view battle. No return-to-home after each hit.
## Y-sort by foot position. Unique kits for 4 fighters.

@onready var braxor: Fighter = $Fighters/Braxor
@onready var nixara: Fighter = $Fighters/Nixara
@onready var stonekin: Fighter = $Fighters/Stonekin
@onready var shadewolf: Fighter = $Fighters/Shadewolf
@onready var hud = $HUD
@onready var floaters: Node2D = $Floaters
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
var demo_time: float = 0.0
var screenshot_done: bool = false
var ended: bool = false
var active_vfx: int = 0
const MAX_VFX: int = 8

# Demo scripted showcase beats
var demo_phase: int = 0
var demo_timer: float = 0.0

func _ready() -> void:
	players = [braxor, nixara]
	enemies = [stonekin, shadewolf]
	_configure_fighters()
	for f in players + enemies:
		f.died.connect(_on_fighter_died)
		f.energy_changed.connect(_on_energy_changed)
		f.ult_ready.connect(_on_ult_ready)
	hud.setup(players)
	hud.ult_pressed.connect(_on_ult_pressed)
	hud.speed_changed.connect(_on_speed_changed)
	hud.auto_toggled.connect(_on_auto_toggled)
	wave_label.text = "WAVE 1/1"
	_log("Динамический бой. Браксор → вправо.")
	_ensure_facing_debug_arrows()
	var tw := create_tween().set_loops()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", -14.0, 9.0).as_relative()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", 14.0, 9.0).as_relative()

func _ensure_facing_debug_arrows() -> void:
	# Temporary QA arrows: allies → , enemies ←  (outside character body)
	for f in players:
		_add_dir_arrow(f, true)
	for f in enemies:
		_add_dir_arrow(f, false)

func _add_dir_arrow(f: Fighter, point_right: bool) -> void:
	if f.get_node_or_null("UI/DirArrow") != null:
		return
	var lbl := Label.new()
	lbl.name = "DirArrow"
	lbl.text = "→" if point_right else "←"
	lbl.position = Vector2(70 if point_right else -90, -160)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.76, 0.42))
	lbl.add_theme_color_override("font_outline_color", Color(0.09, 0.15, 0.2))
	lbl.add_theme_constant_override("outline_size", 5)
	f.ui.add_child(lbl)

func _configure_fighters() -> void:
	braxor.style = Fighter.Style.TANK
	braxor.preferred_range = 120.0
	braxor.move_speed = 55.0
	# Sprites flopped to face RIGHT on disk; authored_right=true.
	braxor.faces_right_by_default = true
	braxor.lock_team_facing()

	nixara.style = Fighter.Style.ASSASSIN
	nixara.preferred_range = 95.0
	nixara.move_speed = 140.0
	nixara.faces_right_by_default = true
	nixara.lock_team_facing()

	stonekin.style = Fighter.Style.BRUTE
	stonekin.preferred_range = 125.0
	stonekin.move_speed = 40.0
	stonekin.faces_right_by_default = false # authored facing left
	stonekin.lock_team_facing()

	shadewolf.style = Fighter.Style.BEAST
	shadewolf.preferred_range = 100.0
	shadewolf.move_speed = 130.0
	shadewolf.faces_right_by_default = false
	shadewolf.lock_team_facing()

func _process(delta: float) -> void:
	var d := delta * battle_speed
	elapsed += d
	demo_time += delta
	demo_timer += d
	timer_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	$ParallaxRoot/Trees.position.x = sin(elapsed * 0.35) * 8.0

	if not screenshot_done and demo_time >= 2.5:
		_take_screenshot()
		screenshot_done = true

	if ended:
		return

	for f in players + enemies:
		if f.alive:
			f.gain_energy(5.5 * d)
			f.attack_cd = max(0.0, f.attack_cd - d)
			f.skill_cd = max(0.0, f.skill_cd - d)

	_update_targets()
	_demo_scripted_skills()
	for f in players + enemies:
		if f.alive and not f.busy:
			_ai_step(f, d)

	if auto_mode:
		_try_auto_ults()

	_check_end()
	if OS.get_environment("BASH_DEMO_QUIT") == "1" and demo_time >= 22.0:
		get_tree().quit()

func _update_targets() -> void:
	for f in players:
		if f.alive:
			f.current_target = _nearest_living(f, enemies)
	for f in enemies:
		if f.alive:
			f.current_target = _nearest_living(f, players)

func _nearest_living(self_f: Fighter, pool: Array[Fighter]) -> Fighter:
	var best: Fighter = null
	var best_d := INF
	for t in pool:
		if not t.alive:
			continue
		# Tanks prefer front-row if available
		var d := self_f.distance_to_fighter(t)
		if self_f.style == Fighter.Style.TANK and t.is_front_row:
			d *= 0.85
		if self_f.style == Fighter.Style.ASSASSIN and not t.is_front_row:
			d *= 0.9
		if d < best_d:
			best_d = d
			best = t
	return best

func _ai_step(f: Fighter, d: float) -> void:
	var target := f.current_target
	if target == null or not target.alive:
		f.play_anim("idle")
		return
	f.lock_team_facing()
	var dist := f.distance_to_fighter(target)
	var range := f.preferred_range
	# Approach point: stay on correct side of target (allies left of foe, enemies right of foe)
	var side := _attack_dir_x(f)
	var approach := Vector2(target.global_position.x - side * range, target.global_position.y)
	if dist > range + 18.0:
		_move_towards(f, approach, d)
		f.play_anim("run" if f.style == Fighter.Style.ASSASSIN or f.style == Fighter.Style.BEAST else "walk")
	elif dist < range - 40.0:
		# Back off to preferred range without crossing
		_move_towards(f, approach, d * 0.7)
		f.play_anim("walk")
	else:
		# In range: attack when cooldown ready
		if f.attack_cd <= 0.0:
			_start_attack(f, target)
		elif f.sprite.animation in ["walk", "run"]:
			f.play_anim("idle")

func _move_towards(f: Fighter, dest: Vector2, d: float) -> void:
	var dir := (dest - f.global_position)
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	# Keep slight lane (home_y) so depth stays readable; allow small Y adjust toward target lane
	var next := f.global_position + dir * f.move_speed * d
	next.y = lerpf(f.global_position.y, dest.y, 0.08)
	# Soft team lanes: allies stay left half, enemies right half (reduces crossing/wrong silhouette)
	if f.team == "player":
		next.x = clampf(next.x, 140.0, 620.0)
	else:
		next.x = clampf(next.x, 460.0, 940.0)
	next.y = clampf(next.y, 860.0, 1120.0)
	f.global_position = next

func _start_attack(f: Fighter, target: Fighter) -> void:
	f.busy = true
	f.attack_cd = _attack_cooldown(f)
	match f.style:
		Fighter.Style.TANK:
			_braxor_attack(f, target)
		Fighter.Style.ASSASSIN:
			_nixara_attack(f, target)
		Fighter.Style.BRUTE:
			_stonekin_attack(f, target)
		Fighter.Style.BEAST:
			_shadewolf_attack(f, target)

func _attack_cooldown(f: Fighter) -> float:
	match f.style:
		Fighter.Style.TANK: return 1.35
		Fighter.Style.ASSASSIN: return 0.85
		Fighter.Style.BRUTE: return 1.7
		Fighter.Style.BEAST: return 1.0
	return 1.1

func _attack_dir_x(f: Fighter) -> float:
	# Players lunge RIGHT, enemies LEFT — never flip based on overshoot.
	return 1.0 if f.team == "player" else -1.0

func _braxor_attack(f: Fighter, target: Fighter) -> void:
	# Shield raise then bash — stay at contact range (no return home)
	f.lock_team_facing()
	f.play_anim("block")
	_log("%s: блок → удар щитом" % f.display_name)
	var tw := create_tween()
	tw.tween_interval(0.22)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		f.lock_team_facing()
		f.play_anim("attack1")
		# lunge toward enemy side (right for allies)
		f.global_position.x = clampf(f.global_position.x + 22.0 * _attack_dir_x(f), 140.0, 940.0)
	)
	tw.tween_interval(0.28) # windup to impact
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 1.15, Color(1.0, 0.85, 0.35, 0.95), "shield")
		f.gain_energy(22.0)
	)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _nixara_attack(f: Fighter, target: Fighter) -> void:
	# Dash into target, dual slash, slight slip — always approach from left of foe
	_log("%s: теневой рывок" % f.display_name)
	f.lock_team_facing()
	f.play_anim("skill2")
	var start := f.global_position
	var dir := _attack_dir_x(f)
	var contact := Vector2(target.global_position.x - dir * 55.0, lerpf(start.y, target.global_position.y, 0.5))
	contact.x = clampf(contact.x, 140.0, 940.0)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, 0.16)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.lock_team_facing()
		f.play_anim("attack2")
		_spawn_trail(f, Color(0.75, 0.2, 0.85, 0.7))
	)
	tw.tween_interval(0.18)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 0.7, Color(0.9, 0.3, 1.0, 0.9), "slash")
	)
	tw.tween_interval(0.12)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 0.85, Color(1.0, 0.4, 0.8, 0.95), "slash")
		f.gain_energy(20.0)
		# Small step toward enemy side (not past into wrong facing)
		f.global_position.x = clampf(f.global_position.x + dir * 12.0, 140.0, 940.0)
	)
	tw.tween_interval(0.25)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _stonekin_attack(f: Fighter, target: Fighter) -> void:
	_log("%s: каменный удар" % f.display_name)
	f.lock_team_facing()
	f.play_anim("attack1")
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.play_anim("attack2")
		# small dust
		_spawn_ring(f.global_position + Vector2(0, 40), Color(0.65, 0.55, 0.4, 0.8), 1.2)
	)
	tw.tween_interval(0.22)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 1.35, Color(0.8, 0.7, 0.45, 0.95), "slam")
		# brief stagger on target
		if target.alive and not target.busy:
			target.play_anim("stagger")
		f.gain_energy(18.0)
	)
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _shadewolf_attack(f: Fighter, target: Fighter) -> void:
	_log("%s: прыжок-укус" % f.display_name)
	f.lock_team_facing()
	f.play_anim("run")
	var leap := Vector2(target.global_position.x, target.global_position.y - 10.0)
	leap.x = clampf(leap.x - _attack_dir_x(f) * 40.0, 140.0, 940.0)
	var tw := create_tween()
	tw.tween_property(f, "global_position", leap, 0.18)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.play_anim("attack2")
		_spawn_trail(f, Color(0.35, 0.1, 0.45, 0.75))
	)
	tw.tween_interval(0.16)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 1.05, Color(0.6, 0.2, 0.7, 0.95), "bite")
		f.gain_energy(16.0)
	)
	tw.tween_interval(0.22)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _perform_ultimate(actor: Fighter) -> void:
	if not actor.can_ult():
		return
	var target := actor.current_target
	if target == null or not target.alive:
		target = _nearest_living(actor, enemies if actor.team == "player" else players)
	if target == null:
		return
	actor.energy = 0.0
	actor._update_bars()
	actor.busy = true
	actor.lock_team_facing()
	if actor.style == Fighter.Style.ASSASSIN:
		_nixara_ult(actor, target)
	elif actor.style == Fighter.Style.TANK:
		_braxor_ult(actor, target)
	else:
		_generic_ult(actor, target)

func _braxor_ult(f: Fighter, target: Fighter) -> void:
	_log("УЛЬТ Браксор: Хребет не сдаётся")
	f.lock_team_facing()
	f.play_anim("ultimate")
	_spawn_ring(f.global_position, Color(1.0, 0.75, 0.3, 0.9), 2.2)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if not f.alive:
			return
		# AoE around tank line
		for e in enemies:
			if e.alive and f.distance_to_fighter(e) < 220.0:
				_resolve_hit(f, e, f.attack_power * 1.6, Color(1.0, 0.8, 0.3, 1.0), "ult")
	)
	tw.tween_interval(0.45)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("victory" if ended else "idle")
	)

func _nixara_ult(f: Fighter, target: Fighter) -> void:
	_log("УЛЬТ Никсара: Ночь без свидетелей")
	f.play_anim("ultimate")
	_spawn_trail(f, Color(0.6, 0.1, 0.9, 0.85))
	var marks: Array[Fighter] = []
	for e in enemies:
		if e.alive:
			marks.append(e)
	var tw := create_tween()
	var i := 0
	for e in marks:
		var idx := i
		tw.tween_callback(func():
			if not f.alive or not e.alive:
				return
			f.lock_team_facing()
			# Stay on ally side of the target (left of enemy)
			f.global_position = Vector2(e.global_position.x - 55.0, e.global_position.y)
			f.global_position.x = clampf(f.global_position.x, 140.0, 940.0)
			f.play_anim("attack2")
			_spawn_trail(f, Color(0.8, 0.2, 1.0, 0.8))
			_resolve_hit(f, e, f.attack_power * 1.4, Color(0.85, 0.25, 1.0, 1.0), "ult")
		)
		tw.tween_interval(0.22)
		i += 1
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _generic_ult(f: Fighter, target: Fighter) -> void:
	f.play_anim("ultimate")
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func():
		if f.alive and target.alive:
			_resolve_hit(f, target, f.attack_power * 1.8, Color(1, 1, 1, 0.9), "ult")
	)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _resolve_hit(attacker: Fighter, target: Fighter, amount: float, vfx_color: Color, _kind: String) -> void:
	if not attacker.alive or not target.alive:
		return
	var is_crit := randf() < 0.18
	var dmg := amount * (1.45 if is_crit else 1.0) * randf_range(0.92, 1.08)
	target.apply_damage(dmg, is_crit)
	attacker.flash_vfx(vfx_color, 1.5)
	_spawn_damage_number(target.global_position + Vector2(0, -130), int(dmg), is_crit)
	_log("%s → %s%s" % [attacker.display_name, target.display_name, " CRIT!" if is_crit else ""])

func _spawn_damage_number(pos: Vector2, value: int, is_crit: bool) -> void:
	var lbl := Label.new()
	lbl.text = str(value)
	lbl.global_position = pos + Vector2(randf_range(-20, 20), 0)
	lbl.z_index = 4000
	lbl.add_theme_font_size_override("font_size", 34 if is_crit else 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_crit else Color(1, 0.95, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15))
	lbl.add_theme_constant_override("outline_size", 4)
	floaters.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 60.0, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

func _spawn_trail(f: Fighter, color: Color) -> void:
	if active_vfx >= MAX_VFX:
		return
	active_vfx += 1
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([Vector2(-20, -10), Vector2(20, -6), Vector2(16, 10), Vector2(-24, 8)])
	poly.global_position = f.global_position + Vector2(0, -20)
	poly.z_index = f.z_index + 1
	floaters.add_child(poly)
	var tw := create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		poly.queue_free()
	)

func _spawn_ring(pos: Vector2, color: Color, scale_to: float) -> void:
	if active_vfx >= MAX_VFX:
		return
	active_vfx += 1
	var s := Sprite2D.new()
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(64):
		for x in range(64):
			var dx := x - 32.0
			var dy := y - 32.0
			var r2 := dx * dx + dy * dy
			if r2 < 30 * 30 and r2 > 18 * 18:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	s.texture = ImageTexture.create_from_image(img)
	s.modulate = color
	s.global_position = pos
	s.z_index = 3500
	floaters.add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2(scale_to, scale_to), 0.35)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		s.queue_free()
	)

func _demo_scripted_skills() -> void:
	# Guarantees showcase of 4 skills + 2 ults during the recording window
	if demo_phase == 0 and demo_timer > 1.2 and braxor.alive and stonekin.alive and not braxor.busy:
		demo_phase = 1
		braxor.busy = false
		_braxor_attack(braxor, stonekin)
	elif demo_phase == 1 and demo_timer > 3.0 and nixara.alive and not nixara.busy:
		demo_phase = 2
		_nixara_attack(nixara, shadewolf if shadewolf.alive else stonekin)
	elif demo_phase == 2 and demo_timer > 5.0 and stonekin.alive and not stonekin.busy:
		demo_phase = 3
		_stonekin_attack(stonekin, braxor if braxor.alive else nixara)
	elif demo_phase == 3 and demo_timer > 7.0 and shadewolf.alive and not shadewolf.busy:
		demo_phase = 4
		_shadewolf_attack(shadewolf, nixara if nixara.alive else braxor)
	elif demo_phase == 4 and demo_timer > 9.5 and braxor.alive:
		demo_phase = 5
		braxor.energy = braxor.max_energy
		_perform_ultimate(braxor)
	elif demo_phase == 5 and demo_timer > 12.0 and nixara.alive:
		demo_phase = 6
		nixara.energy = nixara.max_energy
		_perform_ultimate(nixara)

func _try_auto_ults() -> void:
	if demo_phase < 6:
		return
	for f in players:
		if f.can_ult() and randf() < 0.2:
			_perform_ultimate(f)
			return

func _on_ult_pressed(fighter_id: String) -> void:
	for f in players:
		if f.fighter_id == fighter_id:
			_perform_ultimate(f)
			return

func _on_speed_changed(mult: float) -> void:
	battle_speed = mult
	speed_label.text = "x%s" % str(mult).trim_suffix(".0")

func _on_auto_toggled(enabled: bool) -> void:
	auto_mode = enabled
	auto_label.text = "AUTO: ON" if enabled else "AUTO: OFF"

func _on_fighter_died(f: Fighter) -> void:
	_log("%s повержен" % f.display_name)
	_spawn_damage_number(f.global_position + Vector2(0, -100), 0, false)

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
	if not ended and (not players_alive or not enemies_alive):
		ended = true
		_log("Победа!" if players_alive else "Поражение...")
		for f in players:
			if f.alive:
				f.play_anim("victory")

func _log(msg: String) -> void:
	log_label.text = msg

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://battle_prototype_screenshot.png")
	var out := OS.get_environment("BASH_SCREENSHOT_PATH")
	if out != "":
		img.save_png(out)
