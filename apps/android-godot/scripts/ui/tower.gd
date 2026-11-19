extends Control

@onready var title: Label = $Margin/VBox/Title
@onready var blurb: Label = $Margin/VBox/Blurb
@onready var progress: Label = $Margin/VBox/Progress
@onready var list: VBoxContainer = $Margin/VBox/Scroll/List
@onready var detail_name: Label = $Margin/VBox/Detail/Name
@onready var detail_flavour: Label = $Margin/VBox/Detail/Flavour
@onready var detail_enemies: Label = $Margin/VBox/Detail/Enemies
@onready var detail_reward: Label = $Margin/VBox/Detail/Reward
@onready var btn_fight: Button = $Margin/VBox/Nav/BtnFight
@onready var btn_back: Button = $Margin/VBox/Nav/BtnBack
@onready var btn_squad: Button = $Margin/VBox/Nav/BtnSquad

var _selected: int = 1

func _ready() -> void:
	var tower := GameState.get_tower()
	title.text = str(tower.get("title_ru", "Башня испытаний"))
	blurb.text = str(tower.get("blurb", ""))
	btn_back.pressed.connect(func(): GameState.go_menu())
	btn_squad.pressed.connect(func(): GameState.go_squad())
	btn_fight.pressed.connect(_on_fight)
	GameState.tower_changed.connect(_rebuild)
	_selected = clampi(GameState.next_tower_floor(), 1, maxi(1, GameState.max_tower_floor()))
	_rebuild()

func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()
	await get_tree().process_frame
	progress.text = "Прогресс: этаж %d / %d · золото %d" % [
		GameState.tower_floor, GameState.max_tower_floor(), GameState.gold,
	]
	for fl in GameState.get_tower_floors():
		list.add_child(_make_floor_row(fl))
	_show(_selected)

func _make_floor_row(fl: Dictionary) -> Button:
	var n := int(fl.get("floor", 0))
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 56)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var cleared := n <= GameState.tower_floor
	var unlocked := GameState.can_fight_tower_floor(n)
	var mark := "✓" if cleared else ("●" if unlocked else "🔒")
	var mile := " · веха" if bool(fl.get("is_milestone", false)) else ""
	btn.text = "%s  %s%s" % [mark, str(fl.get("name_ru", "Этаж %d" % n)), mile]
	btn.disabled = not unlocked and not cleared
	btn.pressed.connect(func(): _show(n))
	return btn

func _show(floor_n: int) -> void:
	_selected = floor_n
	var fl := GameState.get_tower_floor(floor_n)
	if fl.is_empty():
		return
	detail_name.text = str(fl.get("name_ru", "Этаж %d" % floor_n))
	detail_flavour.text = str(fl.get("flavour", ""))
	var names: PackedStringArray = PackedStringArray()
	for eid in fl.get("enemy_ids", []):
		var data := CharacterRegistry.get_character(str(eid))
		names.append(data.display_name if data else str(eid))
	detail_enemies.text = "Враги: " + ", ".join(names)
	var mile := " · веха AFK +1/ч" if bool(fl.get("is_milestone", false)) else ""
	detail_reward.text = "Награда: %d золота%s" % [int(fl.get("reward_gold", 0)), mile]
	var can := GameState.can_fight_tower_floor(floor_n) and GameState.can_start_battle()
	btn_fight.disabled = not can
	if floor_n <= GameState.tower_floor:
		btn_fight.text = "Повторить"
	elif floor_n == GameState.next_tower_floor():
		btn_fight.text = "Штурм этажа"
	else:
		btn_fight.text = "Закрыто"

func _on_fight() -> void:
	GameState.start_tower_battle(_selected)
