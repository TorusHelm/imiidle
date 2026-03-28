class_name PotView
extends Control


signal seed_button_pressed(slot_index: int)
signal pot_button_pressed(slot_index: int)


var slot_index := -1


@onready var slot_button: Button = $SlotButton
@onready var slot_label: Label = $SlotLabel
@onready var pot_texture: TextureRect = $PotTexture
@onready var seed_button: Button = $SeedButton
@onready var plant_view: PlantView = $PlantView


func _ready() -> void:
	slot_button.grab_focus()


func set_slot_index(value: int) -> void:
	slot_index = value


func update_view(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	if pot_instance == null:
		slot_button.visible = true
		slot_button.disabled = not can_place_pot
		slot_label.visible = true
		pot_texture.visible = false
		seed_button.visible = false
		plant_view.visible = false
		slot_button.tooltip_text = "Empty slot\nChoose a pot for this shelf slot."
		slot_label.tooltip_text = slot_button.tooltip_text
		tooltip_text = slot_button.tooltip_text
		return

	slot_button.visible = false
	slot_label.visible = false
	pot_texture.visible = true
	seed_button.visible = true
	plant_view.visible = true
	pot_texture.texture = load(pot_instance.definition.texture_path) if not pot_instance.definition.texture_path.is_empty() else null
	seed_button.disabled = not can_plant_seed

	var pot_details := "%s\nStatus: empty" % pot_instance.definition.display_name

	if pot_instance.active_plant == null:
		plant_view.show_empty()
		pot_texture.tooltip_text = pot_details
		seed_button.tooltip_text = "Choose a seed for %s." % pot_instance.definition.display_name
		tooltip_text = pot_details
		return

	if pot_instance.active_plant.is_mature():
		pot_details = "%s\nPlant: %s\nStatus: mature" % [
			pot_instance.definition.display_name,
			pot_instance.active_plant.definition.display_name,
		]
	else:
		pot_details = "%s\nPlant: %s\nStatus: growing" % [
			pot_instance.definition.display_name,
			pot_instance.active_plant.definition.display_name,
		]

	plant_view.show_plant(pot_instance.active_plant)
	pot_texture.tooltip_text = pot_details
	seed_button.tooltip_text = "This pot already has a plant."
	tooltip_text = pot_details


func _on_seed_button_pressed() -> void:
	seed_button_pressed.emit(slot_index)


func _on_slot_button_pressed() -> void:
	pot_button_pressed.emit(slot_index)
