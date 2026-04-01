@tool
class_name ShelfView
extends Control


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const SHELF_SLOT_VIEW_SCENE := preload("res://Ui/ShelfSlotView.tscn")
const SHELF_MODEL_SCRIPT = preload("res://scripts/shelf_model.gd")


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

@export var preview_totem_definition: TotemDefinition = null:
	set(value):
		_disconnect_totem_resource(preview_totem_definition)
		preview_totem_definition = value
		_connect_totem_resource(preview_totem_definition)
		_queue_preview_refresh()

@export_range(0, 32, 1) var preview_slot_index := 0:
	set(value):
		preview_slot_index = value
		_queue_preview_refresh()

@export_group("Editor Guides")
@export var show_slot_guides_in_editor := true:
	set(value):
		show_slot_guides_in_editor = value
		queue_redraw()


var _slot_views: Array[ShelfSlotView] = []
var _current_shelf_id := ""
var _shelf_model = SHELF_MODEL_SCRIPT.new()


@onready var slots_root: Node2D = $SlotsRoot
@onready var shelf_texture: TextureRect = $ShelfTexture
@onready var shelf_title: Label = $ShelfTitle


func _ready() -> void:
	_connect_shelf_resource(preview_shelf_definition)
	_connect_pot_resource(preview_pot_definition)
	_connect_plant_resource(preview_plant_definition)
	_connect_totem_resource(preview_totem_definition)
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and preview_shelf_definition != null:
		_refresh_preview()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if not show_slot_guides_in_editor:
		return
	if preview_shelf_definition == null:
		return

	_draw_slot_guides(preview_shelf_definition)


func update_view(game_state: GameState, room_slot_index := -1) -> void:
	if room_slot_index >= 0:
		var room_shelf := game_state.get_shelf_in_room_slot(room_slot_index)
		configure(room_shelf.definition if room_shelf != null else null)
	else:
		configure(game_state.get_active_shelf_definition())

	for index in _slot_views.size():
		var slot_view := _slot_views[index]
		var pot_instance := game_state.get_pot_in_room_slot(room_slot_index, index) if room_slot_index >= 0 else game_state.get_pot_in_slot(index)
		var totem_instance := game_state.get_totem_in_room_slot(room_slot_index, index) if room_slot_index >= 0 else game_state.get_totem_in_slot(index)
		slot_view.position = _shelf_model.get_slot_position_by_index(index)
		if totem_instance != null:
			slot_view.show_totem(totem_instance)
		else:
			slot_view.show_pot(
				pot_instance,
				game_state.can_place_pot_in_room_slot(room_slot_index, index) if room_slot_index >= 0 else game_state.can_place_pot(index),
				game_state.can_plant_seed_in_room_slot(room_slot_index, index) if room_slot_index >= 0 else game_state.can_plant_seed_in_slot(index)
			)

		var active_modifiers := game_state.get_active_modifiers_in_room_slot(room_slot_index, index) if room_slot_index >= 0 else game_state.get_active_modifiers_in_slot(index)
		slot_view.update_status_modifiers(active_modifiers)


func play_visual_feedback(feedback_events: Array[Dictionary]) -> void:
	for feedback_event in feedback_events:
		var target_slot_index := int(feedback_event.get("slot_index", -1))
		var slot_view := get_slot_view(target_slot_index)
		if slot_view == null:
			continue
		slot_view.play_feedback([feedback_event])


func preview(shelf_definition: ShelfDefinition, pot_definition: PotDefinition, plant_definition: PlantDefinition, preview_slot_index := 0) -> void:
	configure(shelf_definition)
	if not _are_slot_views_ready():
		_queue_preview_refresh()
		return

	for index in _slot_views.size():
		var pot_instance: PotInstance = null
		var totem_instance: TotemInstance = null

		if preview_totem_definition != null and index == preview_slot_index:
			totem_instance = TotemInstance.new(preview_totem_definition)
		elif pot_definition != null and index == preview_slot_index:
			pot_instance = PotInstance.new(pot_definition)
			if plant_definition != null:
				pot_instance.active_plant = PlantInstance.new(plant_definition)

		var slot_view := _slot_views[index]
		slot_view.position = _shelf_model.get_slot_position_by_index(index)
		if totem_instance != null:
			slot_view.show_totem(totem_instance)
			continue
		slot_view.show_pot(pot_instance, true, pot_instance != null and pot_instance.active_plant == null)


func preview_slots(shelf_definition: ShelfDefinition, slot_previews: Array[CompositionPreviewSlot]) -> void:
	configure(shelf_definition)
	if not _are_slot_views_ready():
		_queue_preview_refresh()
		return

	for index in _slot_views.size():
		var pot_instance: PotInstance = null
		var totem_instance: TotemInstance = null
		var slot_preview: CompositionPreviewSlot = slot_previews[index] if index < slot_previews.size() else null

		if slot_preview != null and slot_preview.enabled:
			if slot_preview.totem_definition != null:
				totem_instance = TotemInstance.new(slot_preview.totem_definition)
			elif slot_preview.pot_definition != null:
				pot_instance = PotInstance.new(slot_preview.pot_definition)
				if slot_preview.plant_definition != null:
					pot_instance.active_plant = PlantInstance.new(slot_preview.plant_definition)

		var slot_view := _slot_views[index]
		slot_view.position = _shelf_model.get_slot_position_by_index(index)
		if totem_instance != null:
			slot_view.show_totem(totem_instance)
			continue
		slot_view.show_pot(pot_instance, true, pot_instance != null and pot_instance.active_plant == null)


func get_slot_count() -> int:
	return _shelf_model.get_slot_count()


