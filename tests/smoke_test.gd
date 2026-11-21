extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pathfinding()
	_test_combat_rules()
	_test_structured_command()
	_test_external_resources()
	_test_character_selection_assets()
	_test_mage_visual_assets()
	_test_grass_terrain_assets()
	_test_equipment_system()
	_test_height_and_line_of_sight()
	_test_status_effects()
	_test_turn_order()
	_test_abilities_and_cooldowns()
	_test_death_and_outcome()
	_test_races_and_stat_calculation()
	_test_character_roster()
	_test_experience_and_level_limits()
	_test_skill_points_and_learning()
	_test_profession_changes()
	_test_campaign_progression()
	_test_mission_objectives_and_dialogue()
	_test_save_round_trip()
	_test_complete_battles()
	await _test_main_scene()
	if failures.is_empty():
		print("SMOKE TEST OK: combate, razas, profesiones, niveles, SP, persistencia e interfaz")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_pathfinding() -> void:
	var blocked := {Vector2i(1, 0): true}
	var occupied := {Vector2i(0, 0): "hero"}
	var reachable := GridPathfinder.reachable_cells(Vector2i.ZERO, 2, Vector2i(4, 4), blocked, occupied)
	_expect(not reachable.has(Vector2i(1, 0)), "El pathfinder incluyó un obstáculo.")
	_expect(reachable.has(Vector2i(0, 2)), "El pathfinder omitió una casilla alcanzable.")
	var path := GridPathfinder.find_path(Vector2i.ZERO, Vector2i(2, 0), Vector2i(4, 4), blocked, occupied, 4)
	_expect(path.size() == 4, "El pathfinder no rodeó correctamente el obstáculo.")

func _test_combat_rules() -> void:
	var attacker := UnitData.new()
	attacker.unit_id = "attacker"
	attacker.physical_attack = 12
	attacker.magical_attack = 14
	attacker.grid_position = Vector2i(1, 1)
	var defender := UnitData.new()
	defender.unit_id = "defender"
	defender.team = UnitData.Team.ENEMIES
	defender.physical_defense = 6
	defender.magical_defense = 8
	defender.grid_position = Vector2i(1, 2)
	_expect(CombatRules.can_basic_attack(attacker, defender), "Un ataque cuerpo a cuerpo válido fue rechazado.")
	var damage := CombatRules.basic_attack_damage(attacker, defender)
	_expect(damage == 9, "El cálculo de daño físico no es determinista o cambió inesperadamente.")
	var applied := CombatRules.apply_damage(defender, damage)
	_expect(applied == 9 and defender.hp == 21, "La aplicación de daño no actualizó el HP correctamente.")
	var ability := AbilityData.create(&"ice", "Hielo", 5, 3, 4, AbilityData.DamageType.MAGICAL)
	_expect(CombatRules.can_use_ability(attacker, defender, ability), "Una habilidad mágica válida fue rechazada.")

func _test_structured_command() -> void:
	var command := BattleCommand.move("hero", Vector2i(3, 5))
	var payload := command.serialize()
	_expect(command.is_valid_for("hero") and not command.is_valid_for("enemy"), "La validación estructural aceptó un actor fuera de turno.")
	_expect(payload.actor_id == "hero" and payload.target_cell.x == 3, "La serialización del comando perdió datos.")

func _test_external_resources() -> void:
	var mage := load("res://data/archetypes/hero_mage.tres") as UnitArchetype
	var mission := load("res://data/missions/mission_01.tres") as MissionData
	_expect(mage != null and mage.magical_attack == 15, "No se cargó el arquetipo externo del mago.")
	var unit := mage.instantiate("test_mage", UnitData.Team.HEROES, Vector2i.ZERO)
	_expect(unit.abilities.size() == 2 and unit.abilities[0].id == &"ice_lance" and unit.abilities[1].id == &"paralyzing_frost", "Las habilidades .tres no fueron vinculadas al arquetipo.")
	_expect(mission != null and mission.height_cells.size() > 0, "La misión externa no contiene alturas.")

func _test_character_selection_assets() -> void:
	var reference := load("res://assets/ui/character_selection/character_selection.png") as Texture2D
	_expect(reference != null and reference.get_size() == Vector2(1672, 941), "La referencia visual no se importó con sus dimensiones reales.")
	var expected_sizes := {
		"human": Vector2(201, 156), "elf": Vector2(200, 156), "dark_elf": Vector2(205, 156),
		"orc": Vector2(196, 156), "dwarf": Vector2(205, 156),
	}
	for race_id in expected_sizes:
		var portrait := load("res://assets/portraits/races/portrait_%s.png" % race_id) as Texture2D
		_expect(portrait != null and portrait.get_size() == expected_sizes[race_id], "El retrato extraído de %s falta o fue deformado." % race_id)

