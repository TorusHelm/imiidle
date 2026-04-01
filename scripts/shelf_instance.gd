class_name ShelfInstance
extends RefCounted


var definition: ShelfDefinition
var room: RoomInstance = null
var slots: Array[SlotInstance] = []
var tick_interval := 0.15
var _tick_accumulator := 0.0
var _incoming_events: Array[Dictionary] = []
var _pending_applications: Array[Dictionary] = []
var _coins_generated := 0.0
var _visual_feedback_queue: Array[Dictionary] = []


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


func can_place_totem(slot_index: int) -> bool:
	var slot := get_slot(slot_index)
	return slot != null and slot.is_empty()


func get_slot(slot_index: int) -> SlotInstance:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]


func get_pot_in_slot(slot_index: int) -> PotInstance:
	var slot := get_slot(slot_index)
	return slot.pot if slot != null else null


func get_totem_in_slot(slot_index: int) -> TotemInstance:
	var slot := get_slot(slot_index)
	return slot.totem if slot != null else null


func tick(delta: float) -> void:
	_tick_accumulator += maxf(delta, 0.0)
	while _tick_accumulator >= tick_interval:
		_tick_accumulator -= tick_interval
		_run_tick(tick_interval)


func drain_generated_coins() -> float:
	var generated := _coins_generated
	_coins_generated = 0.0
	return generated


func drain_visual_feedback() -> Array[Dictionary]:
	var feedback := _visual_feedback_queue.duplicate(true)
	_visual_feedback_queue.clear()
	return feedback


func get_incoming_events() -> Array[Dictionary]:
	return _incoming_events.duplicate(true)


func get_pending_applications() -> Array[Dictionary]:
	return _pending_applications.duplicate(true)


func get_active_aura_snapshots_for_slot(slot_index: int) -> Array[Dictionary]:
	var target_slot := get_slot(slot_index)
	var aura_snapshots: Array[Dictionary] = []
	if target_slot == null:
		return aura_snapshots

	for source_slot in slots:
		if source_slot == null or source_slot.totem == null or source_slot.totem.definition == null:
			continue
		for aura_definition in source_slot.totem.definition.aura_definitions:
			if aura_definition == null:
				continue
			if not _aura_applies_to_slot(aura_definition, source_slot, target_slot):
				continue
			aura_snapshots.append(_build_aura_snapshot(aura_definition, source_slot))

	return aura_snapshots


func _run_tick(delta: float) -> void:
	var next_events: Array[Dictionary] = []
	var apply_reports := _apply_phase()
	for apply_report in apply_reports:
		_append_report_event(next_events, int(apply_report.get("slot_index", -1)), String(apply_report.get("source_actor_type", "")), apply_report.get("report", {}))

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
			plant_context.merge(_build_aura_context_for_slot(slot), true)
			var report: Dictionary = actor.update_tick(delta, plant_context)
			if report.is_empty():
				continue

			_append_report_event(next_events, slot.index, "plant", report)
			continue

		if actor is TotemInstance:
			var result: Dictionary = actor.update_tick(delta, _incoming_events, slot.index)
			var report_data: Dictionary = result.get("report", {})
			if not report_data.is_empty():
				_append_report_event(next_events, slot.index, "totem", report_data)

			var request_data: Dictionary = result.get("request", {})
			if request_data.is_empty():
				continue

			var resolved_targets := _resolve_targets(slot, request_data)
			for target_slot in resolved_targets:
				next_applications.append(
					{
						"type": String(request_data.get("type", "")),
						"target_slot_index": target_slot.index,
						"modifier_definitions": request_data.get("modifier_definitions", []).duplicate(),
						"instant_effect_definitions": request_data.get("instant_effect_definitions", []).duplicate(),
						"modifier_source": request_data.get("modifier_source", {}).duplicate(true),
					}
				)

	_incoming_events = next_events
	_pending_applications = next_applications


