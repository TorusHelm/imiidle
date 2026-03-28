class_name PotView
extends Control


signal seed_button_pressed(slot_index: int)
signal pot_button_pressed(slot_index: int)


var slot_index := -1


@onready var slot_button: Button = $SlotButton
@onready var slot_label: Label = $SlotLabel
@onready var pot_texture: TextureRect = $PotTexture
@onready var pot_status_label: Label = $PotStatusLabel
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
		pot_status_label.visible = false
		seed_button.visible = false
		plant_view.visible = false
		return

	slot_button.visible = false
	slot_label.visible = false
	pot_texture.visible = true
	pot_status_label.visible = true
	seed_button.visible = true
	plant_view.visible = true
	pot_texture.texture = load(pot_instance.definition.texture_path) if not pot_instance.definition.texture_path.is_empty() else null
	seed_button.disabled = not can_plant_seed

	if pot_instance.active_plant == null:
		pot_status_label.text = "Empty pot"
		plant_view.show_empty()
		return

	if pot_instance.active_plant.is_mature():
		pot_status_label.text = "%s is mature" % pot_instance.active_plant.definition.display_name
	else:
		pot_status_label.text = "%s is growing" % pot_instance.active_plant.definition.display_name

	plant_view.show_plant(pot_instance.active_plant)


func _on_seed_button_pressed() -> void:
	seed_button_pressed.emit(slot_index)


func _on_slot_button_pressed() -> void:
	pot_button_pressed.emit(slot_index)
