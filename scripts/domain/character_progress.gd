class_name CharacterProgress
extends Resource

const INVENTORY_CAPACITY := 40

@export var character_id := ""
@export var display_name := ""
@export var race_id := "human"
@export var profession_id := "warrior"
@export var profession_history: Array[String] = []
@export_range(1, ExperienceRules.MAX_LEVEL) var level := 1
@export var total_experience := 0
@export var sp_available := 0
@export var sp_spent := 0
@export var base_attributes: Dictionary = {}
@export var learned_ability_ids: Array[String] = []
@export var appearance_id := "warrior"
# `inventory` se conserva como indice agregado para compatibilidad con partidas
# y llamadas antiguas. `inventory_slots` es la fuente de verdad desde fase 4.
@export var inventory: Dictionary = {}
@export var inventory_slots: Array[Dictionary] = []
@export var equipped_items: Dictionary = {}
@export var current_hp := -1
@export var current_mp := -1

func setup(id: String, name: String, selected_race: RaceData, initial_profession: String, initial_abilities: Array[String] = []) -> void:
	character_id = id
	display_name = name
	race_id = selected_race.race_id
	profession_id = initial_profession
	profession_history = [initial_profession]
	level = 1
	total_experience = 0
	sp_available = 0
	sp_spent = 0
	base_attributes = selected_race.base_attributes.duplicate(true)
	learned_ability_ids = initial_abilities.duplicate()
	appearance_id = initial_profession
	inventory.clear()
	inventory_slots.clear()
	_ensure_inventory_slots()
	equipped_items.clear()
	current_hp = -1
	current_mp = -1

func add_item(item_id: String, quantity := 1, stackable := false, max_stack := 1) -> int:
	if item_id.is_empty() or quantity <= 0:
		return maxi(0, quantity)
	_ensure_inventory_slots()
	var remaining := quantity
	var limit := maxi(1, max_stack if stackable else 1)
	if stackable:
		for slot_index in inventory_slots.size():
			var slot: Dictionary = inventory_slots[slot_index]
			if str(slot.get("item_id", "")) != item_id or int(slot.get("quantity", 0)) >= limit:
				continue
			var moved := mini(remaining, limit - int(slot.quantity))
			slot["quantity"] = int(slot.quantity) + moved
			inventory_slots[slot_index] = slot
			remaining -= moved
			if remaining <= 0:
				break
	while remaining > 0:
		var empty_index := first_empty_slot()
		if empty_index < 0:
			break
		var moved := mini(remaining, limit)
		inventory_slots[empty_index] = {
			"index": empty_index, "item_id": item_id, "quantity": moved, "state": {},
		}
		remaining -= moved
	_sync_inventory_cache()
	return remaining

func item_quantity(item_id: String) -> int:
	_ensure_inventory_slots()
	var total := 0
	for slot in inventory_slots:
		if str(slot.get("item_id", "")) == item_id:
			total += maxi(0, int(slot.get("quantity", 0)))
	return total

func occupied_slot_count() -> int:
	_ensure_inventory_slots()
	var count := 0
	for slot in inventory_slots:
		if not str(slot.get("item_id", "")).is_empty() and int(slot.get("quantity", 0)) > 0:
			count += 1
	return count

func first_empty_slot() -> int:
	_ensure_inventory_slots()
	for slot_index in inventory_slots.size():
		if str(inventory_slots[slot_index].get("item_id", "")).is_empty():
			return slot_index
	return -1

func inventory_slot(slot_index: int) -> Dictionary:
	_ensure_inventory_slots()
	if slot_index < 0 or slot_index >= INVENTORY_CAPACITY:
		return {}
	return inventory_slots[slot_index].duplicate(true)

func remove_item(item_id: String, quantity := 1) -> bool:
	if quantity <= 0 or item_quantity(item_id) < quantity:
		return false
	var remaining := quantity
	for slot_index in range(inventory_slots.size() - 1, -1, -1):
		var slot: Dictionary = inventory_slots[slot_index]
		if str(slot.get("item_id", "")) != item_id:
			continue
		var removed := mini(remaining, int(slot.get("quantity", 0)))
		slot["quantity"] = int(slot.quantity) - removed
		remaining -= removed
		inventory_slots[slot_index] = InventorySlotData.empty(slot_index) if int(slot.quantity) <= 0 else slot
		if remaining <= 0:
			break
	_sync_inventory_cache()
	return remaining == 0

func discard_from_slot(slot_index: int, quantity := 1) -> bool:
	var slot := inventory_slot(slot_index)
	if slot.is_empty() or quantity <= 0 or quantity > int(slot.get("quantity", 0)):
		return false
	var new_quantity := int(slot.quantity) - quantity
	inventory_slots[slot_index] = InventorySlotData.empty(slot_index) if new_quantity <= 0 else {
		"index": slot_index, "item_id": str(slot.item_id), "quantity": new_quantity,
		"state": slot.get("state", {}).duplicate(true),
	}
	_sync_inventory_cache()
	return true

