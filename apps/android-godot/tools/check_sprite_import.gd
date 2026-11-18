extends SceneTree

## Validates sprite folders for registry characters + roster stubs.
## - Heroes with art: idle.png exists, source_facing rule
## - STUB_NO_ART entries: allowed without folder
## Usage: godot4 --headless -s res://tools/check_sprite_import.gd

func _init() -> void:
	var failures: PackedStringArray = []
	var warnings: PackedStringArray = []
	var checked := 0

	# Live registry characters must import.
	for id in CharacterRegistry.list_ids():
		checked += 1
		var data: CharacterData = CharacterRegistry.get_character(id)
		if data == null or data.visual == null:
			failures.append("%s: missing registry/visual" % id)
			continue
		var folder := data.visual.sprite_base_path()
		var idle := folder + "idle.png"
		if not ResourceLoader.exists(idle) and not FileAccess.file_exists(idle):
			# Also accept filesystem path under project
			var abs := ProjectSettings.globalize_path(idle)
			if not FileAccess.file_exists(abs):
				failures.append("%s: missing idle.png at %s" % [id, idle])
		var present := 0
		for anim in CharacterVisualDef.ANIM_CONTRACT:
			var p := folder + anim + ".png"
			var abs2 := ProjectSettings.globalize_path(p)
			if ResourceLoader.exists(p) or FileAccess.file_exists(abs2):
				present += 1
		# Also count common multi-frame names used by Fighter._build_frames
		for extra in ["walk_0.png", "attack_0.png", "hit.png", "block.png"]:
			var p2: String = folder + str(extra)
			if ResourceLoader.exists(p2) or FileAccess.file_exists(ProjectSettings.globalize_path(p2)):
				present += 1
		if present < 1:
			failures.append("%s: no animation frames under %s" % [id, folder])
		print("[IMPORT] %s folder=%s frames≈%d source=%s" % [
			id, data.visual.sprite_folder, present,
			"RIGHT" if data.visual.source_facing == CharacterVisualDef.Facing.RIGHT else "LEFT",
		])

	# Roster stubs: STUB_NO_ART must not claim a folder.
	var roster_path := "res://content/hero_roster_batch01.json"
	if FileAccess.file_exists(ProjectSettings.globalize_path(roster_path)):
		var f := FileAccess.open(roster_path, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("entries"):
			for e in parsed["entries"]:
				checked += 1
				var status := str(e.get("visual_status", ""))
				var slug := str(e.get("slug", ""))
				var is_hero := bool(e.get("is_hero", true))
				var facing := str(e.get("source_facing", ""))
				if is_hero and facing != "RIGHT":
					failures.append("%s: hero stub must source_facing=RIGHT" % slug)
				if not is_hero and facing != "LEFT" and not e.has("source_facing_override"):
					failures.append("%s: mob stub must source_facing=LEFT" % slug)
				if status == "STUB_NO_ART" and e.get("sprite_folder", null) != null:
					failures.append("%s: STUB_NO_ART must have sprite_folder=null" % slug)
				if status in ["V1_APPROVED", "BATCH_PACKED"] and e.get("sprite_folder", null) == null:
					failures.append("%s: V1_APPROVED needs sprite_folder" % slug)
				print("[ROSTER] %s status=%s facing=%s" % [slug, status, facing])
	else:
		warnings.append("roster json missing: %s" % roster_path)

	for w in warnings:
		print("[WARN] ", w)
	for err in failures:
		printerr("[FAIL] ", err)
	if failures.size() > 0:
		quit(1)
	else:
		print("[IMPORT-QA] OK checked=%d warnings=%d" % [checked, warnings.size()])
		quit(0)
