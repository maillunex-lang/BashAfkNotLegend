extends SceneTree

## Usage: godot -s res://tools/shot_ui.gd
## Optional: BASH_UI_SCENE, BASH_SCREENSHOT_PATH, BASH_DEMO_SECONDS

func _initialize() -> void:
	var scene_path := OS.get_environment("BASH_UI_SCENE")
	if scene_path == "":
		scene_path = "res://scenes/ui/WorldMap.tscn"
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Cannot load %s" % scene_path)
		quit(1)
		return
	var root_node := packed.instantiate()
	root.add_child(root_node)
	var wait_s := float(OS.get_environment("BASH_DEMO_SECONDS"))
	if wait_s <= 0.0:
		wait_s = 1.4
	await create_timer(wait_s).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var path := OS.get_environment("BASH_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/playable_world_map.png"
	img.save_png(path)
	print("[SHOT-UI] saved ", path)
	quit(0)
