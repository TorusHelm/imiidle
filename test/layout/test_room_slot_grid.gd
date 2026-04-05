extends GutTest


const DEFAULT_ROOM: RoomDefinition = preload("res://Rooms/DefaultRoom/data/default_room.tres")
const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")


func test_default_room_grid_reuses_shared_slot_unit_and_excludes_center_gap() -> void:
	var positions := DEFAULT_ROOM.get_slot_positions()

	assert_same(DEFAULT_ROOM.get_slot_layout(), DEFAULT_SLOT_LAYOUT, "Default room should reuse the shared slot layout resource.")
	assert_eq(DEFAULT_ROOM.get_slot_area_size(), DEFAULT_SLOT_LAYOUT.slot_area_size, "Room grid cells should match the shared shelf slot unit size.")
	assert_eq(DEFAULT_ROOM.get_slot_count(), 48, "Default room should skip the configured central gap cells and keep the full outer ring.")
	assert_eq(positions[0], Vector2(40, 180), "First room grid cell should start at the configured room origin.")
	assert_eq(positions[11], Vector2(1910, 180), "Top row should advance by one shared slot width per room cell.")
	assert_eq(positions[12], Vector2(40, 460), "Second row should start directly below the first row using the shared slot height.")
	assert_eq(positions[14], Vector2(380, 460), "Second row should preserve the shared slot step before the central exclusion.")
	assert_eq(positions[15], Vector2(1570, 460), "Central gap should remove the middle cells from the generated room grid.")
	assert_eq(positions[47], Vector2(1910, 1580), "Last room grid cell should land on the bottom-right edge after the exclusion.")
