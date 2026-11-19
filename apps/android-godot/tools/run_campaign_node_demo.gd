extends SceneTree

## Sets campaign node then opens battle for screenshot demos.
## BASH_CAMPAIGN_NODE=ufa_gate BASH_DEMO_QUIT=1 ...

func _initialize() -> void:
	await process_frame
	var node_id := OS.get_environment("BASH_CAMPAIGN_NODE")
	if node_id == "":
		node_id = "ufa_gate"
	# Ensure GameState autoload exists
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		push_error("GameState autoload missing")
		quit(1)
		return
	if not gs.is_node_unlocked(node_id):
		gs.unlocked_nodes.append(node_id)
	gs.start_node_battle(node_id)
