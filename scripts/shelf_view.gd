class_name ShelfView
extends Control


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const POT_VIEW_SCENE := preload("res://Pots/_shared/sceens/Pot.tscn")


var _pot_views: Array[PotView] = []
var _current_shelf_id := ""
var _slot_positions: Array[Vector2] = []


@onready var slots_root: Node2D = $SlotsRoot
@onready var shelf_texture: TextureRect = $ShelfTexture
@onready var shelf_title: Label = $ShelfTitle


func _ready() -> void:
	pass


func update_view(game_state: GameState) -> void:
	configure(game_state.get_active_shelf_definition())

	for index in _pot_views.size():
		var pot_instance := game_state.get_pot_in_slot(index)
		_pot_views[index].update_view(
			pot_instance,
			game_state.can_place_pot(index),
			game_state.can_plant_seed_in_slot(index)
		)
		_pot_views[index].position = _slot_positions[index] - _pot_views[index].get_pot_baseline_local_position()


func get_slot_count() -> int:
	return _pot_views.size()


func _on_pot_button_pressed(slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)


func configure(definition: ShelfDefinition) -> void:
	if definition == null:
		return

	var needs_rebuild := _current_shelf_id != definition.id or _pot_views.size() != definition.slot_positions.size()
	_current_shelf_id = definition.id
	_slot_positions = definition.slot_positions.duplicate()
	_apply_definition_layout(definition)

	if needs_rebuild:
		_rebuild_slot_views(definition)


func _rebuild_slot_views(definition: ShelfDefinition) -> void:
	for child in slots_root.get_children():
		if child is PotView:
			child.queue_free()

	_pot_views.clear()

	for index in definition.slot_positions.size():
		var pot_view: PotView = POT_VIEW_SCENE.instantiate()
		pot_view.name = "PotView%d" % index
		pot_view.position = definition.slot_positions[index] - pot_view.get_pot_baseline_local_position()
		pot_view.set_slot_index(index)
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)
		slots_root.add_child(pot_view)
		_pot_views.append(pot_view)


func _apply_definition_layout(definition: ShelfDefinition) -> void:
	custom_minimum_size = definition.view_size
	size = definition.view_size
	shelf_texture.position = definition.texture_position
	shelf_texture.size = definition.texture_size
	shelf_texture.texture = load(definition.texture_path) if not definition.texture_path.is_empty() else null
	shelf_title.position = definition.title_position
	shelf_title.size = definition.title_size
	shelf_title.text = definition.display_name
