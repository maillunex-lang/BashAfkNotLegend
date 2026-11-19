extends Node

## Offline client state for the playable prototype (no authoritative server yet).
## Squad + campaign chapter 1 + mock AFK. Combat reads squads from here.

signal squad_changed
signal campaign_changed
signal economy_changed

const MAX_SQUAD := 5
const BATTLE_SCENE := "res://scenes/battle/BattlePrototype.tscn"
const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const SQUAD_SCENE := "res://scenes/ui/SquadSelect.tscn"
const COLLECTION_SCENE := "res://scenes/ui/Collection.tscn"
const MAP_SCENE := "res://scenes/ui/WorldMap.tscn"
const SAVE_PATH := "user://bash_save_v1.json"
const CAMPAIGN_PATH := "res://content/campaign_chapter01.json"
const BASE_AFK_GOLD_PER_HOUR := 12.0
const AFK_CAP_HOURS := 24.0

## Default starter squad (V1 + MASS) — CHARACTER_BIBLE IDs only.
var player_squad: Array[String] = ["braxor", "nixara", "velkor", "mossar", "aurix"]
var enemy_squad: Array[String] = ["grimzor", "draxel", "morvex", "obsidrak", "scaria"]

var last_battle_won: bool = false
var battles_fought: int = 0
var battle_mode: String = "skirmish" # skirmish | campaign
var active_node_id: String = ""

var gold: int = 0
var afk_rate_bonus: int = 0
var afk_last_claim_unix: int = 0
var cleared_nodes: Array[String] = []
var unlocked_nodes: Array[String] = ["ufa_gate"]

var _campaign: Dictionary = {}

func _ready() -> void:
	_load_campaign()
	_load_save()
	_sanitize_squads()
	if afk_last_claim_unix <= 0:
		afk_last_claim_unix = int(Time.get_unix_time_from_system())

func _load_campaign() -> void:
	if not FileAccess.file_exists(CAMPAIGN_PATH):
		push_warning("Campaign missing: %s" % CAMPAIGN_PATH)
		_campaign = {}
		return
	var f := FileAccess.open(CAMPAIGN_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_campaign = parsed
	else:
		_campaign = {}

func get_campaign() -> Dictionary:
	return _campaign

func get_nodes() -> Array:
	if _campaign.has("nodes"):
		return _campaign["nodes"]
	return []

func get_campaign_node(node_id: String) -> Dictionary:
	for n in get_nodes():
		if str(n.get("id", "")) == node_id:
			return n
	return {}

func is_node_unlocked(node_id: String) -> bool:
	return unlocked_nodes.has(node_id)

func is_node_cleared(node_id: String) -> bool:
	return cleared_nodes.has(node_id)

func afk_gold_per_hour() -> float:
	return BASE_AFK_GOLD_PER_HOUR + float(afk_rate_bonus)

func afk_pending_gold() -> int:
	var now := int(Time.get_unix_time_from_system())
	var hours := clampf(float(now - afk_last_claim_unix) / 3600.0, 0.0, AFK_CAP_HOURS)
	return int(floor(hours * afk_gold_per_hour()))

func afk_pending_hours() -> float:
	var now := int(Time.get_unix_time_from_system())
	return clampf(float(now - afk_last_claim_unix) / 3600.0, 0.0, AFK_CAP_HOURS)

func claim_afk() -> int:
	## Offline mock. Real AFK must be server-time (GAME.md). Marked in UI.
	var gained := afk_pending_gold()
	if gained > 0:
		gold += gained
		economy_changed.emit()
	afk_last_claim_unix = int(Time.get_unix_time_from_system())
	_save()
	return gained

func list_heroes() -> PackedStringArray:
	return CharacterRegistry.list_hero_ids()

func get_player_squad() -> Array[String]:
	_sanitize_squads()
	return player_squad.duplicate()

func get_enemy_squad() -> Array[String]:
	_sanitize_squads()
	return enemy_squad.duplicate()

func set_squad_slot(index: int, hero_id: String) -> void:
	if index < 0 or index >= MAX_SQUAD:
		return
	while player_squad.size() <= index:
		player_squad.append("")
	for i in range(player_squad.size()):
		if i != index and player_squad[i] == hero_id:
			player_squad[i] = ""
	player_squad[index] = hero_id
	_compact_squad()
	squad_changed.emit()
	_save()

func clear_squad_slot(index: int) -> void:
	if index < 0 or index >= player_squad.size():
		return
	player_squad[index] = ""
	_compact_squad()
	squad_changed.emit()
	_save()

func squad_filled_count() -> int:
	var n := 0
	for id in player_squad:
		if id != "":
			n += 1
	return n

func can_start_battle() -> bool:
	return squad_filled_count() >= 1

func go_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func go_squad() -> void:
	get_tree().change_scene_to_file(SQUAD_SCENE)

func go_collection() -> void:
	get_tree().change_scene_to_file(COLLECTION_SCENE)

func go_map() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)

