extends GutTest


const POT_SCENE := preload("res://Pots/_shared/sceens/Pot.tscn")
const SHELF_SCENE := preload("res://Shelfs/_shared/sceens/Shelf.tscn")
const ORANGE_POT: PotDefinition = preload("res://Pots/OrangePot/data/pot_orange.tres")
const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")


func test_pot_view_uses_visual_layout_from_definition_resource() -> void:
	var pot_view: PotView = add_child_autofree(POT_SCENE.instantiate())
	await wait_process_frames(2)

	pot_view.update_view(PotInstance.new(ORANGE_POT), true, true)
	await wait_process_frames(2)

	assert_true(pot_view.visible, "Pot view should stay visible when a pot instance is shown.")
	assert_eq(pot_view.custom_minimum_size, ORANGE_POT.view_size, "Pot view size should come from the definition resource.")
	assert_eq(pot_view.pot_texture.position, ORANGE_POT.pot_texture_position, "Pot sprite position should come from the definition resource.")
	assert_eq(pot_view.pot_texture.size, ORANGE_POT.pot_texture_size, "Pot sprite size should come from the definition resource.")
	assert_not_null(pot_view.pot_texture.texture, "Pot sprite should load from the texture path stored in the definition resource.")
	assert_eq(pot_view.get_pot_baseline_local_position(), ORANGE_POT.pot_baseline, "Pot baseline should come from the definition resource.")
	assert_eq(pot_view.get_slot_footprint_local_rect(), ORANGE_POT.get_slot_footprint_local_rect(), "Pot footprint should come from the definition resource.")


func test_pot_view_refreshes_when_preview_definition_texture_size_changes() -> void:
	var pot_view: PotView = add_child_autofree(POT_SCENE.instantiate())
	var preview_definition: PotDefinition = ORANGE_POT.duplicate(true)
	await wait_process_frames(2)

	pot_view.preview_definition = preview_definition
	await wait_process_frames(2)

	var updated_texture_size := Vector2(96.0, 132.0)

	preview_definition.pot_texture_size = updated_texture_size
	preview_definition.emit_changed()
	await wait_process_frames(2)

	assert_eq(pot_view.pot_texture.size, updated_texture_size, "Pot preview should react to pot_texture_size changes from the assigned definition resource.")


func test_runtime_shelf_pot_uses_definition_texture_size() -> void:
	var shelf_view: ShelfView = add_child_autofree(SHELF_SCENE.instantiate())
	var runtime_definition: PotDefinition = ORANGE_POT.duplicate(true)
	runtime_definition.pot_texture_size = Vector2(14.0, 18.0)
	await wait_process_frames(2)

	shelf_view.preview(SHELF_A, runtime_definition, null, 0)
	await wait_process_frames(2)

	var pot_view := shelf_view.get_pot_view(0)

	assert_true(pot_view.visible, "Shelf preview should render the pot in the selected slot.")
	assert_eq(pot_view.pot_texture.size, Vector2(14.0, 18.0), "Runtime shelf path should respect PotDefinition.pot_texture_size.")
