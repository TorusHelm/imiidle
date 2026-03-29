class_name PlantView
extends Control


@onready var plant_texture: TextureRect = $PlantTexture


func show_empty() -> void:
	plant_texture.visible = false
	plant_texture.texture = null
	tooltip_text = "No plant\nPlant a seed to start growing."
	plant_texture.tooltip_text = tooltip_text


func show_plant(plant: PlantInstance) -> void:
	if plant == null or plant.definition == null:
		show_empty()
		return

	_apply_definition_layout(plant.definition)
	plant_texture.visible = true
	plant_texture.texture = load(plant.definition.texture_path) if not plant.definition.texture_path.is_empty() else null
	plant_texture.modulate = plant.definition.display_color

	var status_text := "Status: growing"
	var details_text := "Growth: %d%%" % plant.get_growth_percent()

	if plant.is_mature():
		status_text = "Status: mature"
		details_text = "Income: %.1f coins/sec" % plant.definition.coins_per_second

	tooltip_text = "%s\n%s\n%s" % [plant.definition.display_name, status_text, details_text]
	plant_texture.tooltip_text = tooltip_text


func _apply_definition_layout(definition: PlantDefinition) -> void:
	if definition == null:
		return

	position = definition.texture_offset
	custom_minimum_size = definition.texture_size
	size = definition.texture_size
	plant_texture.position = Vector2.ZERO
	plant_texture.size = definition.texture_size
