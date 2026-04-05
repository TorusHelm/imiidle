class_name GameState
extends RefCounted

const DEFAULT_CATALOG: GameCatalog = preload("res://Game/data/default_catalog.tres")
const GRID_OCCUPANCY_MODEL_SCRIPT = preload("res://scripts/grid_occupancy_model.gd")
const SHELF_ITEM_INSTANCE_SCRIPT = preload("res://scripts/shelf_item_instance.gd")
const SHELF_BACKPACK_COLUMNS := 30
const SHELF_BACKPACK_ROWS := 20

var coins := 0.0
var experience := 0.0
var seed_inventory: Dictionary = {}
var plant_definitions: Dictionary = {}
var pot_inventory: Dictionary = {}
var pot_definitions: Dictionary = {}
var aura_definitions: Dictionary = {}
var instant_effect_definitions: Dictionary = {}
var modifier_definitions: Dictionary = {}
var totem_inventory: Dictionary = {}
var totem_definitions: Dictionary = {}
var shelf_inventory: Dictionary = {}
var shelf_definitions: Dictionary = {}
var room_definition: RoomDefinition
var background_color_hex := "#e3efdf"
var shelf_slots: Array = []
var room := RoomInstance.new()
var shelf_backpack = GRID_OCCUPANCY_MODEL_SCRIPT.new(SHELF_BACKPACK_COLUMNS, SHELF_BACKPACK_ROWS)
var shelf_items: Dictionary = {}
var active_room_slot_index := -1
var _pending_visual_feedback_by_room_slot: Dictionary = {}
var _next_shelf_runtime_id := 1


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


func can_move_item_in_room_shelf_slot(room_slot_index: int, from_slot_index: int, to_slot_index: int) -> bool:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null:
		return false
	return shelf.can_move_slot_item(from_slot_index, to_slot_index)


func move_item_in_room_shelf_slot(room_slot_index: int, from_slot_index: int, to_slot_index: int) -> bool:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	if shelf == null or not shelf.move_slot_item(from_slot_index, to_slot_index):
		return false
	if active_room_slot_index == room_slot_index:
		_sync_shelf_slots()
	return true


func has_any_shelf() -> bool:
	return get_shelf_backpack_item_count() > 0


func can_place_shelf(room_slot_index: int, shelf_id := "") -> bool:
	var shelf_item: RefCounted = _find_backpack_shelf_item_by_definition_id(shelf_id) if not shelf_id.is_empty() else _get_first_backpack_shelf_item()
	if shelf_item == null:
		return false

	return room.can_place_shelf(room_slot_index, shelf_item.shelf)


func place_shelf(room_slot_index: int, shelf_id: String) -> bool:
	var shelf_item: RefCounted = _find_backpack_shelf_item_by_definition_id(shelf_id)
	if shelf_item == null:
		return false
	return place_shelf_item_in_room(shelf_item.runtime_id, room_slot_index)


func place_shelf_item_in_room(runtime_id: String, room_slot_index: int) -> bool:
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null or shelf_item.shelf == null or not shelf_item.is_in_backpack():
		return false

	if not room.can_place_shelf(room_slot_index, shelf_item.shelf):
		return false
	if not room.place_shelf(room_slot_index, shelf_item.shelf):
		return false

	shelf_backpack.remove(runtime_id)
	shelf_item.backpack_origin = Vector2i(-1, -1)
	shelf_item.room_anchor_slot_index = room_slot_index
	active_room_slot_index = room_slot_index
	_rebuild_shelf_inventory_counts()
	_sync_shelf_slots()
	return true


func can_place_shelf_item_in_room(runtime_id: String, room_slot_index: int) -> bool:
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null or shelf_item.shelf == null:
		return false
	if shelf_item.is_in_backpack():
		return room.can_place_shelf(room_slot_index, shelf_item.shelf)
	if shelf_item.is_in_room():
		return room.can_move_shelf(shelf_item.room_anchor_slot_index, room_slot_index)
	return false


