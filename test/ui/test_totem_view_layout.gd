extends GutTest


const TOTEM_SCENE := preload("res://Totems/_shared/sceens/Totem.tscn")
const SHELF_SCENE := preload("res://Shelfs/_shared/sceens/Shelf.tscn")
const METRONOME: TotemDefinition = preload("res://Totems/Metronome/data/totem_metronome.tres")
const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")


func test_totem_view_uses_visual_layout_from_definition_resource() -> void:
	var totem_view: TotemView = add_child_autofree(TOTEM_SCENE.instantiate())
	await wait_process_frames(2)

	totem_view.show_totem(TotemInstance.new(METRONOME))
	await wait_process_frames(2)

	var texture_rect: TextureRect = totem_view.get_node("TotemTexture")

	assert_true(totem_view.visible, "Totem view should become visible when a totem instance is shown.")
	assert_eq(totem_view.custom_minimum_size, METRONOME.view_size, "Totem view size should come from the definition resource.")
	assert_eq(texture_rect.position, METRONOME.texture_position, "Totem sprite position should come from the definition resource.")
	assert_eq(texture_rect.size, METRONOME.texture_size, "Totem sprite size should come from the definition resource.")
	assert_not_null(texture_rect.texture, "Totem sprite should load from the texture path stored in the definition resource.")
	assert_eq(totem_view.get_totem_baseline_local_position(), METRONOME.totem_baseline, "Totem baseline should come from the definition resource.")
	assert_eq(totem_view.get_slot_footprint_local_rect(), METRONOME.get_slot_footprint_local_rect(), "Totem footprint should come from the definition resource.")


func test_totem_view_refreshes_when_preview_definition_texture_size_changes() -> void:
	var totem_view: TotemView = add_child_autofree(TOTEM_SCENE.instantiate())
	var preview_definition: TotemDefinition = METRONOME.duplicate(true)
	await wait_process_frames(2)

	totem_view.preview_definition = preview_definition
	await wait_process_frames(2)

	var texture_rect: TextureRect = totem_view.get_node("TotemTexture")
	var updated_texture_size := Vector2(88.0, 144.0)

	preview_definition.texture_size = updated_texture_size
	preview_definition.emit_changed()
	await wait_process_frames(2)

	assert_eq(texture_rect.size, updated_texture_size, "Totem preview should react to texture_size changes from the assigned definition resource.")


func test_runtime_shelf_totem_uses_definition_texture_size() -> void:
	var shelf_view: ShelfView = add_child_autofree(SHELF_SCENE.instantiate())
	var runtime_definition: TotemDefinition = METRONOME.duplicate(true)
	runtime_definition.texture_size = Vector2(12.0, 15.0)
	await wait_process_frames(2)

	shelf_view.preview_totem_definition = runtime_definition
	shelf_view.preview(SHELF_A, null, null, 0)
	await wait_process_frames(2)

	var totem_view := shelf_view.get_totem_view(0)
	var texture_rect: TextureRect = totem_view.get_node("TotemTexture")

	assert_true(totem_view.visible, "Shelf preview should render the totem in the selected slot.")
	assert_eq(texture_rect.size, Vector2(12.0, 15.0), "Runtime shelf path should respect TotemDefinition.texture_size.")
