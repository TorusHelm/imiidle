@tool
class_name RoomDefinition
extends Resource

const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")
const SHELF_MODEL_SCRIPT = preload("res://scripts/shelf_model.gd")

@export_group("Identity")
@export var id := ""
@export var display_name := ""

@export_group("Layout")
@export var slot_layout: SlotLayout
@export var use_slot_grid := true
@export_range(0, 32, 1) var slot_grid_columns := 2
@export_range(0, 32, 1) var slot_grid_rows := 2
@export var slot_area_origin := Vector2(120.0, 140.0)
@export var slot_area_size := Vector2(170.0, 280.0)
@export var slot_area_gap := Vector2.ZERO
@export var slot_anchor_offset := Vector2(0.0, 0.0)
@export var excluded_grid_origin := Vector2i(-1, -1)
@export var excluded_grid_size := Vector2i.ZERO
@export var slot_positions: Array[Vector2] = []


func get_slot_count() -> int:
	return get_slot_cells().size()


func get_slot_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for slot_cell in get_slot_cells():
		positions.append(slot_cell.get("position", Vector2.ZERO))
	return positions


func get_slot_cells() -> Array[Dictionary]:
	return _build_slot_cells()


func get_slot_cell(slot_index: int) -> Dictionary:
	var slot_cells := get_slot_cells()
	if slot_index < 0 or slot_index >= slot_cells.size():
		return {}
	return slot_cells[slot_index].duplicate(true)


func get_slot_index_at_grid_cell(row: int, column: int) -> int:
	for slot_cell in get_slot_cells():
		if int(slot_cell.get("row", -1)) == row and int(slot_cell.get("col", -1)) == column:
			return int(slot_cell.get("index", -1))
	return -1


func get_grid_cell_position(row: int, column: int) -> Vector2:
	for slot_cell in get_slot_cells():
		if int(slot_cell.get("row", -1)) == row and int(slot_cell.get("col", -1)) == column:
			return slot_cell.get("position", Vector2.ZERO)
	return Vector2.ZERO


func get_blocked_grid_cells() -> Array[Vector2i]:
	var blocked_cells: Array[Vector2i] = []
	if not use_slot_grid:
		return blocked_cells
	for row in maxi(slot_grid_rows, 0):
		for column in maxi(slot_grid_columns, 0):
			if not _is_excluded_grid_cell(row, column):
				continue
			blocked_cells.append(Vector2i(column, row))
	return blocked_cells


func is_valid_grid_cell(row: int, column: int) -> bool:
	if not use_slot_grid:
		return column == 0 and row >= 0 and row < slot_positions.size()
	if row < 0 or row >= maxi(slot_grid_rows, 0):
		return false
	if column < 0 or column >= maxi(slot_grid_columns, 0):
		return false
	return not _is_excluded_grid_cell(row, column)


func get_slot_layout() -> SlotLayout:
	return slot_layout if slot_layout != null else DEFAULT_SLOT_LAYOUT


func get_slot_area_size() -> Vector2:
	if slot_layout != null:
		return slot_layout.slot_area_size
	if slot_area_size != Vector2(170.0, 280.0):
		return slot_area_size
	return get_slot_layout().slot_area_size


func get_room_model() -> ShelfModel:
	var resolved_slot_positions := get_slot_positions()
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
	var positions: Array[Vector2] = []
	for slot_cell in _build_slot_cells():
		positions.append(slot_cell.get("position", Vector2.ZERO))
	return positions


func _build_slot_cells() -> Array[Dictionary]:
	if not use_slot_grid:
		var manual_cells: Array[Dictionary] = []
		for index in slot_positions.size():
			manual_cells.append(
				{
					"index": index,
					"row": index,
					"col": 0,
					"position": slot_positions[index],
				}
			)
		return manual_cells

	var slot_cells: Array[Dictionary] = []
	var resolved_slot_area_size := get_slot_area_size()
	var slot_index := 0
	for row in maxi(slot_grid_rows, 0):
		for column in maxi(slot_grid_columns, 0):
			if _is_excluded_grid_cell(row, column):
				continue
			var slot_origin := slot_area_origin + Vector2(
				column * (resolved_slot_area_size.x + slot_area_gap.x),
				row * (resolved_slot_area_size.y + slot_area_gap.y)
			)
			slot_cells.append(
				{
					"index": slot_index,
					"row": row,
					"col": column,
					"position": slot_origin + slot_anchor_offset,
				}
			)
			slot_index += 1

	return slot_cells


func _is_excluded_grid_cell(row: int, column: int) -> bool:
	if excluded_grid_size.x <= 0 or excluded_grid_size.y <= 0:
		return false
	if excluded_grid_origin.x < 0 or excluded_grid_origin.y < 0:
		return false
	return (
		column >= excluded_grid_origin.x
		and column < excluded_grid_origin.x + excluded_grid_size.x
		and row >= excluded_grid_origin.y
		and row < excluded_grid_origin.y + excluded_grid_size.y
	)