func _apply_phase() -> Array[Dictionary]:
	var apply_reports: Array[Dictionary] = []
	for application in _pending_applications:
		if String(application.get("type", "")) != "apply_effects" and String(application.get("type", "")) != "apply_modifier":
			continue

		var target_slot := get_slot(int(application.get("target_slot_index", -1)))
		if target_slot == null:
			continue

		var actor: RefCounted = target_slot.get_actor()
		if actor == null:
			continue

		var modifier_source: Dictionary = application.get("modifier_source", {})
		if actor.has_method("apply_modifier"):
			var modifier_definitions: Array = application.get("modifier_definitions", [])
			if modifier_definitions.is_empty():
				var legacy_definition = application.get("modifier_definition", null)
				if legacy_definition != null:
					modifier_definitions = [legacy_definition]
			for modifier_definition in modifier_definitions:
				if actor.has_method("can_accept_modifier") and not actor.can_accept_modifier(modifier_definition):
					continue
				actor.apply_modifier(modifier_definition, modifier_source)

		if actor.has_method("apply_instant_effect"):
			var instant_effect_definitions: Array = application.get("instant_effect_definitions", [])
			for effect_definition in instant_effect_definitions:
				if actor.has_method("can_accept_instant_effect") and not actor.can_accept_instant_effect(effect_definition):
					continue
				var report: Dictionary = actor.apply_instant_effect(effect_definition, modifier_source)
				if report.is_empty():
					continue
				apply_reports.append(
					{
						"slot_index": target_slot.index,
						"source_actor_type": _get_actor_type_name(actor),
						"report": report,
					}
				)
	return apply_reports


func _resolve_targets(source_slot: SlotInstance, request_data: Dictionary) -> Array[SlotInstance]:
	var target_rule := String(request_data.get("target_rule", ""))
	var target_actor_type := String(request_data.get("target_actor_type", "any"))
	var required_tags := _to_string_array(request_data.get("target_required_tags", []))
	var excluded_tags := _to_string_array(request_data.get("target_excluded_tags", []))
	match target_rule:
		"adjacent":
			return _filter_target_slots(_get_adjacent_slots_in_row(source_slot), target_actor_type, required_tags, excluded_tags)
		"event_source":
			return _filter_target_slots(_get_event_source_target_slots(int(request_data.get("event_source_slot_index", -1))), target_actor_type, required_tags, excluded_tags)
		"all_except_event_source":
			return _filter_target_slots(_get_all_except_event_source_slots(int(request_data.get("event_source_slot_index", -1))), target_actor_type, required_tags, excluded_tags)
		"mirror_from_source":
			return _filter_target_slots(_get_mirrored_target_slots(source_slot, int(request_data.get("event_source_slot_index", -1))), target_actor_type, required_tags, excluded_tags)
		"all_plants":
			return _filter_target_slots(slots, target_actor_type, required_tags, excluded_tags)
		"same_row_plants":
			return _filter_target_slots(_get_same_row_slots(source_slot), target_actor_type, required_tags, excluded_tags)
		"random_plant":
			return _filter_target_slots(_get_random_slot(slots), target_actor_type, required_tags, excluded_tags)
		"self":
			return _filter_target_slots([source_slot], target_actor_type, required_tags, excluded_tags)
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


func _get_event_source_target_slots(event_source_slot_index: int) -> Array[SlotInstance]:
	var event_source_slot := get_slot(event_source_slot_index)
	if event_source_slot == null:
		return []
	return [event_source_slot]


func _get_all_except_event_source_slots(event_source_slot_index: int) -> Array[SlotInstance]:
	var candidate_slots: Array[SlotInstance] = []
	for slot in slots:
		if slot.index == event_source_slot_index:
			continue
		candidate_slots.append(slot)
	return candidate_slots


func _get_same_row_slots(source_slot: SlotInstance) -> Array[SlotInstance]:
	var candidate_slots: Array[SlotInstance] = []
	if source_slot == null:
		return candidate_slots
	for slot in slots:
		if slot.row != source_slot.row:
			continue
		candidate_slots.append(slot)
	return candidate_slots


func _get_random_slot(candidate_slots: Array[SlotInstance]) -> Array[SlotInstance]:
	var valid_slots: Array[SlotInstance] = []
	for slot in candidate_slots:
		if slot == null:
			continue
		valid_slots.append(slot)
	if valid_slots.is_empty():
		return []
	return [valid_slots[randi() % valid_slots.size()]]


func _find_slot(row: int, col: int) -> SlotInstance:
	for slot in slots:
		if slot.row == row and slot.col == col:
			return slot
	return null


func _build_aura_context_for_slot(target_slot: SlotInstance) -> Dictionary:
	var context := {
		"aura_speed_multiplier": 1.0,
		"aura_reward_multiplier": 1.0,
		"aura_flat_reward_bonus": 0.0,
		"aura_blocks_activation": false,
	}

	for source_slot in slots:
		if source_slot == null or source_slot.totem == null or source_slot.totem.definition == null:
			continue
		for aura_definition in source_slot.totem.definition.aura_definitions:
			if aura_definition == null:
				continue
			if not _aura_applies_to_slot(aura_definition, source_slot, target_slot):
				continue
			context["aura_speed_multiplier"] = float(context.get("aura_speed_multiplier", 1.0)) * maxf(float(aura_definition.get("speed_multiplier")), 0.0)
			context["aura_reward_multiplier"] = float(context.get("aura_reward_multiplier", 1.0)) * maxf(float(aura_definition.get("reward_multiplier")), 0.0)
			context["aura_flat_reward_bonus"] = float(context.get("aura_flat_reward_bonus", 0.0)) + float(aura_definition.get("flat_reward_bonus"))
			if bool(aura_definition.get("blocks_activation")):
				context["aura_blocks_activation"] = true

	return context