func move_shelf_in_room(from_room_slot_index: int, to_room_slot_index: int) -> bool:
	var shelf_item: RefCounted = _find_room_shelf_item_by_anchor_slot(from_room_slot_index)
	if shelf_item == null:
		return false
	if not room.move_shelf(from_room_slot_index, to_room_slot_index):
		return false

	shelf_item.room_anchor_slot_index = to_room_slot_index
	if active_room_slot_index == from_room_slot_index:
		active_room_slot_index = to_room_slot_index
	_sync_shelf_slots()
	return true


func move_shelf_to_backpack(from_room_slot_index: int, backpack_origin: Vector2i) -> bool:
	var shelf_item: RefCounted = _find_room_shelf_item_by_anchor_slot(from_room_slot_index)
	if shelf_item == null:
		return false
	if not shelf_backpack.place(shelf_item.runtime_id, backpack_origin, shelf_item.get_footprint()):
		return false

	var removed_shelf := room.remove_shelf(from_room_slot_index)
	if removed_shelf == null:
		shelf_backpack.remove(shelf_item.runtime_id)
		return false

	shelf_item.room_anchor_slot_index = -1
	shelf_item.backpack_origin = backpack_origin
	if active_room_slot_index == from_room_slot_index:
		active_room_slot_index = -1
	_rebuild_shelf_inventory_counts()
	_sync_shelf_slots()
	return true


func move_shelf_item_to_room(runtime_id: String, room_slot_index: int) -> bool:
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null:
		return false
	if shelf_item.is_in_backpack():
		return place_shelf_item_in_room(runtime_id, room_slot_index)
	if shelf_item.is_in_room():
		return move_shelf_in_room(shelf_item.room_anchor_slot_index, room_slot_index)
	return false


func can_place_shelf_item_in_backpack(runtime_id: String, backpack_origin: Vector2i) -> bool:
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null:
		return false
	if shelf_item.is_in_backpack():
		return shelf_backpack.can_place(runtime_id, backpack_origin, shelf_item.get_footprint(), runtime_id)
	return shelf_backpack.can_place(runtime_id, backpack_origin, shelf_item.get_footprint())


func can_move_or_swap_shelf_item_in_backpack(runtime_id: String, backpack_origin: Vector2i) -> bool:
	if can_place_shelf_item_in_backpack(runtime_id, backpack_origin):
		return true
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null or not shelf_item.is_in_backpack():
		return false
	var overlaps := shelf_backpack.get_overlapping_item_ids(backpack_origin, shelf_item.get_footprint(), runtime_id)
	if overlaps.size() != 1:
		return false
	var other_item_id := String(overlaps[0])
	var other_item = get_shelf_item(other_item_id)
	if other_item == null:
		return false
	return shelf_backpack.can_place(other_item_id, shelf_item.backpack_origin, other_item.get_footprint(), runtime_id)


func move_shelf_item_to_backpack(runtime_id: String, backpack_origin: Vector2i) -> bool:
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null:
		return false
	if shelf_item.is_in_backpack():
		if not shelf_backpack.try_move_or_swap(runtime_id, backpack_origin):
			return false
		shelf_item.backpack_origin = shelf_backpack.get_item_origin(runtime_id)
		_rebuild_shelf_inventory_counts()
		return true
	if shelf_item.is_in_room():
		return move_shelf_to_backpack(shelf_item.room_anchor_slot_index, backpack_origin)
	return false


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


func get_shelf_backpack_item_count() -> int:
	var count := 0
	for shelf_item in shelf_items.values():
		if shelf_item != null and shelf_item.is_in_backpack():
			count += 1
	return count


func get_shelf_backpack_items() -> Array:
	var items: Array = []
	for shelf_item in shelf_items.values():
		if shelf_item != null and shelf_item.is_in_backpack():
			items.append(shelf_item)
	items.sort_custom(func(a, b) -> bool:
		if a.backpack_origin.y == b.backpack_origin.y:
			return a.backpack_origin.x < b.backpack_origin.x
		return a.backpack_origin.y < b.backpack_origin.y
	)
	return items


func get_shelf_item(runtime_id: String):
	return shelf_items.get(runtime_id, null)


func get_room_shelf_anchor_slot_index(room_slot_index: int) -> int:
	return room.get_shelf_anchor_slot_index(room_slot_index)


