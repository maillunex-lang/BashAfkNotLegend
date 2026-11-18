extends Control

@onready var title: Label = $Center/VBox/Title
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var btn_battle: Button = $Center/VBox/BtnBattle
@onready var btn_squad: Button = $Center/VBox/BtnSquad
@onready var btn_collection: Button = $Center/VBox/BtnCollection
@onready var squad_hint: Label = $Center/VBox/SquadHint
@onready var last_result: Label = $Center/VBox/LastResult

func _ready() -> void:
	title.text = "Башкирия"
	subtitle.text = "Герои без легенд"
	btn_battle.pressed.connect(_on_battle)
	btn_squad.pressed.connect(func(): GameState.go_squad())
	btn_collection.pressed.connect(func(): GameState.go_collection())
	_refresh()

func _refresh() -> void:
	var n := GameState.squad_filled_count()
	squad_hint.text = "Отряд: %d / 5" % n
	btn_battle.disabled = not GameState.can_start_battle()
	if GameState.battles_fought <= 0:
		last_result.text = "Offline прототип · 30 героев · 5v5"
	else:
		last_result.text = ("Последний бой: победа" if GameState.last_battle_won else "Последний бой: поражение") + " · боёв: %d" % GameState.battles_fought

func _on_battle() -> void:
	GameState.start_battle()
