class_name TurnManager
extends RefCounted

var round_number := 1
var order: Array[String] = []
var acted_ids: Array[String] = []
var active_unit_id := ""

func start(units: Array[UnitData], starting_round := 1) -> void:
	round_number = maxi(1, starting_round)
	acted_ids.clear()
	_rebuild_order(units)
	active_unit_id = order[0] if not order.is_empty() else ""

func complete_active_turn(units: Array[UnitData]) -> bool:
	if not active_unit_id.is_empty() and not acted_ids.has(active_unit_id):
		acted_ids.append(active_unit_id)
	_remove_defeated(units)
	for unit_id in order:
		if not acted_ids.has(unit_id) and _is_alive(unit_id, units):
			active_unit_id = unit_id
			return false
	round_number += 1
	acted_ids.clear()
	_rebuild_order(units)
	active_unit_id = order[0] if not order.is_empty() else ""
	return true

func snapshot() -> Dictionary:
	return {
		"round": round_number,
		"order": order.duplicate(),
		"acted_ids": acted_ids.duplicate(),
		"active_unit_id": active_unit_id,
	}

func restore(data: Dictionary, units: Array[UnitData]) -> void:
	round_number = maxi(1, int(data.get("round", 1)))
	order.assign(data.get("order", []))
	acted_ids.assign(data.get("acted_ids", []))
	active_unit_id = str(data.get("active_unit_id", ""))
	_remove_defeated(units)
	if order.is_empty():
		_rebuild_order(units)
	if not _is_alive(active_unit_id, units):
		active_unit_id = ""
		for unit_id in order:
			if not acted_ids.has(unit_id) and _is_alive(unit_id, units):
				active_unit_id = unit_id
				break

func _rebuild_order(units: Array[UnitData]) -> void:
	var living: Array[UnitData] = units.filter(func(unit: UnitData): return unit.is_alive())
	living.sort_custom(func(a: UnitData, b: UnitData):
		if a.speed == b.speed:
			return a.unit_id < b.unit_id
		return a.speed > b.speed
	)
	order.clear()
	for unit in living:
		order.append(unit.unit_id)

func _remove_defeated(units: Array[UnitData]) -> void:
	var filtered: Array[String] = []
	for unit_id in order:
		if _is_alive(unit_id, units):
			filtered.append(unit_id)
	order = filtered

func _is_alive(unit_id: String, units: Array[UnitData]) -> bool:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit.is_alive()
	return false
