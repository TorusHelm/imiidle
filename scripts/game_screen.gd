extends Control


var game_state := GameState.new()


@onready var coins_value_label: Label = %CoinsValueLabel
@onready var experience_value_label: Label = %ExperienceValueLabel
@onready var seeds_value_label: Label = %SeedsValueLabel
@onready var background: ColorRect = $Background
@onready var shelf_view: ShelfView = %ShelfView
@onready var empty_shelf_state: Control = %EmptyShelfState
@onready var empty_shelf_panel: Control = $EmptyShelfState/Panel
@onready var seed_modal: SeedModal = %SeedModal
@onready var pot_modal: PotModal = %PotModal
@onready var shelf_modal: ShelfModal = %ShelfModal


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


func _on_choose_shelf_button_pressed() -> void:
	shelf_modal.open_modal(game_state.get_shelf_options())


func _on_shelf_selected(shelf_id: String) -> void:
	if game_state.place_shelf(shelf_id):
		shelf_view.configure(game_state.get_active_shelf_definition())
	shelf_modal.close_modal()
	_refresh_ui()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sceens/Main.tscn")


func _refresh_ui() -> void:
	var active_shelf := game_state.get_active_shelf_definition()
	background.color = game_state.get_background_color()
	coins_value_label.text = "%.1f" % game_state.coins
	experience_value_label.text = "%.1f" % game_state.experience
	seeds_value_label.text = str(game_state.get_total_seed_count())
	shelf_view.visible = active_shelf != null
	empty_shelf_state.visible = active_shelf == null
	if active_shelf != null:
		shelf_view.configure(active_shelf)
		_position_shelf_view()
		shelf_view.update_view(game_state)


func _position_shelf_view() -> void:
	var panel_rect: Rect2 = empty_shelf_panel.get_global_rect()
	var root_rect: Rect2 = get_global_rect()
	var local_position := panel_rect.position - root_rect.position
	shelf_view.position = local_position + (panel_rect.size - shelf_view.size) * 0.5