func _aura_applies_to_slot(aura_definition: Resource, source_slot: SlotInstance, target_slot: SlotInstance) -> bool:
	if target_slot == null:
		return false
	var target_actor_type := String(aura_definition.get("target_actor_type"))
	var required_tags := _to_string_array(aura_definition.get("target_required_tags"))
	var excluded_tags := _to_string_array(aura_definition.get("target_excluded_tags"))
	if not _slot_matches_request_filters(target_slot, target_actor_type, required_tags, excluded_tags):
		return false

	match String(aura_definition.get("target_rule")):
		"all_plants":
			return true
		"self":
			return source_slot != null and source_slot.index == target_slot.index
		"adjacent":
			if source_slot == null:
				return false
			return source_slot.row == target_slot.row and absi(source_slot.col - target_slot.col) == 1
		_:
			return false


func _build_aura_snapshot(aura_definition: Resource, source_slot: SlotInstance) -> Dictionary:
	return {
		"id": String(aura_definition.get("id")),
		"aura_type": String(aura_definition.get("aura_type")),
		"display_name": String(aura_definition.get("display_name")),
		"description": String(aura_definition.get("description")),
		"speed_multiplier": float(aura_definition.get("speed_multiplier")),
		"reward_multiplier": float(aura_definition.get("reward_multiplier")),
		"flat_reward_bonus": float(aura_definition.get("flat_reward_bonus")),
		"blocks_activation": bool(aura_definition.get("blocks_activation")),
		"icon_path": String(aura_definition.get("icon_path")),
		"is_aura": true,
		"stacks": 1,
		"source": {
			"source_actor_type": "totem",
			"source_slot_index": source_slot.index,
		},
	}


func _filter_target_slots(candidate_slots: Array, target_actor_type: String, required_tags: Array[String] = [], excluded_tags: Array[String] = []) -> Array[SlotInstance]:
	var filtered_slots: Array[SlotInstance] = []
	for candidate in candidate_slots:
		var slot := candidate as SlotInstance
		if slot == null:
			continue
		if not _slot_matches_request_filters(slot, target_actor_type, required_tags, excluded_tags):
			continue
		filtered_slots.append(slot)
	return filtered_slots


func _slot_matches_request_filters(slot: SlotInstance, target_actor_type: String, required_tags: Array[String], excluded_tags: Array[String]) -> bool:
	if not _slot_matches_target_actor_type(slot, target_actor_type):
		return false
	var actor := slot.get_actor()
	if actor == null:
		return false
	if not required_tags.is_empty():
		for required_tag in required_tags:
			if not actor.has_method("has_tag") or not actor.has_tag(required_tag):
				return false
	if not excluded_tags.is_empty():
		for excluded_tag in excluded_tags:
			if actor.has_method("has_tag") and actor.has_tag(excluded_tag):
				return false
	return true


func _slot_matches_target_actor_type(slot: SlotInstance, target_actor_type: String) -> bool:
	match target_actor_type:
		"plant":
			return slot.pot != null and slot.pot.active_plant != null
		"totem":
			return slot.totem != null
		"any", "":
			return slot.get_actor() != null
		_:
			return false


func _append_report_event(next_events: Array[Dictionary], slot_index: int, actor_type: String, report_data: Dictionary) -> void:
	if report_data.is_empty():
		return
	_coins_generated += float(report_data.get("reward", 0.0))
	_enqueue_visual_feedback(slot_index, actor_type, report_data)
	next_events.append(
		{
			"type": String(report_data.get("type", "")),
			"source_slot_index": slot_index,
			"source_actor_type": actor_type,
		}
	)


func _get_actor_type_name(actor: RefCounted) -> String:
	if actor is PlantInstance:
		return "plant"
	if actor is TotemInstance:
		return "totem"
	return ""


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			var text := String(entry)
			if text.is_empty():
				continue
			result.append(text)
	return result


func _enqueue_visual_feedback(slot_index: int, actor_type: String, report_data: Dictionary) -> void:
	var reward := float(report_data.get("reward", 0.0))
	if reward <= 0.0:
		return

	_visual_feedback_queue.append(
		{
			"type": "coin_gain",
			"slot_index": slot_index,
			"source_actor_type": actor_type,
			"amount": reward,
		}
	)
