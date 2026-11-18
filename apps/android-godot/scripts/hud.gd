extends CanvasLayer

signal ult_pressed(fighter_id: String)
signal speed_changed(mult: float)
signal auto_toggled(enabled: bool)

@onready var slot_box: HBoxContainer = $BottomBar/Margin/Slots
@onready var btn_x1: Button = $TopBar/Margin/VBox/SpeedRow/BtnX1
@onready var btn_x2: Button = $TopBar/Margin/VBox/SpeedRow/BtnX2
@onready var btn_x3: Button = $TopBar/Margin/VBox/SpeedRow/BtnX3
@onready var btn_auto: Button = $TopBar/Margin/VBox/SpeedRow/BtnAuto
@onready var btn_pause: Button = $TopBar/Margin/VBox/Row1/BtnPause
@onready var speed_label: Label = $TopBar/Margin/VBox/SpeedRow/SpeedLabel
@onready var auto_label: Label = $TopBar/Margin/VBox/SpeedRow/AutoLabel

var _paused: bool = false
var _slots: Dictionary = {}
var _auto_on: bool = true

func _ready() -> void:
	btn_x1.pressed.connect(func(): _set_speed(1.0))
	btn_x2.pressed.connect(func(): _set_speed(2.0))
	btn_x3.pressed.connect(func(): _set_speed(3.0))
	btn_auto.pressed.connect(_toggle_auto)
	btn_pause.pressed.connect(_toggle_pause)
	_set_speed(1.0)

func setup(players: Array) -> void:
	for child in slot_box.get_children():
		child.queue_free()
	_slots.clear()
	await get_tree().process_frame
	# Always show 5 hero slots (prototype fills first N; rest are empty placeholders)
	for f in players:
		slot_box.add_child(_make_slot(f))
	for _i in range(maxi(0, 5 - players.size())):
		slot_box.add_child(_make_empty_slot())

func _make_empty_slot() -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(150, 250)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	var box := ColorRect.new()
	box.custom_minimum_size = Vector2(120, 120)
	box.color = Color(0.12, 0.18, 0.24, 0.85)
	root.add_child(box)
	var lbl := Label.new()
	lbl.text = "—"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	root.add_child(lbl)
	return root

func _make_slot(f: Fighter) -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(160, 250)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.alignment = BoxContainer.ALIGNMENT_CENTER

	var portrait_host := Control.new()
	portrait_host.custom_minimum_size = Vector2(140, 140)
	portrait_host.clip_contents = true

	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.clip_text = true
	btn.pressed.connect(func():
		set_ready(f.fighter_id, false)
		ult_pressed.emit(f.fighter_id)
	)
	portrait_host.add_child(btn)

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_path := "res://assets/ui/portraits/%s.jpg" % f.fighter_id
	if ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	portrait_host.add_child(tex_rect)
	root.add_child(portrait_host)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(170, 20)
	bar.max_value = f.max_energy
	bar.value = f.energy
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.49, 0.83, 0.8, 1)
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	root.add_child(bar)

	var ready := Label.new()
	ready.text = "%d%%" % int(100.0 * f.energy / max(f.max_energy, 1.0))
	ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready.add_theme_color_override("font_color", Color("F3C36A"))
	ready.add_theme_font_size_override("font_size", 18)
	root.add_child(ready)

	var name_l := Label.new()
	name_l.text = f.display_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 20)
	root.add_child(name_l)

	_slots[f.fighter_id] = {"bar": bar, "ready": ready}
	return root

func update_energy(fighter_id: String, value: float, max_value: float) -> void:
	if not _slots.has(fighter_id):
		return
	var bar: ProgressBar = _slots[fighter_id]["bar"]
	bar.max_value = max_value
	bar.value = value
	if value >= max_value:
		_slots[fighter_id]["ready"].text = "READY"
	else:
		_slots[fighter_id]["ready"].text = "%d%%" % int(100.0 * value / max(max_value, 1.0))

func set_ready(fighter_id: String, is_ready: bool) -> void:
	if not _slots.has(fighter_id):
		return
	if is_ready:
		_slots[fighter_id]["ready"].text = "READY"
	else:
		var bar: ProgressBar = _slots[fighter_id]["bar"]
		_slots[fighter_id]["ready"].text = "%d%%" % int(100.0 * bar.value / max(bar.max_value, 1.0))

func _set_speed(mult: float) -> void:
	speed_label.text = "x%s" % str(mult).trim_suffix(".0")
	speed_changed.emit(mult)

func _toggle_auto() -> void:
	_auto_on = not _auto_on
	btn_auto.text = "Auto: ON" if _auto_on else "Auto: OFF"
	auto_label.text = "AUTO: ON" if _auto_on else "AUTO: OFF"
	auto_toggled.emit(_auto_on)

func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	btn_pause.text = "▶" if _paused else "❚❚"