func move_inventory_slot(from_index: int, to_index: int) -> bool:
	_ensure_inventory_slots()
	if from_index < 0 or from_index >= INVENTORY_CAPACITY or to_index < 0 or to_index >= INVENTORY_CAPACITY or from_index == to_index:
		return false
	var source: Dictionary = inventory_slots[from_index]
	if str(source.get("item_id", "")).is_empty():
		return false
	var target: Dictionary = inventory_slots[to_index]
	source["index"] = to_index
	target["index"] = from_index
	inventory_slots[to_index] = source
	inventory_slots[from_index] = target
	_sync_inventory_cache()
	return true

func split_inventory_stack(slot_index: int, quantity: int, target_index := -1) -> bool:
	var source := inventory_slot(slot_index)
	if source.is_empty() or quantity <= 0 or quantity >= int(source.get("quantity", 0)):
		return false
	if target_index < 0:
		target_index = first_empty_slot()
	if target_index < 0 or target_index >= INVENTORY_CAPACITY or not str(inventory_slots[target_index].get("item_id", "")).is_empty():
		return false
	source["quantity"] = int(source.quantity) - quantity
	inventory_slots[slot_index] = source
	inventory_slots[target_index] = {
		"index": target_index, "item_id": str(source.item_id), "quantity": quantity,
		"state": source.get("state", {}).duplicate(true),
	}
	_sync_inventory_cache()
	return true

func sort_inventory(category_by_item: Dictionary) -> void:
	_ensure_inventory_slots()
	var occupied: Array[Dictionary] = []
	for slot in inventory_slots:
		if not str(slot.get("item_id", "")).is_empty():
			occupied.append(slot.duplicate(true))
	occupied.sort_custom(func(a: Dictionary, b: Dictionary):
		var category_a := str(category_by_item.get(str(a.item_id), "zzzz"))
		var category_b := str(category_by_item.get(str(b.item_id), "zzzz"))
		return str(a.item_id) < str(b.item_id) if category_a == category_b else category_a < category_b
	)
	_reset_inventory_slots()
	for index in occupied.size():
		occupied[index]["index"] = index
		inventory_slots[index] = occupied[index]
	_sync_inventory_cache()

func equip(item: EquipmentItemData) -> bool:
	if item == null or item_quantity(item.item_id) <= 0 or not item.can_be_used_by(self):
		return false
	var slot_id := item.slot_key()
	if str(equipped_items.get(slot_id, "")) == item.item_id:
		return true
	var previous_id := str(equipped_items.get(slot_id, ""))
	# Si la pila no libera una ranura, reemplazar requiere otro espacio para no
	# perder el objeto anterior.
	if not previous_id.is_empty() and item_quantity(item.item_id) > 1 and first_empty_slot() < 0:
		return false
	if not remove_item(item.item_id, 1):
		return false
	if not previous_id.is_empty():
		if add_item(previous_id) > 0:
			add_item(item.item_id)
			return false
	equipped_items[slot_id] = item.item_id
	return true

func unequip(slot_id: String) -> bool:
	var item_id := str(equipped_items.get(slot_id, ""))
	if item_id.is_empty():
		return false
	if first_empty_slot() < 0:
		return false
	equipped_items.erase(slot_id)
	if add_item(item_id) > 0:
		equipped_items[slot_id] = item_id
		return false
	return true

func gain_experience(amount: int) -> Dictionary:
	var safe_amount := clampi(amount, 0, ExperienceRules.MAX_EXPERIENCE_GAIN)
	var old_level := level
	var old_sp := sp_available
	var old_experience := total_experience
	if level < ExperienceRules.MAX_LEVEL:
		total_experience = mini(ExperienceRules.total_xp_for_level(ExperienceRules.MAX_LEVEL), total_experience + safe_amount)
		level = ExperienceRules.level_for_total_xp(total_experience)
		for gained_level in range(old_level + 1, level + 1):
			sp_available += ExperienceRules.sp_for_level(gained_level)
	return {
		"xp_gained": total_experience - old_experience,
		"levels_gained": level - old_level,
		"sp_gained": sp_available - old_sp,
		"new_level": level,
	}

func experience_into_level() -> int:
	return maxi(0, total_experience - ExperienceRules.total_xp_for_level(level))

func experience_to_next_level() -> int:
	return ExperienceRules.xp_for_next_level(level)

func has_profession(profession: String) -> bool:
	return profession_id == profession or profession_history.has(profession)

