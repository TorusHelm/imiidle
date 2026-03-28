class_name PlantView
extends Control


@onready var plant_texture: TextureRect = $PlantTexture
@onready var plant_name_label: Label = $PlantNameLabel
@onready var plant_stage_label: Label = $PlantStageLabel
@onready var growth_value_label: Label = $GrowthValueLabel


func show_empty() -> void:
	plant_texture.visible = false
	plant_texture.texture = null
	plant_name_label.text = "No plant"
	plant_stage_label.text = "Status: empty"
	growth_value_label.text = "Plant a seed to start growing."


func show_plant(plant: PlantInstance) -> void:
	if plant == null or plant.definition == null:
		show_empty()
		return

	plant_texture.visible = true
	plant_texture.texture = load(plant.definition.texture_path) if not plant.definition.texture_path.is_empty() else null
	plant_texture.modulate = plant.definition.display_color
	plant_name_label.text = plant.definition.display_name

	if plant.is_mature():
		plant_stage_label.text = "Status: mature"
		growth_value_label.text = "Income: %.1f coins/sec" % plant.definition.coins_per_second
		return

	plant_stage_label.text = "Status: growing"
	growth_value_label.text = "Growth: %d%%" % plant.get_growth_percent()