func _test_mage_visual_assets() -> void:
	var sheet := load("res://assets/sprites/characters/mage/mage_spritesheet.png") as Texture2D
	_expect(sheet != null and sheet.get_size() == Vector2(1536, 1024), "La hoja original del mago no se importó con sus dimensiones reales.")
	var required_frames := [
		"idle/front_00.png", "idle/right_00.png", "idle/back_00.png", "idle/left_00.png",
		"walk/right_00.png", "walk/right_03.png", "attack/right_00.png", "attack/right_03.png",
		"cast/right_00.png", "cast/right_03.png", "hurt/right_00.png", "hurt/right_02.png",
		"death/right_00.png", "death/right_03.png",
	]
	for relative_path in required_frames:
		var texture := load("res://assets/sprites/characters/mage/%s" % relative_path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(96, 96), "El fotograma normalizado %s falta o tiene un lienzo incorrecto." % relative_path)
		if texture != null:
			_expect(texture.get_image().get_pixel(0, 0).a < 0.05, "El fotograma %s conserva fondo oscuro en la esquina." % relative_path)
	for effect_name in ["magic_circle_00", "orb_03", "ice_02", "explosion_01"]:
		_expect(ResourceLoader.exists("res://assets/sprites/characters/mage/effects/%s.png" % effect_name), "Falta el efecto mágico %s." % effect_name)
	_expect(ResourceLoader.exists("res://assets/portraits/classes/portrait_human_mage.png"), "Falta el retrato específico del mago humano.")

func _test_grass_terrain_assets() -> void:
	var source := load("res://assets/tilesets/grass/grass_tileset.png") as Texture2D
	_expect(source != null and source.get_size() == Vector2(1448, 1086), "La composicion original de cesped no conserva sus dimensiones reales.")
	var flat_tiles := [
		"grass_plain_01", "grass_plain_04", "grass_flowers_01", "grass_flowers_03",
		"grass_stones_01", "grass_stones_03", "grass_tall_01", "grass_tall_02",
	]
	for tile_name in flat_tiles:
		var texture := load("res://assets/tilesets/grass/%s.png" % tile_name) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(72, 48), "La pieza %s falta o no esta normalizada." % tile_name)
		if texture != null:
			_expect(texture.get_image().get_pixel(0, 0).a < 0.05, "La pieza %s conserva fondo en su esquina." % tile_name)
	for tile_name in ["grass_block_01", "grass_edge_01", "grass_stairs_01"]:
		_expect(ResourceLoader.exists("res://assets/tilesets/grass/%s.png" % tile_name), "Falta la pieza de altura %s." % tile_name)
	var grid := IsometricGrid.new()
	var mission := load("res://data/missions/mission_02.tres") as MissionData
	grid.configure(mission)
	var sample_cell := Vector2i(3, 4)
	var first_variant := grid.grass_variant_id(sample_cell)
	_expect(first_variant == grid.grass_variant_id(sample_cell), "La variante visual de cesped cambia entre dibujos.")
	_expect(grid.get_height(Vector2i(5, 2)) == 2, "La integracion visual altero las alturas logicas de la mision.")
	_expect(grid.grid_to_world_flat(Vector2i(1, 0)) == Vector2(32, 16), "La integracion visual altero la geometria 64x32 del tablero.")
	grid.free()

