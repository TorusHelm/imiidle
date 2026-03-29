@tool
extends Control


@export var shelf_definition: ShelfDefinition = null:
	set(value):
		_disconnect_shelf_resource(shelf_definition)
		shelf_definition = value
		_connect_shelf_resource(shelf_definition)
		_queue_preview_refresh()

@export var preview_slots: Array[CompositionPreviewSlot] = []:
	set(value):
		_disconnect_slot_resources(preview_slots)
		preview_slots = value
		_connect_slot_resources(preview_slots)
		_queue_preview_refresh()

@export_range(0, 32, 1) var preview_slot_index := 0:
	set(value):
		preview_slot_index = value
		_queue_preview_refresh()

@export var background_color_hex := "#1e1e1e":
	set(value):
		background_color_hex = value
		_queue_preview_refresh()

@export var show_grid := true:
	set(value):
		show_grid = value
		_queue_preview_refresh()

@export_range(8, 256, 1) var grid_size := 32:
	set(value):
		grid_size = value
		_queue_preview_refresh()

@export var show_slot_markers := true:
	set(value):
		show_slot_markers = value
		_queue_preview_refresh()

@export var show_pot_guides := true:
	set(value):
		show_pot_guides = value
		_queue_preview_refresh()


@onready var background: ColorRect = $Background
@onready var shelf_view: ShelfView = %ShelfView


func _ready() -> void:
	_connect_shelf_resource(shelf_definition)
	_connect_slot_resources(preview_slots)
	shelf_view.use_internal_preview = false
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_preview()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_refresh_preview()


func _queue_preview_refresh() -> void:
	if not is_node_ready():
		return
	call_deferred("_refresh_preview")


func _refresh_preview() -> void:
	if not is_node_ready():
		return

	background.color = Color.from_string(background_color_hex, Color(0.117647, 0.117647, 0.117647, 1))

	if shelf_definition == null:
		return

	_ensure_preview_slot_capacity()
	shelf_view.preview_slots(shelf_definition, preview_slots)
	queue_redraw()


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


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()


func _draw() -> void:
	if not is_node_ready():
		return

	if show_grid:
		_draw_grid()

	if shelf_definition == null:
		return

	if show_slot_markers:
		_draw_slot_markers()

	if show_pot_guides:
		_draw_pot_guides()


func _ensure_preview_slot_capacity() -> void:
	if shelf_definition == null:
		return

	var expected_size := shelf_definition.get_slot_count()
	if preview_slots.size() == expected_size:
		return

	while preview_slots.size() < expected_size:
		preview_slots.append(CompositionPreviewSlot.new())

	if preview_slots.size() > expected_size:
		preview_slots.resize(expected_size)


func _connect_slot_resources(slot_configs: Array[CompositionPreviewSlot]) -> void:
	for slot_config in slot_configs:
		_connect_slot_resource(slot_config)


func _disconnect_slot_resources(slot_configs: Array[CompositionPreviewSlot]) -> void:
	for slot_config in slot_configs:
		_disconnect_slot_resource(slot_config)


func _connect_slot_resource(slot_config: CompositionPreviewSlot) -> void:
	if slot_config == null:
		return

	if not slot_config.changed.is_connected(_on_preview_resource_changed):
		slot_config.changed.connect(_on_preview_resource_changed)

	if slot_config.pot_definition != null and not slot_config.pot_definition.changed.is_connected(_on_preview_resource_changed):
		slot_config.pot_definition.changed.connect(_on_preview_resource_changed)

	if slot_config.plant_definition != null and not slot_config.plant_definition.changed.is_connected(_on_preview_resource_changed):
		slot_config.plant_definition.changed.connect(_on_preview_resource_changed)


func _disconnect_slot_resource(slot_config: CompositionPreviewSlot) -> void:
	if slot_config == null:
		return

	if slot_config.changed.is_connected(_on_preview_resource_changed):
		slot_config.changed.disconnect(_on_preview_resource_changed)

	if slot_config.pot_definition != null and slot_config.pot_definition.changed.is_connected(_on_preview_resource_changed):
		slot_config.pot_definition.changed.disconnect(_on_preview_resource_changed)

	if slot_config.plant_definition != null and slot_config.plant_definition.changed.is_connected(_on_preview_resource_changed):
		slot_config.plant_definition.changed.disconnect(_on_preview_resource_changed)


