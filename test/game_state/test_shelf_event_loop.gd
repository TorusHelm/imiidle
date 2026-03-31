extends GutTest


const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const DEFAULT_POT: PotDefinition = preload("res://Pots/DefaultPot/data/pot_default.tres")
const DEFAULT_ROOM: RoomDefinition = preload("res://Game/data/default_room.tres")
const METRONOME: TotemDefinition = preload("res://Totems/Metronome/data/totem_metronome.tres")


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
	assert_eq(target_plant.get_active_modifier("haste").get("multiplier"), 2.0, "Metronome should apply haste through Shelf targeting.")


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
