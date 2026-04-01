extends Control


var game_state := GameState.new()
var _view_offset := Vector2.ZERO
var _is_panning := false
var _zoom_level := 1.0

@export_group("World Navigation")
@export var pan_screen_span := Vector2(2.0, 2.0)
@export_range(0.1, 4.0, 0.1) var drag_pan_multiplier := 1.0
@export_range(0.1, 4.0, 0.05) var min_zoom := 0.8
@export_range(0.1, 4.0, 0.05) var max_zoom := 1.6
@export_range(0.01, 1.0, 0.01) var wheel_zoom_step := 0.1

@onready var coins_value_label: Label = %CoinsValueLabel
@onready var experience_value_label: Label = %ExperienceValueLabel
@onready var seeds_value_label: Label = %SeedsValueLabel
@onready var background: ColorRect = $Background
@onready var room_view: RoomView = %Room
@onready var world_root: Control = room_view.world_root
@onready var seed_modal: SeedModal = %SeedModal
@onready var pot_modal: PotModal = %PotModal
@onready var shelf_modal: ShelfModal = %ShelfModal

var _pending_room_slot_index := -1


func _ready() -> void:
	_connect_ui_signals()
	_clamp_zoom_level()
	_apply_world_transform()
	_refresh_ui()


func _process(delta: float) -> void:
	game_state.tick(delta)
	_refresh_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_clamp_view_offset()
		_apply_world_transform()
		_position_world_content()


func _input(event: InputEvent) -> void:
	if not _can_pan_view():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = event.pressed
			if event.pressed:
				get_viewport().set_input_as_handled()
			else:
				get_viewport().set_input_as_handled()
			return

		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_view(1.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_view(-1.0)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_panning:
		_view_offset += event.relative * drag_pan_multiplier
		_clamp_view_offset()
		_apply_world_transform()
		get_viewport().set_input_as_handled()


func _on_pot_slot_pressed(room_slot_index: int, slot_index: int) -> void:
	game_state.set_active_room_slot_index(room_slot_index)
	pot_modal.open_modal(slot_index, game_state.get_pot_options(), game_state.get_totem_options())
	_refresh_ui()


func _on_pot_selected(slot_index: int, pot_id: String) -> void:
	game_state.place_pot(slot_index, pot_id)
	pot_modal.close_modal()
	_refresh_ui()


func _on_totem_selected(slot_index: int, totem_id: String) -> void:
	game_state.place_totem(slot_index, totem_id)
	pot_modal.close_modal()
	_refresh_ui()


func _on_seed_button_pressed(room_slot_index: int, slot_index: int) -> void:
	game_state.set_active_room_slot_index(room_slot_index)
	seed_modal.open_modal(slot_index, game_state.get_seed_options())
	_refresh_ui()


func _on_seed_selected(slot_index: int, seed_id: String) -> void:
	game_state.plant_seed(slot_index, seed_id)
	seed_modal.close_modal()
	_refresh_ui()


func _on_choose_shelf_button_pressed(room_slot_index: int) -> void:
	_pending_room_slot_index = room_slot_index
	shelf_modal.open_modal(game_state.get_shelf_options())


func _on_shelf_selected(shelf_id: String) -> void:
	if _pending_room_slot_index >= 0:
		game_state.place_shelf(_pending_room_slot_index, shelf_id)
		game_state.set_active_room_slot_index(_pending_room_slot_index)
	_pending_room_slot_index = -1
	shelf_modal.close_modal()
	_refresh_ui()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sceens/Main.tscn")


func _refresh_ui() -> void:
	var active_shelf := game_state.get_active_shelf_definition()
	background.color = game_state.get_background_color()
	coins_value_label.text = "%.1f" % game_state.coins
	experience_value_label.text = "%.1f" % game_state.experience
	seeds_value_label.text = str(game_state.get_total_seed_count())
	room_view.update_view(game_state)
	_clamp_view_offset()
	_position_world_content()


func _position_world_content() -> void:
	if room_view == null or world_root == null:
		return
	var viewport_size := get_viewport_rect().size
	room_view.position_content(viewport_size)


func _can_pan_view() -> bool:
	return not seed_modal.visible and not pot_modal.visible and not shelf_modal.visible


func _zoom_view(direction: float) -> void:
	_zoom_level += direction * wheel_zoom_step
	_clamp_zoom_level()
	_clamp_view_offset()
	_apply_world_transform()


func _clamp_view_offset() -> void:
	var viewport_size := get_viewport_rect().size
	var effective_pan_span := pan_screen_span * _zoom_level
	var max_offset := Vector2(
		maxf(viewport_size.x * maxf(effective_pan_span.x - 1.0, 0.0) * 0.5, 0.0),
		maxf(viewport_size.y * maxf(effective_pan_span.y - 1.0, 0.0) * 0.5, 0.0)
	)
	_view_offset.x = clampf(_view_offset.x, -max_offset.x, max_offset.x)
	_view_offset.y = clampf(_view_offset.y, -max_offset.y, max_offset.y)


func _clamp_zoom_level() -> void:
	var zoom_min := minf(min_zoom, max_zoom)
	var zoom_max := maxf(min_zoom, max_zoom)
	_zoom_level = clampf(_zoom_level, zoom_min, zoom_max)


func _apply_world_transform() -> void:
	if world_root == null:
		return
	world_root.pivot_offset = get_viewport_rect().size * 0.5
	world_root.position = _view_offset
	world_root.scale = Vector2.ONE * _zoom_level


func _connect_ui_signals() -> void:
	if not room_view.choose_shelf_pressed.is_connected(_on_choose_shelf_button_pressed):
		room_view.choose_shelf_pressed.connect(_on_choose_shelf_button_pressed)
	if not room_view.pot_slot_pressed.is_connected(_on_pot_slot_pressed):
		room_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
	if not room_view.seed_slot_pressed.is_connected(_on_seed_button_pressed):
		room_view.seed_slot_pressed.connect(_on_seed_button_pressed)
