extends GutTest


func test_starts_without_active_shelf_and_with_both_shelves_in_inventory() -> void:
	var game_state := GameState.new()

	assert_null(game_state.get_active_shelf_definition(), "Game should start without a placed shelf.")
	assert_eq(game_state.get_shelf_count("shelf_a"), 1, "Shelf A should be available once at start.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 1, "Shelf B should be available once at start.")
	assert_eq(game_state.get_totem_count("metronome"), 1, "Metronome should exist as a real starter totem in the catalog.")
	assert_eq(game_state.get_room_definition().get_slot_count(), 4, "Default room should expose multiple shelf slots.")
	assert_eq(game_state.shelf_slots.size(), 0, "No shelf slots should exist before placing a shelf.")


func test_place_shelf_consumes_inventory_and_builds_slots() -> void:
	var game_state := GameState.new()

	var placed := game_state.place_shelf(0, "shelf_b")

	assert_true(placed, "Expected shelf placement to succeed.")
	assert_eq(game_state.get_active_shelf_definition().id, "shelf_b", "Placed shelf should become active.")
	assert_eq(game_state.get_shelf_count("shelf_b"), 0, "Placed shelf should be removed from inventory.")
	assert_eq(game_state.shelf_slots.size(), game_state.get_active_shelf_definition().get_slot_count(), "Shelf slots should match the selected shelf.")
	assert_false(game_state.can_place_shelf(0, "shelf_a"), "Occupied room slot should reject another shelf.")
	assert_true(game_state.can_place_shelf(1, "shelf_a"), "Another room slot should still accept a shelf.")


func test_totem_is_placed_into_shelf_slot_through_room_aware_game_state() -> void:
	var game_state := GameState.new()
	assert_true(game_state.place_shelf(0, "shelf_a"), "Expected first room slot to accept Shelf A.")

	var placed := game_state.place_totem(1, "metronome")

	assert_true(placed, "GameState should place a real Metronome into the active shelf through Shelf.")
	assert_not_null(game_state.get_totem_in_room_slot(0, 1), "Placed totem should live inside the shelf slot.")
	assert_eq(game_state.get_totem_count("metronome"), 0, "Placed totem should be consumed from inventory.")
