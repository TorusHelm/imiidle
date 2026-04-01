extends GutTest


const HASTE_MODIFIER = preload("res://Modifiers/Haste/data/modifier_haste.tres")


func test_plant_refreshes_existing_haste_modifier_instance_instead_of_stacking() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "modifier_test_plant"
	plant_definition.display_name = "Modifier Test Plant"
	plant_definition.growth_duration = 10.0
	var plant := PlantInstance.new(plant_definition)

	plant.apply_modifier(HASTE_MODIFIER, {"source_slot_index": 1})
	assert_eq(plant.active_modifiers.size(), 1, "First haste application should create one modifier instance.")

	var first_instance: Variant = plant.get_active_modifier("haste")
	assert_not_null(first_instance, "Haste modifier instance should be accessible by type.")

	first_instance.advance(0.4)
	var remaining_before_refresh: float = first_instance.remaining_time

	plant.apply_modifier(HASTE_MODIFIER, {"source_slot_index": 2})
	assert_eq(plant.active_modifiers.size(), 1, "Repeated haste applications should refresh the same modifier type instead of stacking.")

	var refreshed_instance: Variant = plant.get_active_modifier("haste")
	assert_same(first_instance, refreshed_instance, "Plant should keep the same modifier instance object and refresh it in place.")
	assert_gt(refreshed_instance.remaining_time, remaining_before_refresh, "Refreshing haste should restore its remaining duration.")
	assert_eq(int(refreshed_instance.source.get("source_slot_index", -1)), 2, "Latest source metadata should replace the previous source on refresh.")
