class_name GameState
extends RefCounted

const DEFAULT_CATALOG: GameCatalog = preload("res://Game/data/default_catalog.tres")

var coins := 0.0
var experience := 0.0
var seed_inventory: Dictionary = {}
var plant_definitions: Dictionary = {}
var pot_inventory: Dictionary = {}
var pot_definitions: Dictionary = {}
var modifier_definitions: Dictionary = {}
var totem_inventory: Dictionary = {}
var totem_definitions: Dictionary = {}
var shelf_inventory: Dictionary = {}
var shelf_definitions: Dictionary = {}
var room_definition: RoomDefinition
var background_color_hex := "#e3efdf"
var shelf_slots: Array = []
var room := RoomInstance.new()
var active_room_slot_index := -1
var _pending_visual_feedback_by_room_slot: Dictionary = {}


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
	var active_shelf := get_active_shelf()
	if active_shelf == null:
		return false

	if not _is_valid_slot_index(slot_index):
		return false

	if not active_shelf.can_place_pot(slot_index):
		return false

	if pot_id.is_empty():
		return has_any_pot()

	return get_pot_count(pot_id) > 0


func place_pot(slot_index: int, pot_id: String) -> bool:
	var active_shelf := get_active_shelf()
	if not can_place_pot(slot_index, pot_id):
		return false

	var definition: PotDefinition = pot_definitions.get(pot_id)
	if definition == null:
		return false

	if not active_shelf.place_pot(slot_index, definition):
		return false

	pot_inventory[pot_id] = get_pot_count(pot_id) - 1
	_sync_shelf_slots()
	return true


func can_plant_seed_in_slot(slot_index: int, seed_id := "") -> bool:
	var active_shelf := get_active_shelf()
	if active_shelf == null or not _is_valid_slot_index(slot_index):
		return false

	if not active_shelf.can_plant_seed(slot_index):
		return false

	return can_plant_seed(seed_id)


func plant_seed(slot_index: int, seed_id: String) -> bool:
	var active_shelf := get_active_shelf()
	if not can_plant_seed_in_slot(slot_index, seed_id):
		return false

	var definition: PlantDefinition = plant_definitions.get(seed_id)
	if definition == null:
		return false

	if not active_shelf.plant_seed(slot_index, definition):
		return false

	seed_inventory[seed_id] = get_seed_count(seed_id) - 1
	_sync_shelf_slots()
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
	var active_shelf := get_active_shelf()
	if active_shelf == null or not _is_valid_slot_index(slot_index):
		return null
	return active_shelf.get_pot_in_slot(slot_index)


func has_any_totem() -> bool:
	for totem_count in totem_inventory.values():
		if int(totem_count) > 0:
			return true
	return false


func get_totem_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	for totem_id in totem_definitions.keys():
		var definition: TotemDefinition = totem_definitions[totem_id]
		options.append(
			{
				"id": definition.id,
				"display_name": definition.display_name,
				"count": get_totem_count(definition.id),
				"trigger_event_type": definition.trigger_event_type,
				"target_rule": definition.target_rule,
			}
		)

	return options


func get_totem_count(totem_id: String) -> int:
	return int(totem_inventory.get(totem_id, 0))


func can_place_totem(slot_index: int, totem_id := "") -> bool:
	var active_shelf := get_active_shelf()
	if active_shelf == null:
		return false

	if not _is_valid_slot_index(slot_index):
		return false

	if not active_shelf.can_place_totem(slot_index):
		return false

	if totem_id.is_empty():
		return has_any_totem()

	return get_totem_count(totem_id) > 0


func place_totem(slot_index: int, totem_id: String) -> bool:
	var active_shelf := get_active_shelf()
	if not can_place_totem(slot_index, totem_id):
		return false

	var definition: TotemDefinition = totem_definitions.get(totem_id)
	if definition == null:
		return false

	if not active_shelf.place_totem(slot_index, TotemInstance.new(definition)):
		return false

	totem_inventory[totem_id] = get_totem_count(totem_id) - 1
	_sync_shelf_slots()
	return true


