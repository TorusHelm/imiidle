extends Control


var game_state := GameState.new()


@onready var coins_value_label: Label = %CoinsValueLabel
@onready var experience_value_label: Label = %ExperienceValueLabel
@onready var seeds_value_label: Label = %SeedsValueLabel
@onready var shelf_view: ShelfView = %ShelfView
@onready var seed_modal: SeedModal = %SeedModal
@onready var pot_modal: PotModal = %PotModal


func _ready() -> void:
	_refresh_ui()


func _process(delta: float) -> void:
	game_state.tick(delta)
	_refresh_ui()


func _on_pot_slot_pressed(slot_index: int) -> void:
	pot_modal.open_modal(slot_index, game_state.get_pot_options())
	_refresh_ui()


func _on_pot_selected(slot_index: int, pot_id: String) -> void:
	game_state.place_pot(slot_index, pot_id)
	pot_modal.close_modal()
	_refresh_ui()


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_modal.open_modal(slot_index, game_state.get_seed_options())
	_refresh_ui()


func _on_seed_selected(slot_index: int, seed_id: String) -> void:
	game_state.plant_seed(slot_index, seed_id)
	seed_modal.close_modal()
	_refresh_ui()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sceens/Main.tscn")


func _refresh_ui() -> void:
	coins_value_label.text = "%.1f" % game_state.coins
	experience_value_label.text = "%.1f" % game_state.experience
	seeds_value_label.text = str(game_state.get_total_seed_count())
	shelf_view.update_view(game_state)
