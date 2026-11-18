extends Node2D

## BATTLE-POLISH-002: simultaneous side-view battle with source_facing,
## engagement slots, soft separation, YSort feet, readable x1 tempo.

@onready var braxor: Fighter = $Fighters/Braxor
@onready var nixara: Fighter = $Fighters/Nixara
@onready var stonekin: Fighter = $Fighters/Stonekin
@onready var shadewolf: Fighter = $Fighters/Shadewolf
@onready var hud = $HUD
@onready var floaters: Node2D = $Floaters
@onready var fighters_root: Node2D = $Fighters
@onready var speed_label: Label = $HUD/TopBar/Margin/VBox/SpeedRow/SpeedLabel
@onready var auto_label: Label = $HUD/TopBar/Margin/VBox/SpeedRow/AutoLabel
@onready var wave_label: Label = $HUD/TopBar/Margin/VBox/Row1/WaveLabel
@onready var timer_label: Label = $HUD/TopBar/Margin/VBox/Row1/TimerLabel
@onready var log_label: Label = $HUD/LogLabel

var players: Array[Fighter] = []
var enemies: Array[Fighter] = []
var all_fighters: Array[Fighter] = []
var battle_speed: float = 1.0
var auto_mode: bool = true
var elapsed: float = 0.0
var wall_start_ms: int = 0
var screenshot_done: bool = false
var ended: bool = false
var active_vfx: int = 0
const MAX_VFX: int = 14

var demo_phase: int = 0
var demo_timer: float = 0.0

# Engagement slot bookkeeping: target_id -> Array of {fighter, angle}
var _slots: Dictionary = {}

func _ready() -> void:
	wall_start_ms = Time.get_ticks_msec()
	Engine.time_scale = 1.0
	players = [braxor, nixara]
	enemies = [stonekin, shadewolf]
	all_fighters = players + enemies
	fighters_root.y_sort_enabled = true
	_configure_fighters()
	for f in all_fighters:
		f.died.connect(_on_fighter_died)
		f.energy_changed.connect(_on_energy_changed)
		f.ult_ready.connect(_on_ult_ready)
	hud.setup(players)
	hud.ult_pressed.connect(_on_ult_pressed)
	hud.speed_changed.connect(_on_speed_changed)
	hud.auto_toggled.connect(_on_auto_toggled)
	wave_label.text = "WAVE 1/1"
	_log("Бой: source_facing + слоты. Браксор → вправо.")
	_print_facing_diagnostics()
	var tw := create_tween().set_loops()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", -14.0, 9.0).as_relative()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", 14.0, 9.0).as_relative()

func _print_facing_diagnostics() -> void:
	for f in all_fighters:
		print("[FACING] ", f.debug_facing_report())

func _configure_fighters() -> void:
	# Source facing from PNG audit (pixel mass). Desired facing follows target.
	braxor.style = Fighter.Style.TANK
	braxor.preferred_range = 135.0
	braxor.move_speed = 32.0
	braxor.personal_space = 88.0
	# Canonical PNG faces RIGHT (see assets/sprites/braxor/_authored_right).
	# Never flop these again without visual QA of face+shield toward enemy.
	braxor.source_facing = Fighter.Facing.RIGHT
	braxor.battle_side = Fighter.BattleSide.LEFT
	braxor.set_desired_facing(Fighter.Facing.RIGHT)

	nixara.style = Fighter.Style.ASSASSIN
	nixara.preferred_range = 110.0
	nixara.move_speed = 58.0
	nixara.personal_space = 64.0
	nixara.source_facing = Fighter.Facing.LEFT # PNG faces left
	nixara.battle_side = Fighter.BattleSide.LEFT
	nixara.set_desired_facing(Fighter.Facing.RIGHT) # flip_h true

	stonekin.style = Fighter.Style.BRUTE
	stonekin.preferred_range = 140.0
	stonekin.move_speed = 24.0
	stonekin.personal_space = 96.0
	stonekin.source_facing = Fighter.Facing.RIGHT
	stonekin.battle_side = Fighter.BattleSide.RIGHT
	stonekin.set_desired_facing(Fighter.Facing.LEFT) # flip_h true

	shadewolf.style = Fighter.Style.BEAST
	shadewolf.preferred_range = 115.0
	shadewolf.move_speed = 62.0
	shadewolf.personal_space = 70.0
	shadewolf.source_facing = Fighter.Facing.LEFT
	shadewolf.battle_side = Fighter.BattleSide.RIGHT
	shadewolf.set_desired_facing(Fighter.Facing.LEFT) # flip_h false

