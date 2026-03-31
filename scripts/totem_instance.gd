class_name TotemInstance
extends RefCounted


var definition: TotemDefinition
var active_modifiers: Array[Dictionary] = []
var activation_count := 0


func _init(totem_definition: TotemDefinition) -> void:
	definition = totem_definition


func update_tick(incoming_events: Array[Dictionary], slot_index: int) -> Dictionary:
	if definition == null:
		return {}

	for event_data in incoming_events:
		if String(event_data.get("type", "")) != definition.trigger_event_type:
			continue
		if int(event_data.get("source_slot_index", -1)) == slot_index:
			continue

		activation_count += 1
		return {
			"report": {
				"type": "totem_activated",
			},
			"request": {
				"type": "apply_modifier",
				"target_rule": definition.target_rule,
				"event_source_slot_index": int(event_data.get("source_slot_index", -1)),
				"modifier": {
					"modifier_type": definition.modifier_type,
					"multiplier": definition.modifier_multiplier,
					"remaining_duration": definition.modifier_duration,
				},
			},
		}

	return {}


func apply_modifier(modifier: Dictionary) -> void:
	var modifier_type := String(modifier.get("modifier_type", ""))
	if modifier_type.is_empty():
		return

	for index in active_modifiers.size():
		if String(active_modifiers[index].get("modifier_type", "")) != modifier_type:
			continue
		active_modifiers[index] = modifier.duplicate(true)
		return

	active_modifiers.append(modifier.duplicate(true))
