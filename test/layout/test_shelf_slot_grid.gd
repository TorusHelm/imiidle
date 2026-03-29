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
