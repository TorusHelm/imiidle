@tool
class_name ShelfView
extends Control


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const POT_VIEW_SCENE := preload("res://Pots/_shared/sceens/Pot.tscn")


@export var preview_shelf_definition: ShelfDefinition = null:
	set(value):
		_disconnect_shelf_resource(preview_shelf_definition)
		preview_shelf_definition = value
		_connect_shelf_resource(preview_shelf_definition)
		_queue_preview_refresh()

@export var preview_pot_definition: PotDefinition = null:
	set(value):
		_disconnect_pot_resource(preview_pot_definition)
		preview_pot_definition = value
		_connect_pot_resource(preview_pot_definition)
		_queue_preview_refresh()

@export var preview_plant_definition: PlantDefinition = null:
	set(value):
		_disconnect_plant_resource(preview_plant_definition)
		preview_plant_definition = value
		_connect_plant_resource(preview_plant_definition)
		_queue_preview_refresh()

@export_range(0, 32, 1) var preview_slot_index := 0:
	set(value):
		preview_slot_index = value
		_queue_preview_refresh()

@export var use_internal_preview := true:
	set(value):
		use_internal_preview = value
		_queue_preview_refresh()


var _pot_views: Array[PotView] = []
var _current_shelf_id := ""
var _slot_positions: Array[Vector2] = []


@onready var slots_root: Node2D = $SlotsRoot
@onready var shelf_texture: TextureRect = $ShelfTexture
@onready var shelf_title: Label = $ShelfTitle


func _ready() -> void:
	_connect_shelf_resource(preview_shelf_definition)
	_connect_pot_resource(preview_pot_definition)
	_connect_plant_resource(preview_plant_definition)
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and use_internal_preview:
		_refresh_preview()


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


func preview(shelf_definition: ShelfDefinition, pot_definition: PotDefinition, plant_definition: PlantDefinition, preview_slot_index := 0) -> void:
	configure(shelf_definition)

	for index in _pot_views.size():
		var pot_instance: PotInstance = null

		if pot_definition != null and index == preview_slot_index:
			pot_instance = PotInstance.new(pot_definition)
			if plant_definition != null:
				pot_instance.active_plant = PlantInstance.new(plant_definition)

		_pot_views[index].update_view(pot_instance, true, pot_instance != null and pot_instance.active_plant == null)
		_pot_views[index].position = _slot_positions[index] - _pot_views[index].get_pot_baseline_local_position()


func preview_slots(shelf_definition: ShelfDefinition, slot_previews: Array[CompositionPreviewSlot]) -> void:
	configure(shelf_definition)

	for index in _pot_views.size():
		var pot_instance: PotInstance = null
		var slot_preview: CompositionPreviewSlot = slot_previews[index] if index < slot_previews.size() else null

		if slot_preview != null and slot_preview.enabled and slot_preview.pot_definition != null:
			pot_instance = PotInstance.new(slot_preview.pot_definition)
			if slot_preview.plant_definition != null:
				pot_instance.active_plant = PlantInstance.new(slot_preview.plant_definition)

		_pot_views[index].update_view(pot_instance, true, pot_instance != null and pot_instance.active_plant == null)
		_pot_views[index].position = _slot_positions[index] - _pot_views[index].get_pot_baseline_local_position()


func get_slot_count() -> int:
	return _pot_views.size()


func get_slot_positions() -> Array[Vector2]:
	return _slot_positions.duplicate()


func get_pot_view(slot_index: int) -> PotView:
	if slot_index < 0 or slot_index >= _pot_views.size():
		return null
	return _pot_views[slot_index]


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
		pot_view.use_internal_preview = false
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


func _queue_preview_refresh() -> void:
	if not is_node_ready():
		return
	call_deferred("_refresh_preview")


func _refresh_preview() -> void:
	if not is_node_ready():
		return

	if not Engine.is_editor_hint():
		return

	if not use_internal_preview:
		return

	if preview_shelf_definition == null:
		return

	var safe_slot_index := clampi(preview_slot_index, 0, max(preview_shelf_definition.slot_positions.size() - 1, 0))
	preview(preview_shelf_definition, preview_pot_definition, preview_plant_definition, safe_slot_index)


func _connect_shelf_resource(definition: ShelfDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)


func _disconnect_shelf_resource(definition: ShelfDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)


func _connect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)


func _disconnect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)


func _connect_plant_resource(definition: PlantDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)


func _disconnect_plant_resource(definition: PlantDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()
