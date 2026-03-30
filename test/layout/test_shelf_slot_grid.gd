extends GutTest


const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const SHELF_B: ShelfDefinition = preload("res://Shelfs/ShelfB/data/shelf_b.tres")
const DEFAULT_POT: PotDefinition = preload("res://Pots/DefaultPot/data/pot_default.tres")
const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")


func test_shelf_a_uses_fixed_three_slot_work_area() -> void:
	var positions := SHELF_A.get_slot_positions()

	assert_true(SHELF_A.use_slot_grid, "Shelf A should use grid-based slot layout.")
	assert_eq(SHELF_A.get_slot_count(), 3, "Shelf A should resolve to three slots.")
	assert_eq(positions, [Vector2(92, 204), Vector2(262, 204), Vector2(432, 204)], "Shelf A slots should be derived from the shared slot unit.")


func test_shelf_b_reuses_same_slot_unit_across_two_rows() -> void:
	var positions := SHELF_B.get_slot_positions()

	assert_true(SHELF_B.use_slot_grid, "Shelf B should use grid-based slot layout.")
	assert_eq(SHELF_B.get_slot_count(), 6, "Shelf B should resolve to six slots.")
	assert_eq(positions, [
		Vector2(92, 284),
		Vector2(262, 284),
		Vector2(432, 284),
		Vector2(92, 606),
		Vector2(262, 606),
		Vector2(432, 606),
	], "Shelf B should stack the same slot unit across rows without changing slot width.")


func test_shelf_and_pot_share_the_same_slot_layout_resource() -> void:
	assert_same(SHELF_A.get_slot_layout(), DEFAULT_SLOT_LAYOUT, "Shelf A should use the shared slot layout resource.")
	assert_same(SHELF_B.get_slot_layout(), DEFAULT_SLOT_LAYOUT, "Shelf B should use the shared slot layout resource.")
	assert_same(DEFAULT_POT.get_slot_layout(), DEFAULT_SLOT_LAYOUT, "Default pot should use the shared slot layout resource.")
	assert_eq(DEFAULT_POT.get_slot_footprint_size(), SHELF_A.get_slot_area_size(), "Pot footprint should match the shared slot size.")
	assert_eq(DEFAULT_POT.get_slot_footprint_offset(), -SHELF_A.get_slot_anchor_offset(), "Pot footprint origin should be derived from the shared slot anchor.")


func test_shelf_model_exposes_grid_navigation_api() -> void:
	var model := SHELF_B.get_shelf_model()
	var center_slot := model.get_slot(1, 1)
	var slot_by_index := model.get_slot_by_index(4)
	var neighbors_4 := _slot_indexes(model.get_neighbors_4(0, 1))
	var neighbors_8 := _slot_indexes(model.get_neighbors_8(0, 1))

	neighbors_4.sort()
	neighbors_8.sort()

	assert_eq(model.rows, 2, "Shelf model should preserve the configured row count.")
	assert_eq(model.cols, 3, "Shelf model should preserve the configured column count.")
	assert_true(model.is_in_bounds(1, 2), "Grid coordinates inside the shelf should be valid.")
	assert_false(model.is_in_bounds(2, 0), "Grid coordinates outside the shelf should be rejected.")
	assert_eq(model.get_index(1, 2), 5, "Grid navigation should resolve row and column to the flat slot index.")
	assert_eq(center_slot.get("index"), 4, "Shelf model should expose the correct index for row/column lookup.")
	assert_eq(slot_by_index.get("position"), Vector2(262, 606), "Flat index lookup should keep the existing slot anchor position.")
	assert_eq(neighbors_4, [0, 2, 4], "4-neighbors should include only orthogonal adjacent slots.")
	assert_eq(neighbors_8, [0, 2, 3, 4, 5], "8-neighbors should include diagonals around the target slot.")


func test_manual_slot_positions_build_a_linear_shelf_model() -> void:
	var definition := ShelfDefinition.new()
	definition.slot_positions = [Vector2(10, 20), Vector2(40, 20), Vector2(70, 20)]

	var model := definition.get_shelf_model()

	assert_eq(model.rows, 1, "Manual slot shelves should stay addressable as a single logical row.")
	assert_eq(model.cols, 3, "Manual slot shelves should expose one column per manual slot.")
	assert_eq(model.get_index(0, 2), 2, "Linear manual shelves should preserve flat index lookup.")
	assert_eq(model.get_slot(0, 1).get("position"), Vector2(40, 20), "Manual slot positions should pass through unchanged.")


func _slot_indexes(slots: Array[Dictionary]) -> Array[int]:
	var indexes: Array[int] = []
	for slot in slots:
		indexes.append(slot.get("index", -1))
	return indexes
