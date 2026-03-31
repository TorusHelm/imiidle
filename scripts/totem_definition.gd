class_name TotemDefinition
extends Resource


@export_group("Identity")
@export var id := ""
@export var display_name := ""

@export_group("Reaction")
@export var trigger_event_type := "plant_activated"
@export var target_rule := "mirror_from_source"
@export var modifier_type := "haste"
@export var modifier_multiplier := 2.0
@export var modifier_duration := 1.0