func get_totem_in_slot(slot_index: int) -> TotemInstance:
	var active_shelf := get_active_shelf()
	if active_shelf == null or not _is_valid_slot_index(slot_index):
		return null
	return active_shelf.get_totem_in_slot(slot_index)


func can_place_pot_in_room_slot(room_slot_index: int, slot_index: int, pot_id := "") -> bool:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null or slot_index < 0 or slot_index >= shelf.slots.size():
		return false
	if not shelf.can_place_pot(slot_index):
		return false
	if pot_id.is_empty():
		return has_any_pot()
	return get_pot_count(pot_id) > 0


func can_plant_seed_in_room_slot(room_slot_index: int, slot_index: int, seed_id := "") -> bool:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null or slot_index < 0 or slot_index >= shelf.slots.size():
		return false
	if not shelf.can_plant_seed(slot_index):
		return false
	return can_plant_seed(seed_id)


func get_pot_in_room_slot(room_slot_index: int, slot_index: int) -> PotInstance:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null:
		return null
	if slot_index < 0 or slot_index >= shelf.slots.size():
		return null
	return shelf.get_pot_in_slot(slot_index)


func can_place_totem_in_room_slot(room_slot_index: int, slot_index: int, totem_id := "") -> bool:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null or slot_index < 0 or slot_index >= shelf.slots.size():
		return false
	if not shelf.can_place_totem(slot_index):
		return false
	if totem_id.is_empty():
		return has_any_totem()
	return get_totem_count(totem_id) > 0


func get_totem_in_room_slot(room_slot_index: int, slot_index: int) -> TotemInstance:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null:
		return null
	if slot_index < 0 or slot_index >= shelf.slots.size():
		return null
	return shelf.get_totem_in_slot(slot_index)


func has_any_shelf() -> bool:
	for shelf_count in shelf_inventory.values():
		if int(shelf_count) > 0:
			return true
	return false


func can_place_shelf(room_slot_index: int, shelf_id := "") -> bool:
	if not room.can_place_shelf(room_slot_index):
		return false

	if shelf_id.is_empty():
		return has_any_shelf()

	return get_shelf_count(shelf_id) > 0


func place_shelf(room_slot_index: int, shelf_id: String) -> bool:
	if not can_place_shelf(room_slot_index, shelf_id):
		return false

	var definition: ShelfDefinition = shelf_definitions.get(shelf_id)
	if definition == null:
		return false

	var shelf := ShelfInstance.new(definition, room)
	if not room.place_shelf(room_slot_index, shelf):
		return false

	shelf_inventory[shelf_id] = get_shelf_count(shelf_id) - 1
	active_room_slot_index = room_slot_index
	_sync_shelf_slots()
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


func get_room_definition() -> RoomDefinition:
	return room_definition


func get_active_shelf_definition() -> ShelfDefinition:
	var active_shelf := get_active_shelf()
	return active_shelf.definition if active_shelf != null else null


func get_active_room_slot_index() -> int:
	return active_room_slot_index


func set_active_room_slot_index(room_slot_index: int) -> void:
	if room_slot_index < 0 or room_slot_index >= room.shelf_slots.size():
		active_room_slot_index = -1
		return
	active_room_slot_index = room_slot_index


func get_active_shelf() -> ShelfInstance:
	if active_room_slot_index < 0:
		return null
	return room.get_shelf(active_room_slot_index)


func get_shelf_in_room_slot(room_slot_index: int) -> ShelfInstance:
	return room.get_shelf(room_slot_index)


func get_background_color() -> Color:
	return Color.from_string(background_color_hex, Color(0.890196, 0.937255, 0.878431, 1))


func get_modifier_definition(modifier_id: String) -> Resource:
	return modifier_definitions.get(modifier_id, null)


func tick(delta: float) -> void:
	_pending_visual_feedback_by_room_slot.clear()

	for room_slot_index in range(room.shelf_slots.size()):
		var shelf: ShelfInstance = room.shelf_slots[room_slot_index]
		if shelf == null:
			continue
		shelf.tick(delta)
		coins += shelf.drain_generated_coins()

		var visual_feedback := shelf.drain_visual_feedback()
		if not visual_feedback.is_empty():
			_pending_visual_feedback_by_room_slot[room_slot_index] = visual_feedback

	_sync_shelf_slots()


