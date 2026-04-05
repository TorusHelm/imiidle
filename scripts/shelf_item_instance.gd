class_name ShelfItemInstance
extends RefCounted


var runtime_id := ""
var definition: ShelfDefinition = null
var shelf: ShelfInstance = null
var backpack_origin := Vector2i(-1, -1)
var room_anchor_slot_index := -1


func _init(runtime_id_value := "", shelf_definition: ShelfDefinition = null, room_instance: RoomInstance = null) -> void:
	runtime_id = runtime_id_value
	definition = shelf_definition
	if definition != null:
		shelf = ShelfInstance.new(definition, room_instance)


func get_footprint() -> Vector2i:
	if definition == null:
		return Vector2i.ONE
	return Vector2i(
		maxi(definition.slot_grid_columns, 1),
		maxi(definition.slot_grid_rows if definition.use_slot_grid else 1, 1)
	)


func is_in_backpack() -> bool:
	return backpack_origin.x >= 0 and backpack_origin.y >= 0


func is_in_room() -> bool:
	return room_anchor_slot_index >= 0
