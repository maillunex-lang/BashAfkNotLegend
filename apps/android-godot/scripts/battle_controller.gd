extends Node2D

## BATTLE-POLISH-002 + VISUAL-APPROVAL-001:
## CharacterRegistry supplies CharacterData + CharacterVisualDef.
## Facing follows target/side; source_facing from visual package.

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

# Turn-based: one actor strikes then returns home
var _slots: Dictionary = {}
var turn_queue: Array[Fighter] = []
var turn_index: int = 0
var turn_lock: bool = false
var between_turn_cd: float = 0.0

func _ready() -> void:
	wall_start_ms = Time.get_ticks_msec()
	Engine.time_scale = 1.0
	Engine.max_fps = 30
	players = [braxor, nixara]
	enemies = [stonekin, shadewolf]
	all_fighters = players + enemies
	fighters_root.y_sort_enabled = true
	_configure_fighters()
	for f in all_fighters:
		f.died.connect(_on_fighter_died)
		f.energy_changed.connect(_on_energy_changed)
		f.ult_ready.connect(_on_ult_ready)
		f.remember_home()
	_rebuild_turn_queue()
	hud.setup(players)
	hud.ult_pressed.connect(_on_ult_pressed)
	hud.speed_changed.connect(_on_speed_changed)
	hud.auto_toggled.connect(_on_auto_toggled)
	wave_label.text = "WAVE 1/1"
	_log("Очередь: удар → назад. FPS 30. Лицом →")
	_print_facing_diagnostics()
	var tw := create_tween().set_loops()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", -14.0, 9.0).as_relative()
	tw.tween_property($ParallaxRoot/Mountains, "position:x", 14.0, 9.0).as_relative()

func _rebuild_turn_queue() -> void:
	turn_queue.clear()
	# Speed order: assassin/beast first, then tank/brute; alternate sides
	var order: Array[Fighter] = [nixara, shadewolf, braxor, stonekin]
	for f in order:
		if f != null and f.alive:
			turn_queue.append(f)
	turn_index = 0

func _print_facing_diagnostics() -> void:
	for f in all_fighters:
		print("[FACING] ", f.debug_facing_report())

func _configure_fighters() -> void:
	# Logic + visuals from CharacterRegistry (swap PNGs without rewriting combat).
	braxor.apply_character_data(CharacterRegistry.get_character("braxor"))
	nixara.apply_character_data(CharacterRegistry.get_character("nixara"))
	stonekin.apply_character_data(CharacterRegistry.get_character("stonekin"))
	shadewolf.apply_character_data(CharacterRegistry.get_character("shadewolf"))

	# 5v5-ready formation (2 front + 3 back). 2v2 occupies front0 + back0.
	# BASH_SWAP_SIDES=1 → PvP mirror: heroes on RIGHT face LEFT.
	var swap := OS.get_environment("BASH_SWAP_SIDES") == "1"
	var heroes_left := not swap
	BattleFormation.apply_to_fighter(braxor, heroes_left, 0) # front
	BattleFormation.apply_to_fighter(nixara, heroes_left, 2) # back
	BattleFormation.apply_to_fighter(stonekin, not heroes_left, 0)
	BattleFormation.apply_to_fighter(shadewolf, not heroes_left, 2)
	if swap:
		_log("PvP SWAP: герои справа → лицом влево (formation)")

	# Rebuild frames if sprites already ready (apply after scene export defaults).
	for f in [braxor, nixara, stonekin, shadewolf]:
		if f.sprite != null and f.sprite.sprite_frames != null:
			f._build_frames()
			f.hp = f.max_hp
			f._update_bars()
			f.name_label.text = f.display_name
			f._apply_facing()
			f.play_anim("idle")

func _process(delta: float) -> void:
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
		return

	for f in all_fighters:
		if f.alive:
			f.gain_energy(2.4 * d)
			f.skill_cd = max(0.0, f.skill_cd - d)
			# Idle at home facing target side
			if not f.busy and not turn_lock:
				f.global_position = f.global_position.lerp(f.home_pos, clampf(4.0 * d, 0.0, 1.0))
				if f.current_target != null and f.current_target.alive:
					f.face_towards(f.current_target.global_position)
				else:
					f.lock_team_facing()
				if f.sprite.animation not in ["idle", "victory"]:
					f.play_anim("idle")

	_update_targets()
	_demo_scripted_skills()

	if between_turn_cd > 0.0:
		between_turn_cd = max(0.0, between_turn_cd - d)
	elif not turn_lock:
		_try_next_turn()

	_check_end()
	var quit_after := float(OS.get_environment("BASH_DEMO_SECONDS"))
	if quit_after <= 0.0:
		quit_after = 40.0
	if OS.get_environment("BASH_DEMO_QUIT") == "1" and wall_s >= quit_after:
		get_tree().quit()