func _process(delta: float) -> void:
	# Engine.time_scale drives unified battle tempo; delta is already scaled.
	var d := delta
	elapsed += d
	demo_timer += d
	timer_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	$ParallaxRoot/Trees.position.x = sin(elapsed * 0.35) * 8.0

	var wall_s := (Time.get_ticks_msec() - wall_start_ms) / 1000.0
	if not screenshot_done and wall_s >= 3.0:
		_take_screenshot()
		screenshot_done = true

	if ended:
		_soft_separate(d)
		return

	for f in all_fighters:
		if f.alive:
			f.gain_energy(3.2 * d)
			f.attack_cd = max(0.0, f.attack_cd - d)
			f.skill_cd = max(0.0, f.skill_cd - d)

	_update_targets()
	_assign_engagement_slots()
	_demo_scripted_skills()
	for f in all_fighters:
		if f.alive and not f.busy:
			_ai_step(f, d)
	_soft_separate(d)

	if auto_mode:
		_try_auto_ults()

	_check_end()
	var quit_after := float(OS.get_environment("BASH_DEMO_SECONDS"))
	if quit_after <= 0.0:
		quit_after = 45.0
	if OS.get_environment("BASH_DEMO_QUIT") == "1" and wall_s >= quit_after:
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
		var d := self_f.distance_to_fighter(t)
		if self_f.style == Fighter.Style.TANK and t.is_front_row:
			d *= 0.85
		if self_f.style == Fighter.Style.ASSASSIN and not t.is_front_row:
			d *= 0.88
		if d < best_d:
			best_d = d
			best = t
	return best

func _assign_engagement_slots() -> void:
	_slots.clear()
	# Group attackers by target and fan them around preferred range.
	var by_target: Dictionary = {}
	for f in all_fighters:
		if not f.alive or f.current_target == null or not f.current_target.alive:
			f.has_reserved_slot = false
			continue
		var tid := f.current_target.get_instance_id()
		if not by_target.has(tid):
			by_target[tid] = []
		by_target[tid].append(f)

	for tid in by_target.keys():
		var group: Array = by_target[tid]
		var target: Fighter = group[0].current_target
		var n := group.size()
		for i in range(n):
			var f: Fighter = group[i]
			var side_sign := 1.0 if f.battle_side == Fighter.BattleSide.LEFT else -1.0
			# Spread angles: tanks near front center, assassins flank, beasts offset Y
			var base_angle := 0.0
			match f.style:
				Fighter.Style.TANK:
					base_angle = deg_to_rad(-8.0 + i * 10.0)
				Fighter.Style.ASSASSIN:
					if side_sign > 0.0:
						base_angle = deg_to_rad(-38.0 - float(i) * 12.0)
					else:
						base_angle = deg_to_rad(38.0 + float(i) * 12.0)
				Fighter.Style.BRUTE:
					base_angle = deg_to_rad(6.0)
				Fighter.Style.BEAST:
					base_angle = deg_to_rad(32.0 if side_sign > 0.0 else -32.0)
			var dist := f.preferred_range
			var ox := -side_sign * cos(base_angle) * dist
			var oy := sin(base_angle) * dist * 0.55
			# Lane bias from home_y
			oy += (f.home_y - target.global_position.y) * 0.25
			var slot := Vector2(target.global_position.x + ox, clampf(target.global_position.y + oy, 860.0, 1120.0))
			# Keep teams on their halves loosely
			if f.battle_side == Fighter.BattleSide.LEFT:
				slot.x = clampf(slot.x, 120.0, 640.0)
			else:
				slot.x = clampf(slot.x, 440.0, 960.0)
			f.reserved_slot = slot
			f.has_reserved_slot = true

