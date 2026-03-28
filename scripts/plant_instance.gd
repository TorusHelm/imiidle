class_name PlantInstance
extends RefCounted


var definition: PlantDefinition
var age_seconds := 0.0


func _init(plant_definition: PlantDefinition) -> void:
	definition = plant_definition


func advance(delta: float) -> void:
	age_seconds += delta


func get_growth_ratio() -> float:
	if definition == null or definition.growth_duration <= 0.0:
		return 1.0
	return min(age_seconds / definition.growth_duration, 1.0)


func is_mature() -> bool:
	return get_growth_ratio() >= 1.0


func get_growth_percent() -> int:
	return int(round(get_growth_ratio() * 100.0))
