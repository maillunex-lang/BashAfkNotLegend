extends Node

## Offline client state for the playable prototype (no server yet).
## Squad = up to 5 hero IDs from CharacterRegistry. Combat reads this.

signal squad_changed

const MAX_SQUAD := 5
const BATTLE_SCENE := "res://scenes/battle/BattlePrototype.tscn"
const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const SQUAD_SCENE := "res://scenes/ui/SquadSelect.tscn"
const COLLECTION_SCENE := "res://scenes/ui/Collection.tscn"

## Default starter squad (V1 + MASS tanks/DPS) — all CHARACTER_BIBLE IDs.
var player_squad: Array[String] = ["braxor", "nixara", "velkor", "mossar", "aurix"]
## Offline wave: opposing heroes as AI (showcases packed art without new mobs).
var enemy_squad: Array[String] = ["grimzor", "draxel", "morvex", "obsidrak", "scaria"]

var last_battle_won: bool = false
var battles_fought: int = 0

func _ready() -> void:
	_sanitize_squads()

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
	# Unique: remove duplicate elsewhere
	for i in range(player_squad.size()):
		if i != index and player_squad[i] == hero_id:
			player_squad[i] = ""
	player_squad[index] = hero_id
	_compact_squad()
	squad_changed.emit()

func clear_squad_slot(index: int) -> void:
	if index < 0 or index >= player_squad.size():
		return
	player_squad[index] = ""
	_compact_squad()
	squad_changed.emit()

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

func start_battle() -> void:
	if not can_start_battle():
		return
	battles_fought += 1
	get_tree().change_scene_to_file(BATTLE_SCENE)

func record_battle_result(won: bool) -> void:
	last_battle_won = won

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
