extends GutTest


const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const SHELF_B: ShelfDefinition = preload("res://Shelfs/ShelfB/data/shelf_b.tres")
const DEFAULT_POT: PotDefinition = preload("res://Pots/DefaultPot/data/pot_default.tres")
const DEFAULT_ROOM: RoomDefinition = preload("res://Game/data/default_room.tres")
const METRONOME: TotemDefinition = preload("res://Totems/Metronome/data/totem_metronome.tres")
const SNAIL: TotemDefinition = preload("res://Totems/Snail/data/totem_snail.tres")


func test_metronome_reacts_one_tick_later_and_applies_haste_on_next_tick_inside_room() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var shelf := ShelfInstance.new(SHELF_A, room)
	var fast_plant := PlantDefinition.new()
	fast_plant.id = "fast"
	fast_plant.display_name = "Fast"
	fast_plant.growth_duration = 0.1
	fast_plant.coins_per_second = 1.0

	var slow_plant := PlantDefinition.new()
	slow_plant.id = "slow"
	slow_plant.display_name = "Slow"
	slow_plant.growth_duration = 10.0
	slow_plant.coins_per_second = 1.0

	assert_true(room.place_shelf(0, shelf), "Room should hold Shelf as a top-level container.")

	assert_true(shelf.place_pot(0, DEFAULT_POT), "Plant source slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(METRONOME)), "Middle slot should accept the metronome.")
	assert_true(shelf.place_pot(2, DEFAULT_POT), "Target slot should accept a pot.")
	assert_true(shelf.plant_seed(0, fast_plant), "Source plant should be planted.")
	assert_true(shelf.plant_seed(2, slow_plant), "Target plant should be planted.")

	var target_plant := shelf.get_pot_in_slot(2).active_plant

	shelf.tick(0.1)
	assert_eq(shelf.get_incoming_events().size(), 1, "Tick N should convert the plant report into one gameplay event for the next tick.")
	assert_eq(target_plant.active_modifiers.size(), 0, "No modifier should be applied in the same tick as the activation.")

	shelf.tick(0.1)
	assert_eq(shelf.get_pending_applications().size(), 1, "Tick N+1 should build one deferred modifier application.")
	assert_eq(target_plant.active_modifiers.size(), 0, "Reaction should not apply the modifier in the same tick.")

	shelf.tick(0.1)
	assert_eq(target_plant.active_modifiers.size(), 1, "Tick N+2 should apply the queued modifier in APPLY.")
	var applied_haste: Variant = target_plant.get_active_modifier("haste")
	assert_not_null(applied_haste, "Target plant should store haste as a modifier instance.")
	assert_eq(applied_haste.get_multiplier(), 2.0, "Metronome should apply haste through Shelf targeting.")
	assert_eq(applied_haste.definition.id, "haste", "Applied haste should come from the shared modifier definition resource.")


func test_room_keeps_shelf_event_loops_isolated() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var source_shelf := ShelfInstance.new(SHELF_A, room)
	var other_shelf := ShelfInstance.new(SHELF_A, room)

	assert_true(room.place_shelf(0, source_shelf), "Room slot 0 should accept the first shelf.")
	assert_true(room.place_shelf(1, other_shelf), "Room slot 1 should accept the second shelf.")
	assert_true(source_shelf.place_pot(0, DEFAULT_POT), "Source shelf should accept the plant pot.")
	assert_true(source_shelf.place_totem(1, TotemInstance.new(METRONOME)), "Source shelf should accept the metronome.")
	assert_true(source_shelf.place_pot(2, DEFAULT_POT), "Source shelf should accept the target pot.")

	var fast_plant := PlantDefinition.new()
	fast_plant.id = "isolated_fast"
	fast_plant.display_name = "Isolated Fast"
	fast_plant.growth_duration = 0.1
	fast_plant.coins_per_second = 1.0

	var slow_plant := PlantDefinition.new()
	slow_plant.id = "isolated_slow"
	slow_plant.display_name = "Isolated Slow"
	slow_plant.growth_duration = 10.0
	slow_plant.coins_per_second = 1.0

	assert_true(source_shelf.plant_seed(0, fast_plant), "Source shelf should plant the trigger plant.")
	assert_true(source_shelf.plant_seed(2, slow_plant), "Source shelf should plant the local target.")
	assert_true(other_shelf.place_pot(0, DEFAULT_POT), "Other shelf should accept its own pot.")
	assert_true(other_shelf.plant_seed(0, slow_plant), "Other shelf should have a plant for cross-shelf isolation checks.")

	var local_target := source_shelf.get_pot_in_slot(2).active_plant
	var remote_target := other_shelf.get_pot_in_slot(0).active_plant

	source_shelf.tick(0.1)
	other_shelf.tick(0.1)
	source_shelf.tick(0.1)
	other_shelf.tick(0.1)
	source_shelf.tick(0.1)
	other_shelf.tick(0.1)

	assert_eq(local_target.active_modifiers.size(), 1, "Metronome should still affect its local shelf target.")
	assert_eq(remote_target.active_modifiers.size(), 0, "Room must not route source shelf events into another shelf.")


func test_snail_applies_slow_to_the_activating_plant_and_keeps_profit_aura_on_the_shelf() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var shelf := ShelfInstance.new(SHELF_B, room)
	var source_plant_definition := PlantDefinition.new()
	source_plant_definition.id = "snail_source"
	source_plant_definition.display_name = "Snail Source"
	source_plant_definition.growth_duration = 0.1
	source_plant_definition.coins_per_second = 1.0

	var other_plant_definition := PlantDefinition.new()
	other_plant_definition.id = "snail_other"
	other_plant_definition.display_name = "Snail Other"
	other_plant_definition.growth_duration = 4.0
	other_plant_definition.coins_per_second = 2.0

	assert_true(room.place_shelf(0, shelf), "Room should hold Shelf B for the Snail targeting test.")
	assert_true(shelf.place_pot(0, DEFAULT_POT), "Source plant slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(SNAIL)), "Snail slot should accept the Snail totem.")
	assert_true(shelf.place_pot(2, DEFAULT_POT), "Second plant slot should accept a pot.")
	assert_true(shelf.place_totem(3, TotemInstance.new(METRONOME)), "Control totem slot should accept another totem for filter checks.")
	assert_true(shelf.plant_seed(0, source_plant_definition), "Source plant should be planted.")
	assert_true(shelf.plant_seed(2, other_plant_definition), "Other plant should be planted.")

	var source_plant := shelf.get_pot_in_slot(0).active_plant
	var other_plant := shelf.get_pot_in_slot(2).active_plant
	var metronome := shelf.get_totem_in_slot(3)
	var source_aura_snapshots := shelf.get_active_aura_snapshots_for_slot(0)
	var other_aura_snapshots := shelf.get_active_aura_snapshots_for_slot(2)

	shelf.tick(0.1)
	assert_almost_eq(shelf.drain_generated_coins(), 0.15, 0.001, "Snail aura should immediately increase the triggering plant reward by 1.5x.")
	shelf.tick(0.1)
	assert_eq(shelf.get_pending_applications().size(), 1, "Snail should schedule one deferred application for the plant that triggered the event.")
	shelf.tick(0.1)

	var source_slow: Variant = source_plant.get_active_modifier("slow")
	var other_slow: Variant = other_plant.get_active_modifier("slow")

	assert_not_null(source_slow, "Snail should apply Slow to the plant that triggered the event.")
	assert_null(other_slow, "Snail should not apply Slow to other plants on the shelf.")
	assert_almost_eq(source_slow.remaining_time, 3.0, 0.001, "Snail Slow should use a 3 second duration.")
	assert_eq(metronome.active_modifiers.size(), 0, "Snail should not apply plant-only modifiers to other totems on the shelf.")
	assert_eq(source_aura_snapshots.size(), 1, "Snail should expose one aura snapshot on the triggering plant slot.")
	assert_eq(other_aura_snapshots.size(), 1, "Snail should expose one aura snapshot on other plant slots too.")
	assert_eq(String(source_aura_snapshots[0].get("aura_type", "")), "rich_harvest_percent", "Snail should expose Rich Harvest as a shelf aura.")

	other_plant.progress_seconds = other_plant.get_cycle_time()
	shelf.tick(0.1)
	assert_almost_eq(shelf.drain_generated_coins(), 12.0, 0.001, "Snail aura should increase reward for every plant on the shelf, not only the triggering plant.")
