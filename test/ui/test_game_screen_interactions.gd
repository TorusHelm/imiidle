extends GutTest


const GAME_SCENE := preload("res://sceens/Game.tscn")


func test_clicking_choose_shelf_button_opens_shelf_modal() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var empty_shelf_state: Control = game.get_node("Room/WorldRoot/SlotsRoot/RoomSlot0/EmptyShelfState")
	var choose_shelf_button: Button = empty_shelf_state.get_node("Panel/Content/ChooseShelfButton")
	var shelf_modal: ShelfModal = game.get_node("ShelfModal")

	_click_control(choose_shelf_button)
	await wait_process_frames(3)

	assert_true(shelf_modal.visible, "Choose shelf button should open the shelf modal.")
	assert_gt(shelf_modal.get_node("CenterContainer/ModalPanel/Content/ShelfList").get_child_count(), 0, "Shelf modal should populate shelf options after click.")


func test_clicking_empty_shelf_click_area_opens_shelf_modal() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var empty_shelf_state: Control = game.get_node("Room/WorldRoot/SlotsRoot/RoomSlot0/EmptyShelfState")
	var click_area: Button = empty_shelf_state.get_node("Panel/ClickArea")
	var shelf_modal: ShelfModal = game.get_node("ShelfModal")

	_click_control(click_area)
	await wait_process_frames(3)

	assert_true(shelf_modal.visible, "Empty shelf click area should open the shelf modal.")


func test_clicking_empty_pot_slot_opens_pot_modal() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	game._on_choose_shelf_button_pressed(0)
	game._on_shelf_selected("shelf_a")
	await wait_process_frames(3)

	var shelf_view: ShelfView = game.get_node("Room/WorldRoot/SlotsRoot/RoomSlot0/ShelfView")
	var first_pot_view: PotView = shelf_view.get_pot_view(0)
	var pot_modal: PotModal = game.get_node("PotModal")

	assert_not_null(first_pot_view, "Placed shelf should create the first pot slot view.")
	assert_true(first_pot_view.slot_button.visible, "First slot should be empty and expose the pot selection button.")

	_click_control(first_pot_view.slot_button)
	await wait_process_frames(3)

	assert_true(pot_modal.visible, "Clicking an empty pot slot should open the pot modal.")


func test_mouse_wheel_zooms_world_without_changing_pan_offset() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	game._on_choose_shelf_button_pressed(0)
	game._on_shelf_selected("shelf_a")
	await wait_process_frames(3)

	var world_root: Control = game.get_node("%WorldRoot")
	var initial_position := world_root.position

	_scroll_wheel(game, MOUSE_BUTTON_WHEEL_UP)
	await wait_process_frames(3)

	assert_eq(world_root.position, initial_position, "Mouse wheel zoom should not change world pan offset.")
	assert_almost_eq(world_root.scale.x, 1.1, 0.001, "Mouse wheel up should zoom the world in.")
	assert_almost_eq(world_root.scale.y, 1.1, 0.001, "World scale should stay uniform after zoom in.")


func test_mouse_wheel_zoom_respects_min_and_max_limits() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	game._on_choose_shelf_button_pressed(0)
	game._on_shelf_selected("shelf_a")
	await wait_process_frames(3)

	var world_root: Control = game.get_node("%WorldRoot")

	for _index in range(20):
		_scroll_wheel(game, MOUSE_BUTTON_WHEEL_UP)
	await wait_process_frames(3)

	assert_almost_eq(world_root.scale.x, 1.6, 0.001, "Zoom in should stop at the configured maximum scale.")

	for _index in range(20):
		_scroll_wheel(game, MOUSE_BUTTON_WHEEL_DOWN)
	await wait_process_frames(3)

	assert_almost_eq(world_root.scale.x, 0.8, 0.001, "Zoom out should stop at the configured minimum scale.")
	assert_almost_eq(world_root.scale.y, 0.8, 0.001, "World scale should stay uniform at minimum zoom.")


func test_emitting_choose_shelf_button_pressed_opens_shelf_modal() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var empty_shelf_state: Control = game.get_node("Room/WorldRoot/SlotsRoot/RoomSlot0/EmptyShelfState")
	var choose_shelf_button: Button = empty_shelf_state.get_node("Panel/Content/ChooseShelfButton")
	var shelf_modal: ShelfModal = game.get_node("ShelfModal")

	choose_shelf_button.pressed.emit()
	await wait_process_frames(3)

	assert_true(shelf_modal.visible, "Direct button signal should open the shelf modal.")


func test_emitting_empty_pot_slot_button_pressed_opens_pot_modal() -> void:
	var game: Control = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	game._on_choose_shelf_button_pressed(0)
	game._on_shelf_selected("shelf_a")
	await wait_process_frames(3)

	var shelf_view: ShelfView = game.get_node("Room/WorldRoot/SlotsRoot/RoomSlot0/ShelfView")
	var first_pot_view: PotView = shelf_view.get_pot_view(0)
	var pot_modal: PotModal = game.get_node("PotModal")

	first_pot_view.slot_button.pressed.emit()
	await wait_process_frames(3)

	assert_true(pot_modal.visible, "Direct slot button signal should open the pot modal.")


func _click_control(control: Control) -> void:
	var sender: GutInputSender = autofree(GutInputSender.new(Input))
	sender.set_auto_flush_input(true)
	var global_position := control.get_global_rect().get_center()
	sender.mouse_left_button_down(global_position, global_position)
	sender.mouse_left_button_up(global_position, global_position)


func _scroll_wheel(control: Control, button_index: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	var global_position := control.get_global_rect().get_center()
	event.position = global_position
	event.global_position = global_position
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
