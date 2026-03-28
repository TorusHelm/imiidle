class_name SeedModal
extends Control


signal seed_selected(slot_index: int, seed_id: String)
signal closed


var current_slot_index := -1


@onready var seed_list: VBoxContainer = %SeedList
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	hide()


func open_modal(slot_index: int, seed_options: Array[Dictionary]) -> void:
	current_slot_index = slot_index
	title_label.text = "Choose a seed for pot %d" % (slot_index + 1)
	_clear_seed_list()

	for option in seed_options:
		var button := Button.new()
		var count := int(option.get("count", 0))
		button.text = "%s (%d)" % [String(option.get("display_name", "Seed")), count]
		button.disabled = count <= 0
		button.custom_minimum_size = Vector2(220, 40)
		button.pressed.connect(_on_seed_option_pressed.bind(String(option.get("id", ""))))
		seed_list.add_child(button)

		var details := Label.new()
		details.text = "Growth %.0fs | Income %.1f/sec" % [
			float(option.get("growth_duration", 0.0)),
			float(option.get("coins_per_second", 0.0)),
		]
		seed_list.add_child(details)

	show()


func close_modal() -> void:
	hide()
	closed.emit()


func _on_seed_option_pressed(seed_id: String) -> void:
	seed_selected.emit(current_slot_index, seed_id)


func _on_close_button_pressed() -> void:
	close_modal()


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_modal()


func _clear_seed_list() -> void:
	for child in seed_list.get_children():
		child.queue_free()