func _test_equipment_system() -> void:
	var source := load("res://assets/characters/base/base_characters.png") as Texture2D
	_expect(source != null and source.get_size() == Vector2(1672, 941), "La composicion base de personajes no conserva sus dimensiones reales.")
	var profile := CampaignProfile.new()
	profile.initialize_new()
	var character := profile.create_character("equipment_test", "Equipo", "human", "warrior")
	_expect(character != null and character.appearance_id == "warrior", "El personaje no conserva una apariencia independiente de su profesion futura.")
	_expect(profile.catalog.equipment.size() == 22 and profile.catalog.appearances.size() == 5, "El catalogo de equipamiento o apariencias esta incompleto.")
	for body_id in ["warrior", "mage", "archer", "acolyte", "explorer"]:
		var base := load("res://assets/characters/base/extracted/base_%s.png" % body_id) as Texture2D
		_expect(base != null and base.get_size() == Vector2(256, 384), "La base extraida de %s falta o fue deformada." % body_id)
		if base != null:
			_expect(base.get_image().get_pixel(0, 0).a < 0.05, "La base %s conserva fondo en su esquina." % body_id)
	var race := profile.catalog.race(character.race_id)
	var profession := profile.catalog.profession(character.profession_id)
	var base_stats := StatCalculator.calculate(character, race, profession, profile.equipment_bonuses(character))
	_expect(character.item_quantity("iron_sword") == 1, "El kit inicial no ingreso al inventario.")
	_expect(profile.equip_item(character.character_id, "iron_sword"), "No se pudo equipar una espada compatible.")
	_expect(character.item_quantity("iron_sword") == 0 and str(character.equipped_items.get("main_hand", "")) == "iron_sword", "Equipar no traslado correctamente la espada al slot.")
	var sword_stats := StatCalculator.calculate(character, race, profession, profile.equipment_bonuses(character))
	_expect(int(sword_stats.derived.physical_attack) == int(base_stats.derived.physical_attack) + 4, "La espada no aplica exactamente una vez su ataque fisico.")
	_expect(not profile.equip_item(character.character_id, "iron_sword"), "Se pudo duplicar una espada ya equipada sin inventario.")
	var repeated_stats := StatCalculator.calculate(character, race, profession, profile.equipment_bonuses(character))
	_expect(repeated_stats == sword_stats, "Reequipar acumulo bonificaciones incorrectamente.")
	_expect(not profile.equip_item(character.character_id, "apprentice_staff"), "Un guerrero equipo un objeto incompatible o inexistente en su inventario.")
	for item_id in ["wooden_shield", "leather_helmet", "leather_armor", "leather_boots"]:
		_expect(profile.equip_item(character.character_id, item_id), "No se pudo equipar %s." % item_id)
	var unit := (load("res://data/archetypes/hero_warrior.tres") as UnitArchetype).instantiate(character.character_id, UnitData.Team.HEROES, Vector2i.ZERO)
	profile.apply_to_hero(unit)
	_expect(unit.equipment_ids.size() == 5 and unit.physical_attack == int(sword_stats.derived.physical_attack), "El combate no recibio el equipo o recalculo mal las estadisticas.")
	var layers := EquipmentLayerVisual.new()
	layers.configure(unit.body_model_id, unit.equipment_items)
	_expect(layers.get_child_count() == 5, "Las capas visuales de combate no reflejan todos los objetos equipados.")
	layers.set_facing("back")
	_expect((layers.layer_sprites.get("main_hand") as Sprite2D).z_index < 0, "El arma no cambia de orden al mirar hacia atras.")
	layers.free()
	var snapshot := profile.make_snapshot()
	var restored := CampaignProfile.new()
	restored.restore(snapshot)
	var restored_character := restored.character(character.character_id)
	_expect(restored_character != null and restored_character.equipped_items == character.equipped_items, "Guardar y cargar no restauro el equipamiento por IDs.")
	_expect(restored_character.item_quantity("iron_sword") == 0, "La carga duplico un objeto equipado en el inventario.")
	_expect(restored.unequip_item(character.character_id, "main_hand"), "No se pudo desequipar la espada restaurada.")
	_expect(restored_character.item_quantity("iron_sword") == 1 and not restored_character.equipped_items.has("main_hand"), "Desequipar no devolvio el objeto al inventario.")

func _test_height_and_line_of_sight() -> void:
	var heights := {Vector2i(1, 0): 2, Vector2i(0, 1): 1}
	var occupied := {Vector2i.ZERO: true}
	var reachable := GridPathfinder.reachable_cells(Vector2i.ZERO, 4, Vector2i(4, 4), {}, occupied, heights, 1)
	_expect(not reachable.has(Vector2i(1, 0)), "Una unidad escaló más niveles que su límite.")
	_expect(reachable.has(Vector2i(0, 1)), "Una subida válida quedó fuera del movimiento.")
	_expect(not CombatRules.has_line_of_sight(Vector2i.ZERO, Vector2i(0, 3), {}, {Vector2i(0, 1): true}), "Un obstáculo no bloqueó la línea de visión.")
	_expect(CombatRules.has_line_of_sight(Vector2i.ZERO, Vector2i(0, 3), {}, {}), "Una línea de visión despejada fue rechazada.")

func _test_status_effects() -> void:
	var unit := UnitData.new()
	unit.hp = 20
	unit.max_hp = 20
	unit.move_range = 4
	var chilled := load("res://data/status_effects/chilled.tres") as StatusEffectData
	var burning := load("res://data/status_effects/burning.tres") as StatusEffectData
	unit.add_status(chilled)
	unit.add_status(burning)
	unit.add_status(chilled)
	_expect(unit.effective_move_range() == 2, "Escarcha no acumuló la reducción de movimiento.")
	unit.process_status_turn()
	_expect(unit.hp == 17, "Quemadura no infligió daño por turno.")
	unit.process_status_turn()
	_expect(unit.active_statuses.is_empty(), "Los estados no expiraron al completar su duración.")

