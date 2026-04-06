extends GutTest


const GAME_SCENE := preload("res://sceens/Game.tscn")


func test_backpack_renders_starter_shelves_as_mini_items() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var backpack: ShelfBackpackView = _get_backpack_view(game)

	assert_eq(backpack.get_node("ItemsRoot").get_child_count(), 2, "Backpack should render the two starter shelves as draggable mini items.")
	assert_eq(backpack.columns, 15, "Backpack should render half as many inventory columns so shelf items read more clearly.")
	assert_eq(backpack.cell_size, Vector2(24.0, 24.0), "Backpack cells should be larger so shelf silhouettes are easier to identify.")
	assert_eq(backpack.custom_minimum_size, Vector2(402.0, 537.0), "Backpack view size should match the updated 15x20 grid with larger cells and gaps.")


func test_backpack_item_size_scales_with_larger_inventory_cells() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var backpack: ShelfBackpackView = _get_backpack_view(game)
	var item_view: DraggableShelfItemView = backpack.get_node("ItemsRoot").get_child(0) as DraggableShelfItemView
	var shelf_item = game.game_state.get_shelf_backpack_items()[0]
	var footprint: Vector2i = shelf_item.get_footprint()
	var expected_size := Vector2(
		footprint.x * backpack.cell_size.x + max(footprint.x - 1, 0) * backpack.cell_gap.x,
		footprint.y * backpack.cell_size.y + max(footprint.y - 1, 0) * backpack.cell_gap.y
	)

	assert_not_null(item_view, "Backpack should create an item view for the starter shelf.")
	assert_eq(item_view.size, expected_size, "Backpack shelf item should grow with the larger inventory cells.")


func test_backpack_item_views_are_not_rebuilt_on_every_refresh() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var backpack: ShelfBackpackView = _get_backpack_view(game)
	var first_item := backpack.get_node("ItemsRoot").get_child(0)
	var first_item_id := first_item.get_instance_id()

	game._refresh_ui()
	await wait_process_frames(2)

	var refreshed_first_item := backpack.get_node("ItemsRoot").get_child(0)
	assert_eq(refreshed_first_item.get_instance_id(), first_item_id, "Backpack items must survive UI refreshes; rebuilding them every frame breaks drag-and-drop.")


func test_backpack_item_root_receives_drag_input_instead_of_inner_frame() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var backpack: Control = _get_backpack_view(game)
	var item_view: DraggableShelfItemView = backpack.get_node("ItemsRoot").get_child(0) as DraggableShelfItemView

	assert_not_null(item_view, "Backpack should create at least one draggable shelf item view.")
	assert_eq(item_view.get_node("Frame").mouse_filter, Control.MOUSE_FILTER_IGNORE, "Inner frame must ignore mouse so the root draggable control can start the drag.")
	assert_eq(item_view.get_node("Frame/ShelfMount/Shelf").mouse_filter, Control.MOUSE_FILTER_IGNORE, "Embedded shelf preview must also ignore mouse so its texture and labels do not steal the drag gesture.")


func test_backpack_item_preview_builds_without_ready_errors() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var backpack: Control = _get_backpack_view(game)
	var item_view: DraggableShelfItemView = backpack.get_node("ItemsRoot").get_child(0) as DraggableShelfItemView
	var preview: Control = autofree(item_view._build_drag_preview_control())

	assert_not_null(preview, "Backpack item should be able to build drag preview control.")
	assert_eq(preview.get_child_count(), 1, "Drag preview should contain a single shelf preview control.")


func test_room_slot_drop_places_shelf_from_backpack() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items()[0]
	var room_slot_view := _get_room_slot_view(game, 0)

	room_slot_view._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	assert_not_null(game.game_state.get_shelf_in_room_slot(0), "Dropping a backpack shelf onto a room cell should place it in the room.")
	assert_eq(game.game_state.get_shelf_backpack_item_count(), 1, "Placed shelf should be removed from the backpack grid.")


