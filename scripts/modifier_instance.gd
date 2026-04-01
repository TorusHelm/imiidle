class_name ModifierInstance
extends RefCounted


var definition: Resource
var source: Dictionary = {}
var remaining_time := 0.0


func _init(modifier_definition: Resource = null, modifier_source: Dictionary = {}) -> void:
	definition = modifier_definition
	source = modifier_source.duplicate(true)
	remaining_time = _get_default_duration()


func refresh(modifier_definition: Resource = null, modifier_source: Dictionary = {}) -> void:
	if modifier_definition != null:
		definition = modifier_definition
	source = modifier_source.duplicate(true)
	remaining_time = _get_default_duration()


func advance(delta: float) -> void:
	remaining_time = maxf(remaining_time - maxf(delta, 0.0), 0.0)


func is_expired() -> bool:
	return remaining_time <= 0.0


func get_modifier_type() -> String:
	if definition == null:
		return ""
	return String(definition.get("modifier_type"))


func get_display_name() -> String:
	if definition == null:
		return ""
	var display_name := String(definition.get("display_name"))
	if not display_name.is_empty():
		return display_name
	return get_modifier_type().capitalize()


func get_multiplier() -> float:
	if definition == null:
		return 1.0
	var value = definition.get("multiplier")
	return float(value if value != null else 1.0)


func get_icon_path() -> String:
	if definition == null:
		return ""
	return String(definition.get("icon_path"))


func to_snapshot() -> Dictionary:
	var definition_id := ""
	if definition != null:
		definition_id = String(definition.get("id"))
	return {
		"id": definition_id,
		"modifier_type": get_modifier_type(),
		"display_name": get_display_name(),
		"multiplier": get_multiplier(),
		"remaining_duration": remaining_time,
		"icon_path": get_icon_path(),
		"source": source.duplicate(true),
	}


func _get_default_duration() -> float:
	if definition == null:
		return 0.0
	var value = definition.get("duration")
	return maxf(float(value if value != null else 0.0), 0.0)
