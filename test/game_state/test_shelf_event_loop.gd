extends GutTest


const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const SHELF_B: ShelfDefinition = preload("res://Shelfs/ShelfB/data/shelf_b.tres")
const DEFAULT_POT: PotDefinition = preload("res://Pots/DefaultPot/data/pot_default.tres")
const DEFAULT_ROOM: RoomDefinition = preload("res://Game/data/default_room.tres")
const METRONOME: TotemDefinition = preload("res://Totems/Metronome/data/totem_metronome.tres")
const SCALES: TotemDefinition = preload("res://Totems/Scales/data/totem_scales.tres")
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


func test_scales_applies_charge_to_the_mirrored_plant() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var shelf := ShelfInstance.new(SHELF_A, room)
	var source_plant_definition := PlantDefinition.new()
	source_plant_definition.id = "ping_source"
	source_plant_definition.display_name = "Ping Source"
	source_plant_definition.growth_duration = 0.1
	source_plant_definition.coins_per_second = 1.0

	var target_plant_definition := PlantDefinition.new()
	target_plant_definition.id = "ping_target"
	target_plant_definition.display_name = "Ping Target"
	target_plant_definition.growth_duration = 10.0
	target_plant_definition.coins_per_second = 1.0

	assert_true(room.place_shelf(0, shelf), "Room should hold Shelf A for Scales.")
	assert_true(shelf.place_pot(0, DEFAULT_POT), "Source plant slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(SCALES)), "Middle slot should accept Scales.")
	assert_true(shelf.place_pot(2, DEFAULT_POT), "Mirrored target slot should accept a pot.")
	assert_true(shelf.plant_seed(0, source_plant_definition), "Source plant should be planted.")
	assert_true(shelf.plant_seed(2, target_plant_definition), "Target plant should be planted.")

	var target_plant := shelf.get_pot_in_slot(2).active_plant

	shelf.tick(0.1)
	shelf.tick(0.1)
	assert_eq(shelf.get_pending_applications().size(), 1, "Scales should schedule one deferred instant effect for the mirrored plant.")
	shelf.tick(0.1)

	assert_almost_eq(target_plant.progress_seconds, 1.3, 0.001, "Scales charge should advance the mirrored plant by one second during APPLY and then continue normal tick progress.")
	assert_eq(target_plant.activation_count, 0, "Charge should not activate a long-cycle plant immediately when it stays below the threshold.")


func test_target_required_tags_filter_targets_before_apply() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var shelf := ShelfInstance.new(SHELF_A, room)
	var flower_plant_definition := PlantDefinition.new()
	flower_plant_definition.id = "flower_target"
	flower_plant_definition.display_name = "Flower Target"
	flower_plant_definition.tags = ["flower"]
	flower_plant_definition.growth_duration = 0.1
	flower_plant_definition.coins_per_second = 1.0

	var cactus_plant_definition := PlantDefinition.new()
	cactus_plant_definition.id = "cactus_target"
	cactus_plant_definition.display_name = "Cactus Target"
	cactus_plant_definition.tags = ["cactus"]
	cactus_plant_definition.growth_duration = 10.0
	cactus_plant_definition.coins_per_second = 1.0

	var tagged_totem_definition := TotemDefinition.new()
	tagged_totem_definition.id = "tag_filter_totem"
	tagged_totem_definition.display_name = "Tag Filter Totem"
	tagged_totem_definition.trigger_event_type = "plant_activated"
	tagged_totem_definition.target_rule = "all_plants"
	tagged_totem_definition.target_actor_type = "plant"
	tagged_totem_definition.target_required_tags = ["flower"]
	tagged_totem_definition.modifier_definitions = [preload("res://Modifiers/Slow/data/modifier_slow_long.tres")]

	assert_true(room.place_shelf(0, shelf), "Room should hold Shelf A for tag filtering.")
	assert_true(shelf.place_pot(0, DEFAULT_POT), "First plant slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(tagged_totem_definition)), "Middle slot should accept the custom tag filter totem.")
	assert_true(shelf.place_pot(2, DEFAULT_POT), "Second plant slot should accept a pot.")
	assert_true(shelf.plant_seed(0, flower_plant_definition), "Flower-tagged plant should be planted.")
	assert_true(shelf.plant_seed(2, cactus_plant_definition), "Cactus-tagged plant should be planted.")

	shelf.tick(0.1)
	shelf.tick(0.1)
	shelf.tick(0.1)

	assert_not_null(shelf.get_pot_in_slot(0).active_plant.get_active_modifier("slow"), "Required tag filter should allow the flower-tagged plant to receive the modifier.")
	assert_null(shelf.get_pot_in_slot(2).active_plant.get_active_modifier("slow"), "Required tag filter should exclude plants without the matching tag.")


func test_same_row_plants_rule_ignores_other_rows() -> void:
	var room := RoomInstance.new(DEFAULT_ROOM)
	var shelf := ShelfInstance.new(SHELF_B, room)
	var trigger_plant_definition := PlantDefinition.new()
	trigger_plant_definition.id = "row_trigger"
	trigger_plant_definition.display_name = "Row Trigger"
	trigger_plant_definition.growth_duration = 0.1
	trigger_plant_definition.coins_per_second = 1.0

	var same_row_plant_definition := PlantDefinition.new()
	same_row_plant_definition.id = "same_row"
	same_row_plant_definition.display_name = "Same Row"
	same_row_plant_definition.growth_duration = 10.0
	same_row_plant_definition.coins_per_second = 1.0

	var other_row_plant_definition := PlantDefinition.new()
	other_row_plant_definition.id = "other_row"
	other_row_plant_definition.display_name = "Other Row"
	other_row_plant_definition.growth_duration = 10.0
	other_row_plant_definition.coins_per_second = 1.0

	var row_totem_definition := TotemDefinition.new()
	row_totem_definition.id = "row_totem"
	row_totem_definition.display_name = "Row Totem"
	row_totem_definition.trigger_event_type = "plant_activated"
	row_totem_definition.target_rule = "same_row_plants"
	row_totem_definition.target_actor_type = "plant"
	row_totem_definition.modifier_definitions = [preload("res://Modifiers/Slow/data/modifier_slow_long.tres")]

	assert_true(room.place_shelf(0, shelf), "Room should hold Shelf B for same-row targeting.")
	assert_true(shelf.place_pot(0, DEFAULT_POT), "Trigger plant slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(row_totem_definition)), "Row totem slot should accept the custom totem.")
	assert_true(shelf.place_pot(2, DEFAULT_POT), "Same-row target slot should accept a pot.")
	assert_true(shelf.place_pot(3, DEFAULT_POT), "Other-row plant slot should accept a pot.")
	assert_true(shelf.plant_seed(0, trigger_plant_definition), "Trigger plant should be planted.")
	assert_true(shelf.plant_seed(2, same_row_plant_definition), "Same-row target plant should be planted.")
	assert_true(shelf.plant_seed(3, other_row_plant_definition), "Other-row target plant should be planted.")

	shelf.tick(0.1)
	shelf.tick(0.1)
	shelf.tick(0.1)

	assert_not_null(shelf.get_pot_in_slot(2).active_plant.get_active_modifier("slow"), "same_row_plants should affect targets in the trigger row.")
	assert_null(shelf.get_pot_in_slot(3).active_plant.get_active_modifier("slow"), "same_row_plants should not affect plants in other rows.")
