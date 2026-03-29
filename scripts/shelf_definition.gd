class_name ShelfDefinition
extends Resource


@export var id := ""
@export var display_name := ""
@export_file("*.png") var texture_path := ""
@export var view_size := Vector2(700.0, 300.0)
@export var texture_position := Vector2(64.0, 198.0)
@export var texture_size := Vector2(572.0, 54.0)
@export var title_position := Vector2(0.0, 260.0)
@export var title_size := Vector2(700.0, 24.0)
@export var slot_positions: Array[Vector2] = []
