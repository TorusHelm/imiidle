class_name ShelfModel
extends RefCounted


var rows := 0
var cols := 0
var slots: Array[Dictionary] = []


func _init(slot_positions: Array[Vector2] = [], row_count := 0, column_count := 0) -> void:
	var resolved_slot_positions := slot_positions.duplicate()
	var resolved_rows := maxi(row_count, 0)
	var resolved_cols := maxi(column_count, 0)

	if resolved_slot_positions.is_empty():
		rows = 0
		cols = 0
		return

	if resolved_rows <= 0 or resolved_cols <= 0:
		resolved_rows = 1
		resolved_cols = resolved_slot_positions.size()

	rows = resolved_rows
	cols = resolved_cols

	for index in resolved_slot_positions.size():
		var column := index % cols
		var row := int(index / float(cols))
		slots.append(
			{
				"index": index,
				"row": row,
				"col": column,
				"position": resolved_slot_positions[index],
			}
		)


func get_slot_count() -> int:
	return slots.size()


func get_slot_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for slot in slots:
		positions.append(slot["position"])
	return positions


func get_index(row: int, col: int) -> int:
	if not is_in_bounds(row, col):
		return -1

	var index := row * cols + col
	return index if index < slots.size() else -1


func is_in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < rows and col >= 0 and col < cols


func get_slot(row: int, col: int) -> Dictionary:
	return get_slot_by_index(get_index(row, col))


func get_slot_by_index(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	return slots[index].duplicate(true)


func get_slot_position_by_index(index: int) -> Vector2:
	var slot := get_slot_by_index(index)
	return slot.get("position", Vector2.ZERO)


func get_adjacent_slots_in_row(row: int, col: int) -> Array[Dictionary]:
	var neighbors: Array[Dictionary] = []

	for col_offset in [-1, 1]:
		var neighbor_slot := get_slot(row, col + col_offset)
		if neighbor_slot.is_empty():
			continue
		neighbors.append(neighbor_slot)

	return neighbors