func can_learn(ability: AbilityData) -> bool:
	if ability == null or learned_ability_ids.has(String(ability.id)):
		return false
	if level < ability.required_level or sp_available < ability.sp_cost:
		return false
	if ability.required_profession_ids.is_empty():
		return true
	return ability.required_profession_ids.any(func(required_id: String): return has_profession(required_id))

func learn_ability(ability: AbilityData) -> bool:
	if not can_learn(ability):
		return false
	sp_available -= ability.sp_cost
	sp_spent += ability.sp_cost
	learned_ability_ids.append(String(ability.id))
	return true

func can_change_profession(next_profession: ProfessionData) -> bool:
	return next_profession != null \
		and next_profession.previous_profession_id == profession_id \
		and level >= next_profession.minimum_level \
		and next_profession.allows_race(race_id)

func change_profession(next_profession: ProfessionData) -> bool:
	if not can_change_profession(next_profession):
		return false
	profession_id = next_profession.profession_id
	if not profession_history.has(profession_id):
		profession_history.append(profession_id)
	return true

func make_snapshot() -> Dictionary:
	return {
		"character_id": character_id,
		"display_name": display_name,
		"race_id": race_id,
		"profession_id": profession_id,
		"profession_history": profession_history.duplicate(),
		"level": level,
		"total_experience": total_experience,
		"sp_available": sp_available,
		"sp_spent": sp_spent,
		"base_attributes": base_attributes.duplicate(true),
		"learned_ability_ids": learned_ability_ids.duplicate(),
		"appearance_id": appearance_id,
		"inventory": inventory.duplicate(true),
		"inventory_slots": inventory_slots.duplicate(true),
		"equipped_items": equipped_items.duplicate(true),
		"current_hp": current_hp,
		"current_mp": current_mp,
	}

func restore(snapshot: Dictionary, fallback_race: RaceData) -> void:
	character_id = str(snapshot.get("character_id", character_id))
	display_name = str(snapshot.get("display_name", display_name))
	race_id = str(snapshot.get("race_id", fallback_race.race_id))
	profession_id = str(snapshot.get("profession_id", "warrior"))
	profession_history.assign(snapshot.get("profession_history", [profession_id]))
	if profession_history.is_empty():
		profession_history.append(profession_id)
	total_experience = clampi(int(snapshot.get("total_experience", 0)), 0, ExperienceRules.total_xp_for_level(ExperienceRules.MAX_LEVEL))
	level = ExperienceRules.level_for_total_xp(total_experience)
	sp_available = clampi(int(snapshot.get("sp_available", 0)), 0, 10000)
	sp_spent = clampi(int(snapshot.get("sp_spent", 0)), 0, 10000)
	base_attributes = snapshot.get("base_attributes", fallback_race.base_attributes).duplicate(true)
	learned_ability_ids.assign(snapshot.get("learned_ability_ids", []))
	appearance_id = str(snapshot.get("appearance_id", profession_id))
	inventory = snapshot.get("inventory", {}).duplicate(true)
	inventory_slots.clear()
	if snapshot.has("inventory_slots"):
		for slot_value in snapshot.get("inventory_slots", []):
			if slot_value is Dictionary:
				inventory_slots.append((slot_value as Dictionary).duplicate(true))
	_ensure_inventory_slots()
	equipped_items = snapshot.get("equipped_items", {}).duplicate(true)
	current_hp = int(snapshot.get("current_hp", -1))
	current_mp = int(snapshot.get("current_mp", -1))

func _ensure_inventory_slots() -> void:
	if inventory_slots.is_empty():
		_reset_inventory_slots()
		var legacy := inventory.duplicate(true)
		inventory.clear()
		for item_id in legacy:
			# Las partidas anteriores no guardaban limites de pila. La
			# sanitizacion del perfil reconstruye luego con la definicion real.
			var remaining := maxi(0, int(legacy[item_id]))
			while remaining > 0:
				var empty_index := first_empty_slot()
				if empty_index < 0:
					break
				inventory_slots[empty_index] = {
					"index": empty_index, "item_id": str(item_id), "quantity": remaining, "state": {},
				}
				remaining = 0
	else:
		var normalized: Array[Dictionary] = []
		for index in INVENTORY_CAPACITY:
			var value: Dictionary = inventory_slots[index] if index < inventory_slots.size() else {}
			normalized.append(InventorySlotData.normalized(value, index))
		inventory_slots = normalized
	_sync_inventory_cache()

func _reset_inventory_slots() -> void:
	inventory_slots.clear()
	for index in INVENTORY_CAPACITY:
		inventory_slots.append(InventorySlotData.empty(index))

func _sync_inventory_cache() -> void:
	inventory.clear()
	for slot in inventory_slots:
		var item_id := str(slot.get("item_id", ""))
		var quantity := maxi(0, int(slot.get("quantity", 0)))
		if not item_id.is_empty() and quantity > 0:
			inventory[item_id] = int(inventory.get(item_id, 0)) + quantity