func _ai_step(f: Fighter, d: float) -> void:
	var target := f.current_target
	if target == null or not target.alive:
		f.play_anim("idle")
		return
	f.face_towards(target.global_position)
	var dest := f.reserved_slot if f.has_reserved_slot else Vector2(
		target.global_position.x - f.facing_sign() * f.preferred_range,
		lerpf(f.global_position.y, target.global_position.y, 0.3)
	)
	var dist := f.global_position.distance_to(dest)
	var to_target := f.distance_to_fighter(target)
	if dist > 22.0 and to_target > f.preferred_range * 0.72:
		_move_towards(f, dest, d)
		var moving_fast := f.style == Fighter.Style.ASSASSIN or f.style == Fighter.Style.BEAST
		f.play_anim("run" if moving_fast and dist > 60.0 else "walk")
	elif to_target < f.preferred_range * 0.55:
		_move_towards(f, dest, d * 0.65)
		f.play_anim("walk")
	else:
		if f.attack_cd <= 0.0:
			_start_attack(f, target)
		elif f.sprite.animation in ["walk", "run"]:
			f.play_anim("idle")

func _move_towards(f: Fighter, dest: Vector2, d: float) -> void:
	var dir := dest - f.global_position
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var next := f.global_position + dir * f.move_speed * d
	next.y = lerpf(f.global_position.y, dest.y, clampf(2.2 * d, 0.0, 1.0))
	next.x = clampf(next.x, 110.0, 970.0)
	next.y = clampf(next.y, 860.0, 1125.0)
	f.global_position = next

func _soft_separate(d: float) -> void:
	# Soft personal-space push — no jitter oscillation
	for i in range(all_fighters.size()):
		var a: Fighter = all_fighters[i]
		if not a.alive:
			continue
		for j in range(i + 1, all_fighters.size()):
			var b: Fighter = all_fighters[j]
			if not b.alive:
				continue
			var delta_pos := a.global_position - b.global_position
			# Elliptical: stronger X separation so silhouettes don't stack
			var min_dist := (a.personal_space + b.personal_space) * 0.5
			var dx := delta_pos.x
			var dy := delta_pos.y * 1.35
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 0.001 or dist >= min_dist:
				continue
			var push := (min_dist - dist) / min_dist
			var n := Vector2(dx, dy).normalized()
			var force := n * push * 55.0 * d
			if not a.busy:
				a.global_position += force
			if not b.busy:
				b.global_position -= force
			a.global_position.x = clampf(a.global_position.x, 110.0, 970.0)
			b.global_position.x = clampf(b.global_position.x, 110.0, 970.0)
			a.global_position.y = clampf(a.global_position.y, 860.0, 1125.0)
			b.global_position.y = clampf(b.global_position.y, 860.0, 1125.0)

func _start_attack(f: Fighter, target: Fighter) -> void:
	f.busy = true
	f.attack_cd = _attack_cooldown(f)
	f.face_towards(target.global_position)
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
	# x1 readable cadence (BATTLE-SPEED-001)
	match f.style:
		Fighter.Style.TANK: return 2.15
		Fighter.Style.ASSASSIN: return 1.35
		Fighter.Style.BRUTE: return 2.55
		Fighter.Style.BEAST: return 1.55
	return 1.8

