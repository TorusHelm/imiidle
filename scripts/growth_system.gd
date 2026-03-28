class_name GrowthSystem
extends RefCounted


func tick_plant(plant: PlantInstance, delta: float) -> float:
	if plant == null or plant.definition == null:
		return 0.0

	plant.advance(delta)

	if not plant.is_mature():
		return 0.0

	return plant.definition.coins_per_second * delta
