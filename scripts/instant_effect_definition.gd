@tool
class_name InstantEffectDefinition
extends Resource


@export_group("Identity")
@export var id := ""
@export var effect_type := ""
@export var display_name := ""
@export_multiline var description := ""

@export_group("Targeting")
@export var supported_target_actor_types: Array[String] = []

@export_group("Payload")
@export var progress_seconds_delta := 0.0
@export var reset_progress_on_activation := false

@export_group("Visual")
@export_file("*.png") var icon_path := ""
