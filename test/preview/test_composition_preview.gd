extends GutTest


const COMPOSITION_PREVIEW_SCENE := preload("res://sceens/CompositionPreview.tscn")
const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const SHELF_B: ShelfDefinition = preload("res://Shelfs/ShelfB/data/shelf_b.tres")


func test_disabled_preview_slot_hides_pot_and_plant() -> void:
	var preview: Control = add_child_autofree(COMPOSITION_PREVIEW_SCENE.instantiate())
	await wait_process_frames(2)

	var shelf_view: ShelfView = preview.get_node("ShelfView")
	var target_index := 2
	var target_slot: CompositionPreviewSlot = preview.preview_slots[target_index]

	target_slot.enabled = false
	preview._refresh_preview()
	await wait_process_frames(2)

	var pot_view: PotView = shelf_view.get_pot_view(target_index)
	assert_false(pot_view.pot_texture.visible, "Disabled slot should not show pot texture.")
	assert_false(pot_view.plant_view.visible, "Disabled slot should not show plant view.")
	assert_true(pot_view.slot_button.visible, "Disabled slot should fall back to empty-slot button.")


func test_enabled_preview_slot_shows_assigned_pot_and_plant() -> void:
	var preview: Control = add_child_autofree(COMPOSITION_PREVIEW_SCENE.instantiate())
	await wait_process_frames(2)

	var shelf_view: ShelfView = preview.get_node("ShelfView")
	var target_index := 1
	var target_slot: CompositionPreviewSlot = preview.preview_slots[target_index]

	target_slot.enabled = true
	preview._refresh_preview()
	await wait_process_frames(2)

	var pot_view: PotView = shelf_view.get_pot_view(target_index)
	assert_true(pot_view.pot_texture.visible, "Enabled slot should show pot texture.")
	assert_true(pot_view.plant_view.visible, "Enabled slot should show plant view.")
	assert_false(pot_view.slot_button.visible, "Enabled slot should not show empty-slot button.")


func test_changing_shelf_definition_rebuilds_preview_with_target_shelf() -> void:
	var preview: Control = add_child_autofree(COMPOSITION_PREVIEW_SCENE.instantiate())
	await wait_process_frames(2)

	var shelf_view: ShelfView = preview.get_node("ShelfView")
	assert_eq(shelf_view.get_slot_count(), SHELF_B.slot_positions.size(), "Preview should start with Shelf B slot count.")
	assert_eq(shelf_view.get_node("ShelfTitle").text, SHELF_B.display_name, "Preview should start with Shelf B title.")

	preview.shelf_definition = SHELF_A
	preview._refresh_preview()
	await wait_process_frames(2)

	assert_eq(shelf_view.get_slot_count(), SHELF_A.slot_positions.size(), "Preview should rebuild slot count after switching shelf definition.")
	assert_eq(shelf_view.get_node("ShelfTitle").text, SHELF_A.display_name, "Preview should display the selected shelf title after switching.")

	var first_pot_view: PotView = shelf_view.get_pot_view(0)
	assert_not_null(first_pot_view, "Switched shelf should still render pot previews in available slots.")
	assert_true(first_pot_view.pot_texture.visible, "First preview slot should keep showing its configured pot after switching shelves.")
