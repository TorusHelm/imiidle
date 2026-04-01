@tool
class_name ShelfSlotView
extends Node2D


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

var slot_index := -1


@onready var pot_view: PotView = $PotView
@onready var totem_view: TotemView = $TotemView


func _ready() -> void:
	pot_view.set_slot_index(slot_index)
	if not pot_view.pot_button_pressed.is_connected(_on_pot_button_pressed):
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
	if not pot_view.seed_button_pressed.is_connected(_on_seed_button_pressed):
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)


func set_slot_index(value: int) -> void:
	slot_index = value
	if is_node_ready():
		pot_view.set_slot_index(value)


func show_pot(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	pot_view.visible = true
	totem_view.show_empty()
	pot_view.update_view(pot_instance, can_place_pot, can_plant_seed)
	pot_view.position = -pot_view.get_pot_baseline_local_position()


func show_totem(totem_instance: TotemInstance) -> void:
	pot_view.visible = false
	totem_view.show_totem(totem_instance)
	totem_view.position = -totem_view.get_totem_baseline_local_position()


func get_pot_view() -> PotView:
	return pot_view


func get_totem_view() -> TotemView:
	return totem_view

func _on_pot_button_pressed(_pressed_slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(_pressed_slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)
