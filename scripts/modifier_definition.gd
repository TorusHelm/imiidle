@tool
class_name ModifierDefinition
extends Resource


@export_group("Identity")
@export var id := ""
@export var modifier_type := ""
@export var display_name := ""
@export_multiline var description := ""

@export_group("Timing")
@export var duration := 1.0

@export_group("Effects")
@export var supported_target_actor_types: Array[String] = []
@export var speed_multiplier := 1.0
@export var reward_multiplier := 1.0
@export var flat_reward_bonus := 0.0
@export var blocks_activation := false

@export_group("Visual")
@export_file("*.png") var icon_path := ""
