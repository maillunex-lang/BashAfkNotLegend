extends Control

@onready var title: Label = $Center/VBox/Title
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var btn_campaign: Button = $Center/VBox/BtnCampaign
@onready var btn_tower: Button = $Center/VBox/BtnTower
@onready var btn_battle: Button = $Center/VBox/BtnBattle
@onready var btn_squad: Button = $Center/VBox/BtnSquad
@onready var btn_collection: Button = $Center/VBox/BtnCollection
@onready var squad_hint: Label = $Center/VBox/SquadHint
@onready var last_result: Label = $Center/VBox/LastResult

func _ready() -> void:
	title.text = "Башкирия"
	subtitle.text = "Герои без легенд"
	btn_campaign.pressed.connect(func(): GameState.go_map())
	btn_tower.pressed.connect(func(): GameState.go_tower())
	btn_battle.pressed.connect(func(): GameState.start_skirmish())
	btn_squad.pressed.connect(func(): GameState.go_squad())
	btn_collection.pressed.connect(func(): GameState.go_collection())
	_refresh()

func _refresh() -> void:
	var n := GameState.squad_filled_count()
	squad_hint.text = "Отряд: %d / 5 · золото %d · башня %d · AFK %.0f/ч" % [
		n, GameState.gold, GameState.tower_floor, GameState.afk_gold_per_hour(),
	]
	var can := GameState.can_start_battle()
	btn_battle.disabled = not can
	btn_campaign.disabled = not can
	btn_tower.disabled = not can
	var cleared := GameState.cleared_nodes.size()
	if GameState.battles_fought <= 0:
		last_result.text = "Глава 1 · узлы %d/5 · башня %d/10 · offline" % [cleared, GameState.tower_floor]
	else:
		var outcome := "победа" if GameState.last_battle_won else "поражение"
		last_result.text = "Последний бой: %s · кампания %d · башня %d" % [outcome, cleared, GameState.tower_floor]
