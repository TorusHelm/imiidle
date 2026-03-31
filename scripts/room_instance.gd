class_name RoomInstance
extends RefCounted


var shelf_slots: Array = []
var room_speed_multiplier := 1.0
var definition: RoomDefinition = null


func _init(room_definition: RoomDefinition = null) -> void:
	setup(room_definition)


func setup(room_definition: RoomDefinition = null) -> void:
	definition = room_definition
	var resolved_count := definition.get_slot_count() if definition != null else 1
	shelf_slots.resize(resolved_count)
	for index in shelf_slots.size():
		shelf_slots[index] = null


func can_place_shelf(slot_index := 0) -> bool:
	return slot_index >= 0 and slot_index < shelf_slots.size() and shelf_slots[slot_index] == null


func place_shelf(slot_index: int, shelf: ShelfInstance) -> bool:
	if not can_place_shelf(slot_index):
		return false

	shelf_slots[slot_index] = shelf
	return true


func get_shelf(slot_index := 0) -> ShelfInstance:
	if slot_index < 0 or slot_index >= shelf_slots.size():
		return null
	return shelf_slots[slot_index]
