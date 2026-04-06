extends GutTest


func test_starts_without_active_shelf_and_with_both_shelves_in_inventory() -> void:
	var game_state := GameState.new()

	assert_null(game_state.get_active_shelf_definition(), "Game should start without a placed shelf.")
	assert_eq(game_state.get_shelf_count("shelf_a"), 1, "Shelf A should be available once at start.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 1, "Shelf B should be available once at start.")
	assert_eq(game_state.get_totem_count("metronome"), 1, "Metronome should exist as a real starter totem in the catalog.")
	assert_eq(game_state.get_item_backpack_items().size(), 13, "Starter pots, totems, and seeds should exist as real backpack items, not only as counters.")
	assert_eq(game_state.get_room_definition().get_slot_count(), 48, "Default room should expose the full 12x6 perimeter grid after excluding the central gap.")
	assert_eq(game_state.shelf_slots.size(), 0, "No shelf slots should exist before placing a shelf.")
	assert_eq(game_state.get_shelf_backpack_item_count(), 2, "Starter shelves should exist as movable backpack items, not only as counters.")


func test_place_shelf_consumes_inventory_and_builds_slots() -> void:
	var game_state := GameState.new()

	var placed := game_state.place_shelf(0, "shelf_b")

	assert_true(placed, "Expected shelf placement to succeed.")
	assert_eq(game_state.get_active_shelf_definition().id, "shelf_b", "Placed shelf should become active.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 0, "Placed shelf should be removed from inventory.")
	assert_eq(game_state.shelf_slots.size(), game_state.get_active_shelf_definition().get_slot_count(), "Shelf slots should match the selected shelf.")
	assert_false(game_state.can_place_shelf(0, "shelf_a"), "Anchor cell should reject another shelf once occupied.")
	assert_false(game_state.can_place_shelf(1, "shelf_a"), "Cells covered by a placed multi-cell shelf should also count as occupied.")
	assert_true(game_state.can_place_shelf(3, "shelf_a"), "The next free anchor cell after Shelf B footprint should still accept Shelf A.")


func test_invalid_room_placement_keeps_shelf_in_backpack() -> void:
	var game_state := GameState.new()

	var placed := game_state.place_shelf(2, "shelf_b")

	assert_false(placed, "Shelf B should not place when its 3x2 footprint crosses blocked room cells.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 1, "Rejected shelf placement should keep the shelf item in backpack inventory.")
	assert_eq(game_state.get_shelf_backpack_item_count(), 2, "Rejected shelf placement should not destroy any backpack shelf items.")


func test_moving_shelf_preserves_contents() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected Shelf A to place into the first valid room anchor cell.")
	assert_true(game_state.place_pot(0, "default_pot"), "Placed shelf should still accept a pot in its first slot.")
	assert_true(game_state.plant_seed(0, "gerbera"), "Placed pot should still accept a plant before moving the shelf.")

	var original_shelf := game_state.get_shelf_in_room_slot(0)
	var original_plant := game_state.get_pot_in_room_slot(0, 0).active_plant

	assert_true(game_state.move_shelf_in_room(0, 3), "Shelf A should move to another valid 3x1 room anchor without being recreated.")

	var moved_shelf := game_state.get_shelf_in_room_slot(3)
	var moved_plant := game_state.get_pot_in_room_slot(3, 0).active_plant

	assert_same(moved_shelf, original_shelf, "Moving a shelf inside the room should keep the same shelf runtime instance.")
	assert_same(moved_plant, original_plant, "Moving a shelf inside the room should preserve the existing pot and plant contents.")
	assert_null(game_state.get_shelf_in_room_slot(0), "Old anchor cell should become empty after moving the shelf.")


func test_totem_is_placed_into_shelf_slot_through_room_aware_game_state() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected first room slot to accept Shelf A.")

	var placed := game_state.place_totem(1, "metronome")

	assert_true(placed, "GameState should place a real Metronome into the active shelf through Shelf.")
	assert_not_null(game_state.get_totem_in_room_slot(0, 1), "Placed totem should live inside the shelf slot.")
	assert_eq(game_state.get_totem_count("metronome"), 0, "Placed totem should be consumed from inventory.")


func test_backpack_item_can_be_placed_directly_into_shelf_slot() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected first room slot to accept Shelf A.")

	var pot_item = game_state.get_item_backpack_items().filter(func(item): return item.kind == "pot" and item.get_display_definition().id == "default_pot")[0]

	assert_true(game_state.place_backpack_item_in_room_shelf_slot(pot_item.runtime_id, 0, 0), "Dragging a pot from the item backpack into a shelf slot should place it there.")
	assert_not_null(game_state.get_pot_in_room_slot(0, 0), "Dragged backpack pot should appear inside the shelf slot.")
	assert_eq(game_state.get_pot_count("default_pot"), 2, "Placing one default pot from the backpack should reduce the derived inventory count.")


func test_room_shelf_item_can_be_moved_back_to_item_backpack() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected first room slot to accept Shelf A.")
	assert_true(game_state.place_pot(0, "default_pot"), "Expected first slot to accept a pot from inventory.")
	assert_true(game_state.plant_seed(0, "gerbera"), "Expected placed pot to accept a plant before moving back to the backpack.")

	var backpack_origin := Vector2i(-1, -1)
	for row in range(game_state.SHELF_BACKPACK_ROWS):
		for column in range(game_state.SHELF_BACKPACK_COLUMNS):
			var candidate := Vector2i(column, row)
			if game_state.shelf_backpack.can_place("", candidate, Vector2i.ONE):
				backpack_origin = candidate
				break
		if backpack_origin.x >= 0:
			break

	assert_true(backpack_origin.x >= 0, "Test setup should find a free backpack cell for the returned pot.")

	assert_true(game_state.move_room_shelf_item_to_backpack(0, 0, backpack_origin), "Dragging a shelf pot back into the item backpack should succeed.")
	assert_null(game_state.get_pot_in_room_slot(0, 0), "Source shelf slot should become empty after moving the item back to the backpack.")
	assert_eq(game_state.get_item_backpack_items().filter(func(item): return item.kind == "pot" and item.backpack_origin == backpack_origin).size(), 1, "Returned pot should occupy the requested backpack grid cell.")


func test_item_backpack_item_can_move_to_empty_grid_cell() -> void:
	var game_state := GameState.new()
	var backpack_item = game_state.get_item_backpack_items()[0]
	var target_origin := Vector2i(10, 2)

	assert_true(game_state.can_move_or_swap_backpack_item(backpack_item.runtime_id, target_origin), "Item backpack should allow moving an item into a free grid cell.")
	assert_true(game_state.move_backpack_item(backpack_item.runtime_id, target_origin), "Moving an item inside the backpack should succeed when the target cell is empty.")
	assert_eq(backpack_item.backpack_origin, target_origin, "Moved backpack item should update its stored grid origin.")


func test_item_backpack_items_can_swap_positions() -> void:
	var game_state := GameState.new()
	var first_item = game_state.get_item_backpack_items()[0]
	var second_item = game_state.get_item_backpack_items()[1]
	var first_origin: Vector2i = first_item.backpack_origin
	var second_origin: Vector2i = second_item.backpack_origin

	assert_true(game_state.can_move_or_swap_backpack_item(first_item.runtime_id, second_origin), "Backpack should allow swapping two occupied item cells.")
	assert_true(game_state.move_backpack_item(first_item.runtime_id, second_origin), "Dropping an item onto another occupied cell should swap their backpack positions.")
	assert_eq(first_item.backpack_origin, second_origin, "Dragged item should occupy the target cell after swap.")
	assert_eq(second_item.backpack_origin, first_origin, "Overlapped item should move back into the dragged item's original cell after swap.")


func test_moving_pot_between_shelf_slots_resets_plant_runtime_state() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected Shelf A to place into room slot 0.")
	game_state.set_active_room_slot_index(0)
	assert_true(game_state.place_pot(0, "default_pot"), "Expected first slot to accept a pot.")
	assert_true(game_state.plant_seed(0, "gerbera"), "Expected placed pot to accept a seed.")

	var plant: PlantInstance = game_state.get_pot_in_room_slot(0, 0).active_plant
	plant.progress_seconds = 2.5
	plant.age_seconds = 9.0
	plant.activation_count = 3
	plant.apply_modifier(preload("res://Modifiers/Haste/data/modifier_haste.tres"), {})

	assert_true(game_state.move_item_in_room_shelf_slot(0, 0, 1), "Shelf should allow moving a planted pot to another slot.")

	var moved_pot := game_state.get_pot_in_room_slot(0, 1)

	assert_not_null(moved_pot, "Moved pot should appear in the target slot.")
	assert_eq(moved_pot.active_plant.progress_seconds, 0.0, "Moved plant progress should reset after dragging between shelf slots.")
	assert_eq(moved_pot.active_plant.age_seconds, 0.0, "Moved plant age should reset after dragging between shelf slots.")
	assert_eq(moved_pot.active_plant.activation_count, 0, "Moved plant activation history should reset after dragging between shelf slots.")
	assert_eq(moved_pot.active_plant.active_modifiers.size(), 0, "Moved plant should drop timed modifiers after dragging between shelf slots.")


func test_swapping_pot_and_totem_resets_both_runtime_states() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected Shelf A to place into room slot 0.")
	game_state.set_active_room_slot_index(0)
	assert_true(game_state.place_pot(0, "default_pot"), "Expected first slot to accept a pot.")
	assert_true(game_state.place_totem(1, "metronome"), "Expected second slot to accept a totem.")
	assert_true(game_state.plant_seed(0, "gerbera"), "Expected placed pot to accept a seed.")

	var plant: PlantInstance = game_state.get_pot_in_room_slot(0, 0).active_plant
	var totem: TotemInstance = game_state.get_totem_in_room_slot(0, 1)
	plant.progress_seconds = 1.0
	plant.activation_count = 2
	plant.apply_modifier(preload("res://Modifiers/Haste/data/modifier_haste.tres"), {})
	totem.activation_count = 4
	totem.apply_modifier(preload("res://Modifiers/Slow/data/modifier_slow_long.tres"), {})

	assert_true(game_state.move_item_in_room_shelf_slot(0, 0, 1), "Shelf should allow swapping occupied slots.")

	var swapped_totem := game_state.get_totem_in_room_slot(0, 0)
	var swapped_pot := game_state.get_pot_in_room_slot(0, 1)

	assert_not_null(swapped_totem, "Totem should move into the source slot after swap.")
	assert_not_null(swapped_pot, "Pot should move into the target slot after swap.")
	assert_eq(swapped_totem.activation_count, 0, "Moved totem activation state should reset after swap.")
	assert_eq(swapped_totem.active_modifiers.size(), 0, "Moved totem timed modifiers should reset after swap.")
	assert_eq(swapped_pot.active_plant.progress_seconds, 0.0, "Swapped plant progress should reset after swap.")
	assert_eq(swapped_pot.active_plant.active_modifiers.size(), 0, "Swapped plant timed modifiers should reset after swap.")
