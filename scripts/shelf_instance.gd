class_name ShelfInstance
extends RefCounted


var definition: ShelfDefinition
var room: RoomInstance = null
var slots: Array[SlotInstance] = []
var tick_interval := 0.1
var _tick_accumulator := 0.0
var _incoming_events: Array[Dictionary] = []
var _pending_applications: Array[Dictionary] = []
var _coins_generated := 0.0


func _init(shelf_definition: ShelfDefinition, room_instance: RoomInstance = null) -> void:
	definition = shelf_definition
	room = room_instance

	if definition == null:
		return

	var shelf_model: ShelfModel = definition.get_shelf_model()
	for slot_data in shelf_model.slots:
		slots.append(SlotInstance.new(slot_data))


func can_place_pot(slot_index: int) -> bool:
	var slot := get_slot(slot_index)
	return slot != null and slot.is_empty()


func place_pot(slot_index: int, pot_definition: PotDefinition) -> bool:
	var slot := get_slot(slot_index)
	if slot == null or not slot.is_empty() or pot_definition == null:
		return false

	slot.pot = PotInstance.new(pot_definition)
	return true


func can_plant_seed(slot_index: int) -> bool:
	var slot := get_slot(slot_index)
	return slot != null and slot.pot != null and slot.pot.active_plant == null


func plant_seed(slot_index: int, plant_definition: PlantDefinition) -> bool:
	var slot := get_slot(slot_index)
	if slot == null or slot.pot == null or slot.pot.active_plant != null or plant_definition == null:
		return false

	slot.pot.active_plant = PlantInstance.new(plant_definition)
	return true


func place_totem(slot_index: int, totem: TotemInstance) -> bool:
	var slot := get_slot(slot_index)
	if slot == null or not slot.is_empty() or totem == null:
		return false

	slot.totem = totem
	return true


func get_slot(slot_index: int) -> SlotInstance:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]


func get_pot_in_slot(slot_index: int) -> PotInstance:
	var slot := get_slot(slot_index)
	return slot.pot if slot != null else null


func tick(delta: float) -> void:
	_tick_accumulator += maxf(delta, 0.0)
	while _tick_accumulator >= tick_interval:
		_tick_accumulator -= tick_interval
		_run_tick(tick_interval)


func drain_generated_coins() -> float:
	var generated := _coins_generated
	_coins_generated = 0.0
	return generated


func get_incoming_events() -> Array[Dictionary]:
	return _incoming_events.duplicate(true)


func get_pending_applications() -> Array[Dictionary]:
	return _pending_applications.duplicate(true)


func _run_tick(delta: float) -> void:
	_apply_phase()

	var next_events: Array[Dictionary] = []
	var next_applications: Array[Dictionary] = []

	for slot in slots:
		var actor: RefCounted = slot.get_actor()
		if actor == null:
			continue

		if actor is PlantInstance:
			var plant_context := {
				"pot_speed_multiplier": 1.0,
				"room_speed_multiplier": room.room_speed_multiplier if room != null else 1.0,
			}
			var report: Dictionary = actor.update_tick(delta, plant_context)
			if report.is_empty():
				continue

			_coins_generated += float(report.get("reward", 0.0))
			next_events.append(
				{
					"type": String(report.get("type", "")),
					"source_slot_index": slot.index,
					"source_actor_type": "plant",
				}
			)
			continue

		if actor is TotemInstance:
			var result: Dictionary = actor.update_tick(_incoming_events, slot.index)
			var report_data: Dictionary = result.get("report", {})
			if not report_data.is_empty():
				next_events.append(
					{
						"type": String(report_data.get("type", "")),
						"source_slot_index": slot.index,
						"source_actor_type": "totem",
					}
				)

			var request_data: Dictionary = result.get("request", {})
			if request_data.is_empty():
				continue

			var resolved_targets := _resolve_targets(slot, request_data)
			for target_slot in resolved_targets:
				next_applications.append(
					{
						"type": String(request_data.get("type", "")),
						"target_slot_index": target_slot.index,
						"modifier": request_data.get("modifier", {}).duplicate(true),
					}
				)

	_incoming_events = next_events
	_pending_applications = next_applications


func _apply_phase() -> void:
	for application in _pending_applications:
		if String(application.get("type", "")) != "apply_modifier":
			continue

		var target_slot := get_slot(int(application.get("target_slot_index", -1)))
		if target_slot == null:
			continue

		var actor: RefCounted = target_slot.get_actor()
		if actor == null:
			continue

		if actor.has_method("apply_modifier"):
			actor.apply_modifier(application.get("modifier", {}))


func _resolve_targets(source_slot: SlotInstance, request_data: Dictionary) -> Array[SlotInstance]:
	var target_rule := String(request_data.get("target_rule", ""))
	match target_rule:
		"adjacent":
			return _get_adjacent_slots_in_row(source_slot)
		"mirror_from_source":
			return _get_mirrored_target_slots(source_slot, int(request_data.get("event_source_slot_index", -1)))
		"self":
			return [source_slot]
		_:
			return []


func _get_adjacent_slots_in_row(source_slot: SlotInstance) -> Array[SlotInstance]:
	var targets: Array[SlotInstance] = []
	for col_offset in [-1, 1]:
		var target_slot := _find_slot(source_slot.row, source_slot.col + col_offset)
		if target_slot == null or target_slot.get_actor() == null:
			continue
		targets.append(target_slot)
	return targets


func _get_mirrored_target_slots(source_slot: SlotInstance, event_source_slot_index: int) -> Array[SlotInstance]:
	var event_source_slot := get_slot(event_source_slot_index)
	if event_source_slot == null:
		return []
	if event_source_slot.row != source_slot.row:
		return []

	var mirrored_col := source_slot.col + (source_slot.col - event_source_slot.col)
	var mirrored_slot := _find_slot(source_slot.row, mirrored_col)
	if mirrored_slot == null or mirrored_slot.index == source_slot.index:
		return []
	if mirrored_slot.get_actor() == null:
		return []
	return [mirrored_slot]


func _find_slot(row: int, col: int) -> SlotInstance:
	for slot in slots:
		if slot.row == row and slot.col == col:
			return slot
	return null
