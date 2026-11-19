extends Control

@onready var title: Label = $Margin/VBox/Title
@onready var region: Label = $Margin/VBox/Region
@onready var map_area: Control = $Margin/VBox/MapFrame/MapArea
@onready var detail_name: Label = $Margin/VBox/Detail/Name
@onready var detail_blurb: Label = $Margin/VBox/Detail/Blurb
@onready var detail_enemies: Label = $Margin/VBox/Detail/Enemies
@onready var detail_dialogue: Label = $Margin/VBox/Detail/Dialogue
@onready var economy: Label = $Margin/VBox/Economy
@onready var btn_fight: Button = $Margin/VBox/Nav/BtnFight
@onready var btn_claim: Button = $Margin/VBox/Nav/BtnClaim
@onready var btn_back: Button = $Margin/VBox/Nav/BtnBack
@onready var btn_squad: Button = $Margin/VBox/Nav/BtnSquad

var _selected: String = "ufa_gate"

func _ready() -> void:
	btn_back.pressed.connect(func(): GameState.go_menu())
	btn_squad.pressed.connect(func(): GameState.go_squad())
	btn_fight.pressed.connect(_on_fight)
	btn_claim.pressed.connect(_on_claim)
	GameState.campaign_changed.connect(_rebuild)
	GameState.economy_changed.connect(_refresh_economy)
	var camp := GameState.get_campaign()
	title.text = str(camp.get("title_ru", "Кампания"))
	region.text = str(camp.get("region_ru", ""))
	if not GameState.unlocked_nodes.is_empty():
		_selected = GameState.unlocked_nodes[GameState.unlocked_nodes.size() - 1]
	_rebuild()

func _rebuild() -> void:
	for c in map_area.get_children():
		c.queue_free()
	await get_tree().process_frame
	_draw_paths()
	for node in GameState.get_nodes():
		map_area.add_child(_make_node_btn(node))
	_show(_selected)
	_refresh_economy()

func _draw_paths() -> void:
	var by_id: Dictionary = {}
	for node in GameState.get_nodes():
		by_id[str(node.get("id", ""))] = node
	for node in GameState.get_nodes():
		var from_id := str(node.get("id", ""))
		var from_pos: Array = node.get("map_pos", [0, 0])
		var a := Vector2(float(from_pos[0]), float(from_pos[1]) - 560.0)
		for u in node.get("unlocks", []):
			var uid := str(u)
			if uid == "chapter_clear" or not by_id.has(uid):
				continue
			var to_pos: Array = by_id[uid].get("map_pos", [0, 0])
			var b := Vector2(float(to_pos[0]), float(to_pos[1]) - 560.0)
			var line := Line2D.new()
			line.width = 4.0
			line.default_color = Color(0.75, 0.62, 0.35, 0.9) if GameState.is_node_cleared(from_id) else Color(0.35, 0.45, 0.5, 0.75)
			line.z_index = 1
			line.add_point(a)
			line.add_point(b)
			map_area.add_child(line)

func _make_node_btn(node: Dictionary) -> Button:
	var id := str(node.get("id", ""))
	var pos: Array = node.get("map_pos", [200, 900])
	var btn := Button.new()
	btn.position = Vector2(float(pos[0]) - 70.0, float(pos[1]) - 560.0)
	btn.custom_minimum_size = Vector2(150, 64)
	btn.z_index = 2
	var cleared := GameState.is_node_cleared(id)
	var unlocked := GameState.is_node_unlocked(id)
	if not unlocked:
		btn.disabled = true
		btn.text = "🔒"
		btn.modulate = Color(0.5, 0.55, 0.6, 0.85)
	elif cleared:
		btn.text = "✓"
		btn.modulate = Color(0.75, 0.9, 0.7, 1)
	else:
		btn.text = "●"
		btn.modulate = Color(1, 0.92, 0.7, 1)
	if bool(node.get("is_boss", false)):
		btn.text = (btn.text + " БОСС").strip_edges()
	btn.tooltip_text = str(node.get("name_ru", id))
	btn.pressed.connect(func(): _show(id))
	return btn

func _show(node_id: String) -> void:
	_selected = node_id
	var node := GameState.get_campaign_node(node_id)
	if node.is_empty():
		return
	detail_name.text = str(node.get("name_ru", node_id))
	detail_blurb.text = str(node.get("blurb", ""))
	var enemies: PackedStringArray = PackedStringArray()
	for eid in node.get("enemy_ids", []):
		var data := CharacterRegistry.get_character(str(eid))
		enemies.append(data.display_name if data else str(eid))
	detail_enemies.text = "Враги: " + ", ".join(enemies)
	var quoted: PackedStringArray = PackedStringArray()
	for line in node.get("dialogue", []):
		quoted.append("«%s»" % str(line))
	detail_dialogue.text = "\n".join(quoted)
	var unlocked := GameState.is_node_unlocked(node_id)
	btn_fight.disabled = not unlocked or not GameState.can_start_battle()
	btn_fight.text = "В бой" if not GameState.is_node_cleared(node_id) else "Повторить"

func _refresh_economy() -> void:
	economy.text = "Золото: %d · AFK: %.0f/ч (накоплено %d, ≤%.0fч)" % [
		GameState.gold,
		GameState.afk_gold_per_hour(),
		GameState.afk_pending_gold(),
		GameState.AFK_CAP_HOURS,
	]
	btn_claim.disabled = GameState.afk_pending_gold() <= 0

func _on_fight() -> void:
	GameState.start_node_battle(_selected)

func _on_claim() -> void:
	var g := GameState.claim_afk()
	economy.text = "Получено %d золота. %s" % [g, economy.text]
	_refresh_economy()