func _draw_grid() -> void:
	var step: int = maxi(grid_size, 8)
	var grid_color := Color(1, 1, 1, 0.08)
	var axis_color := Color(1, 1, 1, 0.18)
	var width: float = size.x
	var height: float = size.y
	var center: Vector2 = size * 0.5

	var x := 0.0
	while x <= width:
		draw_line(Vector2(x, 0), Vector2(x, height), axis_color if is_equal_approx(x, center.x) else grid_color, 1.0)
		x += step

	var y := 0.0
	while y <= height:
		draw_line(Vector2(0, y), Vector2(width, y), axis_color if is_equal_approx(y, center.y) else grid_color, 1.0)
		y += step


func _draw_slot_markers() -> void:
	var slot_positions: Array[Vector2] = shelf_view.get_slot_positions()
	var shelf_origin: Vector2 = shelf_view.position
	var marker_radius := 6.0
	var label_font: Font = ThemeDB.fallback_font

	for index in slot_positions.size():
		var slot_global := shelf_origin + slot_positions[index]
		var fill_color := Color(0.95, 0.75, 0.22, 0.9) if index == preview_slot_index else Color(0.88, 0.88, 0.88, 0.65)
		draw_circle(slot_global, marker_radius, fill_color)
		draw_arc(slot_global, marker_radius + 8.0, 0.0, TAU, 24, Color(1, 1, 1, 0.22), 2.0)
		if label_font != null:
			draw_string(label_font, slot_global + Vector2(10, -10), "slot %d" % index, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.9))


func _draw_pot_guides() -> void:
	var pot_view: PotView = shelf_view.get_pot_view(preview_slot_index)
	if pot_view == null:
		return

	var pot_rect := Rect2(shelf_view.position + pot_view.position, pot_view.size)
	var slot_rect := Rect2(shelf_view.position + pot_view.position + pot_view.get_slot_footprint_local_rect().position, pot_view.get_slot_footprint_local_rect().size)
	var baseline_local: Vector2 = pot_view.get_pot_baseline_local_position()
	var baseline_y: float = pot_rect.position.y + baseline_local.y
	var baseline_center_x: float = pot_rect.position.x + baseline_local.x
	var plant_rect := Rect2(pot_rect.position + pot_view.plant_view.position, pot_view.plant_view.size)
	var label_font: Font = ThemeDB.fallback_font

	draw_rect(slot_rect, Color(1.0, 0.8, 0.2, 0.12), true)
	draw_rect(slot_rect, Color(1.0, 0.8, 0.2, 0.75), false, 2.0)

	draw_rect(pot_rect, Color(0.4, 0.75, 1.0, 0.12), true)
	draw_rect(pot_rect, Color(0.4, 0.75, 1.0, 0.75), false, 2.0)

	draw_rect(plant_rect, Color(0.4, 1.0, 0.55, 0.12), true)
	draw_rect(plant_rect, Color(0.4, 1.0, 0.55, 0.75), false, 2.0)

	draw_line(
		Vector2(pot_rect.position.x - 16.0, baseline_y),
		Vector2(pot_rect.end.x + 16.0, baseline_y),
		Color(1.0, 0.4, 0.4, 0.95),
		2.0
	)
	draw_circle(Vector2(baseline_center_x, baseline_y), 5.0, Color(1.0, 0.4, 0.4, 1.0))

	if label_font != null:
		draw_string(label_font, slot_rect.position + Vector2(0, -10), "slot footprint", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.45, 1.0))
		draw_string(label_font, pot_rect.position + Vector2(0, -10), "pot bounds", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.9, 1.0, 1.0))
		draw_string(label_font, plant_rect.position + Vector2(0, -10), "plant view", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 1.0, 0.7, 1.0))
		draw_string(label_font, Vector2(baseline_center_x + 10.0, baseline_y - 8.0), "baseline", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.55, 0.55, 1.0))