func _braxor_attack(f: Fighter, target: Fighter) -> void:
	# Block → shield bash (skill1) OR axe (attack2) alternating by skill_cd
	var use_shield := f.skill_cd <= 0.0
	if use_shield:
		f.skill_cd = 4.5
		_log("%s: удар щитом" % f.display_name)
		f.play_anim("block")
	else:
		_log("%s: удар топором" % f.display_name)
		f.play_anim("attack1")
	var tw := create_tween()
	tw.tween_interval(0.35 if use_shield else 0.28)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		f.face_towards(target.global_position)
		f.play_anim("attack1" if use_shield else "attack2")
		f.global_position.x = clampf(f.global_position.x + 18.0 * f.facing_sign(), 110.0, 970.0)
		if use_shield:
			_spawn_ring(f.global_position + Vector2(40 * f.facing_sign(), -40), Color(0.95, 0.8, 0.4, 0.85), 1.6)
	)
	tw.tween_interval(0.42)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		var dmg := f.attack_power * (1.2 if use_shield else 1.05)
		_resolve_hit(f, target, dmg, Color(1.0, 0.85, 0.35, 0.95), "shield" if use_shield else "axe")
		f.gain_energy(18.0)
	)
	tw.tween_interval(0.45)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _nixara_attack(f: Fighter, target: Fighter) -> void:
	_log("%s: теневой рывок" % f.display_name)
	f.play_anim("skill2")
	_spawn_trail(f, Color(0.75, 0.2, 0.85, 0.7))
	var contact := Vector2(target.global_position.x - f.facing_sign() * 58.0, lerpf(f.global_position.y, target.global_position.y, 0.55))
	contact.x = clampf(contact.x, 110.0, 970.0)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, 0.22)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.face_towards(target.global_position)
		f.play_anim("attack2")
		_spawn_slash(f.global_position + Vector2(30 * f.facing_sign(), -70), f.facing_sign(), Color(0.9, 0.3, 1.0, 0.9))
	)
	tw.tween_interval(0.22)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 0.65, Color(0.9, 0.3, 1.0, 0.9), "slash")
	)
	tw.tween_interval(0.16)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		f.play_anim("attack1")
		_spawn_slash(f.global_position + Vector2(26 * f.facing_sign(), -50), f.facing_sign(), Color(1.0, 0.4, 0.8, 0.95))
		_resolve_hit(f, target, f.attack_power * 0.8, Color(1.0, 0.4, 0.8, 0.95), "slash")
		f.gain_energy(16.0)
		# Flank slip — stay on ally side of target
		f.global_position.x = clampf(target.global_position.x - f.facing_sign() * 70.0, 110.0, 970.0)
		f.global_position.y = clampf(f.global_position.y + randf_range(-18, 18), 860.0, 1125.0)
	)
	tw.tween_interval(0.38)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _stonekin_attack(f: Fighter, target: Fighter) -> void:
	_log("%s: каменный удар" % f.display_name)
	f.face_towards(target.global_position)
	f.play_anim("attack1")
	var tw := create_tween()
	tw.tween_interval(0.55) # heavy windup
	tw.tween_callback(func():
		if not f.alive:
			return
		f.play_anim("attack2")
		_spawn_ring(f.global_position + Vector2(0, 36), Color(0.65, 0.55, 0.4, 0.85), 1.5)
		_spawn_dust(f.global_position + Vector2(20 * f.facing_sign(), 30))
	)
	tw.tween_interval(0.28)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 1.4, Color(0.8, 0.7, 0.45, 0.95), "slam")
		_spawn_ring(target.global_position + Vector2(0, 20), Color(0.7, 0.55, 0.35, 0.7), 2.0)
		if target.alive and not target.busy:
			target.play_anim("stagger")
		f.gain_energy(14.0)
	)
	tw.tween_interval(0.55)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _shadewolf_attack(f: Fighter, target: Fighter) -> void:
	_log("%s: прыжок-укус" % f.display_name)
	f.face_towards(target.global_position)
	f.play_anim("run")
	var leap := Vector2(target.global_position.x - f.facing_sign() * 48.0, target.global_position.y - 8.0)
	leap.x = clampf(leap.x, 110.0, 970.0)
	var tw := create_tween()
	tw.tween_property(f, "global_position", leap, 0.26)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.play_anim("attack2")
		_spawn_trail(f, Color(0.35, 0.1, 0.45, 0.8))
	)
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			f.busy = false
			return
		_resolve_hit(f, target, f.attack_power * 1.05, Color(0.6, 0.2, 0.7, 0.95), "bite")
		f.gain_energy(13.0)
	)
	tw.tween_interval(0.32)
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
	actor.face_towards(target.global_position)
	if actor.style == Fighter.Style.ASSASSIN:
		_nixara_ult(actor, target)
	elif actor.style == Fighter.Style.TANK:
		_braxor_ult(actor, target)
	else:
		_generic_ult(actor, target)

