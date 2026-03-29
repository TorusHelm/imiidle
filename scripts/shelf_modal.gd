class_name ShelfModal
extends Control


signal shelf_selected(shelf_id: String)
signal closed


@onready var shelf_list: VBoxContainer = $CenterContainer/ModalPanel/Content/ShelfList
@onready var title_label: Label = $CenterContainer/ModalPanel/Content/TitleLabel


func _ready() -> void:
	hide()


func open_modal(shelf_options: Array[Dictionary]) -> void:
	title_label.text = "Choose a shelf"
	_clear_shelf_list()

	for option in shelf_options:
		var button := Button.new()
		var count := int(option.get("count", 0))
		button.text = "%s (%d)" % [String(option.get("display_name", "Shelf")), count]
		button.disabled = count <= 0
		button.custom_minimum_size = Vector2(220, 40)
		button.pressed.connect(_on_shelf_option_pressed.bind(String(option.get("id", ""))))
		shelf_list.add_child(button)

	show()


func close_modal() -> void:
	hide()
	closed.emit()


func _on_shelf_option_pressed(shelf_id: String) -> void:
	shelf_selected.emit(shelf_id)


func _on_close_button_pressed() -> void:
	close_modal()


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_modal()


func _clear_shelf_list() -> void:
	for child in shelf_list.get_children():
		child.queue_free()
