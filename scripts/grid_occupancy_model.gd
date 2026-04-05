class_name GridOccupancyModel
extends RefCounted


var columns := 0
var rows := 0

var _blocked_cells: Dictionary = {}
var _item_origins: Dictionary = {}
var _item_sizes: Dictionary = {}
var _cell_items: Dictionary = {}


func _init(column_count := 0, row_count := 0, blocked_cells: Array[Vector2i] = []) -> void:
	columns = maxi(column_count, 0)
	rows = maxi(row_count, 0)
	for blocked_cell in blocked_cells:
		_blocked_cells[_cell_key(blocked_cell)] = true


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows


func is_blocked(cell: Vector2i) -> bool:
	return _blocked_cells.has(_cell_key(cell))


func has_item(item_id: String) -> bool:
	return _item_origins.has(item_id)


func get_item_origin(item_id: String) -> Vector2i:
	return _item_origins.get(item_id, Vector2i(-1, -1))


func get_item_size(item_id: String) -> Vector2i:
	return _item_sizes.get(item_id, Vector2i.ZERO)


func get_item_at(cell: Vector2i) -> String:
	return String(_cell_items.get(_cell_key(cell), ""))


func can_place(item_id: String, origin: Vector2i, size: Vector2i, ignored_item_id := "") -> bool:
	if size.x <= 0 or size.y <= 0:
		return false

	for row in range(origin.y, origin.y + size.y):
		for column in range(origin.x, origin.x + size.x):
			var cell := Vector2i(column, row)
			if not is_in_bounds(cell) or is_blocked(cell):
				return false
			var occupant_id := get_item_at(cell)
			if occupant_id.is_empty():
				continue
			if occupant_id == item_id or occupant_id == ignored_item_id:
				continue
			return false

	return true


func place(item_id: String, origin: Vector2i, size: Vector2i) -> bool:
	if item_id.is_empty():
		return false
	if not can_place(item_id, origin, size, item_id):
		return false

	remove(item_id)
	_item_origins[item_id] = origin
	_item_sizes[item_id] = size
	_fill_cells(item_id, origin, size)
	return true


func move(item_id: String, origin: Vector2i) -> bool:
	if not has_item(item_id):
		return false
	return place(item_id, origin, get_item_size(item_id))


func remove(item_id: String) -> void:
	if not has_item(item_id):
		return

	var origin := get_item_origin(item_id)
	var size := get_item_size(item_id)
	for row in range(origin.y, origin.y + size.y):
		for column in range(origin.x, origin.x + size.x):
			var cell := Vector2i(column, row)
			if get_item_at(cell) == item_id:
				_cell_items.erase(_cell_key(cell))

	_item_origins.erase(item_id)
	_item_sizes.erase(item_id)


func get_overlapping_item_ids(origin: Vector2i, size: Vector2i, ignored_item_id := "") -> Array[String]:
	var unique_ids: Dictionary = {}
	for row in range(origin.y, origin.y + size.y):
		for column in range(origin.x, origin.x + size.x):
			var occupant_id := get_item_at(Vector2i(column, row))
			if occupant_id.is_empty() or occupant_id == ignored_item_id:
				continue
			unique_ids[occupant_id] = true

	var result: Array[String] = []
	for item_id in unique_ids.keys():
		result.append(String(item_id))
	return result


func try_swap(item_id: String, origin: Vector2i) -> bool:
	if not has_item(item_id):
		return false

	var previous_origin := get_item_origin(item_id)
	var item_size := get_item_size(item_id)
	var overlaps := get_overlapping_item_ids(origin, item_size, item_id)
	if overlaps.size() != 1:
		return false

	var other_item_id := overlaps[0]
	if not has_item(other_item_id):
		return false

	var other_origin := get_item_origin(other_item_id)
	var other_size := get_item_size(other_item_id)
	if not can_place(item_id, origin, item_size, other_item_id):
		return false
	if not can_place(other_item_id, get_item_origin(item_id), other_size, item_id):
		return false

	remove(item_id)
	remove(other_item_id)
	place(other_item_id, previous_origin, other_size)
	place(item_id, origin, item_size)
	return true


func try_move_or_swap(item_id: String, origin: Vector2i) -> bool:
	if move(item_id, origin):
		return true

	var previous_origin := get_item_origin(item_id)
	var previous_size := get_item_size(item_id)
	var overlaps := get_overlapping_item_ids(origin, previous_size, item_id)
	if overlaps.size() != 1:
		return false

	var other_item_id := overlaps[0]
	if not has_item(other_item_id):
		return false

	var other_origin := get_item_origin(other_item_id)
	var other_size := get_item_size(other_item_id)
	if not can_place(item_id, origin, previous_size, other_item_id):
		return false
	if not can_place(other_item_id, previous_origin, other_size, item_id):
		return false

	remove(item_id)
	remove(other_item_id)
	place(other_item_id, previous_origin, other_size)
	place(item_id, origin, previous_size)
	return true


func get_all_item_origins() -> Dictionary:
	return _item_origins.duplicate(true)


func _fill_cells(item_id: String, origin: Vector2i, size: Vector2i) -> void:
	for row in range(origin.y, origin.y + size.y):
		for column in range(origin.x, origin.x + size.x):
			_cell_items[_cell_key(Vector2i(column, row))] = item_id


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