func _test_turn_order() -> void:
	var slow := UnitData.new()
	slow.unit_id = "slow"
	slow.speed = 4
	var fast_b := UnitData.new()
	fast_b.unit_id = "fast_b"
	fast_b.team = UnitData.Team.ENEMIES
	fast_b.speed = 9
	var fast_a := UnitData.new()
	fast_a.unit_id = "fast_a"
	fast_a.speed = 9
	var units: Array[UnitData] = [slow, fast_b, fast_a]
	var manager := TurnManager.new()
	manager.start(units)
	_expect(manager.order == ["fast_a", "fast_b", "slow"], "La iniciativa no respeta velocidad y desempate estable.")
	var seen: Array[String] = []
	for index in 3:
		seen.append(manager.active_unit_id)
		manager.complete_active_turn(units)
	_expect(seen == ["fast_a", "fast_b", "slow"] and manager.round_number == 2, "Una unidad actuó dos veces o se perdió al avanzar la ronda.")
	fast_b.hp = 0
	manager.complete_active_turn(units)
	_expect(not manager.order.has("fast_b"), "Una unidad derrotada permaneció en la cola de iniciativa.")

func _test_abilities_and_cooldowns() -> void:
	var warrior_archetype := load("res://data/archetypes/hero_warrior.tres") as UnitArchetype
	var archer_archetype := load("res://data/archetypes/hero_archer.tres") as UnitArchetype
	var warrior := warrior_archetype.instantiate("warrior", UnitData.Team.HEROES, Vector2i.ZERO)
	var enemy := archer_archetype.instantiate("enemy", UnitData.Team.ENEMIES, Vector2i(0, 1))
	var strike: AbilityData = warrior.abilities[0]
	var guard: AbilityData = warrior.abilities[1]
	_expect(CombatRules.can_use_ability(warrior, enemy, strike), "Golpe poderoso rechazó un objetivo enemigo válido.")
	warrior.mp = 0
	_expect(not CombatRules.can_use_ability(warrior, enemy, strike), "Una habilidad pudo usarse sin MP suficiente.")
	warrior.mp = warrior.max_mp
	_expect(not CombatRules.can_use_ability(warrior, enemy, guard), "Guardia de acero aceptó un objetivo que no era el propio usuario.")
	_expect(CombatRules.can_use_ability(warrior, warrior, guard), "Guardia de acero rechazó al propio usuario.")
	warrior.start_ability_cooldown(guard)
	_expect(not warrior.is_ability_ready(guard.id), "El enfriamiento no bloqueó la habilidad.")
	warrior.begin_turn()
	_expect(warrior.ability_cooldown(guard.id) == 2, "El enfriamiento no disminuyó al comenzar la activación.")
	var steel_guard := load("res://data/status_effects/steel_guard.tres") as StatusEffectData
	warrior.add_status(steel_guard)
	_expect(warrior.effective_physical_defense() == warrior.physical_defense + 5, "El aumento temporal de defensa no se aplicó.")
	warrior.process_status_turn()
	warrior.process_status_turn()
	_expect(warrior.effective_physical_defense() == warrior.physical_defense, "El aumento de defensa no expiró.")
	var double_shot := load("res://data/abilities/double_shot.tres") as AbilityData
	_expect(double_shot.hit_count == 2 and double_shot.damage_scale < 1.0, "Disparo doble no contiene dos impactos reducidos.")
	enemy.grid_position = Vector2i(0, 8)
	warrior.mp = warrior.max_mp
	_expect(not CombatRules.can_use_ability(warrior, enemy, strike), "Una habilidad aceptó un objetivo fuera de alcance.")

func _test_death_and_outcome() -> void:
	var hero := UnitData.new()
	hero.unit_id = "hero"
	hero.team = UnitData.Team.HEROES
	var enemy := UnitData.new()
	enemy.unit_id = "enemy"
	enemy.team = UnitData.Team.ENEMIES
	enemy.hp = 1
	var units: Array[UnitData] = [hero, enemy]
	CombatRules.apply_damage(enemy, 5)
	_expect(not enemy.is_alive(), "Una unidad con HP cero no fue marcada como derrotada.")
	_expect(CombatRules.battle_winner(units) == UnitData.Team.HEROES, "La condición de victoria no detectó al equipo superviviente.")
	enemy.hp = 10
	hero.hp = 0
	_expect(CombatRules.battle_winner(units) == UnitData.Team.ENEMIES, "La condición de derrota no detectó al equipo enemigo.")

