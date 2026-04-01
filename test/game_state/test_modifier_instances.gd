extends GutTest


const HASTE_MODIFIER = preload("res://Modifiers/Haste/data/modifier_haste.tres")
const SLOW_MODIFIER = preload("res://Modifiers/Slow/data/modifier_slow.tres")
const RICH_HARVEST_PERCENT_MODIFIER = preload("res://Modifiers/RichHarvest/data/modifier_rich_harvest_percent.tres")
const RICH_HARVEST_FLAT_MODIFIER = preload("res://Modifiers/RichHarvest/data/modifier_rich_harvest_flat.tres")
const CHARGE_EFFECT = preload("res://Effects/Charge/data/effect_charge_1s.tres")


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


func test_modifier_snapshot_exposes_stable_ui_contract() -> void:
	var modifier_instance = ModifierInstance.new(HASTE_MODIFIER, {"source_slot_index": 1, "source_actor_type": "totem"})
	var snapshot := modifier_instance.to_snapshot()

	assert_eq(snapshot.get("id"), "haste", "Modifier snapshot should expose stable definition id.")
	assert_eq(snapshot.get("modifier_type"), "haste", "Modifier snapshot should expose modifier type for view routing.")
	assert_eq(snapshot.get("display_name"), "Haste", "Modifier snapshot should expose display name from the definition.")
	assert_eq(snapshot.get("description"), "Increases target speed while active.", "Modifier snapshot should expose description from the definition.")
	assert_ne(String(snapshot.get("icon_path", "")), "", "Modifier snapshot should expose a non-empty icon reference from the definition.")
	assert_eq(snapshot.get("stacks"), 1, "Current modifier model should expose a fixed stack count for UI consistency.")
	assert_eq(snapshot.get("speed_multiplier"), 2.0, "Haste snapshot should expose speed contribution.")
	assert_eq(snapshot.get("reward_multiplier"), 1.0, "Unused reward multiplier should stay neutral in the snapshot.")
	assert_eq(snapshot.get("flat_reward_bonus"), 0.0, "Unused flat reward bonus should stay neutral in the snapshot.")
	assert_false(bool(snapshot.get("blocks_activation", true)), "Haste should not block activations.")
	assert_eq(int((snapshot.get("source", {}) as Dictionary).get("source_slot_index", -1)), 1, "Snapshot should retain source metadata for tooltip/debug usage.")


func test_slow_modifier_reduces_plant_progress_through_general_speed_api() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "slow_test_plant"
	plant_definition.display_name = "Slow Test Plant"
	plant_definition.growth_duration = 10.0
	var plant := PlantInstance.new(plant_definition)

	plant.apply_modifier(SLOW_MODIFIER)
	plant.update_tick(1.0)

	assert_almost_eq(plant.progress_seconds, 0.5, 0.001, "Slow should reduce plant progress through the shared speed modifier calculation.")


func test_rich_harvest_percent_modifier_multiplies_reward() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "rich_percent_plant"
	plant_definition.display_name = "Rich Percent Plant"
	plant_definition.growth_duration = 2.0
	plant_definition.coins_per_second = 2.0
	var plant := PlantInstance.new(plant_definition)

	plant.apply_modifier(RICH_HARVEST_PERCENT_MODIFIER)

	assert_eq(plant.get_activation_reward(), 6.0, "Percent rich harvest should multiply the base activation reward.")


func test_rich_harvest_flat_modifier_adds_flat_reward_bonus() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "rich_flat_plant"
	plant_definition.display_name = "Rich Flat Plant"
	plant_definition.growth_duration = 2.0
	plant_definition.coins_per_second = 2.0
	var plant := PlantInstance.new(plant_definition)

	plant.apply_modifier(RICH_HARVEST_FLAT_MODIFIER)

	assert_eq(plant.get_activation_reward(), 5.0, "Flat rich harvest should add a fixed bonus coin on top of the base activation reward.")


func test_game_state_loads_modifier_definition_library_from_catalog() -> void:
	var game_state := GameState.new()

	assert_not_null(game_state.get_modifier_definition("haste"), "Default catalog should register Haste in the modifier library.")
	assert_not_null(game_state.get_modifier_definition("slow"), "Default catalog should register Slow in the modifier library.")
	assert_not_null(game_state.get_modifier_definition("rich_harvest_percent"), "Default catalog should register percent Rich Harvest in the modifier library.")
	assert_not_null(game_state.get_modifier_definition("rich_harvest_flat"), "Default catalog should register flat Rich Harvest in the modifier library.")
	assert_not_null(game_state.get_aura_definition("rich_harvest_percent_aura"), "Default catalog should register Rich Harvest aura in the aura library.")
	assert_not_null(game_state.get_instant_effect_definition("charge_1s"), "Default catalog should register Charge in the instant effect library.")


func test_charge_effect_resets_progress_to_zero_after_activation_overflow() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "charge_test_plant"
	plant_definition.display_name = "Charge Test Plant"
	plant_definition.growth_duration = 0.5
	plant_definition.coins_per_second = 2.0
	var plant := PlantInstance.new(plant_definition)
	plant.progress_seconds = 0.2

	var report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 1})

	assert_eq(plant.activation_count, 1, "Charge should trigger one activation when the added seconds overflow the cycle.")
	assert_eq(plant.progress_seconds, 0.0, "Charge overflow should reset progress to zero after activation.")
	assert_eq(float(report.get("reward", 0.0)), 1.0, "Charge-triggered activation should return the same reward report as a normal plant activation.")
