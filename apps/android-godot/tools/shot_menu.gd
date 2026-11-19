extends SceneTree

func _initialize() -> void:
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var path := OS.get_environment("BASH_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/playable_main_menu.png"
	img.save_png(path)
	quit(0)