func get_room_shelf_runtime_id(room_slot_index: int) -> String:
	var anchor_slot_index := room.get_shelf_anchor_slot_index(room_slot_index)
	if anchor_slot_index < 0:
		return ""
	var shelf_item: RefCounted = _find_room_shelf_item_by_anchor_slot(anchor_slot_index)
	return String(shelf_item.runtime_id) if shelf_item != null else ""


func get_room_shelf_preview(runtime_id: String, room_slot_index: int) -> Dictionary:
	var preview := {
		"slot_indices": [],
		"can_place": false,
	}
	var shelf_item: RefCounted = get_shelf_item(runtime_id)
	if shelf_item == null or room_definition == null:
		return preview

	var anchor_slot := room_definition.get_slot_cell(room_slot_index)
	if anchor_slot.is_empty():
		return preview

	var footprint: Vector2i = shelf_item.get_footprint()
	var slot_indices: Array[int] = []
	for row in range(int(anchor_slot.get("row", -1)), int(anchor_slot.get("row", -1)) + footprint.y):
		for column in range(int(anchor_slot.get("col", -1)), int(anchor_slot.get("col", -1)) + footprint.x):
			var slot_index := room_definition.get_slot_index_at_grid_cell(row, column)
			if slot_index >= 0:
				slot_indices.append(slot_index)
	preview["slot_indices"] = slot_indices
	preview["can_place"] = can_place_shelf_item_in_room(runtime_id, room_slot_index)
	return preview


func get_room_definition() -> RoomDefinition:
	return room_definition


func get_active_shelf_definition() -> ShelfDefinition:
	var active_shelf := get_active_shelf()
	return active_shelf.definition if active_shelf != null else null


func get_active_room_slot_index() -> int:
	return active_room_slot_index


func set_active_room_slot_index(room_slot_index: int) -> void:
	if room_slot_index < 0 or room_slot_index >= room.shelf_slots.size() or room.get_shelf(room_slot_index) == null:
		active_room_slot_index = -1
		return
	var anchor_slot_index := room.get_shelf_anchor_slot_index(room_slot_index)
	active_room_slot_index = anchor_slot_index if anchor_slot_index >= 0 else room_slot_index


func get_active_shelf() -> ShelfInstance:
	if active_room_slot_index < 0:
		return null
	return room.get_shelf(active_room_slot_index)


func get_shelf_in_room_slot(room_slot_index: int) -> ShelfInstance:
	return room.get_shelf(room_slot_index)


func get_background_color() -> Color:
	return Color.from_string(background_color_hex, Color(0.890196, 0.937255, 0.878431, 1))


func get_aura_definition(aura_id: String) -> Resource:
	return aura_definitions.get(aura_id, null)


func get_instant_effect_definition(effect_id: String) -> Resource:
	return instant_effect_definitions.get(effect_id, null)


func get_modifier_definition(modifier_id: String) -> Resource:
	return modifier_definitions.get(modifier_id, null)


func tick(delta: float) -> void:
	_pending_visual_feedback_by_room_slot.clear()

	for room_slot_index in room.get_anchor_slot_indices():
		var shelf: ShelfInstance = room.get_shelf(room_slot_index)
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


func get_active_status_effects_in_room_slot(room_slot_index: int, slot_index: int) -> Array:
	var shelf := get_shelf_in_room_slot(room_slot_index)
	return _get_active_status_effects_for_shelf_slot(shelf, slot_index)


func get_active_status_effects_in_slot(slot_index: int) -> Array:
	return _get_active_status_effects_for_shelf_slot(get_active_shelf(), slot_index)


func get_active_modifiers_in_room_slot(room_slot_index: int, slot_index: int) -> Array:
	return get_active_status_effects_in_room_slot(room_slot_index, slot_index)


func get_active_modifiers_in_slot(slot_index: int) -> Array:
	return get_active_status_effects_in_slot(slot_index)


