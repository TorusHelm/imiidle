extends GutTest


const SHELF_A: ShelfDefinition = preload("res://Shelfs/ShelfA/data/shelf_a.tres")
const DEFAULT_POT: PotDefinition = preload("res://Pots/DefaultPot/data/pot_default.tres")


func test_metronome_reacts_one_tick_later_and_applies_haste_on_next_tick() -> void:
	var shelf := ShelfInstance.new(SHELF_A)
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

	var metronome_definition := TotemDefinition.new()
	metronome_definition.id = "metronome"
	metronome_definition.display_name = "Metronome"
	metronome_definition.target_rule = "mirror_from_source"
	metronome_definition.modifier_type = "haste"
	metronome_definition.modifier_multiplier = 2.0
	metronome_definition.modifier_duration = 1.0

	assert_true(shelf.place_pot(0, DEFAULT_POT), "Plant source slot should accept a pot.")
	assert_true(shelf.place_totem(1, TotemInstance.new(metronome_definition)), "Middle slot should accept the metronome.")
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