func start_skirmish() -> void:
	if not can_start_battle():
		return
	battle_mode = "skirmish"
	active_node_id = ""
	enemy_squad = ["grimzor", "draxel", "morvex", "obsidrak", "scaria"]
	_sanitize_squads()
	battles_fought += 1
	get_tree().change_scene_to_file(BATTLE_SCENE)

func start_battle() -> void:
	## Back-compat: menu "В бой" opens skirmish.
	start_skirmish()

func start_node_battle(node_id: String) -> void:
	if not can_start_battle():
		return
	if not is_node_unlocked(node_id):
		return
	var node := get_campaign_node(node_id)
	if node.is_empty():
		return
	battle_mode = "campaign"
	active_node_id = node_id
	enemy_squad.clear()
	for eid in node.get("enemy_ids", []):
		enemy_squad.append(str(eid))
	_sanitize_squads()
	battles_fought += 1
	get_tree().change_scene_to_file(BATTLE_SCENE)

func record_battle_result(won: bool) -> void:
	last_battle_won = won
	if won and battle_mode == "campaign" and active_node_id != "":
		_apply_node_victory(active_node_id)
	_save()

func _apply_node_victory(node_id: String) -> void:
	var node := get_campaign_node(node_id)
	if node.is_empty():
		return
	if not cleared_nodes.has(node_id):
		cleared_nodes.append(node_id)
		gold += int(node.get("reward_gold", 0))
		afk_rate_bonus += int(node.get("afk_rate_bonus", 0))
		for u in node.get("unlocks", []):
			var uid := str(u)
			if uid == "chapter_clear":
				continue
			if not unlocked_nodes.has(uid):
				unlocked_nodes.append(uid)
		economy_changed.emit()
		campaign_changed.emit()

func last_reward_summary() -> String:
	if battle_mode != "campaign" or active_node_id == "":
		return ""
	var node := get_campaign_node(active_node_id)
	if node.is_empty():
		return ""
	return "+%d золота · AFK +%d/ч" % [int(node.get("reward_gold", 0)), int(node.get("afk_rate_bonus", 0))]

func faction_label(faction_id: String) -> String:
	match faction_id:
		"ural_wardens":
			return "Уральские стражи"
		"forest_spirits":
			return "Духи леса"
		"dark_creatures":
			return "Тёмные создания"
		"skyborn":
			return "Небожители"
		"ancients":
			return "Древние"
		"renegades":
			return "Отступники"
		_:
			return faction_id

func class_label(class_id: String) -> String:
	match class_id:
		"tank":
			return "Танк"
		"warrior":
			return "Воин"
		"mage":
			return "Маг"
		"healer":
			return "Целитель"
		"support":
			return "Поддержка"
		"assassin":
			return "Убийца"
		_:
			return class_id

func _sanitize_squads() -> void:
	player_squad = _filter_valid(player_squad)
	enemy_squad = _filter_valid(enemy_squad)
	if player_squad.is_empty():
		player_squad = ["braxor", "nixara"]
	if enemy_squad.is_empty():
		enemy_squad = ["stonekin", "shadewolf"]

func _filter_valid(ids: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id in ids:
		if id == "":
			continue
		if CharacterRegistry.get_character(id) == null:
			continue
		if out.has(id):
			continue
		out.append(id)
		if out.size() >= MAX_SQUAD:
			break
	return out

func _compact_squad() -> void:
	var out: Array[String] = []
	for id in player_squad:
		if id != "":
			out.append(id)
	player_squad = out

func _save() -> void:
	var data := {
		"gold": gold,
		"afk_rate_bonus": afk_rate_bonus,
		"afk_last_claim_unix": afk_last_claim_unix,
		"cleared_nodes": cleared_nodes,
		"unlocked_nodes": unlocked_nodes,
		"player_squad": player_squad,
		"battles_fought": battles_fought,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	gold = int(parsed.get("gold", 0))
	afk_rate_bonus = int(parsed.get("afk_rate_bonus", 0))
	afk_last_claim_unix = int(parsed.get("afk_last_claim_unix", 0))
	battles_fought = int(parsed.get("battles_fought", 0))
	cleared_nodes.clear()
	for n in parsed.get("cleared_nodes", []):
		cleared_nodes.append(str(n))
	unlocked_nodes.clear()
	for n in parsed.get("unlocked_nodes", []):
		unlocked_nodes.append(str(n))
	if unlocked_nodes.is_empty():
		unlocked_nodes = ["ufa_gate"]
	player_squad.clear()
	for id in parsed.get("player_squad", []):
		player_squad.append(str(id))
