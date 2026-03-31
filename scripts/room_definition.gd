@tool
class_name RoomDefinition
extends Resource

const SHELF_MODEL_SCRIPT = preload("res://scripts/shelf_model.gd")

@export_group("Identity")
@export var id := ""
@export var display_name := ""

@export_group("Layout")
@export var use_slot_grid := true
@export_range(0, 32, 1) var slot_grid_columns := 2
@export_range(0, 32, 1) var slot_grid_rows := 2
@export var slot_area_origin := Vector2(120.0, 140.0)
@export var slot_area_size := Vector2(760.0, 360.0)
@export var slot_area_gap := Vector2(80.0, 60.0)
@export var slot_anchor_offset := Vector2(0.0, 0.0)
@export var slot_positions: Array[Vector2] = []


func get_slot_count() -> int:
	return get_room_model().get_slot_count()


func get_slot_positions() -> Array[Vector2]:
	return get_room_model().get_slot_positions()


func get_room_model() -> ShelfModel:
	var resolved_slot_positions := _build_slot_positions()
	if not use_slot_grid:
		return SHELF_MODEL_SCRIPT.new(
			resolved_slot_positions,
			1 if not resolved_slot_positions.is_empty() else 0,
			resolved_slot_positions.size()
		)

	return SHELF_MODEL_SCRIPT.new(
		resolved_slot_positions,
		maxi(slot_grid_rows, 0),
		maxi(slot_grid_columns, 0)
	)


func _build_slot_positions() -> Array[Vector2]:
	if not use_slot_grid:
		return slot_positions.duplicate()

	var positions: Array[Vector2] = []
	for row in maxi(slot_grid_rows, 0):
		for column in maxi(slot_grid_columns, 0):
			var slot_origin := slot_area_origin + Vector2(
				column * (slot_area_size.x + slot_area_gap.x),
				row * (slot_area_size.y + slot_area_gap.y)
			)
			positions.append(slot_origin + slot_anchor_offset)

	return positions