func _test_campaign_progression() -> void:
	var profile := CampaignProfile.new()
	profile.initialize_default()
	var archetype := load("res://data/archetypes/hero_warrior.tres") as UnitArchetype
	var hero := archetype.instantiate("hero_warrior", UnitData.Team.HEROES, Vector2i.ZERO)
	var heroes: Array[UnitData] = [hero]
	profile.award_mission(load("res://data/missions/mission_01.tres") as MissionData, heroes)
	profile.award_mission(load("res://data/missions/mission_02.tres") as MissionData, heroes)
	var advanced := archetype.instantiate("hero_warrior", UnitData.Team.HEROES, Vector2i.ZERO)
	profile.apply_to_hero(advanced)
	var progress := profile.character("hero_warrior")
	_expect(progress.total_experience == 100 and advanced.max_hp > 0 and advanced.race_id == "human", "La experiencia o las estadísticas persistentes no se integraron al combate.")
	_expect(advanced.abilities.size() == 2, "Las habilidades aprendidas no se integraron con la unidad de combate.")

func _test_races_and_stat_calculation() -> void:
	var profile := CampaignProfile.new()
	profile.initialize_default()
	_expect(profile.catalog.races.size() == 5, "No se cargaron las cinco razas requeridas.")
	_expect(profile.catalog.professions.size() == 23, "El árbol profesional externo tiene referencias faltantes.")
	_expect(profile.catalog.abilities.size() == 12, "No se cargaron las habilidades existentes y las seis habilidades nuevas.")
	_expect(profile.catalog.races.size() == 5, "No se cargaron las cinco razas jugables.")
	_expect(profile.catalog.professions.size() >= 23, "El árbol profesional externo está incompleto.")
	var human := profile.catalog.race("human")
	var orc := profile.catalog.race("orc")
	_expect(human.allows_profession("mage") and not orc.allows_profession("mage"), "Los requisitos raciales de profesiones no se aplicaron.")
	var human_character := CharacterProgress.new()
	human_character.setup("human_test", "Humano", human, "warrior")
	var orc_character := CharacterProgress.new()
	orc_character.setup("orc_test", "Orco", orc, "warrior")
	var human_stats := StatCalculator.calculate(human_character, human, profile.catalog.profession("warrior"))
	var orc_stats := StatCalculator.calculate(orc_character, orc, profile.catalog.profession("warrior"))
	_expect(int(orc_stats.derived.max_hp) > int(human_stats.derived.max_hp), "Los modificadores raciales no alteraron las estadísticas derivadas.")
	_expect(int(human_stats.derived.speed) > int(orc_stats.derived.speed), "La especialización racial no refleja la diferencia de velocidad.")
	var repeated := StatCalculator.calculate(human_character, human, profile.catalog.profession("warrior"))
	_expect(repeated == human_stats, "El cálculo de estadísticas acumuló bonificaciones entre llamadas.")
	var equipped := StatCalculator.calculate(human_character, human, profile.catalog.profession("warrior"), {
		"attributes": {"STR": 2}, "derived": {"max_hp": 5},
	})
	_expect(int(equipped.attributes.STR) == int(human_stats.attributes.STR) + 2 and int(equipped.derived.max_hp) == int(human_stats.derived.max_hp) + 7, "El punto de extensión de bonificaciones de equipo no recalculó las estadísticas.")
	var creation_profile := CampaignProfile.new()
	creation_profile.initialize_new()
	_expect(creation_profile.create_character("dwarf_explorer", "Borin", "dwarf", "explorer") != null, "No se pudo crear un personaje con raza y profesión compatibles.")
	_expect(creation_profile.create_character("invalid_dwarf_mage", "Error", "dwarf", "mage") == null, "Se creó un personaje con una profesión racial no permitida.")

func _test_character_roster() -> void:
	var profile := CampaignProfile.new()
	profile.initialize_new()
	_expect(profile.characters.is_empty() and profile.slot_ids.is_empty() and profile.formation_ids.is_empty(), "Una partida nueva no comenzó con tres espacios vacíos.")
	_expect(not profile.validate_character_name("ab").is_empty(), "Se aceptó un nombre demasiado corto.")
	_expect(not profile.validate_character_name("nombre demasiado largo").is_empty(), "Se aceptó un nombre demasiado largo.")
	_expect(not profile.validate_character_name("Ana\nX").is_empty(), "Se aceptó un carácter de control.")
	var first := profile.create_character_auto("  Aria   Sol  ", "human", "warrior")
	_expect(first != null and first.display_name == "Aria Sol" and first.character_id == "character_001", "El primer personaje no normalizó el nombre o perdió su identificador estable.")
	_expect(profile.create_character_auto("aria sol", "elf", "mage") == null, "Se aceptó un nombre duplicado ignorando mayúsculas.")
	var second := profile.create_character_auto("Nara", "orc", "acolyte")
	var third := profile.create_character_auto("Borin", "dwarf", "explorer")
	_expect(second != null and third != null and profile.characters.size() == 3, "No se ocuparon correctamente los tres espacios.")
	_expect(profile.create_character_auto("Cuarto", "human", "archer") == null, "Se permitió crear más de tres personajes.")
	_expect(profile.toggle_formation_character(second.character_id) and profile.formation_ids.size() == 2, "No se pudo cambiar la formación seleccionada.")
	var snapshot := profile.make_snapshot()
	var restored := CampaignProfile.new()
	restored.restore(snapshot)
	_expect(restored.slot_ids == profile.slot_ids and restored.formation_ids == profile.formation_ids, "El guardado no conservó espacios y formación.")
	_expect(restored.delete_character(second.character_id) and restored.characters.size() == 2 and not restored.slot_ids.has(second.character_id), "Eliminar un personaje no liberó su espacio.")
	var legacy := CampaignProfile.new()
	legacy.initialize_default()
	var legacy_snapshot := legacy.make_snapshot()
	legacy_snapshot.erase("slot_ids")
	legacy_snapshot.erase("formation_ids")
	var migrated := CampaignProfile.new()
	migrated.restore(legacy_snapshot)
	_expect(migrated.characters.size() == 3 and migrated.formation_ids.size() == 3, "Una partida anterior no migró su formación predeterminada.")

