@tool
class_name ModifierDefinition
extends Resource


@export_group("Identity")
@export var id := ""
@export var modifier_type := ""
@export var display_name := ""

@export_group("Timing")
@export var duration := 1.0

@export_group("Effects")
@export var multiplier := 1.0

@export_group("Visual")
@export_file("*.png") var icon_path := ""