func _get_active_status_effects_for_shelf_slot(shelf: ShelfInstance, slot_index: int) -> Array:
	var status_effects: Array = []
	if shelf == null or slot_index < 0 or slot_index >= shelf.slots.size():
		return status_effects

	var slot := shelf.get_slot(slot_index)
	if slot == null:
		return status_effects

	var actor: RefCounted = slot.get_actor()
	if actor == null:
		return status_effects

	for aura_snapshot in shelf.get_active_aura_snapshots_for_slot(slot_index):
		status_effects.append(aura_snapshot)

	var actor_modifiers: Array = actor.get("active_modifiers")
	for modifier in actor_modifiers:
		status_effects.append(modifier)
	return status_effects


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
	aura_definitions.clear()
	instant_effect_definitions.clear()
	modifier_definitions.clear()
	totem_definitions.clear()
	shelf_definitions.clear()
	seed_inventory.clear()
	pot_inventory.clear()
	totem_inventory.clear()
	shelf_inventory.clear()
	room_definition = null
	room = RoomInstance.new()
	shelf_backpack = GRID_OCCUPANCY_MODEL_SCRIPT.new(SHELF_BACKPACK_COLUMNS, SHELF_BACKPACK_ROWS)
	shelf_items.clear()
	active_room_slot_index = -1
	background_color_hex = "#e3efdf"
	_next_shelf_runtime_id = 1

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

	for definition in catalog.aura_definitions:
		if definition == null:
			continue
		var aura_id := String(definition.get("id"))
		if aura_id.is_empty():
			continue
		aura_definitions[aura_id] = definition

	for definition in catalog.instant_effect_definitions:
		if definition == null:
			continue
		var effect_id := String(definition.get("id"))
		if effect_id.is_empty():
			continue
		instant_effect_definitions[effect_id] = definition

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
		var shelf_count := int(catalog.starting_shelf_inventory[shelf_id])
		var definition: ShelfDefinition = shelf_definitions.get(String(shelf_id), null)
		if definition == null:
			continue
		for _index in range(shelf_count):
			_add_shelf_item_to_backpack(definition)

	background_color_hex = catalog.background_color_hex
	_rebuild_shelf_inventory_counts()
	ensure_shelf_slot_capacity(0)


func _add_shelf_item_to_backpack(definition: ShelfDefinition) -> void:
	if definition == null:
		return

	var runtime_id := _build_next_shelf_runtime_id()
	var shelf_item = SHELF_ITEM_INSTANCE_SCRIPT.new(runtime_id, definition, room)
	var backpack_origin := _find_first_backpack_origin(shelf_item.get_footprint())
	if backpack_origin.x < 0 or backpack_origin.y < 0:
		return

	if not shelf_backpack.place(runtime_id, backpack_origin, shelf_item.get_footprint()):
		return

	shelf_item.backpack_origin = backpack_origin
	shelf_items[runtime_id] = shelf_item


func _build_next_shelf_runtime_id() -> String:
	var runtime_id := "shelf_item_%d" % _next_shelf_runtime_id
	_next_shelf_runtime_id += 1
	return runtime_id


func _find_first_backpack_origin(footprint: Vector2i) -> Vector2i:
	for row in range(SHELF_BACKPACK_ROWS):
		for column in range(SHELF_BACKPACK_COLUMNS):
			var origin := Vector2i(column, row)
			if shelf_backpack.can_place("", origin, footprint):
				return origin
	return Vector2i(-1, -1)


func _rebuild_shelf_inventory_counts() -> void:
	shelf_inventory.clear()
	for shelf_item in shelf_items.values():
		if shelf_item == null or not shelf_item.is_in_backpack() or shelf_item.definition == null:
			continue
		shelf_inventory[shelf_item.definition.id] = int(shelf_inventory.get(shelf_item.definition.id, 0)) + 1


func _get_first_backpack_shelf_item():
	for shelf_item in get_shelf_backpack_items():
		return shelf_item
	return null


func _find_backpack_shelf_item_by_definition_id(shelf_id: String):
	for shelf_item in get_shelf_backpack_items():
		if shelf_item.definition != null and shelf_item.definition.id == shelf_id:
			return shelf_item
	return null


func _find_room_shelf_item_by_anchor_slot(anchor_slot_index: int):
	for shelf_item in shelf_items.values():
		if shelf_item != null and shelf_item.room_anchor_slot_index == anchor_slot_index:
			return shelf_item
	return null
