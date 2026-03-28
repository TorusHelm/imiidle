class_name ShelfView
extends Control


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

@onready var pot_view_0: PotView = %PotView0
@onready var pot_view_1: PotView = %PotView1
@onready var pot_view_2: PotView = %PotView2


func _ready() -> void:
	var pot_views: Array[PotView] = [pot_view_0, pot_view_1, pot_view_2]
	for index in pot_views.size():
		pot_views[index].set_slot_index(index)
		pot_views[index].pot_button_pressed.connect(_on_pot_button_pressed)
		pot_views[index].seed_button_pressed.connect(_on_seed_button_pressed)


func update_view(game_state: GameState) -> void:
	var pot_views: Array[PotView] = [pot_view_0, pot_view_1, pot_view_2]
	for index in pot_views.size():
		pot_views[index].update_view(
			game_state.get_pot_in_slot(index),
			game_state.can_place_pot(index),
			game_state.can_plant_seed_in_slot(index)
		)


func _on_pot_button_pressed(slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)
