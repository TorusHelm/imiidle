extends Control


var game_state := GameState.new()
var _view_offset := Vector2.ZERO
var _is_panning := false

@export_group("World Navigation")
@export var pan_screen_span := Vector2(2.0, 2.0)
@export_range(8.0, 256.0, 1.0) var wheel_pan_step := 96.0
@export_range(0.1, 4.0, 0.1) var drag_pan_multiplier := 1.0

@onready var coins_value_label: Label = %CoinsValueLabel
@onready var experience_value_label: Label = %ExperienceValueLabel
@onready var seeds_value_label: Label = %SeedsValueLabel
@onready var background: ColorRect = $Background
@onready var world_root: Control = %WorldRoot
@onready var shelf_view: ShelfView = %ShelfView
@onready var empty_shelf_state: Control = %EmptyShelfState
@onready var seed_modal: SeedModal = %SeedModal
@onready var pot_modal: PotModal = %PotModal
@onready var shelf_modal: ShelfModal = %ShelfModal
@onready var choose_shelf_button: Button = empty_shelf_state.get_node("Panel/Content/ChooseShelfButton")
@onready var empty_shelf_click_area: Button = empty_shelf_state.get_node("Panel/ClickArea")


func _ready() -> void:
	_connect_ui_signals()
	_apply_world_offset()
	_refresh_ui()


func _process(delta: float) -> void:
	game_state.tick(delta)
	_refresh_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_clamp_view_offset()
		_apply_world_offset()
		_position_world_content()


func _input(event: InputEvent) -> void:
	if not _can_pan_view():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _handle_world_primary_click(event.position):
				get_viewport().set_input_as_handled()
				return

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
			_pan_view(Vector2.RIGHT if Input.is_key_pressed(KEY_SHIFT) else Vector2.DOWN)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_pan_view(Vector2.LEFT if Input.is_key_pressed(KEY_SHIFT) else Vector2.UP)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_panning:
		_view_offset += event.relative * drag_pan_multiplier
		_clamp_view_offset()
		_apply_world_offset()
		get_viewport().set_input_as_handled()


func _on_pot_slot_pressed(slot_index: int) -> void:
	pot_modal.open_modal(slot_index, game_state.get_pot_options())
	_refresh_ui()


func _on_pot_selected(slot_index: int, pot_id: String) -> void:
	game_state.place_pot(slot_index, pot_id)
	pot_modal.close_modal()
	_refresh_ui()


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_modal.open_modal(slot_index, game_state.get_seed_options())
	_refresh_ui()


func _on_seed_selected(slot_index: int, seed_id: String) -> void:
	game_state.plant_seed(slot_index, seed_id)
	seed_modal.close_modal()
	_refresh_ui()


func _on_choose_shelf_button_pressed() -> void:
	shelf_modal.open_modal(game_state.get_shelf_options())


func _on_shelf_selected(shelf_id: String) -> void:
	if game_state.place_shelf(shelf_id):
		shelf_view.configure(game_state.get_active_shelf_definition())
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
	shelf_view.visible = active_shelf != null
	empty_shelf_state.visible = active_shelf == null
	if active_shelf != null:
		shelf_view.configure(active_shelf)
		_clamp_view_offset()
		_position_world_content()
		shelf_view.update_view(game_state)
	else:
		_position_world_content()


func _position_world_content() -> void:
	if world_root == null or shelf_view == null or empty_shelf_state == null:
		return
	var viewport_size := get_viewport_rect().size
	shelf_view.position = (viewport_size - shelf_view.size) * 0.5


func _can_pan_view() -> bool:
	return not seed_modal.visible and not pot_modal.visible and not shelf_modal.visible


func _pan_view(direction: Vector2) -> void:
	_view_offset += direction * wheel_pan_step
	_clamp_view_offset()
	_apply_world_offset()


func _clamp_view_offset() -> void:
	var viewport_size := get_viewport_rect().size
	var max_offset := Vector2(
		maxf(viewport_size.x * maxf(pan_screen_span.x - 1.0, 0.0) * 0.5, 0.0),
		maxf(viewport_size.y * maxf(pan_screen_span.y - 1.0, 0.0) * 0.5, 0.0)
	)
	_view_offset.x = clampf(_view_offset.x, -max_offset.x, max_offset.x)
	_view_offset.y = clampf(_view_offset.y, -max_offset.y, max_offset.y)


func _apply_world_offset() -> void:
	if world_root == null:
		return
	world_root.position = _view_offset


func _connect_ui_signals() -> void:
	if not shelf_view.pot_slot_pressed.is_connected(_on_pot_slot_pressed):
		shelf_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
	if not shelf_view.seed_slot_pressed.is_connected(_on_seed_button_pressed):
		shelf_view.seed_slot_pressed.connect(_on_seed_button_pressed)
	if not choose_shelf_button.pressed.is_connected(_on_choose_shelf_button_pressed):
		choose_shelf_button.pressed.connect(_on_choose_shelf_button_pressed)
	if not empty_shelf_click_area.pressed.is_connected(_on_choose_shelf_button_pressed):
		empty_shelf_click_area.pressed.connect(_on_choose_shelf_button_pressed)


func _handle_world_primary_click(global_position: Vector2) -> bool:
	if seed_modal.visible or pot_modal.visible or shelf_modal.visible:
		return false

	if empty_shelf_state.visible:
		if choose_shelf_button.get_global_rect().has_point(global_position):
			_on_choose_shelf_button_pressed()
			return true
		if empty_shelf_click_area.get_global_rect().has_point(global_position):
			_on_choose_shelf_button_pressed()
			return true
		return false

	if not shelf_view.visible:
		return false

	for slot_index in shelf_view.get_slot_count():
		var pot_view := shelf_view.get_pot_view(slot_index)
		if pot_view == null:
			continue

		if pot_view.slot_button.visible and not pot_view.slot_button.disabled and pot_view.slot_button.get_global_rect().has_point(global_position):
			_on_pot_slot_pressed(slot_index)
			return true

		if pot_view.seed_button.visible and not pot_view.seed_button.disabled and pot_view.seed_button.get_global_rect().has_point(global_position):
			_on_seed_button_pressed(slot_index)
			return true

	return false
