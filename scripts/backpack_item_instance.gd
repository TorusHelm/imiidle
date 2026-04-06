class_name BackpackItemInstance
extends RefCounted


var runtime_id := ""
var kind := ""
var backpack_origin := Vector2i(-1, -1)
var pot: PotInstance = null
var totem: TotemInstance = null
var seed_definition: PlantDefinition = null


func _init(runtime_id_value := "", kind_value := "", pot_instance: PotInstance = null, totem_instance: TotemInstance = null, seed_definition_value: PlantDefinition = null) -> void:
	runtime_id = runtime_id_value
	kind = kind_value
	pot = pot_instance
	totem = totem_instance
	seed_definition = seed_definition_value


func get_footprint() -> Vector2i:
	return Vector2i.ONE


func is_in_backpack() -> bool:
	return backpack_origin.x >= 0 and backpack_origin.y >= 0


func get_display_definition():
	if kind == "pot" and pot != null:
		return pot.definition
	if kind == "totem" and totem != null:
		return totem.definition
	if kind == "seed" and seed_definition != null:
		return seed_definition
	return null


func reset_runtime_state() -> void:
	if kind == "pot" and pot != null and pot.has_method("reset_runtime_state"):
		pot.reset_runtime_state()
	elif kind == "totem" and totem != null and totem.has_method("reset_runtime_state"):
		totem.reset_runtime_state()
