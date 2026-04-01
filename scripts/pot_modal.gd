class_name PotModal
extends Control


signal pot_selected(slot_index: int, pot_id: String)
signal totem_selected(slot_index: int, totem_id: String)
signal closed


var current_slot_index := -1


@onready var pot_list: VBoxContainer = $CenterContainer/ModalPanel/Content/PotList
@onready var title_label: Label = $CenterContainer/ModalPanel/Content/TitleLabel


func _ready() -> void:
	hide()


func open_modal(slot_index: int, pot_options: Array[Dictionary], totem_options: Array[Dictionary] = []) -> void:
	current_slot_index = slot_index
	title_label.text = "Choose an item for slot %d" % (slot_index + 1)
	_clear_pot_list()

	_add_option_section("Pots", pot_options, "Pot", _on_pot_option_pressed)
	_add_option_section("Totems", totem_options, "Totem", _on_totem_option_pressed)

	show()


func close_modal() -> void:
	hide()
	closed.emit()


func _on_pot_option_pressed(pot_id: String) -> void:
	pot_selected.emit(current_slot_index, pot_id)


func _on_totem_option_pressed(totem_id: String) -> void:
	totem_selected.emit(current_slot_index, totem_id)


func _on_close_button_pressed() -> void:
	close_modal()


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_modal()


func _clear_pot_list() -> void:
	for child in pot_list.get_children():
		child.queue_free()


func _add_option_section(
	title: String,
	options: Array[Dictionary],
	fallback_name: String,
	pressed_handler: Callable
) -> void:
	if options.is_empty():
		return

	var section_label := Label.new()
	section_label.text = title
	pot_list.add_child(section_label)

	for option in options:
		var button := Button.new()
		var count := int(option.get("count", 0))
		button.text = "%s (%d)" % [String(option.get("display_name", fallback_name)), count]
		button.disabled = count <= 0
		button.custom_minimum_size = Vector2(220, 40)
		button.pressed.connect(pressed_handler.bind(String(option.get("id", ""))))
		pot_list.add_child(button)
