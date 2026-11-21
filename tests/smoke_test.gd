extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pathfinding()
	_test_combat_rules()
	_test_structured_command()
	_test_external_resources()
	_test_height_and_line_of_sight()
	_test_inventory_and_equipment()
	_test_status_effects()
	_test_turn_order()
	_test_abilities_and_cooldowns()
	_test_death_and_outcome()
	_test_campaign_progression()
	_test_mission_objectives_and_dialogue()
	_test_save_round_trip()
	_test_complete_battles()
	await _test_main_scene()
	if failures.is_empty():
		print("SMOKE TEST OK: rutas, reglas, comandos y escena principal")
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

func _test_height_and_line_of_sight() -> void:
	var heights := {Vector2i(1, 0): 2, Vector2i(0, 1): 1}
	var occupied := {Vector2i.ZERO: true}
	var reachable := GridPathfinder.reachable_cells(Vector2i.ZERO, 4, Vector2i(4, 4), {}, occupied, heights, 1)
	_expect(not reachable.has(Vector2i(1, 0)), "Una unidad escaló más niveles que su límite.")
	_expect(reachable.has(Vector2i(0, 1)), "Una subida válida quedó fuera del movimiento.")
	_expect(not CombatRules.has_line_of_sight(Vector2i.ZERO, Vector2i(0, 3), {}, {Vector2i(0, 1): true}), "Un obstáculo no bloqueó la línea de visión.")
	_expect(CombatRules.has_line_of_sight(Vector2i.ZERO, Vector2i(0, 3), {}, {}), "Una línea de visión despejada fue rechazada.")

func _test_inventory_and_equipment() -> void:
	var inventory := InventoryState.new()
	inventory.initialize_default()
	var archetype := load("res://data/archetypes/hero_warrior.tres") as UnitArchetype
	var warrior := archetype.instantiate("hero_warrior", UnitData.Team.HEROES, Vector2i.ZERO)
	inventory.apply_equipment(warrior)
	_expect(warrior.physical_attack == 17 and warrior.max_hp == 54, "El equipo inicial no aplicó sus bonificaciones.")
	warrior.hp = 20
	var previous_quantity := inventory.quantity("health_potion")
	_expect(inventory.consume(warrior, "health_potion"), "No se pudo consumir una poción válida.")
	_expect(warrior.hp == 38 and inventory.quantity("health_potion") == previous_quantity - 1, "El consumible no restauró HP o no descontó inventario.")
	var archer_archetype := load("res://data/archetypes/hero_archer.tres") as UnitArchetype
	var archer := archer_archetype.instantiate("hero_archer", UnitData.Team.HEROES, Vector2i.ZERO)
	_expect(not inventory.equip_item(archer, "guard_armor"), "Una única armadura pudo equiparse simultáneamente en dos héroes.")

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
	_expect(advanced.level == 2 and advanced.max_hp == 58, "La experiencia o el equipo persistente no produjeron estadísticas válidas.")
	_expect(profile.gold == 65, "Las recompensas monetarias no persistieron.")

func _test_mission_objectives_and_dialogue() -> void:
	var extraction := load("res://data/missions/mission_02.tres") as MissionData
	var survival := load("res://data/missions/mission_03.tres") as MissionData
	_expect(extraction.objective_type == MissionData.ObjectiveType.REACH_CELL and extraction.objective_cell == Vector2i(11, 6), "La misión de extracción no está configurada.")
	_expect(survival.objective_type == MissionData.ObjectiveType.SURVIVE_ROUNDS and survival.survive_rounds == 5, "La misión de supervivencia no está configurada.")
	_expect(not extraction.intro_dialogue.is_empty() and not survival.victory_dialogue.is_empty(), "Faltan diálogos de campaña externos.")

func _test_save_round_trip() -> void:
	var source := {"mission_index": 1, "round": 4, "units": [{"unit_id": "hero_mage", "hp": 17}]}
	var profile := CampaignProfile.new()
	profile.initialize_default()
	source["profile"] = profile.make_snapshot()
	var restored := SaveSystem.decode_payload(SaveSystem.encode_payload(source))
	var legacy := SaveSystem.decode_payload(JSON.stringify({"version": 3, "mission_index": 0}))
	_expect(int(legacy.get("version", -1)) == SaveSystem.SAVE_VERSION, "Una partida versión 3 no fue migrada al formato actual.")
	_expect(int(restored.get("mission_index", -1)) == 1, "El guardado perdió el progreso de campaña.")
	_expect(int(restored.get("round", -1)) == 4, "El guardado perdió la ronda actual.")
	var temporary_path := "res://tests/.temporary_save_test.json"
	var written := SaveSystem.save_game(source, temporary_path)
	var loaded := SaveSystem.load_game(temporary_path)
	_expect(written and int(loaded.get("round", -1)) == 4, "La persistencia real en disco no completó el ciclo guardar/cargar.")
	if FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))

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
	_expect(scene.get_node("Units").get_child_count() == 6, "La escena no creó las seis unidades requeridas.")
	_expect(scene.get_node_or_null("Interface/BattleUI") != null, "La escena no contiene la interfaz de combate.")
	scene.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
