class_name GameState
extends RefCounted


var coins := 0.0
var experience := 0.0
var seed_inventory: Dictionary = {}
var plant_definitions: Dictionary = {}
var pot_inventory: Dictionary = {}
var pot_definitions: Dictionary = {}
var shelf_slots: Array = []
var growth_system := GrowthSystem.new()


func _init() -> void:
	var pothos := PlantDefinition.new()
	pothos.id = "pothos"
	pothos.display_name = "Sansevieria"
	pothos.growth_duration = 8.0
	pothos.coins_per_second = 1.0
	pothos.display_color = Color(0.286275, 0.717647, 0.341176, 1)
	pothos.texture_path = "res://assets/plants/plant-sansevieria.png"

	var monstera := PlantDefinition.new()
	monstera.id = "gerbera"
	monstera.display_name = "Gerbera"
	monstera.growth_duration = 12.0
	monstera.coins_per_second = 1.6
	monstera.display_color = Color(0.164706, 0.6, 0.270588, 1)
	monstera.texture_path = "res://assets/plants/plant-gerbera.png"

	var cactus := PlantDefinition.new()
	cactus.id = "cactus"
	cactus.display_name = "Cactus"
	cactus.growth_duration = 6.0
	cactus.coins_per_second = 0.8
	cactus.display_color = Color(0.278431, 0.631373, 0.321569, 1)
	cactus.texture_path = "res://assets/plants/plant-cactus.png"

	plant_definitions[pothos.id] = pothos
	plant_definitions[monstera.id] = monstera
	plant_definitions[cactus.id] = cactus

	seed_inventory[pothos.id] = 1
	seed_inventory[monstera.id] = 1
	seed_inventory[cactus.id] = 1

	var default_pot := PotDefinition.new()
	default_pot.id = "default_pot"
	default_pot.display_name = "Clay Pot"
	default_pot.texture_path = "res://assets/pots/pot-default.png"

	var orange_pot := PotDefinition.new()
	orange_pot.id = "orange_pot"
	orange_pot.display_name = "Orange Pot"
	orange_pot.texture_path = "res://assets/pots/pot-orange.png"

	var purple_pot := PotDefinition.new()
	purple_pot.id = "purple_pot"
	purple_pot.display_name = "Purple Pot"
	purple_pot.texture_path = "res://assets/pots/pot-purp.png"

	pot_definitions[default_pot.id] = default_pot
	pot_definitions[orange_pot.id] = orange_pot
	pot_definitions[purple_pot.id] = purple_pot

	pot_inventory[default_pot.id] = 1
	pot_inventory[orange_pot.id] = 1
	pot_inventory[purple_pot.id] = 1

	ensure_shelf_slot_capacity(3)


func ensure_shelf_slot_capacity(slot_count: int) -> void:
	if slot_count <= 0:
		shelf_slots.clear()
		return

	while shelf_slots.size() < slot_count:
		shelf_slots.append(null)

	while shelf_slots.size() > slot_count:
		shelf_slots.resize(slot_count)


func has_any_seed() -> bool:
	for seed_count in seed_inventory.values():
		if int(seed_count) > 0:
			return true
	return false


func can_plant_seed(seed_id := "") -> bool:
	if seed_id.is_empty():
		return has_any_seed()

	return get_seed_count(seed_id) > 0


func can_place_pot(slot_index: int, pot_id := "") -> bool:
	if not _is_valid_slot_index(slot_index):
		return false

	if shelf_slots[slot_index] != null:
		return false

	if pot_id.is_empty():
		return has_any_pot()

	return get_pot_count(pot_id) > 0


func place_pot(slot_index: int, pot_id: String) -> bool:
	if not can_place_pot(slot_index, pot_id):
		return false

	var definition: PotDefinition = pot_definitions.get(pot_id)
	if definition == null:
		return false

	pot_inventory[pot_id] = get_pot_count(pot_id) - 1
	shelf_slots[slot_index] = PotInstance.new(definition)
	return true


func can_plant_seed_in_slot(slot_index: int, seed_id := "") -> bool:
	if not _is_valid_slot_index(slot_index):
		return false

	var pot: PotInstance = shelf_slots[slot_index]
	if pot == null or pot.active_plant != null:
		return false

	return can_plant_seed(seed_id)


func plant_seed(slot_index: int, seed_id: String) -> bool:
	if not can_plant_seed_in_slot(slot_index, seed_id):
		return false

	var definition: PlantDefinition = plant_definitions.get(seed_id)
	if definition == null:
		return false

	seed_inventory[seed_id] = get_seed_count(seed_id) - 1
	var pot: PotInstance = shelf_slots[slot_index]
	pot.active_plant = PlantInstance.new(definition)
	return true


func get_seed_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	for seed_id in plant_definitions.keys():
		var definition: PlantDefinition = plant_definitions[seed_id]
		options.append(
			{
				"id": definition.id,
				"display_name": definition.display_name,
				"count": get_seed_count(definition.id),
				"coins_per_second": definition.coins_per_second,
				"growth_duration": definition.growth_duration,
			}
		)

	return options


func get_seed_count(seed_id: String) -> int:
	return int(seed_inventory.get(seed_id, 0))


func get_total_seed_count() -> int:
	var total := 0
	for seed_count in seed_inventory.values():
		total += int(seed_count)
	return total


func has_any_pot() -> bool:
	for pot_count in pot_inventory.values():
		if int(pot_count) > 0:
			return true
	return false


func get_pot_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	for pot_id in pot_definitions.keys():
		var definition: PotDefinition = pot_definitions[pot_id]
		options.append(
			{
				"id": definition.id,
				"display_name": definition.display_name,
				"count": get_pot_count(definition.id),
				"texture_path": definition.texture_path,
			}
		)

	return options


func get_pot_count(pot_id: String) -> int:
	return int(pot_inventory.get(pot_id, 0))


func get_pot_in_slot(slot_index: int) -> PotInstance:
	if not _is_valid_slot_index(slot_index):
		return null
	return shelf_slots[slot_index]


func tick(delta: float) -> void:
	for pot in shelf_slots:
		if pot == null or pot.active_plant == null:
			continue
		coins += growth_system.tick_plant(pot.active_plant, delta)


func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < shelf_slots.size()
