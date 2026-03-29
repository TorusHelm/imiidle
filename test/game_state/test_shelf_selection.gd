extends GutTest


func test_starts_without_active_shelf_and_with_both_shelves_in_inventory() -> void:
	var game_state := GameState.new()

	assert_null(game_state.get_active_shelf_definition(), "Game should start without a placed shelf.")
	assert_eq(game_state.get_shelf_count("shelf_a"), 1, "Shelf A should be available once at start.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 1, "Shelf B should be available once at start.")
	assert_eq(game_state.shelf_slots.size(), 0, "No shelf slots should exist before placing a shelf.")


func test_place_shelf_consumes_inventory_and_builds_slots() -> void:
	var game_state := GameState.new()

	var placed := game_state.place_shelf("shelf_b")

	assert_true(placed, "Expected shelf placement to succeed.")
	assert_eq(game_state.get_active_shelf_definition().id, "shelf_b", "Placed shelf should become active.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 0, "Placed shelf should be removed from inventory.")
	assert_eq(game_state.shelf_slots.size(), game_state.get_active_shelf_definition().slot_positions.size(), "Shelf slots should match the selected shelf.")
	assert_false(game_state.can_place_shelf("shelf_a"), "Another shelf should not be placeable once one is active.")
