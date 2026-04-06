class_name ShelfBackpackView
extends Control

signal shelf_drop_requested(runtime_id: String, backpack_origin: Vector2i)

const DRAGGABLE_SHELF_ITEM_VIEW_SCENE := preload("res://Ui/DraggableShelfItemView.tscn")

@export var cell_size := Vector2(24.0, 24.0)
@export var cell_gap := Vector2(3.0, 3.0)
@export var columns := 15
@export var rows := 20

var _game_state: GameState = null
var _preview_origin := Vector2i(-1, -1)
var _preview_runtime_id := ""
var _preview_can_place := false
var _rendered_signature := ""

@onready var items_root: Control = $ItemsRoot


func _ready() -> void:
	_update_view_size()


func update_view(game_state: GameState) -> void:
	_game_state = game_state
	_update_view_size()
	var next_signature := _build_items_signature()
	if next_signature != _rendered_signature:
		_rebuild_items()
		_rendered_signature = next_signature
	queue_redraw()


func _draw() -> void:
	var cell_extent := cell_size + cell_gap
	for row in range(rows):
		for column in range(columns):
			var rect := Rect2(Vector2(column * cell_extent.x, row * cell_extent.y), cell_size)
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.05), true)
			draw_rect(rect, Color(0.65, 0.78, 0.82, 0.35), false, 1.0)

	if _preview_origin.x < 0 or _preview_origin.y < 0 or _game_state == null:
		return

	var shelf_item = _game_state.get_shelf_item(_preview_runtime_id)
	if shelf_item == null:
		return

	var preview_color := Color(0.32, 0.84, 0.45, 0.28) if _preview_can_place else Color(0.96, 0.28, 0.28, 0.28)
	for row in range(_preview_origin.y, _preview_origin.y + shelf_item.get_footprint().y):
		for column in range(_preview_origin.x, _preview_origin.x + shelf_item.get_footprint().x):
			if column < 0 or column >= columns or row < 0 or row >= rows:
				continue
			var rect := Rect2(Vector2(column * cell_extent.x, row * cell_extent.y), cell_size)
			draw_rect(rect, preview_color, true)
			draw_rect(rect, preview_color.darkened(0.25), false, 2.0)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or String(data.get("type", "")) != "shelf" or _game_state == null:
		return false

	var runtime_id := String(data.get("runtime_id", ""))
	var origin := _position_to_grid(at_position)
	_preview_runtime_id = runtime_id
	_preview_origin = origin
	_preview_can_place = _game_state.can_move_or_swap_shelf_item_in_backpack(runtime_id, origin)
	queue_redraw()
	return _preview_can_place


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	var runtime_id := String(data.get("runtime_id", ""))
	var origin := _position_to_grid(at_position)
	shelf_drop_requested.emit(runtime_id, origin)
	_clear_preview()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_preview()


func _rebuild_items() -> void:
	for child in items_root.get_children():
		child.queue_free()

	if _game_state == null:
		return

	for shelf_item in _game_state.get_shelf_backpack_items():
		var item_view = DRAGGABLE_SHELF_ITEM_VIEW_SCENE.instantiate()
		var footprint: Vector2i = shelf_item.get_footprint()
		item_view.position = _grid_to_position(shelf_item.backpack_origin)
		item_view.configure(
			shelf_item.runtime_id,
			shelf_item.definition,
			footprint,
			Vector2(
				footprint.x * cell_size.x + max(footprint.x - 1, 0) * cell_gap.x,
				footprint.y * cell_size.y + max(footprint.y - 1, 0) * cell_gap.y
			)
		)
		items_root.add_child(item_view)


func _build_items_signature() -> String:
	if _game_state == null:
		return ""

	var parts: PackedStringArray = []
	for shelf_item in _game_state.get_shelf_backpack_items():
		var footprint: Vector2i = shelf_item.get_footprint()
		parts.append("%s|%s|%d|%d|%d|%d" % [
			shelf_item.runtime_id,
			shelf_item.definition.id if shelf_item.definition != null else "",
			shelf_item.backpack_origin.x,
			shelf_item.backpack_origin.y,
			footprint.x,
			footprint.y,
		])
	return "|".join(parts)


func _update_view_size() -> void:
	custom_minimum_size = Vector2(
		columns * cell_size.x + max(columns - 1, 0) * cell_gap.x,
		rows * cell_size.y + max(rows - 1, 0) * cell_gap.y
	)
	size = custom_minimum_size


func _grid_to_position(origin: Vector2i) -> Vector2:
	return Vector2(
		origin.x * (cell_size.x + cell_gap.x),
		origin.y * (cell_size.y + cell_gap.y)
	)


func _position_to_grid(at_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(at_position.x / (cell_size.x + cell_gap.x))), 0, max(columns - 1, 0)),
		clampi(int(floor(at_position.y / (cell_size.y + cell_gap.y))), 0, max(rows - 1, 0))
	)


func _clear_preview() -> void:
	_preview_runtime_id = ""
	_preview_origin = Vector2i(-1, -1)
	_preview_can_place = false
	queue_redraw()