func _try_next_turn() -> void:
	if turn_queue.is_empty():
		_rebuild_turn_queue()
	if turn_queue.is_empty():
		return
	# Find next living actor
	for _i in range(turn_queue.size()):
		if turn_index >= turn_queue.size():
			turn_index = 0
		var actor: Fighter = turn_queue[turn_index]
		turn_index = (turn_index + 1) % max(turn_queue.size(), 1)
		if actor == null or not actor.alive or actor.busy:
			continue
		var target := actor.current_target
		if target == null or not target.alive:
			target = _nearest_living(actor, enemies if actor.team == "player" else players)
			actor.current_target = target
		if target == null:
			continue
		turn_lock = true
		# Ult if ready and auto
		if auto_mode and actor.can_ult() and actor.team == "player" and randf() < 0.45:
			_perform_ultimate(actor)
		else:
			_start_attack(actor, target)
		return

func _end_turn(actor: Fighter) -> void:
	if actor != null and actor.alive:
		actor.busy = false
		actor.play_anim("idle")
		actor.lock_team_facing()
	turn_lock = false
	between_turn_cd = 0.35
	_rebuild_turn_queue()

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

func _contact_pos(f: Fighter, target: Fighter, gap: float = 70.0) -> Vector2:
	var p := Vector2(target.global_position.x - f.facing_sign() * gap, lerpf(f.home_pos.y, target.global_position.y, 0.35))
	p.x = clampf(p.x, 120.0, 960.0)
	p.y = clampf(p.y, 880.0, 1120.0)
	return p

func _return_home(f: Fighter, tw: Tween, after: float = 0.28) -> void:
	tw.tween_interval(0.12)
	tw.tween_callback(func():
		if f.alive:
			f.play_anim("walk")
	)
	tw.tween_property(f, "global_position", f.home_pos, after)
	tw.tween_callback(func():
		_end_turn(f)
	)

func _pick_basic_ability_id(f: Fighter) -> String:
	if f.character_data == null:
		return "basic"
	# Prefer skill when off cooldown for kits that define a skill1/skill2.
	if f.skill_cd <= 0.0 and f.character_data.skill1_id != "" and f.character_data.skill1_id != "skill1":
		return f.character_data.skill1_id
	return f.character_data.basic_attack_id if f.character_data.basic_attack_id != "" else "basic"

func _start_attack(f: Fighter, target: Fighter) -> void:
	f.busy = true
	f.face_towards(target.global_position)
	var ability := AbilityCatalog.get_ability(_pick_basic_ability_id(f))
	_execute_ability(f, target, ability)

func _execute_ability(f: Fighter, target: Fighter, ability: AbilityDef) -> void:
	_log("%s: %s" % [f.display_name, ability.display_name])
	if ability.skill_cooldown > 0.0:
		f.skill_cd = ability.skill_cooldown
	match ability.kit:
		AbilityDef.Kit.SHIELD_BASH:
			_kit_shield_bash(f, target, ability)
		AbilityDef.Kit.DASH_COMBO:
			_kit_dash_combo(f, target, ability)
		AbilityDef.Kit.LEAP_BITE:
			_kit_leap_bite(f, target, ability)
		AbilityDef.Kit.ULT_AOE_STOMP:
			_kit_ult_aoe(f, target, ability)
		AbilityDef.Kit.ULT_MULTI_MARK:
			_kit_ult_marks(f, ability)
		AbilityDef.Kit.GENERIC_BURST:
			_kit_generic_burst(f, target, ability)
		_:
			_kit_melee_step(f, target, ability)

func _attach_world(f: Fighter, kind: String) -> Vector2:
	return f.global_position + f.attach_point(kind)

func _hit_anchor(target: Fighter) -> Vector2:
	return target.global_position + target.attach_point("hit")

