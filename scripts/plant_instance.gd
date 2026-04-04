class_name PlantInstance
extends RefCounted

const MODIFIER_INSTANCE_SCRIPT := preload("res://scripts/modifier_instance.gd")

var definition: PlantDefinition
var progress_seconds := 0.0
var age_seconds := 0.0
var activation_count := 0
var active_modifiers: Array = []


func _init(plant_definition: PlantDefinition) -> void:
	definition = plant_definition


func advance(delta: float) -> void:
	var resolved_delta := maxf(delta, 0.0)
	age_seconds += resolved_delta
	_advance_modifiers(resolved_delta)
	progress_seconds += resolved_delta * _get_speed_multiplier({})


func update_tick(delta: float, context: Dictionary = {}) -> Dictionary:
	var resolved_delta := maxf(delta, 0.0)
	age_seconds += resolved_delta
	_advance_modifiers(resolved_delta)
	if _blocks_activation(context):
		return {}
	progress_seconds += resolved_delta * _get_speed_multiplier(context)

	var cycle_time := get_cycle_time()
	if cycle_time <= 0.0:
		return _build_activation_report(context)

	if progress_seconds < cycle_time:
		return {}

	progress_seconds -= cycle_time
	activation_count += 1
	return _build_activation_report(context)


func apply_modifier(modifier_definition: Resource, modifier_source: Dictionary = {}) -> void:
	if not can_accept_modifier(modifier_definition):
		return

	var modifier_type := String(modifier_definition.get("modifier_type"))
	if modifier_type.is_empty():
		return

	var existing_index := _find_modifier_index(modifier_type)
	if existing_index == -1:
		active_modifiers.append(MODIFIER_INSTANCE_SCRIPT.new(modifier_definition, modifier_source))
		return

	active_modifiers[existing_index].refresh(modifier_definition, modifier_source)


func apply_instant_effect(effect_definition: Resource, effect_source: Dictionary = {}) -> Dictionary:
	if not can_accept_instant_effect(effect_definition):
		return {}

	match String(effect_definition.get("effect_type")):
		"charge":
			return _apply_charge_effect(effect_definition, effect_source)
		_:
			return {}


func can_accept_modifier(modifier_definition: Resource) -> bool:
	if modifier_definition == null:
		return false
	return _supports_target_actor_type(modifier_definition, "plant")


func can_accept_instant_effect(effect_definition: Resource) -> bool:
	if effect_definition == null:
		return false
	if not _supports_target_actor_type(effect_definition, "plant"):
		return false
	match String(effect_definition.get("effect_type")):
		"charge":
			return true
		_:
			return false


func get_tags() -> Array[String]:
	var tags: Array[String] = ["plant"]
	if definition == null:
		return tags
	for tag in definition.tags:
		var resolved_tag := String(tag)
		if resolved_tag.is_empty() or tags.has(resolved_tag):
			continue
		tags.append(resolved_tag)
	return tags


func has_tag(tag: String) -> bool:
	return get_tags().has(tag)


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


func get_active_modifier(modifier_type: String) -> Variant:
	var modifier_index := _find_modifier_index(modifier_type)
	if modifier_index == -1:
		return null
	return active_modifiers[modifier_index]


func _advance_modifiers(delta: float) -> void:
	if active_modifiers.is_empty():
		return

	var next_active_modifiers: Array = []
	for modifier in active_modifiers:
		modifier.advance(delta)
		if modifier.is_expired():
			continue
		next_active_modifiers.append(modifier)

	active_modifiers = next_active_modifiers


func _get_speed_multiplier(context: Dictionary) -> float:
	var speed_multiplier := 1.0
	speed_multiplier *= maxf(float(context.get("pot_speed_multiplier", 1.0)), 0.0)
	speed_multiplier *= maxf(float(context.get("room_speed_multiplier", 1.0)), 0.0)
	speed_multiplier *= maxf(float(context.get("aura_speed_multiplier", 1.0)), 0.0)

	for modifier in active_modifiers:
		speed_multiplier *= maxf(modifier.get_speed_multiplier(), 0.0)

	return speed_multiplier


func _get_reward_multiplier(context: Dictionary = {}) -> float:
	var reward_multiplier := maxf(float(context.get("aura_reward_multiplier", 1.0)), 0.0)
	for modifier in active_modifiers:
		reward_multiplier *= maxf(modifier.get_reward_multiplier(), 0.0)
	return reward_multiplier


func _get_flat_reward_bonus(context: Dictionary = {}) -> float:
	var flat_reward_bonus := float(context.get("aura_flat_reward_bonus", 0.0))
	for modifier in active_modifiers:
		flat_reward_bonus += modifier.get_flat_reward_bonus()
	return flat_reward_bonus


func _blocks_activation(context: Dictionary = {}) -> bool:
	if bool(context.get("aura_blocks_activation", false)):
		return true
	for modifier in active_modifiers:
		if modifier.blocks_activation():
			return true
	return false


func _build_activation_report(context: Dictionary = {}) -> Dictionary:
	return {
		"type": "plant_activated",
		"reward": get_activation_reward(context),
	}


func get_activation_reward(context: Dictionary = {}) -> float:
	if definition == null:
		return 0.0
	var base_reward := definition.coins_per_second * maxf(definition.growth_duration, 0.0)
	var modified_reward := base_reward * _get_reward_multiplier(context)
	modified_reward += _get_flat_reward_bonus(context)
	return maxf(modified_reward, 0.0)


func _find_modifier_index(modifier_type: String) -> int:
	for index in active_modifiers.size():
		if active_modifiers[index].get_modifier_type() == modifier_type:
			return index
	return -1


func _supports_target_actor_type(effect_definition: Resource, actor_type: String) -> bool:
	if effect_definition == null:
		return false
	var supported_actor_types_variant = effect_definition.get("supported_target_actor_types")
	var supported_actor_types: Array = supported_actor_types_variant if supported_actor_types_variant is Array else []
	if supported_actor_types.is_empty():
		return true
	for supported_actor_type in supported_actor_types:
		if String(supported_actor_type) == actor_type:
			return true
	return false


func _apply_charge_effect(effect_definition: Resource, _effect_source: Dictionary = {}) -> Dictionary:
	var added_seconds_value = effect_definition.get("progress_seconds_delta")
	var added_seconds := maxf(float(added_seconds_value if added_seconds_value != null else 0.0), 0.0)
	var effect_context: Dictionary = _effect_source.get("effect_context", {})
	if added_seconds <= 0.0:
		return {}

	progress_seconds += added_seconds
	var cycle_time := get_cycle_time()
	if cycle_time <= 0.0 or progress_seconds < cycle_time:
		return {}

	activation_count += 1
	if bool(effect_definition.get("reset_progress_on_activation")):
		progress_seconds = 0.0
	else:
		progress_seconds = maxf(progress_seconds - cycle_time, 0.0)

	return _build_activation_report(effect_context)
