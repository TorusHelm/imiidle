class_name PotInstance
extends RefCounted


var definition: PotDefinition
var active_plant: PlantInstance = null


func _init(pot_definition: PotDefinition) -> void:
	definition = pot_definition


func reset_runtime_state() -> void:
	if active_plant != null and active_plant.has_method("reset_runtime_state"):
		active_plant.reset_runtime_state()
