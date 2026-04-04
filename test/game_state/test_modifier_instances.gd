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


func test_plant_does_not_activate_before_minimum_age_even_with_full_progress() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "min_age_test_plant"
	plant_definition.display_name = "Min Age Test Plant"
	plant_definition.growth_duration = 0.1
	plant_definition.coins_per_second = 1.0
	var plant := PlantInstance.new(plant_definition)
	plant.progress_seconds = plant.get_cycle_time()
	plant.age_seconds = 0.9

	var early_report := plant.update_tick(0.05)
	assert_true(early_report.is_empty(), "Plant should not activate before reaching the minimum age, even if it already has enough progress.")
	assert_eq(plant.activation_count, 0, "Plant should not count activations before the minimum age gate opens.")

	var ready_report := plant.update_tick(0.05)
	assert_eq(float(ready_report.get("reward", 0.0)), 0.1, "Plant should activate normally once the minimum age is reached.")
	assert_eq(plant.activation_count, 1, "Plant should activate immediately after reaching the minimum age when progress is already sufficient.")


func test_charge_effect_waits_for_minimum_age_before_activation() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "charge_min_age_plant"
	plant_definition.display_name = "Charge Min Age Plant"
	plant_definition.growth_duration = 0.5
	plant_definition.coins_per_second = 2.0
	var plant := PlantInstance.new(plant_definition)
	plant.age_seconds = 0.5

	var blocked_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 1})
	assert_true(blocked_report.is_empty(), "Charge should not activate a plant before it reaches the minimum activation age.")
	assert_eq(plant.activation_count, 0, "Blocked charge should not increment activation count.")
	assert_eq(plant.progress_seconds, 1.0, "Blocked charge should still keep the added progress for later activation.")

	var ready_report := plant.update_tick(0.5)
	assert_eq(float(ready_report.get("reward", 0.0)), 1.0, "Stored progress should activate once the plant reaches the minimum age.")
	assert_eq(plant.activation_count, 1, "Plant should activate after the age gate opens using the stored charge progress.")


func test_charge_activation_cooldown_blocks_immediate_repeat_from_any_source() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "charge_cooldown_plant"
	plant_definition.display_name = "Charge Cooldown Plant"
	plant_definition.growth_duration = 1.0
	plant_definition.coins_per_second = 1.0
	var plant := PlantInstance.new(plant_definition)
	plant.age_seconds = 1.0

	var first_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 1})
	assert_eq(float(first_report.get("reward", 0.0)), 1.0, "First charge should activate once the plant is old enough.")
	assert_eq(plant.activation_count, 1, "First charge should increment activation count.")

	var blocked_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 2})
	assert_true(blocked_report.is_empty(), "Immediate follow-up charge from another source should respect the shared charge activation cooldown.")
	assert_eq(plant.activation_count, 1, "Blocked charge should not increment activation count.")
	assert_eq(plant.progress_seconds, 1.0, "Blocked charge should keep its progress instead of being discarded.")

	plant.advance(0.25)
	var resumed_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 3})
	assert_eq(float(resumed_report.get("reward", 0.0)), 1.0, "Charge should activate again after the shared cooldown expires.")
	assert_eq(plant.activation_count, 2, "Plant should activate again once the charge cooldown window has passed.")


func test_blocked_charge_does_not_activate_again_during_the_same_tick_update() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "charge_same_tick_guard_plant"
	plant_definition.display_name = "Charge Same Tick Guard Plant"
	plant_definition.growth_duration = 1.0
	plant_definition.coins_per_second = 1.0
	var plant := PlantInstance.new(plant_definition)
	plant.age_seconds = 1.0

	var first_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 1})
	assert_eq(float(first_report.get("reward", 0.0)), 1.0, "First charge should activate immediately once the plant is old enough.")

	var blocked_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 2})
	assert_true(blocked_report.is_empty(), "Immediate second charge should be blocked by the shared charge activation cooldown.")

	var same_tick_report := plant.update_tick(0.15)
	assert_true(same_tick_report.is_empty(), "Blocked charge should not leak into a normal activation later in the same shelf tick.")
	assert_eq(plant.activation_count, 1, "Same-tick update should not create an extra activation after a blocked charge.")

	var resumed_report := plant.update_tick(0.10)
	assert_eq(float(resumed_report.get("reward", 0.0)), 1.0, "Stored charged progress should activate once the cooldown window expires.")
	assert_eq(plant.activation_count, 2, "Plant should activate once after the blocked charge cooldown window has passed.")


func test_blocked_charges_do_not_accumulate_more_than_one_pending_cycle() -> void:
	var plant_definition := PlantDefinition.new()
	plant_definition.id = "charge_overflow_cap_plant"
	plant_definition.display_name = "Charge Overflow Cap Plant"
	plant_definition.growth_duration = 1.0
	plant_definition.coins_per_second = 1.0
	var plant := PlantInstance.new(plant_definition)
	plant.age_seconds = 1.0

	var first_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 1})
	assert_eq(float(first_report.get("reward", 0.0)), 1.0, "First charge should activate immediately.")

	var second_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 2})
	var third_report := plant.apply_instant_effect(CHARGE_EFFECT, {"source_slot_index": 3})
	assert_true(second_report.is_empty(), "Second charge inside cooldown should be deferred.")
	assert_true(third_report.is_empty(), "Third charge inside cooldown should also be deferred.")
	assert_eq(plant.progress_seconds, 1.0, "Deferred charges should cap stored progress at one full cycle instead of accumulating unlimited overflow.")

	var resumed_report := plant.update_tick(0.25)
	assert_eq(float(resumed_report.get("reward", 0.0)), 1.0, "Only one delayed activation should be released after the cooldown window.")
	assert_eq(plant.activation_count, 2, "Multiple blocked charges should still result in just one queued activation.")
