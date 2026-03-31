class_name PlantInstance
extends RefCounted


const MODIFIER_HASTE := "haste"


var definition: PlantDefinition
var progress_seconds := 0.0
var age_seconds := 0.0
var activation_count := 0
var active_modifiers: Array[Dictionary] = []


func _init(plant_definition: PlantDefinition) -> void:
	definition = plant_definition


func advance(delta: float) -> void:
	var resolved_delta := maxf(delta, 0.0)
	age_seconds += resolved_delta
	progress_seconds += resolved_delta


func update_tick(delta: float, context: Dictionary = {}) -> Dictionary:
	var resolved_delta := maxf(delta, 0.0)
	age_seconds += resolved_delta
	_advance_modifiers(resolved_delta)
	progress_seconds += resolved_delta * _get_speed_multiplier(context)

	var cycle_time := get_cycle_time()
	if cycle_time <= 0.0:
		return _build_activation_report()

	if progress_seconds < cycle_time:
		return {}

	progress_seconds -= cycle_time
	activation_count += 1
	return _build_activation_report()


func apply_modifier(modifier: Dictionary) -> void:
	var modifier_type := String(modifier.get("modifier_type", ""))
	if modifier_type.is_empty():
		return

	var resolved_modifier := modifier.duplicate(true)
	var existing_index := _find_modifier_index(modifier_type)
	if existing_index == -1:
		active_modifiers.append(resolved_modifier)
		return

	active_modifiers[existing_index] = resolved_modifier


func get_growth_ratio() -> float:
	if is_mature():
		return 1.0

	var cycle_time := get_cycle_time()
	if cycle_time <= 0.0:
		return 1.0

	return minf(progress_seconds / cycle_time, 1.0)


func is_mature() -> bool:
	return activation_count > 0


func get_growth_percent() -> int:
	return int(round(get_growth_ratio() * 100.0))


func get_cycle_time() -> float:
	if definition == null or definition.growth_duration <= 0.0:
		return 0.0
	return definition.growth_duration


func get_active_modifier(modifier_type: String) -> Dictionary:
	var modifier_index := _find_modifier_index(modifier_type)
	if modifier_index == -1:
		return {}
	return active_modifiers[modifier_index].duplicate(true)


func _advance_modifiers(delta: float) -> void:
	if active_modifiers.is_empty():
		return

	var next_modifiers: Array[Dictionary] = []
	for modifier in active_modifiers:
		var remaining_duration := maxf(float(modifier.get("remaining_duration", 0.0)) - delta, 0.0)
		if remaining_duration <= 0.0:
			continue

		var updated_modifier := modifier.duplicate(true)
		updated_modifier["remaining_duration"] = remaining_duration
		next_modifiers.append(updated_modifier)

	active_modifiers = next_modifiers


func _get_speed_multiplier(context: Dictionary) -> float:
	var speed_multiplier := 1.0
	speed_multiplier *= maxf(float(context.get("pot_speed_multiplier", 1.0)), 0.0)
	speed_multiplier *= maxf(float(context.get("room_speed_multiplier", 1.0)), 0.0)

	for modifier in active_modifiers:
		if String(modifier.get("modifier_type", "")) != MODIFIER_HASTE:
			continue
		speed_multiplier *= maxf(float(modifier.get("multiplier", 1.0)), 0.0)

	return speed_multiplier


func _build_activation_report() -> Dictionary:
	return {
		"type": "plant_activated",
		"reward": get_activation_reward(),
	}


func get_activation_reward() -> float:
	if definition == null:
		return 0.0
	return definition.coins_per_second * maxf(definition.growth_duration, 0.0)


func _find_modifier_index(modifier_type: String) -> int:
	for index in active_modifiers.size():
		if String(active_modifiers[index].get("modifier_type", "")) == modifier_type:
			return index
	return -1
