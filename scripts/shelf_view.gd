class_name ShelfView
extends Control


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const POT_VIEW_SCENE := preload("res://sceens/Pot.tscn")


var _pot_views: Array[PotView] = []


@onready var slots_root: Node2D = $SlotsRoot


func _ready() -> void:
	_build_slot_views()


func update_view(game_state: GameState) -> void:
	for index in _pot_views.size():
		_pot_views[index].update_view(
			game_state.get_pot_in_slot(index),
			game_state.can_place_pot(index),
			game_state.can_plant_seed_in_slot(index)
		)


func get_slot_count() -> int:
	return _pot_views.size()


func _on_pot_button_pressed(slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)


func _build_slot_views() -> void:
	var markers := _get_slot_markers()

	for index in markers.size():
		var pot_view: PotView = POT_VIEW_SCENE.instantiate()
		pot_view.name = "PotView%d" % index
		pot_view.position = markers[index].position - pot_view.get_pot_baseline_local_position()
		pot_view.set_slot_index(index)
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)
		slots_root.add_child(pot_view)
		_pot_views.append(pot_view)


func _get_slot_markers() -> Array[ShelfSlotMarker]:
	var markers: Array[ShelfSlotMarker] = []

	for child in slots_root.get_children():
		if child is ShelfSlotMarker:
			markers.append(child)

	markers.sort_custom(func(a: ShelfSlotMarker, b: ShelfSlotMarker): return a.position.x < b.position.x)
	return markers
