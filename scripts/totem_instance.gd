class_name TotemInstance
extends RefCounted

const MODIFIER_INSTANCE_SCRIPT := preload("res://scripts/modifier_instance.gd")

var definition: TotemDefinition
var active_modifiers: Array = []
var activation_count := 0


func _init(totem_definition: TotemDefinition) -> void:
	definition = totem_definition


func update_tick(delta: float, incoming_events: Array[Dictionary], slot_index: int) -> Dictionary:
	if definition == null:
		return {}

	_advance_modifiers(delta)

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
				"target_actor_type": definition.target_actor_type,
				"event_source_slot_index": int(event_data.get("source_slot_index", -1)),
				"modifier_definitions": definition.get_modifier_definitions(),
				"modifier_source": {
					"source_actor_type": "totem",
					"source_slot_index": slot_index,
				},
			},
		}

	return {}


func apply_modifier(modifier_definition: Resource, modifier_source: Dictionary = {}) -> void:
	if modifier_definition == null:
		return

	var modifier_type := String(modifier_definition.get("modifier_type"))
	if modifier_type.is_empty():
		return

	for index in active_modifiers.size():
		if active_modifiers[index].get_modifier_type() != modifier_type:
			continue
		active_modifiers[index].refresh(modifier_definition, modifier_source)
		return

	active_modifiers.append(MODIFIER_INSTANCE_SCRIPT.new(modifier_definition, modifier_source))


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