func _test_experience_and_level_limits() -> void:
	var race := load("res://data/races/human.tres") as RaceData
	var progress := CharacterProgress.new()
	progress.setup("xp_test", "Prueba", race, "warrior")
	var multi_result := progress.gain_experience(ExperienceRules.total_xp_for_level(5) + 7)
	_expect(progress.level == 5 and int(multi_result.levels_gained) == 4, "La subida de varios niveles simultáneos falló.")
	_expect(progress.sp_available == 8 and int(multi_result.sp_gained) == 8, "Los SP no se otorgaron al subir de nivel.")
	var before_negative := progress.total_experience
	progress.gain_experience(-500)
	_expect(progress.total_experience == before_negative, "La experiencia negativa modificó el progreso.")
	progress.gain_experience(ExperienceRules.MAX_EXPERIENCE_GAIN)
	_expect(progress.level == ExperienceRules.MAX_LEVEL, "No se respetó o alcanzó el nivel máximo configurable.")
	var capped_xp := progress.total_experience
	progress.gain_experience(999999)
	_expect(progress.level == 80 and progress.total_experience == capped_xp, "La experiencia superó el límite del nivel 80.")

func _test_skill_points_and_learning() -> void:
	var profile := CampaignProfile.new()
	profile.initialize_default()
	var warrior := profile.character("hero_warrior")
	warrior.level = 5
	warrior.total_experience = ExperienceRules.total_xp_for_level(5)
	warrior.sp_available = 3
	_expect(profile.learn_ability("hero_warrior", "blade_arc"), "No se pudo aprender una habilidad con requisitos válidos.")
	_expect(warrior.sp_available == 0 and warrior.sp_spent == 3, "El gasto de SP no se registró correctamente.")
	_expect(not profile.learn_ability("hero_warrior", "blade_arc"), "Se permitió aprender una habilidad duplicada.")
	var mage_skill := profile.catalog.ability("arcane_burst")
	warrior.sp_available = 20
	_expect(not warrior.can_learn(mage_skill), "Un Guerrero pudo aprender una habilidad exclusiva de Mago.")

func _test_profession_changes() -> void:
	var profile := CampaignProfile.new()
	profile.initialize_default()
	var warrior := profile.character("hero_warrior")
	var swordsman := profile.catalog.profession("swordsman")
	warrior.level = 19
	_expect(not warrior.change_profession(swordsman), "El cambio de profesión ignoró el nivel mínimo.")
	warrior.level = 20
	_expect(warrior.change_profession(swordsman) and warrior.profession_id == "swordsman", "El cambio explícito a Espadachín falló.")
	var master := profile.catalog.profession("blade_master")
	_expect(not warrior.change_profession(master), "La segunda evolución ignoró el requisito de nivel 40.")
	warrior.level = 40
	_expect(warrior.change_profession(master), "La rama completa Guerrero → Espadachín → Maestro de Espadas no funciona.")
	_expect(warrior.profession_history == ["warrior", "swordsman", "blade_master"], "El historial de profesiones no se conservó.")

func _test_mission_objectives_and_dialogue() -> void:
	var extraction := load("res://data/missions/mission_02.tres") as MissionData
	var survival := load("res://data/missions/mission_03.tres") as MissionData
	_expect(extraction.objective_type == MissionData.ObjectiveType.REACH_CELL and extraction.objective_cell == Vector2i(11, 6), "La misión de extracción no está configurada.")
	_expect(survival.objective_type == MissionData.ObjectiveType.SURVIVE_ROUNDS and survival.survive_rounds == 5, "La misión de supervivencia no está configurada.")
	_expect(not extraction.intro_dialogue.is_empty() and not survival.victory_dialogue.is_empty(), "Faltan diálogos de campaña externos.")

