class_name PlantDefinition
extends Resource


@export var id := ""
@export var display_name := ""
@export var growth_duration := 10.0
@export var coins_per_second := 1.0
@export var display_color := Color(1, 1, 1, 1)
@export_file("*.png") var texture_path := ""
@export var texture_offset := Vector2.ZERO
@export var texture_size := Vector2(160.0, 190.0)
