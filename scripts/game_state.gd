class_name GameState
extends RefCounted

const DEFAULT_CATALOG: GameCatalog = preload("res://Game/data/default_catalog.tres")

var coins := 0.0
var experience := 0.0
var seed_inventory: Dictionary = {}
var plant_definitions: Dictionary = {}
var pot_inventory: Dictionary = {}
var pot_definitions: Dictionary = {}
var shelf_inventory: Dictionary = {}
var shelf_definitions: Dictionary = {}
var active_shelf_definition: ShelfDefinition
var background_color_hex := "#e3efdf"
var shelf_slots: Array = []
var growth_system := GrowthSystem.new()


func _init() -> void:
	_load_catalog(DEFAULT_CATALOG)


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
	if active_shelf_definition == null:
		return false

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


func has_any_shelf() -> bool:
	for shelf_count in shelf_inventory.values():
		if int(shelf_count) > 0:
			return true
	return false


func can_place_shelf(shelf_id := "") -> bool:
	if active_shelf_definition != null:
		return false

	if shelf_id.is_empty():
		return has_any_shelf()

	return get_shelf_count(shelf_id) > 0


func place_shelf(shelf_id: String) -> bool:
	if not can_place_shelf(shelf_id):
		return false

	var definition: ShelfDefinition = shelf_definitions.get(shelf_id)
	if definition == null:
		return false

	shelf_inventory[shelf_id] = get_shelf_count(shelf_id) - 1
	active_shelf_definition = definition
	ensure_shelf_slot_capacity(active_shelf_definition.get_slot_count())
	return true


func get_shelf_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	for shelf_id in shelf_definitions.keys():
		var definition: ShelfDefinition = shelf_definitions[shelf_id]
		options.append(
			{
				"id": definition.id,
				"display_name": definition.display_name,
				"count": get_shelf_count(definition.id),
			}
		)

	return options


func get_shelf_count(shelf_id: String) -> int:
	return int(shelf_inventory.get(shelf_id, 0))


func get_active_shelf_definition() -> ShelfDefinition:
	return active_shelf_definition


func get_background_color() -> Color:
	return Color.from_string(background_color_hex, Color(0.890196, 0.937255, 0.878431, 1))


func tick(delta: float) -> void:
	for pot in shelf_slots:
		if pot == null or pot.active_plant == null:
			continue
		coins += growth_system.tick_plant(pot.active_plant, delta)


func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < shelf_slots.size()


func _load_catalog(catalog: GameCatalog) -> void:
	plant_definitions.clear()
	pot_definitions.clear()
	shelf_definitions.clear()
	seed_inventory.clear()
	pot_inventory.clear()
	shelf_inventory.clear()
	active_shelf_definition = null
	background_color_hex = "#e3efdf"

	if catalog == null:
		ensure_shelf_slot_capacity(0)
		return

	for definition in catalog.plant_definitions:
		if definition == null or definition.id.is_empty():
			continue
		plant_definitions[definition.id] = definition

	for definition in catalog.pot_definitions:
		if definition == null or definition.id.is_empty():
			continue
		pot_definitions[definition.id] = definition

	for definition in catalog.shelf_definitions:
		if definition == null or definition.id.is_empty():
			continue
		shelf_definitions[definition.id] = definition

	for seed_id in catalog.starting_seed_inventory.keys():
		seed_inventory[seed_id] = int(catalog.starting_seed_inventory[seed_id])

	for pot_id in catalog.starting_pot_inventory.keys():
		pot_inventory[pot_id] = int(catalog.starting_pot_inventory[pot_id])

	for shelf_id in catalog.starting_shelf_inventory.keys():
		shelf_inventory[shelf_id] = int(catalog.starting_shelf_inventory[shelf_id])

	active_shelf_definition = shelf_definitions.get(catalog.active_shelf_id)

	background_color_hex = catalog.background_color_hex

	ensure_shelf_slot_capacity(active_shelf_definition.get_slot_count() if active_shelf_definition != null else 0)
