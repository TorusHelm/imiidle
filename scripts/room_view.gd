class_name RoomView
extends Control

signal choose_shelf_pressed(room_slot_index: int)
signal pot_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal seed_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal shelf_drop_requested(room_slot_index: int, runtime_id: String)
signal slot_item_drop_requested(room_slot_index: int, source_slot_index: int, target_slot_index: int)

const ROOM_SLOT_SCENE := preload("res://Ui/RoomShelfSlot.tscn")
const SHELF_SCENE := preload("res://Shelfs/_shared/sceens/Shelf.tscn")
const DEFAULT_ROOM_DEFINITION: RoomDefinition = preload("res://Rooms/DefaultRoom/data/default_room.tres")

@export var room_definition: RoomDefinition = DEFAULT_ROOM_DEFINITION

var _room_slot_views: Array[RoomSlotView] = []
var _placed_shelf_views: Dictionary = {}
var _current_room_id := ""
var _current_game_state: GameState = null

@onready var world_root: Control = $WorldRoot
@onready var slots_root: Control = $WorldRoot/SlotsRoot
@onready var shelves_root: Control = $WorldRoot/ShelvesRoot


func _ready() -> void:
	_rebuild_slot_views()


func configure(definition: RoomDefinition) -> void:
	var resolved_definition := definition if definition != null else DEFAULT_ROOM_DEFINITION
	var next_room_id := resolved_definition.id
	var needs_rebuild := _current_room_id != next_room_id or _room_slot_views.size() != resolved_definition.get_slot_count()
	room_definition = resolved_definition
	_current_room_id = next_room_id
	if not needs_rebuild:
		return
	_rebuild_slot_views()


func update_view(game_state: GameState) -> void:
	configure(game_state.get_room_definition())
	_current_game_state = game_state
	clear_drag_preview()

	for room_slot_index in _room_slot_views.size():
		var slot_view := _room_slot_views[room_slot_index]
		slot_view.set_game_state(game_state)
		var shelf := game_state.get_shelf_in_room_slot(room_slot_index)
		var anchor_slot_index := game_state.get_room_shelf_anchor_slot_index(room_slot_index)
		var room_slot_size := room_definition.get_slot_area_size()
		if shelf == null:
			slot_view.show_empty(room_slot_size)
			continue

		if anchor_slot_index != room_slot_index:
			slot_view.show_occupied(room_slot_size)
			continue

		slot_view.show_shelf(room_slot_size, shelf.definition, game_state, room_slot_index, game_state.get_room_shelf_runtime_id(room_slot_index), false)

	_sync_shelf_overlays(game_state)


func position_content(_viewport_size: Vector2) -> void:
	pass


func _rebuild_slot_views() -> void:
	if not is_node_ready():
		return

	for child in slots_root.get_children():
		child.queue_free()

	_room_slot_views.clear()

	var resolved_definition := room_definition if room_definition != null else DEFAULT_ROOM_DEFINITION
	var slot_cells := resolved_definition.get_slot_cells()

	for slot_data in slot_cells:
		var slot_view: RoomSlotView = ROOM_SLOT_SCENE.instantiate()
		slot_view.name = "RoomSlot%d" % int(slot_data.get("index", -1))
		slot_view.position = slot_data.get("position", Vector2.ZERO)
		slot_view.set_room_slot_index(int(slot_data.get("index", -1)))
		slot_view.choose_shelf_pressed.connect(_on_choose_shelf_pressed)
		slot_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
		slot_view.seed_slot_pressed.connect(_on_seed_slot_pressed)
		slot_view.shelf_drop_requested.connect(_on_shelf_drop_requested)
		slot_view.shelf_drag_hovered.connect(_on_shelf_drag_hovered)
		slot_view.shelf_drag_finished.connect(_on_shelf_drag_finished)
		slot_view.slot_item_drop_requested.connect(_on_slot_item_drop_requested)
		slots_root.add_child(slot_view)
		_room_slot_views.append(slot_view)


func _on_choose_shelf_pressed(room_slot_index: int) -> void:
	choose_shelf_pressed.emit(room_slot_index)


func _on_pot_slot_pressed(room_slot_index: int, shelf_slot_index: int) -> void:
	pot_slot_pressed.emit(room_slot_index, shelf_slot_index)