func _braxor_ult(f: Fighter, target: Fighter) -> void:
	_log("УЛЬТ Браксор: Хребет не сдаётся")
	f.face_towards(target.global_position)
	f.play_anim("ultimate")
	_spawn_ring(f.global_position, Color(1.0, 0.75, 0.3, 0.95), 2.4)
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_callback(func():
		if not f.alive:
			return
		f.play_anim("attack2")
		_spawn_ring(f.global_position + Vector2(30 * f.facing_sign(), -20), Color(1.0, 0.85, 0.4, 1.0), 2.8)
		_spawn_dust(f.global_position)
		for e in enemies:
			if e.alive and f.distance_to_fighter(e) < 260.0:
				_resolve_hit(f, e, f.attack_power * 1.7, Color(1.0, 0.8, 0.3, 1.0), "ult")
	)
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("victory" if ended else "idle")
	)

func _nixara_ult(f: Fighter, _target: Fighter) -> void:
	_log("УЛЬТ Никсара: Ночь без свидетелей")
	f.play_anim("ultimate")
	_spawn_trail(f, Color(0.6, 0.1, 0.9, 0.9))
	var marks: Array[Fighter] = []
	for e in enemies:
		if e.alive:
			marks.append(e)
	var tw := create_tween()
	for e in marks:
		tw.tween_callback(func():
			if not f.alive or not e.alive:
				return
			f.global_position = Vector2(e.global_position.x - 55.0, e.global_position.y)
			f.global_position.x = clampf(f.global_position.x, 110.0, 970.0)
			f.face_towards(e.global_position)
			f.play_anim("attack2")
			_spawn_trail(f, Color(0.8, 0.2, 1.0, 0.85))
			_spawn_slash(f.global_position + Vector2(30, -60), 1.0, Color(0.85, 0.25, 1.0, 1.0))
			_resolve_hit(f, e, f.attack_power * 1.45, Color(0.85, 0.25, 1.0, 1.0), "ult")
		)
		tw.tween_interval(0.38)
	tw.tween_callback(func():
		if f.alive:
			f.busy = false
			f.play_anim("idle")
	)

func _generic_ult(f: Fighter, target: Fighter) -> void:
	f.play_anim("ultimate")
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		if f.alive and target.alive:
			_resolve_hit(f, target, f.attack_power * 1.8, Color(1, 1, 1, 0.9), "ult")
	)
	tw.tween_interval(0.45)
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
	var knock := attacker.facing_sign()
	target.apply_damage(dmg, is_crit, knock)
	attacker.flash_vfx(vfx_color, 1.5)
	_spawn_hit_flash(target.global_position + Vector2(0, -80), vfx_color)
	_spawn_damage_number(target.global_position + Vector2(0, -130), int(dmg), is_crit)
	_log("%s → %s%s" % [attacker.display_name, target.display_name, " CRIT!" if is_crit else ""])

func _spawn_damage_number(pos: Vector2, value: int, is_crit: bool) -> void:
	var lbl := Label.new()
	lbl.text = str(value)
	lbl.global_position = pos + Vector2(randf_range(-20, 20), 0)
	lbl.z_as_relative = false
	lbl.z_index = 5000
	lbl.add_theme_font_size_override("font_size", 36 if is_crit else 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_crit else Color(1, 0.95, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15))
	lbl.add_theme_constant_override("outline_size", 4)
	floaters.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 70.0, 0.85)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85)
	tw.tween_callback(lbl.queue_free)

func _spawn_trail(f: Fighter, color: Color) -> void:
	if active_vfx >= MAX_VFX:
		return
	active_vfx += 1
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([Vector2(-22, -12), Vector2(24, -8), Vector2(18, 12), Vector2(-26, 10)])
	poly.global_position = f.global_position + Vector2(-10 * f.facing_sign(), -24)
	poly.z_as_relative = false
	poly.z_index = 3200
	floaters.add_child(poly)
	var tw := create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		poly.queue_free()
	)

