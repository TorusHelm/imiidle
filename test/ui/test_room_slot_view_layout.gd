extends GutTest


const ROOM_SLOT_SCENE := preload("res://Ui/RoomShelfSlot.tscn")
const DEFAULT_ROOM: RoomDefinition = preload("res://Rooms/DefaultRoom/data/default_room.tres")
const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")


func test_room_slot_view_uses_shared_room_slot_size_for_placeholder() -> void:
	var room_slot_view: RoomSlotView = add_child_autofree(ROOM_SLOT_SCENE.instantiate())
	var slot_size := DEFAULT_ROOM.get_slot_area_size()
	await wait_process_frames(2)

	room_slot_view.show_empty(slot_size)
	await wait_process_frames(2)

	var slot_frame: TextureRect = room_slot_view.get_node("SlotFrame")

	assert_eq(room_slot_view.size, slot_size, "Room slot view should size itself to the shared room grid cell.")
	assert_eq(slot_frame.size, slot_size, "Room slot placeholder texture should fill exactly one shared room grid cell.")
	assert_eq(room_slot_view.get_node("EmptyShelfState").size, slot_size, "Empty room slot overlay should stay inside the shared room grid cell.")


func test_room_slot_view_aligns_shelf_to_first_shared_slot_origin() -> void:
	var room_slot_view: RoomSlotView = add_child_autofree(ROOM_SLOT_SCENE.instantiate())
	var game_state := GameState.new()
	var slot_size := DEFAULT_ROOM.get_slot_area_size()
	await wait_process_frames(2)

	assert_true(game_state.place_shelf(0, "shelf_a"), "Test setup should place Shelf A into the first room grid cell.")
	room_slot_view.show_shelf(slot_size, SHELF_A, game_state, 0)
	await wait_process_frames(2)

	assert_eq(room_slot_view.shelf_view.position, -SHELF_A.get_primary_slot_work_area_origin(), "Shelf view should snap its first internal slot work area to the room grid cell origin.")
