extends RefCounted
class_name AbilityCatalog

## Maps ability_id → AbilityDef. Combat code looks up by ID only.

static func get_ability(ability_id: String) -> AbilityDef:
	match ability_id:
		"braxor_bash":
			return _def("braxor_bash", "Удар топором", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 85.0, 0.38, 0.32, 18.0, 0.0, Color(1.0, 0.85, 0.35, 0.95), "melee")
		"braxor_shield":
			return _def("braxor_shield", "Удар щитом", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.2, 0.0, 85.0, 0.38, 0.32, 18.0, 5.0, Color(0.95, 0.8, 0.4, 0.95), "melee")
		"braxor_spine":
			return _def("braxor_spine", "Хребет не сдаётся", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.7, 0.0, 90.0, 0.35, 0.35, 0.0, 0.0, Color(1.0, 0.8, 0.3, 1.0), "ult")
		"nixara_slash":
			return _def("nixara_slash", "Теневой рывок", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.7, 0.85, 60.0, 0.26, 0.28, 16.0, 0.0, Color(0.9, 0.3, 1.0, 0.9), "slash")
		"nixara_dash":
			return _def("nixara_slash", "Теневой рывок", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.7, 0.85, 60.0, 0.26, 0.28, 16.0, 0.0, Color(0.9, 0.3, 1.0, 0.9), "slash")
		"nixara_night":
			return _def("nixara_night", "Ночь без свидетелей", AbilityDef.Kit.ULT_MULTI_MARK, "run", "attack2", "attack1", 1.45, 0.0, 55.0, 0.2, 0.3, 0.0, 0.0, Color(0.85, 0.25, 1.0, 1.0), "ult")
		"stonekin_slam":
			return _def("stonekin_slam", "Каменный удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.4, 0.0, 95.0, 0.45, 0.4, 14.0, 0.0, Color(0.8, 0.7, 0.45, 0.95), "slam")
		"shadewolf_bite":
			return _def("shadewolf_bite", "Прыжок-укус", AbilityDef.Kit.LEAP_BITE, "run", "attack2", "attack1", 1.05, 0.0, 55.0, 0.24, 0.3, 13.0, 0.0, Color(0.6, 0.2, 0.7, 0.95), "bite")
		# MASS-01 (CHARACTER_BIBLE) — kits only; no PNG binding
		"velkor_strike":
			return _def("velkor_strike", "Рудный удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.1, 0.0, 80.0, 0.34, 0.3, 16.0, 0.0, Color(0.85, 0.55, 0.3, 0.95), "melee")
		"velkor_oreguard":
			return _def("velkor_oreguard", "Рудный заслон", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.15, 0.0, 80.0, 0.34, 0.3, 16.0, 5.0, Color(0.9, 0.65, 0.35, 0.95), "melee")
		"velkor_pass_thunder":
			return _def("velkor_pass_thunder", "Грохот перевала", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.65, 0.0, 85.0, 0.32, 0.32, 0.0, 0.0, Color(1.0, 0.75, 0.35, 1.0), "ult")
		"tarvex_hammer":
			return _def("tarvex_hammer", "Удар молота", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.0, 0.0, 90.0, 0.4, 0.34, 14.0, 0.0, Color(0.8, 0.6, 0.35, 0.95), "slam")
		"tarvex_forge":
			return _def("tarvex_forge", "Ковка печати", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack2", 0.9, 0.0, 95.0, 0.4, 0.34, 14.0, 5.5, Color(0.95, 0.7, 0.3, 0.95), "melee")
		"tarvex_bastion_seal":
			return _def("tarvex_bastion_seal", "Печать бастиона", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.4, 0.0, 95.0, 0.38, 0.35, 0.0, 0.0, Color(1.0, 0.8, 0.4, 1.0), "ult")
		"xorin_stonebolt":
			return _def("xorin_stonebolt", "Каменный болт", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 150.0, 0.28, 0.28, 15.0, 0.0, Color(0.55, 0.7, 0.75, 0.95), "melee")
		"xorin_fault":
			return _def("xorin_fault", "Разлом", AbilityDef.Kit.MELEE_STEP, "walk", "attack2", "attack1", 1.2, 0.0, 145.0, 0.3, 0.3, 15.0, 5.0, Color(0.45, 0.65, 0.7, 0.95), "slam")
		"xorin_ridge_shift":
			return _def("xorin_ridge_shift", "Сдвиг хребта", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.55, 0.0, 140.0, 0.32, 0.32, 0.0, 0.0, Color(0.6, 0.85, 0.9, 1.0), "ult")
		"elvirax_spring":
			return _def("elvirax_spring", "Родник", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.85, 0.0, 145.0, 0.3, 0.3, 14.0, 0.0, Color(0.45, 0.85, 0.8, 0.95), "melee")
		"elvirax_mend":
			return _def("elvirax_mend", "Исцеление источника", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.7, 0.0, 150.0, 0.3, 0.3, 14.0, 5.0, Color(0.5, 0.9, 0.75, 0.95), "melee")
		"elvirax_mountain_heart":
			return _def("elvirax_mountain_heart", "Сердце горы", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.35, 0.0, 140.0, 0.25, 0.3, 0.0, 0.0, Color(0.55, 0.95, 0.85, 1.0), "ult")
		"liorel_bloom":
			return _def("liorel_bloom", "Цветение", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.9, 0.0, 140.0, 0.3, 0.3, 15.0, 0.0, Color(0.55, 0.9, 0.45, 0.95), "melee")
		"liorel_regrowth":
			return _def("liorel_regrowth", "Поросль", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.75, 0.0, 145.0, 0.3, 0.3, 15.0, 5.0, Color(0.4, 0.85, 0.5, 0.95), "melee")
		"liorel_second_bloom":
			return _def("liorel_second_bloom", "Второе цветение", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.45, 0.0, 140.0, 0.25, 0.3, 0.0, 0.0, Color(0.7, 1.0, 0.55, 1.0), "ult")
		"firnax_cut":
			return _def("firnax_cut", "Лиственный рез", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.75, 0.9, 58.0, 0.24, 0.26, 16.0, 0.0, Color(0.45, 0.75, 0.4, 0.95), "slash")
		"firnax_vanish":
			return _def("firnax_vanish", "Скрыться", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.8, 0.95, 55.0, 0.22, 0.26, 16.0, 4.5, Color(0.35, 0.55, 0.45, 0.95), "slash")
		"firnax_unseen":
			return _def("firnax_unseen", "Ты меня не видел", AbilityDef.Kit.ULT_MULTI_MARK, "run", "attack2", "attack1", 1.4, 0.0, 50.0, 0.2, 0.28, 0.0, 0.0, Color(0.5, 0.3, 0.7, 1.0), "ult")
		"mossar_rootbash":
			return _def("mossar_rootbash", "Удар корней", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.25, 0.0, 95.0, 0.42, 0.38, 14.0, 0.0, Color(0.45, 0.6, 0.35, 0.95), "slam")
		"mossar_barkwall":
			return _def("mossar_barkwall", "Стена коры", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.15, 0.0, 95.0, 0.4, 0.36, 14.0, 5.5, Color(0.5, 0.65, 0.4, 0.95), "melee")
		"mossar_still_forest":
			return _def("mossar_still_forest", "Неподвижный лес", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.6, 0.0, 100.0, 0.4, 0.38, 0.0, 0.0, Color(0.4, 0.75, 0.45, 1.0), "ult")
		"zefriel_gust":
			return _def("zefriel_gust", "Порыв крон", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 150.0, 0.28, 0.28, 15.0, 0.0, Color(0.45, 0.85, 0.75, 0.95), "melee")
		"zefriel_crownstorm":
			return _def("zefriel_crownstorm", "Вихрь листьев", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.15, 0.0, 145.0, 0.26, 0.28, 15.0, 5.0, Color(0.4, 0.8, 0.7, 0.95), "melee")
		"zefriel_canopy_tempest":
			return _def("zefriel_canopy_tempest", "Буря крон", AbilityDef.Kit.GENERIC_BURST, "run", "ultimate", "attack2", 1.55, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.55, 0.95, 0.85, 1.0), "ult")
		# MASS-02
		"morvex_page":
			return _def("morvex_page", "Проклятая страница", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 150.0, 0.28, 0.28, 15.0, 0.0, Color(0.7, 0.25, 0.55, 0.95), "melee")
		"morvex_curse":
			return _def("morvex_curse", "Чернильное проклятие", AbilityDef.Kit.MELEE_STEP, "walk", "attack2", "attack1", 1.15, 0.0, 145.0, 0.3, 0.3, 15.0, 5.0, Color(0.55, 0.2, 0.65, 0.95), "melee")
		"morvex_last_page":
			return _def("morvex_last_page", "Последняя страница", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "attack2", 1.55, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.85, 0.3, 0.7, 1.0), "ult")
		"grimzor_bash":
			return _def("grimzor_bash", "Могильный удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.2, 0.0, 95.0, 0.42, 0.38, 14.0, 0.0, Color(0.45, 0.4, 0.5, 0.95), "slam")
		"grimzor_tombguard":
			return _def("grimzor_tombguard", "Дозор плиты", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.15, 0.0, 95.0, 0.4, 0.36, 14.0, 5.5, Color(0.5, 0.45, 0.55, 0.95), "melee")
		"grimzor_grave_watch":
			return _def("grimzor_grave_watch", "Могильный дозор", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.6, 0.0, 100.0, 0.4, 0.38, 0.0, 0.0, Color(0.4, 0.35, 0.55, 1.0), "ult")
		"draxel_cleave":
			return _def("draxel_cleave", "Рассечение", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.15, 0.0, 85.0, 0.34, 0.3, 16.0, 0.0, Color(0.85, 0.25, 0.35, 0.95), "melee")
		"draxel_execute":
			return _def("draxel_execute", "Приговор клинка", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.25, 0.0, 80.0, 0.3, 0.28, 16.0, 5.0, Color(0.9, 0.3, 0.35, 0.95), "slash")
		"draxel_last_argument":
			return _def("draxel_last_argument", "Последний аргумент", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.7, 0.0, 85.0, 0.32, 0.32, 0.0, 0.0, Color(1.0, 0.35, 0.4, 1.0), "ult")
		"vespira_mist":
			return _def("vespira_mist", "Сонный туман", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.9, 0.0, 145.0, 0.3, 0.3, 14.0, 0.0, Color(0.65, 0.45, 0.85, 0.95), "melee")
		"vespira_lull":
			return _def("vespira_lull", "Колыбельная", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.75, 0.0, 150.0, 0.3, 0.3, 14.0, 5.0, Color(0.55, 0.4, 0.8, 0.95), "melee")
		"vespira_unwanted_dream":
			return _def("vespira_unwanted_dream", "Непрошеный сон", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.4, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.7, 0.5, 0.95, 1.0), "ult")
		"aurix_spear":
			return _def("aurix_spear", "Солнечный укол", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.12, 0.0, 85.0, 0.32, 0.3, 16.0, 0.0, Color(1.0, 0.85, 0.35, 0.95), "melee")
		"aurix_verdict":
			return _def("aurix_verdict", "Вердикт", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.2, 0.0, 80.0, 0.28, 0.28, 16.0, 5.0, Color(1.0, 0.9, 0.45, 0.95), "melee")
		"aurix_judgment":
			return _def("aurix_judgment", "Суд без очереди", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.75, 0.0, 85.0, 0.3, 0.3, 0.0, 0.0, Color(1.0, 0.95, 0.5, 1.0), "ult")
		"selestra_ray":
			return _def("selestra_ray", "Луч рассвета", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.88, 0.0, 145.0, 0.3, 0.3, 14.0, 0.0, Color(1.0, 0.75, 0.7, 0.95), "melee")
		"selestra_mend":
			return _def("selestra_mend", "Исцеление зари", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.72, 0.0, 150.0, 0.3, 0.3, 14.0, 5.0, Color(1.0, 0.8, 0.75, 0.95), "melee")
		"selestra_dawn":
			return _def("selestra_dawn", "Рассвет после позора", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.4, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(1.0, 0.9, 0.8, 1.0), "ult")
		"voltario_bolt":
			return _def("voltario_bolt", "Небесный разряд", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.08, 0.0, 155.0, 0.26, 0.28, 15.0, 0.0, Color(0.45, 0.75, 1.0, 0.95), "melee")
		"voltario_static":
			return _def("voltario_static", "Статика", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.18, 0.0, 150.0, 0.26, 0.28, 15.0, 5.0, Color(0.4, 0.7, 0.95, 0.95), "melee")
		"voltario_sky_objects":
			return _def("voltario_sky_objects", "Небо возражает", AbilityDef.Kit.GENERIC_BURST, "run", "ultimate", "attack2", 1.6, 0.0, 150.0, 0.24, 0.3, 0.0, 0.0, Color(0.55, 0.85, 1.0, 1.0), "ult")
		"orionex_bash":
			return _def("orionex_bash", "Звёздный удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.2, 0.0, 95.0, 0.4, 0.36, 14.0, 0.0, Color(0.55, 0.7, 0.95, 0.95), "slam")
		"orionex_bulwark":
			return _def("orionex_bulwark", "Купольный заслон", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.15, 0.0, 95.0, 0.38, 0.34, 14.0, 5.5, Color(0.5, 0.65, 0.9, 0.95), "melee")
		"orionex_dome":
			return _def("orionex_dome", "Купол небес", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.6, 0.0, 100.0, 0.38, 0.36, 0.0, 0.0, Color(0.6, 0.8, 1.0, 1.0), "ult")
		# MASS-03
		"phaelis_star":
			return _def("phaelis_star", "Звезда гида", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.9, 0.0, 145.0, 0.3, 0.3, 14.0, 0.0, Color(0.85, 0.9, 1.0, 0.95), "melee")
		"phaelis_guide":
			return _def("phaelis_guide", "Путеводная нить", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.8, 0.0, 150.0, 0.3, 0.3, 14.0, 5.0, Color(0.7, 0.85, 1.0, 0.95), "melee")
		"phaelis_constellation":
			return _def("phaelis_constellation", "Созвездие победы", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.45, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.9, 0.95, 1.0, 1.0), "ult")
		"cronax_bash":
			return _def("cronax_bash", "Удар монолита", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.25, 0.0, 95.0, 0.42, 0.38, 14.0, 0.0, Color(0.7, 0.55, 0.35, 0.95), "slam")
		"cronax_bulwark":
			return _def("cronax_bulwark", "Хронощит", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.2, 0.0, 95.0, 0.4, 0.36, 14.0, 5.5, Color(0.65, 0.5, 0.3, 0.95), "melee")
		"cronax_monolith":
			return _def("cronax_monolith", "Пробуждение монолита", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.7, 0.0, 100.0, 0.4, 0.38, 0.0, 0.0, Color(0.85, 0.65, 0.35, 1.0), "ult")
		"eontara_tick":
			return _def("eontara_tick", "Тик времени", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.05, 0.0, 155.0, 0.26, 0.28, 15.0, 0.0, Color(0.35, 0.85, 0.8, 0.95), "melee")
		"eontara_fault":
			return _def("eontara_fault", "Разлом часов", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.15, 0.0, 150.0, 0.26, 0.28, 15.0, 5.0, Color(0.3, 0.75, 0.85, 0.95), "melee")
		"eontara_chronology":
			return _def("eontara_chronology", "Ошибка хронологии", AbilityDef.Kit.GENERIC_BURST, "run", "ultimate", "attack2", 1.55, 0.0, 150.0, 0.24, 0.3, 0.0, 0.0, Color(0.4, 0.95, 0.9, 1.0), "ult")
		"relixor_seal":
			return _def("relixor_seal", "Печать руин", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.95, 0.0, 140.0, 0.3, 0.3, 14.0, 0.0, Color(0.8, 0.65, 0.4, 0.95), "melee")
		"relixor_law":
			return _def("relixor_law", "Закон реликвий", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.85, 0.0, 145.0, 0.3, 0.3, 14.0, 5.0, Color(0.75, 0.6, 0.35, 0.95), "melee")
		"relixor_ruins":
			return _def("relixor_ruins", "Закон руин", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.4, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.9, 0.7, 0.4, 1.0), "ult")
		"obsidrak_cleave":
			return _def("obsidrak_cleave", "Обсидиановый рубящий", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.15, 0.0, 85.0, 0.34, 0.3, 16.0, 0.0, Color(0.35, 0.25, 0.45, 0.95), "melee")
		"obsidrak_shatter":
			return _def("obsidrak_shatter", "Осколок эпохи", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.25, 0.0, 80.0, 0.3, 0.28, 16.0, 5.0, Color(0.45, 0.3, 0.55, 0.95), "slash")
		"obsidrak_epoch":
			return _def("obsidrak_epoch", "Разрушитель эпох", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.7, 0.0, 85.0, 0.32, 0.32, 0.0, 0.0, Color(0.55, 0.35, 0.7, 1.0), "ult")
		"scaria_cut":
			return _def("scaria_cut", "Пылевой укол", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.75, 0.9, 55.0, 0.24, 0.26, 15.0, 0.0, Color(0.65, 0.45, 0.35, 0.95), "slash")
		"scaria_vanish":
			return _def("scaria_vanish", "Исчезновение", AbilityDef.Kit.DASH_COMBO, "run", "attack1", "attack2", 0.7, 1.0, 50.0, 0.22, 0.24, 15.0, 5.0, Color(0.55, 0.4, 0.5, 0.95), "slash")
		"scaria_vanished":
			return _def("scaria_vanished", "Исчезнувшая цивилизация", AbilityDef.Kit.ULT_MULTI_MARK, "run", "ultimate", "attack2", 1.5, 0.0, 55.0, 0.2, 0.28, 0.0, 0.0, Color(0.7, 0.5, 0.4, 1.0), "ult")
		"zephirox_slash":
			return _def("zephirox_slash", "Ветровой разрез", AbilityDef.Kit.DASH_COMBO, "run", "attack2", "attack1", 0.7, 0.95, 55.0, 0.22, 0.26, 15.0, 0.0, Color(0.45, 0.9, 0.95, 0.95), "slash")
		"zephirox_gust":
			return _def("zephirox_gust", "Порыв", AbilityDef.Kit.DASH_COMBO, "run", "attack1", "attack2", 0.65, 1.05, 50.0, 0.2, 0.24, 15.0, 5.0, Color(0.4, 0.85, 1.0, 0.95), "slash")
		"zephirox_failure":
			return _def("zephirox_failure", "Великолепный провал", AbilityDef.Kit.ULT_MULTI_MARK, "run", "ultimate", "attack2", 1.55, 0.0, 55.0, 0.2, 0.28, 0.0, 0.0, Color(0.5, 0.95, 1.0, 1.0), "ult")
		"xalia_orb":
			return _def("xalia_orb", "Нестабильная сфера", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.08, 0.0, 155.0, 0.26, 0.28, 15.0, 0.0, Color(0.75, 0.45, 0.95, 0.95), "melee")
		"xalia_spark":
			return _def("xalia_spark", "Искровой сбой", AbilityDef.Kit.MELEE_STEP, "run", "attack2", "attack1", 1.18, 0.0, 150.0, 0.26, 0.28, 15.0, 5.0, Color(0.7, 0.4, 1.0, 0.95), "melee")
		"xalia_almost":
			return _def("xalia_almost", "Почти контролируемый взрыв", AbilityDef.Kit.GENERIC_BURST, "run", "ultimate", "attack2", 1.6, 0.0, 150.0, 0.24, 0.3, 0.0, 0.0, Color(0.85, 0.5, 1.0, 1.0), "ult")
		# MASS-04
		"ravencor_bash":
			return _def("ravencor_bash", "Вороний удар", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.2, 0.0, 95.0, 0.4, 0.36, 14.0, 0.0, Color(0.35, 0.3, 0.4, 0.95), "slam")
		"ravencor_guard":
			return _def("ravencor_guard", "Контрактный заслон", AbilityDef.Kit.SHIELD_BASH, "walk", "block", "attack1", 1.15, 0.0, 95.0, 0.38, 0.34, 14.0, 5.5, Color(0.45, 0.25, 0.35, 0.95), "melee")
		"ravencor_contract":
			return _def("ravencor_contract", "Контракт на выживание", AbilityDef.Kit.ULT_AOE_STOMP, "walk", "ultimate", "attack2", 1.65, 0.0, 100.0, 0.38, 0.36, 0.0, 0.0, Color(0.55, 0.2, 0.3, 1.0), "ult")
		"meltris_dose":
			return _def("meltris_dose", "Служебная доза", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.88, 0.0, 145.0, 0.3, 0.3, 14.0, 0.0, Color(0.45, 0.85, 0.8, 0.95), "melee")
		"meltris_policy":
			return _def("meltris_policy", "Политика ухода", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.75, 0.0, 150.0, 0.3, 0.3, 14.0, 5.0, Color(0.4, 0.8, 0.75, 0.95), "melee")
		"meltris_not_fired":
			return _def("meltris_not_fired", "Вы ещё не уволены", AbilityDef.Kit.GENERIC_BURST, "idle", "ultimate", "victory", 1.4, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(0.5, 0.95, 0.9, 1.0), "ult")
		"flintar_spark":
			return _def("flintar_spark", "Искра план-Б", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 0.95, 0.0, 140.0, 0.3, 0.3, 14.0, 0.0, Color(0.95, 0.55, 0.3, 0.95), "melee")
		"flintar_jury":
			return _def("flintar_jury", "Кустарный ремонт", AbilityDef.Kit.MELEE_STEP, "walk", "block", "attack1", 0.85, 0.0, 145.0, 0.3, 0.3, 14.0, 5.0, Color(0.9, 0.5, 0.25, 0.95), "melee")
		"flintar_plan_b":
			return _def("flintar_plan_b", "План Б, которого не было", AbilityDef.Kit.GENERIC_BURST, "run", "ultimate", "attack2", 1.5, 0.0, 145.0, 0.25, 0.3, 0.0, 0.0, Color(1.0, 0.6, 0.3, 1.0), "ult")
		"basic":
			return _def("basic", "Базовая атака", AbilityDef.Kit.MELEE_STEP, "walk", "attack1", "attack2", 1.0, 0.0, 70.0, 0.35, 0.3, 12.0, 0.0, Color(1, 1, 1, 0.9), "melee")
		_:
			push_warning("Unknown ability_id=%s — using basic" % ability_id)
			return get_ability("basic")

static func _def(
	id: String, name: String, kit: AbilityDef.Kit,
	windup: String, strike: String, follow: String,
	mult: float, mult_b: float, gap: float, approach: float, ret: float,
	energy: float, cd: float, color: Color, kind: String
) -> AbilityDef:
	var a := AbilityDef.new()
	a.ability_id = id
	a.display_name = name
	a.kit = kit
	a.anim_windup = windup
	a.anim_strike = strike
	a.anim_follow = follow
	a.power_mult = mult
	a.power_mult_b = mult_b
	a.contact_gap = gap
	a.approach_time = approach
	a.return_time = ret
	a.energy_gain = energy
	a.skill_cooldown = cd
	a.vfx_color = color
	a.vfx_kind = kind
	return a