func _spawn_slash(pos: Vector2, dir: float, color: Color) -> void:
	if active_vfx >= MAX_VFX:
		return
	active_vfx += 1
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(48 * dir, -28), Vector2(56 * dir, 0), Vector2(40 * dir, 22), Vector2(0, 6)
	])
	poly.global_position = pos
	poly.z_as_relative = false
	poly.z_index = 3300
	floaters.add_child(poly)
	var tw := create_tween()
	tw.tween_property(poly, "scale", Vector2(1.35, 1.15), 0.18)
	tw.parallel().tween_property(poly, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		poly.queue_free()
	)

func _spawn_hit_flash(pos: Vector2, color: Color) -> void:
	if active_vfx >= MAX_VFX:
		return
	active_vfx += 1
	var s := Sprite2D.new()
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(48):
		for x in range(48):
			var dx := x - 24.0
			var dy := y - 24.0
			if dx * dx + dy * dy <= 20.0 * 20.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	s.texture = ImageTexture.create_from_image(img)
	s.modulate = color
	s.global_position = pos
	s.z_as_relative = false
	s.z_index = 3400
	floaters.add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2(2.2, 2.2), 0.16)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		s.queue_free()
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
	s.z_as_relative = false
	s.z_index = 3100
	floaters.add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2(scale_to, scale_to), 0.42)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.42)
	tw.tween_callback(func():
		active_vfx = max(0, active_vfx - 1)
		s.queue_free()
	)

func _spawn_dust(pos: Vector2) -> void:
	if active_vfx >= MAX_VFX:
		return
	for i in range(5):
		if active_vfx >= MAX_VFX:
			break
		active_vfx += 1
		var p := Polygon2D.new()
		p.color = Color(0.55, 0.45, 0.32, 0.85)
		var s := randf_range(4.0, 9.0)
		p.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s * 0.5), Vector2(s * 0.6, s), Vector2(-s * 0.7, s * 0.5)])
		p.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-5, 10))
		p.z_as_relative = false
		p.z_index = 3000
		floaters.add_child(p)
		var tw := create_tween()
		tw.tween_property(p, "global_position", p.global_position + Vector2(randf_range(-30, 30), randf_range(-40, -10)), 0.45)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.45)
		tw.tween_callback(func():
			active_vfx = max(0, active_vfx - 1)
			p.queue_free()
		)

func _demo_scripted_skills() -> void:
	# Showcase at readable x1 pace
	if demo_phase == 0 and demo_timer > 2.0 and braxor.alive and stonekin.alive and not braxor.busy:
		demo_phase = 1
		_braxor_attack(braxor, stonekin)
	elif demo_phase == 1 and demo_timer > 5.5 and nixara.alive and not nixara.busy:
		demo_phase = 2
		_nixara_attack(nixara, shadewolf if shadewolf.alive else stonekin)
	elif demo_phase == 2 and demo_timer > 9.0 and stonekin.alive and not stonekin.busy:
		demo_phase = 3
		_stonekin_attack(stonekin, braxor if braxor.alive else nixara)
	elif demo_phase == 3 and demo_timer > 12.5 and shadewolf.alive and not shadewolf.busy:
		demo_phase = 4
		_shadewolf_attack(shadewolf, nixara if nixara.alive else braxor)
	elif demo_phase == 4 and demo_timer > 17.0 and braxor.alive:
		demo_phase = 5
		braxor.energy = braxor.max_energy
		_perform_ultimate(braxor)
	elif demo_phase == 5 and demo_timer > 21.0 and nixara.alive:
		demo_phase = 6
		nixara.energy = nixara.max_energy
		_perform_ultimate(nixara)

func _try_auto_ults() -> void:
	if demo_phase < 6:
		return
	for f in players:
		if f.can_ult() and randf() < 0.12:
			_perform_ultimate(f)
			return

func _on_ult_pressed(fighter_id: String) -> void:
	for f in players:
		if f.fighter_id == fighter_id:
			_perform_ultimate(f)
			return

func _on_speed_changed(mult: float) -> void:
	battle_speed = mult
	Engine.time_scale = mult
	speed_label.text = "x%s" % str(mult).trim_suffix(".0")
	# Tweens inherit Engine.time_scale automatically

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
	var path := OS.get_environment("BASH_SCREENSHOT_PATH")
	if path == "":
		path = "user://battle_shot.png"
	img.save_png(path)