func _kit_melee_step(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	f.play_anim(a.anim_windup)
	var contact := _contact_pos(f, target, a.contact_gap)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, a.approach_time)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.face_towards(target.global_position)
		f.play_anim(a.anim_strike)
	)
	tw.tween_interval(0.28)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.play_anim(a.anim_follow)
		if a.vfx_kind == "slam":
			_spawn_dust(_attach_world(f, "weapon") + Vector2(0, 40))
			_spawn_ring(target.global_position + Vector2(0, 20), a.vfx_color, 2.0)
		else:
			_spawn_ring(_attach_world(f, "weapon"), a.vfx_color, 1.5)
		_resolve_hit(f, target, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
		f.gain_energy(a.energy_gain)
	)
	_return_home(f, tw, a.return_time)

func _kit_shield_bash(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	f.play_anim(a.anim_windup)
	var contact := _contact_pos(f, target, a.contact_gap)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, a.approach_time)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.face_towards(target.global_position)
		f.play_anim(a.anim_strike)
	)
	tw.tween_interval(0.28)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.play_anim(a.anim_follow)
		_spawn_ring(_attach_world(f, "shield"), a.vfx_color, 1.5)
		_resolve_hit(f, target, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
		f.gain_energy(a.energy_gain)
	)
	_return_home(f, tw, a.return_time)

func _kit_dash_combo(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	f.play_anim(a.anim_windup)
	var contact := _contact_pos(f, target, a.contact_gap)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, a.approach_time)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.face_towards(target.global_position)
		f.play_anim(a.anim_strike)
		_spawn_slash(_attach_world(f, "weapon"), f.facing_sign(), a.vfx_color)
		_resolve_hit(f, target, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
	)
	tw.tween_interval(0.18)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.play_anim(a.anim_follow)
		var c2 := a.vfx_color.lightened(0.15)
		_spawn_slash(_attach_world(f, "weapon") + Vector2(0, 20), f.facing_sign(), c2)
		var mult_b := a.power_mult_b if a.power_mult_b > 0.0 else a.power_mult
		_resolve_hit(f, target, f.attack_power * mult_b, c2, a.vfx_kind)
		f.gain_energy(a.energy_gain)
	)
	_return_home(f, tw, a.return_time)

