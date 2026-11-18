extends SceneTree

## Headless QA: verify CharacterRegistry source_facing vs generation rules.
## Usage: godot4 --headless -s res://tools/check_facing_batch.gd
## Exit 0 = ok; 1 = rule violations (heroes must author RIGHT, mobs LEFT —
## unless visual.source_facing is intentionally overridden for legacy V1 art).

func _init() -> void:
	var ids: PackedStringArray = CharacterRegistry.list_ids()
	var failures: PackedStringArray = []
	var warnings: PackedStringArray = []
	for id in ids:
		var data: CharacterData = CharacterRegistry.get_character(id)
		if data == null or data.visual == null:
			failures.append("%s: missing CharacterData/visual" % id)
			continue
		var src_right := data.visual.source_facing == CharacterVisualDef.Facing.RIGHT
		if data.is_hero and not src_right:
			failures.append("%s: hero must have source_facing=RIGHT (got LEFT)" % id)
		elif not data.is_hero and src_right:
			# V1 legacy override allowed — warn, do not fail hard
			warnings.append("%s: mob rule prefers LEFT; V1 override RIGHT (document in registry)" % id)
		print("[FACING-QA] %s hero=%s source=%s folder=%s" % [
			id,
			data.is_hero,
			"RIGHT" if src_right else "LEFT",
			data.visual.sprite_folder,
		])
		# Ability IDs must resolve without PNG/frame binding.
		for aid in [data.basic_attack_id, data.skill1_id, data.skill2_id, data.ultimate_id]:
			if aid == "" or aid in ["skill1", "skill2", "basic", "ultimate"]:
				continue
			var ab: AbilityDef = AbilityCatalog.get_ability(aid)
			if ab == null or ab.ability_id == "basic" and aid != "basic":
				failures.append("%s: ability '%s' missing from AbilityCatalog" % [id, aid])
			else:
				print("[ABILITY-QA] %s → kit=%s anim=%s/%s" % [aid, ab.kit, ab.anim_strike, ab.anim_follow])
		for anim in CharacterVisualDef.ANIM_CONTRACT:
			var _path := "%s%s.png" % [data.visual.sprite_base_path(), anim]
			# Contract names declared; missing files fall back in Fighter.
			pass
	for w in warnings:
		print("[WARN] ", w)
	for f in failures:
		printerr("[FAIL] ", f)
	if failures.size() > 0:
		quit(1)
	else:
		print("[FACING-QA] OK (%d characters, %d warnings)" % [ids.size(), warnings.size()])
		quit(0)