func _test_save_round_trip() -> void:
	var source := {"mission_index": 1, "round": 4, "units": [{"unit_id": "hero_mage", "hp": 17}]}
	var profile := CampaignProfile.new()
	profile.initialize_new()
	profile.create_character("hero_mage", "Lyra", "elf", "mage", ["ice_lance", "paralyzing_frost"])
	var mage_progress := profile.character("hero_mage")
	mage_progress.gain_experience(ExperienceRules.total_xp_for_level(6))
	mage_progress.sp_available += 10
	profile.learn_ability("hero_mage", "arcane_burst")
	var created_character := profile.create_character_auto("Nara", "orc", "acolyte")
	source["profile"] = profile.make_snapshot()
	var restored := SaveSystem.decode_payload(SaveSystem.encode_payload(source))
	var legacy := SaveSystem.decode_payload(JSON.stringify({"version": 3, "mission_index": 0}))
	_expect(int(legacy.get("version", -1)) == SaveSystem.SAVE_VERSION, "Una partida versión 3 no fue migrada al formato actual.")
	_expect(int(restored.get("mission_index", -1)) == 1, "El guardado perdió el progreso de campaña.")
	_expect(int(restored.get("round", -1)) == 4, "El guardado perdió la ronda actual.")
	var restored_profile := CampaignProfile.new()
	restored_profile.restore(restored.profile)
	var restored_mage := restored_profile.character("hero_mage")
	_expect(restored_mage.level == 6 and restored_mage.learned_ability_ids.has("arcane_burst"), "El guardado y carga no conservaron nivel y habilidades del personaje.")
	var restored_created := restored_profile.character(created_character.character_id)
	_expect(restored_created != null and restored_created.display_name == "Nara" and restored_created.race_id == "orc", "El guardado no conservó un personaje creado por el jugador.")
	var manipulated_profile := CampaignProfile.new()
	manipulated_profile.restore({"characters": {"hero_warrior": {
		"character_id": "identificador_falso", "display_name": "", "race_id": "dwarf",
		"profession_id": "mage", "profession_history": ["mage", "inventada"],
		"base_attributes": {"STR": -500}, "learned_ability_ids": ["arcane_burst", "inventada"],
	}}})
	var sanitized := manipulated_profile.character("hero_warrior")
	_expect(sanitized.character_id == "hero_warrior" and sanitized.profession_id == "warrior", "La carga no saneó una profesión incompatible.")
	_expect(int(sanitized.base_attributes.STR) == 1 and sanitized.learned_ability_ids.is_empty(), "La carga aceptó atributos o habilidades manipulados.")
	_expect(SaveSystem.decode_payload("{archivo corrupto").is_empty(), "Un archivo corrupto fue aceptado como guardado válido.")
	var temporary_path := "res://tests/.temporary_save_test.json"
	var written := SaveSystem.save_game(source, temporary_path)
	var loaded := SaveSystem.load_game(temporary_path)
	_expect(written and int(loaded.get("round", -1)) == 4, "La persistencia real en disco no completó el ciclo guardar/cargar.")
	# Un archivo principal corrupto debe poder recuperarse desde la copia de respaldo.
	_expect(SaveSystem.save_game(source, temporary_path), "No se pudo actualizar un guardado existente con respaldo.")
	var broken := FileAccess.open(temporary_path, FileAccess.WRITE)
	if broken != null:
		broken.store_string("{corrupto")
		broken.close()
	var recovered := SaveSystem.load_game(temporary_path)
	_expect(int(recovered.get("round", -1)) == 4, "No se pudo recuperar el guardado desde el respaldo.")
	for suffix in ["", SaveSystem.BACKUP_SUFFIX, SaveSystem.TEMP_SUFFIX]:
		var candidate: String = temporary_path + str(suffix)
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))

func _test_complete_battles() -> void:
	for path in CampaignManager.MISSION_PATHS:
		var mission := load(path) as MissionData
		var result := BattleSimulator.simulate_mission(mission)
		print("SIMULACIÓN: %s · %d rondas · %d acciones" % [mission.title, int(result.rounds), int(result.actions)])
		_expect(result.finished, "La simulación completa no terminó: %s" % mission.title)
		_expect(int(result.winner) == UnitData.Team.HEROES, "La simulación no resolvió victoria heroica: %s" % mission.title)
		_expect(int(result.actions) > 0 and int(result.rounds) > 0, "La simulación no ejecutó acciones: %s" % mission.title)

