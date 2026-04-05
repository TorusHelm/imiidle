class_name RoomInstance
extends RefCounted

const GRID_OCCUPANCY_MODEL_SCRIPT = preload("res://scripts/grid_occupancy_model.gd")

var shelf_slots: Array = []
var room_speed_multiplier := 1.0
var definition: RoomDefinition = null
var _grid = null
var _item_id_by_anchor_slot: Dictionary = {}
var _anchor_slot_by_item_id: Dictionary = {}
var _shelf_by_item_id: Dictionary = {}
var _anchor_slot_by_occupied_slot: Array[int] = []


func _init(room_definition: RoomDefinition = null) -> void:
	setup(room_definition)


func setup(room_definition: RoomDefinition = null) -> void:
	definition = room_definition
	var resolved_count := definition.get_slot_count() if definition != null else 1
	shelf_slots.resize(resolved_count)
	_anchor_slot_by_occupied_slot.resize(resolved_count)
	for index in range(shelf_slots.size()):
		shelf_slots[index] = null
		_anchor_slot_by_occupied_slot[index] = -1
	_item_id_by_anchor_slot.clear()
	_anchor_slot_by_item_id.clear()
	_shelf_by_item_id.clear()
	var blocked_cells: Array[Vector2i] = []
	var columns: int = 1
	var rows: int = max(resolved_count, 1)
	if definition != null and definition.use_slot_grid:
		blocked_cells = definition.get_blocked_grid_cells()
		columns = maxi(definition.slot_grid_columns, 0)
		rows = maxi(definition.slot_grid_rows, 0)
	_grid = GRID_OCCUPANCY_MODEL_SCRIPT.new(columns, rows, blocked_cells)


func can_place_shelf(slot_index := 0, shelf_or_definition: Variant = null) -> bool:
	var slot_cell := _get_slot_cell(slot_index)
	if slot_cell.is_empty():
		return false
	var footprint := _get_shelf_footprint(shelf_or_definition)
	return _grid.can_place("", Vector2i(int(slot_cell.get("col", -1)), int(slot_cell.get("row", -1))), footprint)


func place_shelf(slot_index: int, shelf: ShelfInstance) -> bool:
	var slot_cell := _get_slot_cell(slot_index)
	if slot_cell.is_empty() or shelf == null:
		return false
	var item_id := _get_item_id_for_shelf(shelf)
	if not _grid.place(item_id, Vector2i(int(slot_cell.get("col", -1)), int(slot_cell.get("row", -1))), _get_shelf_footprint(shelf)):
		return false

	shelf.room = self
	_shelf_by_item_id[item_id] = shelf
	_anchor_slot_by_item_id[item_id] = slot_index
	_item_id_by_anchor_slot[slot_index] = item_id
	_sync_shelf_slots()
	return true


func get_shelf(slot_index := 0) -> ShelfInstance:
	if slot_index < 0 or slot_index >= shelf_slots.size():
		return null
	return shelf_slots[slot_index]


func move_shelf(from_anchor_slot_index: int, to_anchor_slot_index: int) -> bool:
	if not can_move_shelf(from_anchor_slot_index, to_anchor_slot_index):
		return false

	var item_id := String(_item_id_by_anchor_slot.get(from_anchor_slot_index, ""))
	var target_slot_cell := _get_slot_cell(to_anchor_slot_index)
	if not _grid.move(item_id, Vector2i(int(target_slot_cell.get("col", -1)), int(target_slot_cell.get("row", -1)))):
		return false

	_item_id_by_anchor_slot.erase(from_anchor_slot_index)
	_item_id_by_anchor_slot[to_anchor_slot_index] = item_id
	_anchor_slot_by_item_id[item_id] = to_anchor_slot_index
	_sync_shelf_slots()
	return true


func can_move_shelf(from_anchor_slot_index: int, to_anchor_slot_index: int) -> bool:
	if not is_shelf_anchor(from_anchor_slot_index):
		return false

	var target_slot_cell := _get_slot_cell(to_anchor_slot_index)
	if target_slot_cell.is_empty():
		return false

	var item_id := String(_item_id_by_anchor_slot.get(from_anchor_slot_index, ""))
	if item_id.is_empty():
		return false

	return _grid.can_place(item_id, Vector2i(int(target_slot_cell.get("col", -1)), int(target_slot_cell.get("row", -1))), _grid.get_item_size(item_id), item_id)


func remove_shelf(anchor_slot_index: int) -> ShelfInstance:
	if not is_shelf_anchor(anchor_slot_index):
		return null

	var item_id := String(_item_id_by_anchor_slot.get(anchor_slot_index, ""))
	var shelf: ShelfInstance = _shelf_by_item_id.get(item_id, null)
	if item_id.is_empty() or shelf == null:
		return null

	_grid.remove(item_id)
	_item_id_by_anchor_slot.erase(anchor_slot_index)
	_anchor_slot_by_item_id.erase(item_id)
	_shelf_by_item_id.erase(item_id)
	_sync_shelf_slots()
	return shelf


func is_shelf_anchor(slot_index: int) -> bool:
	return _item_id_by_anchor_slot.has(slot_index)


func get_shelf_anchor_slot_index(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= _anchor_slot_by_occupied_slot.size():
		return -1
	return _anchor_slot_by_occupied_slot[slot_index]


func get_anchor_slot_indices() -> Array[int]:
	var anchor_slot_indices: Array[int] = []
	for anchor_slot_index in _item_id_by_anchor_slot.keys():
		anchor_slot_indices.append(int(anchor_slot_index))
	anchor_slot_indices.sort()
	return anchor_slot_indices


func get_unique_shelves() -> Array[ShelfInstance]:
	var shelves: Array[ShelfInstance] = []
	for anchor_slot_index in get_anchor_slot_indices():
		var shelf := get_shelf(anchor_slot_index)
		if shelf != null:
			shelves.append(shelf)
	return shelves


func _sync_shelf_slots() -> void:
	for slot_index in range(shelf_slots.size()):
		shelf_slots[slot_index] = null
		_anchor_slot_by_occupied_slot[slot_index] = -1

	if definition == null:
		return

	for slot_cell in definition.get_slot_cells():
		var slot_index := int(slot_cell.get("index", -1))
		if slot_index < 0 or slot_index >= shelf_slots.size():
			continue
		var item_id: String = _grid.get_item_at(Vector2i(int(slot_cell.get("col", -1)), int(slot_cell.get("row", -1))))
		if item_id.is_empty():
			continue
		shelf_slots[slot_index] = _shelf_by_item_id.get(item_id, null)
		_anchor_slot_by_occupied_slot[slot_index] = int(_anchor_slot_by_item_id.get(item_id, -1))


func _get_slot_cell(slot_index: int) -> Dictionary:
	if definition == null:
		return {}
	return definition.get_slot_cell(slot_index)


func _get_item_id_for_shelf(shelf: ShelfInstance) -> String:
	return str(shelf.get_instance_id())


func _get_shelf_footprint(shelf_or_definition: Variant) -> Vector2i:
	var shelf_definition: ShelfDefinition = null
	if shelf_or_definition is ShelfInstance:
		shelf_definition = shelf_or_definition.definition
	elif shelf_or_definition is ShelfDefinition:
		shelf_definition = shelf_or_definition
	if shelf_definition == null:
		return Vector2i.ONE
	return Vector2i(
		maxi(shelf_definition.slot_grid_columns, 1),
		maxi(shelf_definition.slot_grid_rows if shelf_definition.use_slot_grid else 1, 1)
	)
