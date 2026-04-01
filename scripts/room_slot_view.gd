class_name RoomSlotView
extends Control


signal choose_shelf_pressed(room_slot_index: int)
signal pot_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal seed_slot_pressed(room_slot_index: int, shelf_slot_index: int)


var room_slot_index := -1


@onready var shelf_view: ShelfView = $ShelfView
@onready var empty_shelf_state: Control = $EmptyShelfState
@onready var choose_shelf_button: Button = $EmptyShelfState/Panel/Content/ChooseShelfButton
@onready var empty_shelf_click_area: Button = $EmptyShelfState/Panel/ClickArea


func _ready() -> void:
	if not shelf_view.pot_slot_pressed.is_connected(_on_pot_slot_pressed):
		shelf_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
	if not shelf_view.seed_slot_pressed.is_connected(_on_seed_button_pressed):
		shelf_view.seed_slot_pressed.connect(_on_seed_button_pressed)
	if not choose_shelf_button.pressed.is_connected(_on_choose_shelf_button_pressed):
		choose_shelf_button.pressed.connect(_on_choose_shelf_button_pressed)
	if not empty_shelf_click_area.pressed.is_connected(_on_choose_shelf_button_pressed):
		empty_shelf_click_area.pressed.connect(_on_choose_shelf_button_pressed)


func set_room_slot_index(value: int) -> void:
	room_slot_index = value


func show_empty(slot_size: Vector2) -> void:
	custom_minimum_size = slot_size
	size = slot_size
	shelf_view.visible = false
	empty_shelf_state.visible = true
	empty_shelf_state.position = Vector2.ZERO
	empty_shelf_state.size = slot_size


func show_shelf(slot_size: Vector2, shelf_definition: ShelfDefinition, game_state: GameState, room_slot_index_value: int) -> void:
	custom_minimum_size = slot_size
	size = slot_size
	empty_shelf_state.visible = false
	shelf_view.visible = true
	shelf_view.configure(shelf_definition)
	shelf_view.update_view(game_state, room_slot_index_value)
	shelf_view.play_visual_feedback(game_state.drain_visual_feedback_in_room_slot(room_slot_index_value))
	shelf_view.position = (slot_size - shelf_view.size) * 0.5


func _on_choose_shelf_button_pressed() -> void:
	choose_shelf_pressed.emit(room_slot_index)


func _on_pot_slot_pressed(shelf_slot_index: int) -> void:
	pot_slot_pressed.emit(room_slot_index, shelf_slot_index)


func _on_seed_button_pressed(shelf_slot_index: int) -> void:
	seed_slot_pressed.emit(room_slot_index, shelf_slot_index)
