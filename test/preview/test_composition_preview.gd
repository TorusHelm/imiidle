extends GutTest


const COMPOSITION_PREVIEW_SCENE := preload("res://sceens/CompositionPreview.tscn")


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
