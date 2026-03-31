class_name SlotInstance
extends RefCounted


var index := -1
var row := -1
var col := -1
var pot: PotInstance = null
var totem: TotemInstance = null


func _init(slot_data: Dictionary = {}) -> void:
	index = int(slot_data.get("index", -1))
	row = int(slot_data.get("row", -1))
	col = int(slot_data.get("col", -1))


func is_empty() -> bool:
	return pot == null and totem == null


func has_pot() -> bool:
	return pot != null


func has_totem() -> bool:
	return totem != null


func get_actor() -> RefCounted:
	if pot != null and pot.active_plant != null:
		return pot.active_plant
	return totem