func _kit_leap_bite(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	f.play_anim(a.anim_windup)
	var contact := _contact_pos(f, target, a.contact_gap)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, a.approach_time)
	tw.tween_callback(func():
		if not f.alive or not target.alive:
			_end_turn(f)
			return
		f.face_towards(target.global_position)
		f.play_anim(a.anim_strike)
		_spawn_hit_flash(_hit_anchor(target), a.vfx_color)
		_resolve_hit(f, target, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
		f.gain_energy(a.energy_gain)
	)
	_return_home(f, tw, a.return_time)

func _perform_ultimate(actor: Fighter) -> void:
	if not actor.can_ult():
		_end_turn(actor)
		return
	var target := actor.current_target
	if target == null or not target.alive:
		target = _nearest_living(actor, enemies if actor.team == "player" else players)
	if target == null:
		_end_turn(actor)
		return
	actor.energy = 0.0
	actor._update_bars()
	actor.busy = true
	turn_lock = true
	actor.face_towards(target.global_position)
	var ult_id := "basic"
	if actor.character_data != null and actor.character_data.ultimate_id != "":
		ult_id = actor.character_data.ultimate_id
	_execute_ability(actor, target, AbilityCatalog.get_ability(ult_id))

func _kit_ult_aoe(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	_log("УЛЬТ %s: %s" % [f.display_name, a.display_name])
	f.play_anim(a.anim_windup)
	var contact := _contact_pos(f, target, a.contact_gap)
	var tw := create_tween()
	tw.tween_property(f, "global_position", contact, a.approach_time)
	tw.tween_callback(func():
		if not f.alive:
			_end_turn(f)
			return
		f.face_towards(target.global_position)
		f.play_anim(a.anim_strike)
		_spawn_ring(_attach_world(f, "vfx"), a.vfx_color, 2.4)
	)
	tw.tween_interval(0.45)
	tw.tween_callback(func():
		if not f.alive:
			_end_turn(f)
			return
		f.play_anim(a.anim_follow)
		_spawn_ring(_attach_world(f, "weapon"), a.vfx_color, 2.6)
		_spawn_dust(f.global_position)
		var foes: Array[Fighter] = enemies if f.team == "player" else players
		for e in foes:
			if e.alive and f.distance_to_fighter(e) < 280.0:
				_resolve_hit(f, e, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
	)
	_return_home(f, tw, a.return_time)

func _kit_ult_marks(f: Fighter, a: AbilityDef) -> void:
	_log("УЛЬТ %s: %s" % [f.display_name, a.display_name])
	var foes: Array[Fighter] = enemies if f.team == "player" else players
	var marks: Array[Fighter] = []
	for e in foes:
		if e.alive:
			marks.append(e)
	var tw := create_tween()
	f.play_anim(a.anim_windup)
	for e in marks:
		tw.tween_callback(func():
			if not f.alive or not e.alive:
				return
			# Face target first, then stand on the approach side (PvP-safe).
			f.face_towards(e.global_position)
			f.global_position = Vector2(e.global_position.x - f.facing_sign() * a.contact_gap, e.home_pos.y)
			f.global_position.x = clampf(f.global_position.x, 120.0, 960.0)
			f.face_towards(e.global_position)
			f.play_anim(a.anim_strike)
			_spawn_slash(_attach_world(f, "weapon"), f.facing_sign(), a.vfx_color)
			_resolve_hit(f, e, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
		)
		tw.tween_interval(0.32)
	_return_home(f, tw, a.return_time)

func _kit_generic_burst(f: Fighter, target: Fighter, a: AbilityDef) -> void:
	f.play_anim(a.anim_strike if a.anim_strike != "" else "ultimate")
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		if f.alive and target.alive:
			_resolve_hit(f, target, f.attack_power * a.power_mult, a.vfx_color, a.vfx_kind)
	)
	_return_home(f, tw, a.return_time)

func _resolve_hit(attacker: Fighter, target: Fighter, amount: float, vfx_color: Color, _kind: String) -> void:
	if not attacker.alive or not target.alive:
		return
	var is_crit := randf() < 0.18
	var dmg := amount * (1.45 if is_crit else 1.0) * randf_range(0.92, 1.08)
	var knock := attacker.facing_sign()
	target.apply_damage(dmg, is_crit, knock)
	attacker.flash_vfx(vfx_color, 1.5)
	# Hit VFX + damage numbers use world anchors; UI numbers never inherit body flip.
	_spawn_hit_flash(_hit_anchor(target), vfx_color)
	_spawn_damage_number(target.global_position + Vector2(0, -130), int(dmg), is_crit)
	_log("%s → %s%s" % [attacker.display_name, target.display_name, " CRIT!" if is_crit else ""])

func _spawn_damage_number(pos: Vector2, value: int, is_crit: bool) -> void:
	var lbl := Label.new()
	lbl.text = str(value)
	lbl.global_position = pos + Vector2(randf_range(-20, 20), 0)
	lbl.z_as_relative = false
	lbl.z_index = 100 # floaters above sprites; keep ≤ CANVAS_ITEM_Z_MAX (4096)
	lbl.add_theme_font_size_override("font_size", 36 if is_crit else 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_crit else Color(1, 0.95, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15))
	lbl.add_theme_constant_override("outline_size", 4)
	floaters.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 70.0, 0.85)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85)
	tw.tween_callback(lbl.queue_free)

func _spawn_trail(_f: Fighter, _color: Color) -> void:
	# Disabled: character-shaped afterimages looked like a ghost trail.
	return

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
	poly.z_index = 80
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
	s.z_index = 90
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
	s.z_index = 70
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
		p.z_index = 60
		floaters.add_child(p)
		var tw := create_tween()
		tw.tween_property(p, "global_position", p.global_position + Vector2(randf_range(-30, 30), randf_range(-40, -10)), 0.45)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.45)
		tw.tween_callback(func():
			active_vfx = max(0, active_vfx - 1)
			p.queue_free()
		)

func _demo_scripted_skills() -> void:
	# Force ult showcase once mid-fight without breaking turn lock
	if demo_phase == 0 and demo_timer > 14.0 and braxor.alive and not turn_lock:
		demo_phase = 1
		braxor.energy = braxor.max_energy
	elif demo_phase == 1 and demo_timer > 22.0 and nixara.alive and not turn_lock:
		demo_phase = 2
		nixara.energy = nixara.max_energy

func _on_ult_pressed(fighter_id: String) -> void:
	if turn_lock:
		return
	for f in players:
		if f.fighter_id == fighter_id and f.can_ult():
			turn_lock = true
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
