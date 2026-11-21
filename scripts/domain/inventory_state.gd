class_name InventoryState
extends RefCounted

const ITEM_PATHS: Array[String] = [
	"res://data/items/health_potion.tres",
	"res://data/items/mana_tonic.tres",
	"res://data/items/iron_sword.tres",
	"res://data/items/oak_bow.tres",
	"res://data/items/focus_staff.tres",
	"res://data/items/guard_armor.tres",
]

var catalog: Dictionary = {}
var quantities: Dictionary = {}
var equipped: Dictionary = {}

func initialize_default() -> void:
	_load_catalog()
	quantities = {
		"health_potion": 3,
		"mana_tonic": 2,
		"iron_sword": 1,
		"oak_bow": 1,
		"focus_staff": 1,
		"guard_armor": 1,
	}
	equipped = {
		"hero_warrior": {"weapon": "iron_sword", "armor": "guard_armor"},
		"hero_mage": {"weapon": "focus_staff"},
		"hero_archer": {"weapon": "oak_bow"},
	}

func ensure_catalog() -> void:
	if catalog.is_empty():
		_load_catalog()

func _load_catalog() -> void:
	catalog.clear()
	for path in ITEM_PATHS:
		var item := load(path) as ItemData
		if item != null:
			catalog[item.item_id] = item

func get_item(item_id: String) -> ItemData:
	ensure_catalog()
	return catalog.get(item_id) as ItemData

func quantity(item_id: String) -> int:
	return int(quantities.get(item_id, 0))

func add_item(item_id: String, amount := 1) -> void:
	quantities[item_id] = quantity(item_id) + amount

func consume(unit: UnitData, item_id: String) -> bool:
	var item := get_item(item_id)
	if item == null or item.type != ItemData.Type.CONSUMABLE or quantity(item_id) <= 0:
		return false
	var old_hp := unit.hp
	var old_mp := unit.mp
	unit.hp = mini(unit.max_hp, unit.hp + item.heal_hp)
	unit.mp = mini(unit.max_mp, unit.mp + item.restore_mp)
	if unit.hp == old_hp and unit.mp == old_mp:
		return false
	quantities[item_id] = quantity(item_id) - 1
	return true

func equip_item(unit: UnitData, item_id: String) -> bool:
	var item := get_item(item_id)
	if item == null or quantity(item_id) <= 0 or not item.can_equip(unit):
		return false
	var slots: Dictionary = equipped.get(unit.archetype_id, {})
	var slot := item.slot_name()
	if str(slots.get(slot, "")) == item_id:
		return true
	if _equipped_count(item_id, unit.archetype_id) >= quantity(item_id):
		return false
	if slots.has(slot):
		_apply_bonus(unit, get_item(str(slots[slot])), -1)
	slots[slot] = item_id
	equipped[unit.archetype_id] = slots
	_apply_bonus(unit, item, 1)
	unit.equipped_summary = equipment_summary(unit.archetype_id)
	return true

func apply_equipment(unit: UnitData) -> void:
	ensure_catalog()
	var slots: Dictionary = equipped.get(unit.archetype_id, {})
	for item_id in slots.values():
		_apply_bonus(unit, get_item(str(item_id)), 1)
	unit.equipped_summary = equipment_summary(unit.archetype_id)

func equipment_summary(archetype_id: String) -> String:
	var names: Array[String] = []
	var slots: Dictionary = equipped.get(archetype_id, {})
	for item_id in slots.values():
		var item := get_item(str(item_id))
		if item != null:
			names.append(item.display_name)
	return ", ".join(names) if not names.is_empty() else "Sin equipo"

func list_available_for(unit: UnitData) -> Array[Dictionary]:
	ensure_catalog()
	var result: Array[Dictionary] = []
	for item_id in catalog:
		var item: ItemData = catalog[item_id]
		if quantity(item_id) <= 0:
			continue
		if item.type != ItemData.Type.CONSUMABLE and not item.can_equip(unit):
			continue
		result.append({
			"id": item.item_id,
			"name": item.display_name,
			"description": item.description,
			"quantity": quantity(item.item_id),
			"equippable": item.type != ItemData.Type.CONSUMABLE,
		})
	return result

func make_snapshot() -> Dictionary:
	return {"quantities": quantities.duplicate(true), "equipped": equipped.duplicate(true)}

func restore(snapshot: Dictionary) -> void:
	_load_catalog()
	quantities = snapshot.get("quantities", {}).duplicate(true)
	equipped = snapshot.get("equipped", {}).duplicate(true)

func _apply_bonus(unit: UnitData, item: ItemData, multiplier: int) -> void:
	if item == null:
		return
	var previous_max_hp := unit.max_hp
	var previous_max_mp := unit.max_mp
	unit.max_hp += item.max_hp_bonus * multiplier
	unit.max_mp += item.max_mp_bonus * multiplier
	unit.physical_attack += item.physical_attack_bonus * multiplier
	unit.magical_attack += item.magical_attack_bonus * multiplier
	unit.physical_defense += item.physical_defense_bonus * multiplier
	unit.magical_defense += item.magical_defense_bonus * multiplier
	if multiplier > 0:
		unit.hp += unit.max_hp - previous_max_hp
		unit.mp += unit.max_mp - previous_max_mp
	else:
		unit.hp = mini(unit.hp, unit.max_hp)
		unit.mp = mini(unit.mp, unit.max_mp)

func _equipped_count(item_id: String, excluding_archetype := "") -> int:
	var count := 0
	for archetype_id in equipped:
		if str(archetype_id) == excluding_archetype:
			continue
		var slots: Dictionary = equipped[archetype_id]
		for equipped_id in slots.values():
			if str(equipped_id) == item_id:
				count += 1
	return count
