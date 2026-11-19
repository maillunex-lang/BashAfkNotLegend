extends SceneTree

## Requires BASH_FORCE_TOWER_FLOOR (GameState primes enemies on autoload).

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battle/BattlePrototype.tscn")
	if packed == null:
		push_error("Battle scene missing")
		quit(1)
		return
	root.add_child(packed.instantiate())
	var wait_s := float(OS.get_environment("BASH_DEMO_SECONDS"))
	if wait_s <= 0.0:
		wait_s = 3.5
	await create_timer(wait_s).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var path := OS.get_environment("BASH_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/playable_tower_battle.png"
	img.save_png(path)
	print("[SHOT-TOWER-BATTLE] saved ", path)
	quit(0)
