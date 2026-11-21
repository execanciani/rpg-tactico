class_name CampaignProfile
extends RefCounted

var hero_progress: Dictionary = {}
var inventory := InventoryState.new()
var gold := 0
var completed_missions: Array[String] = []

func initialize_default() -> void:
	hero_progress = {
		"hero_warrior": {"level": 1, "xp": 0},
		"hero_mage": {"level": 1, "xp": 0},
		"hero_archer": {"level": 1, "xp": 0},
	}
	inventory.initialize_default()
	gold = 0
	completed_missions.clear()

func apply_to_hero(unit: UnitData) -> void:
	var progress: Dictionary = hero_progress.get(unit.archetype_id, {"level": 1, "xp": 0})
	unit.level = int(progress.get("level", 1))
	unit.xp = int(progress.get("xp", 0))
	unit.xp_to_next = xp_required(unit.level)
	var gained_levels := unit.level - 1
	unit.max_hp += gained_levels * 4
	unit.hp = unit.max_hp
	unit.max_mp += gained_levels * 2
	unit.mp = unit.max_mp
	unit.physical_attack += gained_levels
	unit.magical_attack += gained_levels
	unit.physical_defense += int(gained_levels / 2.0)
	unit.magical_defense += int(gained_levels / 2.0)
	inventory.apply_equipment(unit)

func award_mission(mission: MissionData, heroes: Array[UnitData]) -> Array[String]:
	var messages: Array[String] = []
	if completed_missions.has(mission.mission_id):
		return messages
	completed_missions.append(mission.mission_id)
	gold += mission.reward_gold
	for item_index in mission.reward_item_ids.size():
		var amount := 1
		if item_index < mission.reward_item_quantities.size():
			amount = mission.reward_item_quantities[item_index]
		inventory.add_item(mission.reward_item_ids[item_index], amount)
	for hero in heroes:
		var progress: Dictionary = hero_progress.get(hero.archetype_id, {"level": 1, "xp": 0})
		progress["xp"] = int(progress.get("xp", 0)) + mission.reward_xp
		var leveled := false
		while int(progress.xp) >= xp_required(int(progress.level)):
			progress["xp"] = int(progress.xp) - xp_required(int(progress.level))
			progress["level"] = int(progress.level) + 1
			leveled = true
		hero_progress[hero.archetype_id] = progress
		if leveled:
			messages.append("%s alcanzó nivel %d" % [hero.display_name, int(progress.level)])
	messages.append("Recompensa: %d XP y %d monedas" % [mission.reward_xp, mission.reward_gold])
	return messages

func xp_required(level: int) -> int:
	return 100 + (level - 1) * 40

func make_snapshot() -> Dictionary:
	return {
		"hero_progress": hero_progress.duplicate(true),
		"inventory": inventory.make_snapshot(),
		"gold": gold,
		"completed_missions": completed_missions.duplicate(),
	}

func restore(snapshot: Dictionary) -> void:
	hero_progress = snapshot.get("hero_progress", {}).duplicate(true)
	gold = int(snapshot.get("gold", 0))
	completed_missions.assign(snapshot.get("completed_missions", []))
	inventory.restore(snapshot.get("inventory", {}))
