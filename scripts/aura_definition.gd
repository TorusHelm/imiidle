@tool
class_name AuraDefinition
extends Resource


@export_group("Identity")
@export var id := ""
@export var aura_type := ""
@export var display_name := ""
@export_multiline var description := ""

@export_group("Targeting")
@export var target_rule := "all_plants"
@export var target_actor_type := "plant"

@export_group("Effects")
@export var speed_multiplier := 1.0
@export var reward_multiplier := 1.0
@export var flat_reward_bonus := 0.0
@export var blocks_activation := false

@export_group("Visual")
@export_file("*.png") var icon_path := ""