func _test_main_scene() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "No se pudo cargar la escena principal.")
	if packed == null:
		return
	var scene := packed.instantiate()
	get_root().add_child(scene)
	await process_frame
	_expect(scene.get_node_or_null("IsometricGrid") != null, "La escena no contiene la cuadrícula.")
	scene.campaign.profile.initialize_new()
	scene.character_selection.configure(scene.campaign.profile)
	_expect(scene.get_node("Units").get_child_count() == 0, "Una partida nueva creó unidades antes de seleccionar personajes.")
	_expect(scene.character_selection.visible and scene.character_selection.slots_row.get_child_count() == 3, "La pantalla inicial no mostró tres espacios.")
	_expect(scene.character_selection.start_button.disabled, "Comenzar aventura se habilitó sin personajes.")
	var empty_card := scene.character_selection.slots_row.get_child(0) as CharacterSlotCard
	empty_card.empty_pressed.emit()
	_expect(scene.character_selection.creation_overlay.visible and scene.character_selection.creation_step == 0, "Presionar un espacio vacío no abrió la selección de raza.")
	var race_panel := scene.character_selection.creation_content.get_child(0) as RaceSelectionPanel
	race_panel.race_selected.emit("orc")
	scene.character_selection._next_creation_step()
	var profession_panel := scene.character_selection.creation_content.get_child(0) as ProfessionSelectionPanel
	var profession_grid := profession_panel.get_child(0) as GridContainer
	_expect(profession_grid.get_child_count() == 2, "La interfaz no filtró las profesiones reales permitidas para el Orco.")
	scene.character_selection.creation_overlay.visible = false
	var created: CharacterProgress = scene.campaign.profile.create_character_auto("Aria", "human", "mage")
	scene.character_selection.refresh()
	_expect(created != null and not scene.character_selection.start_button.disabled, "Un personaje creado no ocupó el espacio ni habilitó la aventura.")
	scene.character_selection._request_delete(created.character_id)
	_expect(scene.character_selection.delete_dialog.visible, "Eliminar no mostró una confirmación clara.")
	scene.character_selection.delete_dialog.hide()
	scene.character_selection.visible = false
	scene.get_node("Interface/BattleUI").visible = true
	scene._start_mission(0, false)
	await process_frame
	_expect(scene.hero_views.size() == 1 and scene.get_node("Units").get_child_count() == 4, "La batalla no se adaptó a una formación de un personaje.")
	_expect(scene.hero_views[0].data.unit_id == created.character_id and scene.hero_views[0].data.race_id == "human" and scene.hero_views[0].data.abilities.size() == 2, "El combate no utilizó la identidad, raza y habilidades del personaje creado.")
	var mage_view := scene.hero_views[0] as TacticalUnit
	_expect(mage_view.mage_visual != null and mage_view.mage_visual.animation == &"idle_front", "El mago humano no apareció con su AnimatedSprite2D en idle.")
	if mage_view.mage_visual != null:
		mage_view.mage_visual.facing = "right"
		mage_view.mage_visual.play_walk()
		_expect(mage_view.mage_visual.animation == &"walk_right", "No se reprodujo caminar del mago.")
		await mage_view.mage_visual.play_attack()
		await mage_view.mage_visual.play_cast()
		await mage_view.mage_visual.play_hurt()
		await mage_view.mage_visual.play_death()
		mage_view.mage_visual.play_idle()
	var ice_lance: AbilityData = scene.campaign.profile.catalog.ability("ice_lance")
	await scene._play_mage_projectile_and_impact(mage_view, scene.enemy_views[0], ice_lance)
	var second: CharacterProgress = scene.campaign.profile.create_character_auto("Nara", "orc", "acolyte")
	scene.phase = BattleController.Phase.FINISHED
	scene._start_mission(0, false)
	await process_frame
	_expect(scene.phase != BattleController.Phase.FINISHED, "Una misión nueva quedó bloqueada en estado FINISHED.")
	_expect(second != null and scene.hero_views.size() == 2, "La batalla no se adaptó a una formación de dos personajes.")
	var third: CharacterProgress = scene.campaign.profile.create_character_auto("Borin", "dwarf", "explorer")
	scene._start_mission(0, false)
	await process_frame
	_expect(third != null and scene.hero_views.size() == 3, "La batalla no se adaptó a una formación de tres personajes.")
	var battle_ui := scene.get_node_or_null("Interface/BattleUI") as BattleUI
	_expect(battle_ui != null, "La escena no contiene la interfaz de combate.")
	if battle_ui != null:
		battle_ui.show_progression(scene.campaign.profile, created.character_id, "character")
		battle_ui.show_unit(scene.hero_views[0].data)
		_expect(battle_ui.progression_overlay.visible and battle_ui.progression_content.get_child_count() > 0, "La interfaz de progresión no mostró el personaje.")
		battle_ui.hide_progression()
	scene.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
