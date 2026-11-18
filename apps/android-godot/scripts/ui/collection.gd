extends Control

@onready var list: VBoxContainer = $Margin/VBox/Scroll/List
@onready var detail_name: Label = $Margin/VBox/Detail/Name
@onready var detail_meta: Label = $Margin/VBox/Detail/Meta
@onready var detail_stats: Label = $Margin/VBox/Detail/Stats
@onready var portrait: TextureRect = $Margin/VBox/Detail/Portrait
@onready var btn_back: Button = $Margin/VBox/Nav/BtnBack
@onready var btn_add: Button = $Margin/VBox/Nav/BtnAdd

var _selected: String = "braxor"

func _ready() -> void:
	btn_back.pressed.connect(func(): GameState.go_menu())
	btn_add.pressed.connect(_add_to_squad)
	_rebuild_list()
	_show(_selected)

func _rebuild_list() -> void:
	for c in list.get_children():
		c.queue_free()
	await get_tree().process_frame
	var by_faction: Dictionary = {}
	for hero_id in GameState.list_heroes():
		var data := CharacterRegistry.get_character(hero_id)
		if data == null:
			continue
		if not by_faction.has(data.faction_id):
			by_faction[data.faction_id] = []
		by_faction[data.faction_id].append(data)
	for faction_id in by_faction.keys():
		var header := Label.new()
		header.text = GameState.faction_label(faction_id)
		header.add_theme_font_size_override("font_size", 24)
		header.add_theme_color_override("font_color", Color(0.9, 0.78, 0.45))
		list.add_child(header)
		for data in by_faction[faction_id]:
			var btn := Button.new()
			btn.text = "%s · %s" % [data.display_name, GameState.class_label(data.class_id)]
			btn.custom_minimum_size = Vector2(0, 52)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var id: String = data.character_id
			btn.pressed.connect(func(): _show(id))
			list.add_child(btn)

func _show(hero_id: String) -> void:
	_selected = hero_id
	var data := CharacterRegistry.get_character(hero_id)
	if data == null:
		return
	detail_name.text = data.display_name
	detail_meta.text = "%s · %s" % [GameState.class_label(data.class_id), GameState.faction_label(data.faction_id)]
	detail_stats.text = "HP %d · ATK %d · RNG %d · SPD %d\n%s / %s / %s" % [
		int(data.max_hp), int(data.attack_power), int(data.preferred_range), int(data.move_speed),
		data.basic_attack_id, data.skill1_id, data.ultimate_id,
	]
	var path := "res://assets/ui/portraits/%s.jpg" % hero_id
	if ResourceLoader.exists(path):
		portrait.texture = load(path)
	else:
		portrait.texture = null

func _add_to_squad() -> void:
	var squad := GameState.get_player_squad()
	var slot := mini(squad.size(), GameState.MAX_SQUAD - 1)
	GameState.set_squad_slot(slot, _selected)
	btn_add.text = "В отряде ✓"