func test_room_slots_covered_by_shelf_hide_placeholder_visuals() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	var covered_room_slot_view := _get_room_slot_view(game, 1)

	assert_not_null(game.game_state.get_shelf_in_room_slot(1), "Setup should cover the next room cell with the placed shelf footprint.")
	assert_eq(game.game_state.get_room_shelf_anchor_slot_index(1), 0, "Covered room cell should point back to the shelf anchor.")
	assert_true(covered_room_slot_view.visible, "Covered room slot should stay in the tree so preview overlays can still render there.")
	assert_false(covered_room_slot_view.get_node("SlotFrame").visible, "Covered room cell should hide the room slot frame once a shelf occupies it.")
	assert_false(covered_room_slot_view.get_node("EmptyShelfState").visible, "Covered room cell should not show the empty-slot placeholder while occupied by a shelf.")


func test_room_shelf_anchor_slot_hides_placeholder_visuals() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	var anchor_room_slot_view := _get_room_slot_view(game, 0)

	assert_not_null(game.game_state.get_shelf_in_room_slot(0), "Setup should place the shelf into the anchor room cell.")
	assert_eq(game.game_state.get_room_shelf_anchor_slot_index(0), 0, "Anchor room cell should point to itself as the shelf anchor.")
	assert_true(anchor_room_slot_view.visible, "Anchor room slot should stay in the tree so drag and preview plumbing still works.")
	assert_false(anchor_room_slot_view.get_node("SlotFrame").visible, "Anchor room cell should hide the room slot frame once the shelf is rendered in the room.")
	assert_false(anchor_room_slot_view.get_node("EmptyShelfState").visible, "Anchor room cell should not show the empty-slot placeholder while occupied by a shelf.")


