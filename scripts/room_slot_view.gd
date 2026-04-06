class_name RoomSlotView
extends Control


signal choose_shelf_pressed(room_slot_index: int)
signal pot_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal seed_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal shelf_drop_requested(room_slot_index: int, runtime_id: String)
signal shelf_drag_hovered(room_slot_index: int, runtime_id: String)
signal shelf_drag_finished()
signal slot_item_drop_requested(room_slot_index: int, source_slot_index: int, target_slot_index: int)


var room_slot_index := -1
var _game_state: GameState = null
var _is_shelf_anchor := false
var _shelf_runtime_id := ""


@onready var shelf_view: ShelfView = $ShelfView
@onready var slot_frame: TextureRect = $SlotFrame
@onready var preview_overlay: ColorRect = $PreviewOverlay
@onready var empty_shelf_state: Control = $EmptyShelfState
@onready var choose_shelf_button: Button = $EmptyShelfState/Panel/Content/ChooseShelfButton
@onready var empty_shelf_click_area: Button = $EmptyShelfState/Panel/ClickArea


func _ready() -> void:
	if not shelf_view.pot_slot_pressed.is_connected(_on_pot_slot_pressed):
		shelf_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
	if not shelf_view.seed_slot_pressed.is_connected(_on_seed_button_pressed):
		shelf_view.seed_slot_pressed.connect(_on_seed_button_pressed)
	if not shelf_view.slot_item_drop_requested.is_connected(_on_slot_item_drop_requested):
		shelf_view.slot_item_drop_requested.connect(_on_slot_item_drop_requested)
	if not choose_shelf_button.pressed.is_connected(_on_choose_shelf_button_pressed):
		choose_shelf_button.pressed.connect(_on_choose_shelf_button_pressed)
	if not empty_shelf_click_area.pressed.is_connected(_on_choose_shelf_button_pressed):
		empty_shelf_click_area.pressed.connect(_on_choose_shelf_button_pressed)


func set_room_slot_index(value: int) -> void:
	room_slot_index = value


func set_game_state(game_state: GameState) -> void:
	_game_state = game_state


func show_empty(slot_size: Vector2) -> void:
	_is_shelf_anchor = false
	_shelf_runtime_id = ""
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	custom_minimum_size = slot_size
	size = slot_size
	modulate = Color.WHITE
	slot_frame.position = Vector2.ZERO
	slot_frame.custom_minimum_size = slot_size
	slot_frame.size = slot_size
	slot_frame.visible = true
	preview_overlay.position = Vector2.ZERO
	preview_overlay.size = slot_size
	preview_overlay.visible = false
	shelf_view.top_level = false
	shelf_view.position = Vector2.ZERO
	shelf_view.visible = false
	empty_shelf_state.visible = true
	empty_shelf_state.position = Vector2.ZERO
	empty_shelf_state.size = slot_size
	choose_shelf_button.visible = false
	empty_shelf_click_area.visible = false


func show_occupied(slot_size: Vector2) -> void:
	_is_shelf_anchor = false
	_shelf_runtime_id = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
	custom_minimum_size = slot_size
	size = slot_size
	modulate = Color.WHITE
	slot_frame.position = Vector2.ZERO
	slot_frame.custom_minimum_size = slot_size
	slot_frame.size = slot_size
	slot_frame.visible = false
	preview_overlay.position = Vector2.ZERO
	preview_overlay.size = slot_size
	preview_overlay.visible = false
	shelf_view.top_level = false
	shelf_view.position = Vector2.ZERO
	shelf_view.visible = false
	empty_shelf_state.visible = false


func show_shelf(slot_size: Vector2, shelf_definition: ShelfDefinition, game_state: GameState, room_slot_index_value: int, shelf_runtime_id := "", show_embedded_view := true) -> void:
	_game_state = game_state
	_is_shelf_anchor = true
	_shelf_runtime_id = shelf_runtime_id
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	custom_minimum_size = slot_size
	size = slot_size
	modulate = Color.WHITE
	slot_frame.position = Vector2.ZERO
	slot_frame.custom_minimum_size = slot_size
	slot_frame.size = slot_size
	slot_frame.visible = false
	preview_overlay.position = Vector2.ZERO
	preview_overlay.size = slot_size
	preview_overlay.visible = false
	empty_shelf_state.visible = false
	shelf_view.top_level = false
	if not show_embedded_view:
		shelf_view.visible = false
		shelf_view.position = Vector2.ZERO
		return
	shelf_view.visible = true
	shelf_view.configure(shelf_definition)
	shelf_view.update_view(game_state, room_slot_index_value)
	shelf_view.play_visual_feedback(game_state.drain_visual_feedback_in_room_slot(room_slot_index_value))
	shelf_view.position = -shelf_definition.get_primary_slot_work_area_origin()


func _on_choose_shelf_button_pressed() -> void:
	choose_shelf_pressed.emit(room_slot_index)


func _on_pot_slot_pressed(shelf_slot_index: int) -> void:
	pot_slot_pressed.emit(room_slot_index, shelf_slot_index)


func _on_seed_button_pressed(shelf_slot_index: int) -> void:
	seed_slot_pressed.emit(room_slot_index, shelf_slot_index)


func set_drop_preview(is_valid: bool) -> void:
	preview_overlay.visible = true
	preview_overlay.color = Color(0.32, 0.84, 0.45, 0.28) if is_valid else Color(0.96, 0.28, 0.28, 0.28)


func clear_drop_preview() -> void:
	preview_overlay.visible = false


func _get_drag_data(_at_position: Vector2):
	if not _is_shelf_anchor or _shelf_runtime_id.is_empty():
		return null

	var preview := Control.new()
	preview.custom_minimum_size = size
	preview.size = size
	var preview_texture := TextureRect.new()
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_SCALE
	preview_texture.size = size
	preview_texture.texture = slot_frame.texture
	preview.add_child(preview_texture)
	set_drag_preview(preview)

	return {
		"type": "shelf",
		"runtime_id": _shelf_runtime_id,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or String(data.get("type", "")) != "shelf":
		return false

	var runtime_id := String(data.get("runtime_id", ""))
	shelf_drag_hovered.emit(room_slot_index, runtime_id)
	return _game_state != null and _game_state.can_place_shelf_item_in_room(runtime_id, room_slot_index)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	shelf_drop_requested.emit(room_slot_index, String(data.get("runtime_id", "")))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		shelf_drag_finished.emit()


func _on_slot_item_drop_requested(_source_room_slot_index: int, source_slot_index: int, _target_room_slot_index: int, target_slot_index: int) -> void:
	slot_item_drop_requested.emit(room_slot_index, source_slot_index, target_slot_index)
