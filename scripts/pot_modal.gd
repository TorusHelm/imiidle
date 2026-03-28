class_name PotModal
extends Control


signal pot_selected(slot_index: int, pot_id: String)
signal closed


var current_slot_index := -1


@onready var pot_list: VBoxContainer = %PotList
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	hide()


func open_modal(slot_index: int, pot_options: Array[Dictionary]) -> void:
	current_slot_index = slot_index
	title_label.text = "Choose a pot for slot %d" % (slot_index + 1)
	_clear_pot_list()

	for option in pot_options:
		var button := Button.new()
		var count := int(option.get("count", 0))
		button.text = "%s (%d)" % [String(option.get("display_name", "Pot")), count]
		button.disabled = count <= 0
		button.custom_minimum_size = Vector2(220, 40)
		button.pressed.connect(_on_pot_option_pressed.bind(String(option.get("id", ""))))
		pot_list.add_child(button)

	show()


func close_modal() -> void:
	hide()
	closed.emit()


func _on_pot_option_pressed(pot_id: String) -> void:
	pot_selected.emit(current_slot_index, pot_id)


func _on_close_button_pressed() -> void:
	close_modal()


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_modal()


func _clear_pot_list() -> void:
	for child in pot_list.get_children():
		child.queue_free()
