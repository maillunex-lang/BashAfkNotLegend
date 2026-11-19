extends Control

@onready var grid: GridContainer = $Margin/VBox/Scroll/Grid
@onready var slots_row: HBoxContainer = $Margin/VBox/SlotsRow
@onready var hint: Label = $Margin/VBox/Hint
@onready var btn_back: Button = $Margin/VBox/Nav/BtnBack
@onready var btn_battle: Button = $Margin/VBox/Nav/BtnBattle

var _selected_slot: int = 0

func _ready() -> void:
	btn_back.pressed.connect(func(): GameState.go_menu())
	btn_battle.pressed.connect(func(): GameState.start_battle())
	GameState.squad_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in slots_row.get_children():
		c.queue_free()
	for c in grid.get_children():
		c.queue_free()
	await get_tree().process_frame

	var squad := GameState.get_player_squad()
	for i in range(GameState.MAX_SQUAD):
		var id := squad[i] if i < squad.size() else ""
		slots_row.add_child(_make_slot_chip(i, id))

	for hero_id in GameState.list_heroes():
		grid.add_child(_make_hero_card(hero_id))

	hint.text = "Слот %d · тап по герою, чтобы поставить · front 0–1, back 2–4" % (_selected_slot + 1)
	btn_battle.disabled = not GameState.can_start_battle()

func _make_slot_chip(index: int, hero_id: String) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 210)
	btn.toggle_mode = true
	btn.button_pressed = index == _selected_slot
	var label := "Front %d" % (index + 1) if index < 2 else "Back %d" % (index - 1)
	if hero_id == "":
		btn.text = "%s\n—" % label
	else:
		var data := CharacterRegistry.get_character(hero_id)
		btn.text = "%s\n%s" % [label, data.display_name if data else hero_id]
	btn.pressed.connect(func():
		_selected_slot = index
		_rebuild()
	)
	if hero_id != "" and ResourceLoader.exists("res://assets/ui/portraits/%s.jpg" % hero_id):
		# Keep text; portrait is in collection. Chip stays compact.
		pass
	return btn

func _make_hero_card(hero_id: String) -> Control:
	var data := CharacterRegistry.get_character(hero_id)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(190, 260)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(190, 190)
	btn.clip_text = true
	var tex_path := "res://assets/ui/portraits/%s.jpg" % hero_id
	if ResourceLoader.exists(tex_path):
		var tr := TextureRect.new()
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture = load(tex_path)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tr)
	btn.pressed.connect(func():
		GameState.set_squad_slot(_selected_slot, hero_id)
		_selected_slot = mini(_selected_slot + 1, GameState.MAX_SQUAD - 1)
	)
	root.add_child(btn)

	var name_l := Label.new()
	name_l.text = data.display_name if data else hero_id
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 16)
	root.add_child(name_l)

	var meta := Label.new()
	if data:
		meta.text = "%s · %s" % [GameState.class_label(data.class_id), GameState.faction_label(data.faction_id)]
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.7, 0.78, 0.8))
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(meta)
	return root