func test_room_drop_preview_marks_entire_shelf_footprint() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var runtime_id: String = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_b")[0].runtime_id
	var room_slot_view := _get_room_slot_view(game, 0)

	assert_true(room_slot_view._can_drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": runtime_id}), "Shelf B should fit in the first room anchor cell.")

	assert_true(_get_room_slot_view(game, 0).get_node("PreviewOverlay").visible, "Preview should mark the anchor cell.")
	assert_true(_get_room_slot_view(game, 1).get_node("PreviewOverlay").visible, "Preview should extend across the shelf footprint width.")
	assert_true(_get_room_slot_view(game, 12).get_node("PreviewOverlay").visible, "Preview should extend across the shelf footprint height.")


func test_backpack_drop_moves_shelf_back_out_of_room() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items()[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	var backpack: Control = _get_backpack_view(game)
	backpack._drop_data(Vector2(101.0, 101.0), {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	assert_null(game.game_state.get_shelf_in_room_slot(0), "Dropping a placed shelf back into the backpack should clear the room anchor.")
	assert_eq(game.game_state.get_shelf_backpack_item_count(), 2, "Returned shelf should reappear in the backpack grid.")


func test_clicking_empty_pot_slot_opens_pot_modal_after_shelf_drop() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	var shelf_view: ShelfView = _get_room_shelf_view(game, 0)
	var first_pot_view: PotView = shelf_view.get_pot_view(0)
	var pot_modal: PotModal = game.get_node("PotModal")

	assert_not_null(first_pot_view, "Dropped shelf should create its first pot slot view.")
	first_pot_view.slot_button.pressed.emit()
	await wait_process_frames(3)

	assert_true(pot_modal.visible, "Clicking an empty pot slot should still open the pot modal after the shelf drag/drop refactor.")


func test_second_shelf_slot_stays_addressable_after_placing_first_pot() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	game.game_state.set_active_room_slot_index(0)
	assert_true(game.game_state.place_pot(0, "default_pot"), "Setup should place a pot into slot 0.")
	game._refresh_ui()
	await wait_process_frames(2)

	var shelf_view: ShelfView = _get_room_shelf_view(game, 0)
	var second_pot_view: PotView = shelf_view.get_pot_view(1)
	var pot_modal: PotModal = game.get_node("PotModal")

	assert_not_null(second_pot_view, "Dropped shelf should still expose the second slot view.")
	assert_true(second_pot_view.slot_button.visible, "Second slot button should stay visible when the slot is empty.")
	assert_false(second_pot_view.slot_button.disabled, "Second slot button should remain enabled when there are still pots in inventory.")
	second_pot_view.slot_button.pressed.emit()
	await wait_process_frames(3)

	assert_true(pot_modal.visible, "Second slot should still open the modal after the first slot receives a pot.")
	assert_eq(pot_modal.current_slot_index, 1, "Second slot should still target shelf slot index 1 after the first slot receives a pot.")


func test_dragging_pot_to_other_shelf_slot_moves_it_and_resets_progress() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	game.game_state.set_active_room_slot_index(0)
	assert_true(game.game_state.place_pot(0, "default_pot"), "Setup should place a pot into slot 0.")
	assert_true(game.game_state.plant_seed(0, "gerbera"), "Setup should plant a seed into slot 0.")
	game.game_state.get_pot_in_room_slot(0, 0).active_plant.progress_seconds = 3.0
	game._refresh_ui()
	await wait_process_frames(2)

	var shelf_view: ShelfView = _get_room_shelf_view(game, 0)
	var target_pot_view: PotView = shelf_view.get_pot_view(1)
	target_pot_view._drop_data(Vector2.ZERO, {"type": "shelf_slot_item", "source_room_slot_index": 0, "source_slot_index": 0})
	await wait_process_frames(3)

	assert_null(game.game_state.get_pot_in_room_slot(0, 0), "Source slot should become empty after dragging the pot away.")
	assert_not_null(game.game_state.get_pot_in_room_slot(0, 1), "Target slot should receive the dragged pot.")
	assert_eq(game.game_state.get_pot_in_room_slot(0, 1).active_plant.progress_seconds, 0.0, "Dragged plant progress should reset after moving inside the shelf.")


func test_dragging_pot_onto_totem_swaps_their_slots() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	game.game_state.set_active_room_slot_index(0)
	assert_true(game.game_state.place_pot(0, "default_pot"), "Setup should place a pot into slot 0.")
	assert_true(game.game_state.plant_seed(0, "gerbera"), "Setup should plant a seed into slot 0.")
	assert_true(game.game_state.place_totem(1, "metronome"), "Setup should place a totem into slot 1.")
	game._refresh_ui()
	await wait_process_frames(2)

	var shelf_view: ShelfView = _get_room_shelf_view(game, 0)
	var target_totem_view: TotemView = shelf_view.get_totem_view(1)
	target_totem_view._drop_data(Vector2.ZERO, {"type": "shelf_slot_item", "source_room_slot_index": 0, "source_slot_index": 0})
	await wait_process_frames(3)

	assert_not_null(game.game_state.get_totem_in_room_slot(0, 0), "Totem should move into the source slot after swap.")
	assert_not_null(game.game_state.get_pot_in_room_slot(0, 1), "Pot should move into the target slot after swap.")


func test_mouse_wheel_zooms_world_without_changing_pan_offset() -> void:
	var game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_process_frames(3)

	var shelf_item = game.game_state.get_shelf_backpack_items().filter(func(item): return item.definition.id == "shelf_a")[0]
	_get_room_slot_view(game, 0)._drop_data(Vector2.ZERO, {"type": "shelf", "runtime_id": shelf_item.runtime_id})
	await wait_process_frames(3)

	var world_root: Control = _get_world_root(game)
	var initial_position := world_root.position

	_scroll_wheel(game, MOUSE_BUTTON_WHEEL_UP)
	await wait_process_frames(3)

	assert_eq(world_root.position, initial_position, "Mouse wheel zoom should not change world pan offset.")
	assert_almost_eq(world_root.scale.x, 1.1, 0.001, "Mouse wheel up should zoom the world in.")
	assert_almost_eq(world_root.scale.y, 1.1, 0.001, "World scale should stay uniform after zoom in.")


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


func _get_room_view(game) -> RoomView:
	return game.find_child("Room", true, false) as RoomView


func _get_room_slot_view(game, room_slot_index := 0) -> RoomSlotView:
	var room_view := _get_room_view(game)
	var slots_root: Control = room_view.get_node("WorldRoot/SlotsRoot")
	if room_slot_index < 0 or room_slot_index >= slots_root.get_child_count():
		return null
	return slots_root.get_child(room_slot_index) as RoomSlotView


func _get_backpack_view(game):
	return game.find_child("ShelfBackpack", true, false)


func _get_world_root(game) -> Control:
	return _get_room_view(game).world_root


func _get_room_shelf_view(game, room_slot_index: int) -> ShelfView:
	var shelves_root: Control = _get_room_view(game).get_node("WorldRoot/ShelvesRoot")
	for child in shelves_root.get_children():
		if child is ShelfView and int(child.get_meta("room_slot_index", -1)) == room_slot_index:
			return child as ShelfView
	return null
