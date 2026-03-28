class_name PotInstance
extends RefCounted


var definition: PotDefinition
var active_plant: PlantInstance = null


func _init(pot_definition: PotDefinition) -> void:
	definition = pot_definition
