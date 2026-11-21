class_name InventorySlotData
extends RefCounted

var index := -1
var item_id := ""
var quantity := 0
var state: Dictionary = {}

static func empty(slot_index: int) -> Dictionary:
	return {"index": slot_index, "item_id": "", "quantity": 0, "state": {}}

static func normalized(value: Dictionary, slot_index: int) -> Dictionary:
	var item := str(value.get("item_id", ""))
	var amount := maxi(0, int(value.get("quantity", 0)))
	if item.is_empty() or amount <= 0:
		return empty(slot_index)
	var raw_state: Variant = value.get("state", {})
	var clean_state: Dictionary = raw_state.duplicate(true) if raw_state is Dictionary else {}
	return {
		"index": slot_index,
		"item_id": item,
		"quantity": amount,
		"state": clean_state,
	}