func _on_seed_slot_pressed(room_slot_index: int, shelf_slot_index: int) -> void:
	seed_slot_pressed.emit(room_slot_index, shelf_slot_index)


func _on_shelf_drop_requested(room_slot_index: int, runtime_id: String) -> void:
	shelf_drop_requested.emit(room_slot_index, runtime_id)
	clear_drag_preview()


func _on_shelf_drag_hovered(room_slot_index: int, runtime_id: String) -> void:
	if _current_game_state == null:
		return
	clear_drag_preview()
	var preview: Dictionary = _current_game_state.get_room_shelf_preview(runtime_id, room_slot_index)
	var slot_indices: Array = preview.get("slot_indices", [])
	var can_place := bool(preview.get("can_place", false))
	for slot_index in slot_indices:
		var slot_view := _get_room_slot_view(int(slot_index))
		if slot_view != null:
			slot_view.set_drop_preview(can_place)


func _on_shelf_drag_finished() -> void:
	clear_drag_preview()


func _on_slot_item_drop_requested(room_slot_index: int, source_slot_index: int, target_slot_index: int) -> void:
	slot_item_drop_requested.emit(room_slot_index, source_slot_index, target_slot_index)


func clear_drag_preview() -> void:
	for slot_view in _room_slot_views:
		slot_view.clear_drop_preview()


func _get_room_slot_view(room_slot_index: int) -> RoomSlotView:
	if room_slot_index < 0 or room_slot_index >= _room_slot_views.size():
		return null
	return _room_slot_views[room_slot_index]


func _sync_shelf_overlays(game_state: GameState) -> void:
	var active_runtime_ids: Dictionary = {}

	for room_slot_index in _room_slot_views.size():
		var shelf := game_state.get_shelf_in_room_slot(room_slot_index)
		if shelf == null:
			continue
		if game_state.get_room_shelf_anchor_slot_index(room_slot_index) != room_slot_index:
			continue

		var runtime_id := game_state.get_room_shelf_runtime_id(room_slot_index)
		if runtime_id.is_empty():
			continue

		active_runtime_ids[runtime_id] = true
		var shelf_view: ShelfView = _placed_shelf_views.get(runtime_id, null)
		if shelf_view == null:
			shelf_view = SHELF_SCENE.instantiate()
			shelf_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shelf_view.pot_slot_pressed.connect(_on_overlay_pot_slot_pressed.bind(shelf_view))
			shelf_view.seed_slot_pressed.connect(_on_overlay_seed_slot_pressed.bind(shelf_view))
			shelf_view.slot_item_drop_requested.connect(_on_overlay_slot_item_drop_requested)
			shelves_root.add_child(shelf_view)
			_placed_shelf_views[runtime_id] = shelf_view

		shelf_view.set_meta("room_slot_index", room_slot_index)
		shelf_view.configure(shelf.definition)
		shelf_view.update_view(game_state, room_slot_index)
		shelf_view.play_visual_feedback(game_state.drain_visual_feedback_in_room_slot(room_slot_index))
		var slot_cell := room_definition.get_slot_cell(room_slot_index)
		shelf_view.position = Vector2(slot_cell.get("position", Vector2.ZERO)) - shelf.definition.get_primary_slot_work_area_origin()

	for runtime_id in _placed_shelf_views.keys():
		if active_runtime_ids.has(runtime_id):
			continue
		var stale_shelf_view: ShelfView = _placed_shelf_views[runtime_id]
		if stale_shelf_view != null:
			stale_shelf_view.queue_free()
		_placed_shelf_views.erase(runtime_id)


func _on_overlay_pot_slot_pressed(shelf_slot_index: int, shelf_view: ShelfView) -> void:
	pot_slot_pressed.emit(int(shelf_view.get_meta("room_slot_index", -1)), shelf_slot_index)


func _on_overlay_seed_slot_pressed(shelf_slot_index: int, shelf_view: ShelfView) -> void:
	seed_slot_pressed.emit(int(shelf_view.get_meta("room_slot_index", -1)), shelf_slot_index)


func _on_overlay_slot_item_drop_requested(source_room_slot_index: int, source_slot_index: int, target_room_slot_index: int, target_slot_index: int) -> void:
	slot_item_drop_requested.emit(target_room_slot_index, source_slot_index, target_slot_index)