func get_slot_positions() -> Array[Vector2]:
	return _shelf_model.get_slot_positions()


func get_pot_view(slot_index: int) -> PotView:
	if slot_index < 0 or slot_index >= _slot_views.size():
		return null
	return _slot_views[slot_index].get_pot_view()


func get_totem_view(slot_index: int) -> TotemView:
	if slot_index < 0 or slot_index >= _slot_views.size():
		return null
	return _slot_views[slot_index].get_totem_view()


func get_slot_view(slot_index: int) -> ShelfSlotView:
	if slot_index < 0 or slot_index >= _slot_views.size():
		return null
	return _slot_views[slot_index]


func _on_pot_button_pressed(slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)


func configure(definition: ShelfDefinition) -> void:
	if definition == null:
		return

	var shelf_model = definition.get_shelf_model()
	var needs_rebuild = _current_shelf_id != definition.id or _slot_views.size() != shelf_model.get_slot_count()
	_current_shelf_id = definition.id
	_shelf_model = shelf_model
	_apply_definition_layout(definition)
	queue_redraw()

	if needs_rebuild:
		_rebuild_slot_views()


func _rebuild_slot_views() -> void:
	for child in slots_root.get_children():
		if child is ShelfSlotView:
			child.queue_free()

	_slot_views.clear()
	var resolved_slot_positions = _shelf_model.get_slot_positions()

	for index in resolved_slot_positions.size():
		var slot_view: ShelfSlotView = SHELF_SLOT_VIEW_SCENE.instantiate()
		slot_view.name = "SlotView%d" % index
		slot_view.position = resolved_slot_positions[index]
		slots_root.add_child(slot_view)
		slot_view.set_slot_index(index)
		slot_view.pot_slot_pressed.connect(_on_pot_button_pressed)
		slot_view.seed_slot_pressed.connect(_on_seed_button_pressed)
		_slot_views.append(slot_view)


func _apply_definition_layout(definition: ShelfDefinition) -> void:
	var resolved_view_size := definition.get_resolved_view_size()
	custom_minimum_size = resolved_view_size
	size = resolved_view_size
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


func _are_slot_views_ready() -> bool:
	for slot_view in _slot_views:
		if slot_view == null or not is_instance_valid(slot_view) or not slot_view.is_node_ready():
			return false
		var pot_view := slot_view.get_pot_view()
		var totem_view := slot_view.get_totem_view()
		if pot_view == null or not is_instance_valid(pot_view) or not pot_view.is_node_ready():
			return false
		if totem_view == null or not is_instance_valid(totem_view) or not totem_view.is_node_ready():
			return false
	return true


func _refresh_preview() -> void:
	if not is_node_ready():
		return

	if not Engine.is_editor_hint():
		return

	if preview_shelf_definition == null:
		return

	var safe_slot_index := clampi(preview_slot_index, 0, max(preview_shelf_definition.get_slot_count() - 1, 0))
	preview(preview_shelf_definition, preview_pot_definition, preview_plant_definition, safe_slot_index)
	queue_redraw()


func _draw_slot_guides(definition: ShelfDefinition) -> void:
	if definition == null or not definition.use_slot_grid:
		return

	var slot_size := definition.get_slot_area_size()
	var slot_anchor := definition.get_slot_anchor_offset()
	var dash_color := Color(1.0, 0.85, 0.25, 0.95)
	var fill_color := Color(1.0, 0.85, 0.25, 0.08)
	var anchor_color := Color(1.0, 0.45, 0.45, 0.95)

	for row in maxi(definition.slot_grid_rows, 0):
		for column in maxi(definition.slot_grid_columns, 0):
			var slot_origin := definition.slot_area_origin + Vector2(
				column * (slot_size.x + definition.slot_area_gap.x),
				row * (slot_size.y + definition.slot_area_gap.y)
			)
			var slot_rect := Rect2(slot_origin, slot_size)
			var anchor_point := slot_origin + slot_anchor
			draw_rect(slot_rect, fill_color, true)
			_draw_dashed_rect(slot_rect, dash_color, 2.0, 10.0, 6.0)
			draw_circle(anchor_point, 4.0, anchor_color)
			draw_line(anchor_point + Vector2(-8.0, 0.0), anchor_point + Vector2(8.0, 0.0), anchor_color, 2.0)
			draw_line(anchor_point + Vector2(0.0, -8.0), anchor_point + Vector2(0.0, 8.0), anchor_color, 2.0)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	_draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), color, width, dash_length, gap_length)
	_draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, color, width, dash_length, gap_length)
	_draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), color, width, dash_length, gap_length)
	_draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, color, width, dash_length, gap_length)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	var segment := to - from
	var total_length := segment.length()
	if total_length <= 0.0:
		return

	var direction := segment / total_length
	var distance := 0.0
	while distance < total_length:
		var dash_start := from + direction * distance
		var dash_end := from + direction * minf(distance + dash_length, total_length)
		draw_line(dash_start, dash_end, color, width)
		distance += dash_length + gap_length


func _connect_shelf_resource(definition: ShelfDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and not slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.connect(_on_preview_resource_changed)


func _disconnect_shelf_resource(definition: ShelfDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.disconnect(_on_preview_resource_changed)


func _connect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and not slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.connect(_on_preview_resource_changed)


func _disconnect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.disconnect(_on_preview_resource_changed)


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


func _connect_totem_resource(definition: TotemDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and not slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.connect(_on_preview_resource_changed)


func _disconnect_totem_resource(definition: TotemDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)
	var slot_layout := definition.get_slot_layout()
	if slot_layout != null and slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.disconnect(_on_preview_resource_changed)


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()