func drain_visual_feedback_in_room_slot(room_slot_index: int) -> Array[Dictionary]:
	var drained: Array[Dictionary] = []
	if not _pending_visual_feedback_by_room_slot.has(room_slot_index):
		return drained

	var feedback_variant = _pending_visual_feedback_by_room_slot.get(room_slot_index, [])
	for feedback_event in feedback_variant:
		drained.append((feedback_event as Dictionary).duplicate(true))
	_pending_visual_feedback_by_room_slot.erase(room_slot_index)
	return drained


func get_active_modifiers_in_room_slot(room_slot_index: int, slot_index: int) -> Array:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	return _get_active_modifiers_for_shelf_slot(shelf, slot_index)


func get_active_modifiers_in_slot(slot_index: int) -> Array:
	return _get_active_modifiers_for_shelf_slot(get_active_shelf(), slot_index)


func _get_active_modifiers_for_shelf_slot(shelf: ShelfInstance, slot_index: int) -> Array:
	var modifiers: Array = []
	if shelf == null or slot_index < 0 or slot_index >= shelf.slots.size():
		return modifiers

	var slot := shelf.get_slot(slot_index)
	if slot == null:
		return modifiers

	var actor: RefCounted = slot.get_actor()
	if actor == null:
		return modifiers

	var actor_modifiers: Array = actor.get("active_modifiers")
	for modifier in actor_modifiers:
		modifiers.append(modifier)
	return modifiers


func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < shelf_slots.size()


func _sync_shelf_slots() -> void:
	var active_shelf := get_active_shelf()
	if active_shelf == null:
		ensure_shelf_slot_capacity(0)
		return

	shelf_slots = active_shelf.slots


func _load_catalog(catalog: GameCatalog) -> void:
	plant_definitions.clear()
	pot_definitions.clear()
	modifier_definitions.clear()
	totem_definitions.clear()
	shelf_definitions.clear()
	seed_inventory.clear()
	pot_inventory.clear()
	totem_inventory.clear()
	shelf_inventory.clear()
	room_definition = null
	room = RoomInstance.new()
	active_room_slot_index = -1
	background_color_hex = "#e3efdf"

	if catalog == null:
		ensure_shelf_slot_capacity(0)
		return

	room_definition = catalog.room_definition
	room = RoomInstance.new()
	room.setup(room_definition)

	for definition in catalog.plant_definitions:
		if definition == null or definition.id.is_empty():
			continue
		plant_definitions[definition.id] = definition

	for definition in catalog.pot_definitions:
		if definition == null or definition.id.is_empty():
			continue
		pot_definitions[definition.id] = definition

	for definition in catalog.modifier_definitions:
		if definition == null:
			continue
		var modifier_id := String(definition.get("id"))
		if modifier_id.is_empty():
			continue
		modifier_definitions[modifier_id] = definition

	for definition in catalog.totem_definitions:
		if definition == null or definition.id.is_empty():
			continue
		totem_definitions[definition.id] = definition

	for definition in catalog.shelf_definitions:
		if definition == null or definition.id.is_empty():
			continue
		shelf_definitions[definition.id] = definition

	for seed_id in catalog.starting_seed_inventory.keys():
		seed_inventory[seed_id] = int(catalog.starting_seed_inventory[seed_id])

	for pot_id in catalog.starting_pot_inventory.keys():
		pot_inventory[pot_id] = int(catalog.starting_pot_inventory[pot_id])

	for totem_id in catalog.starting_totem_inventory.keys():
		totem_inventory[totem_id] = int(catalog.starting_totem_inventory[totem_id])

	for shelf_id in catalog.starting_shelf_inventory.keys():
		shelf_inventory[shelf_id] = int(catalog.starting_shelf_inventory[shelf_id])

	background_color_hex = catalog.background_color_hex
	ensure_shelf_slot_capacity(0)
