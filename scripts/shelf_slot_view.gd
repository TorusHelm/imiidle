@tool
class_name ShelfSlotView
extends Node2D


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const STATUS_ICON_SCENE := preload("res://Ui/SlotStatusIcon.tscn")
const COIN_TEXTURE := preload("res://assets/coin.png")
const DEFAULT_SLOT_RECT := Rect2(Vector2(-85.0, -202.0), Vector2(170.0, 280.0))

@export_group("Status Bar")
@export_range(1, 12, 1) var status_icon_count := 6:
	set(value):
		status_icon_count = max(value, 1)
		_rebuild_status_icon_views()

@export_range(1, 8, 1) var status_icon_columns := 3:
	set(value):
		status_icon_columns = max(value, 1)
		_update_status_icon_layout()

@export var status_icon_size := Vector2(20.0, 20.0):
	set(value):
		status_icon_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_update_status_icon_layout()

@export var status_icon_gap := Vector2(4.0, 4.0):
	set(value):
		status_icon_gap = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_update_status_icon_layout()

@export_group("Coin")
@export_range(0.1, 2.0, 0.05) var coin_animation_duration := 0.5
@export_range(4.0, 120.0, 1.0) var coin_float_distance := 40.0
@export_range(0.1, 2.0, 0.05) var coin_start_scale := 0.9
@export_range(0.1, 2.0, 0.05) var coin_end_scale := 1.0

@export_group("Editor Preview")
@export var show_overlay_preview_in_editor := true:
	set(value):
		show_overlay_preview_in_editor = value
		_update_editor_preview()

@export_range(0, 12, 1) var preview_status_count := 3:
	set(value):
		preview_status_count = maxi(value, 0)
		_update_editor_preview()

@export_range(0.0, 1.0, 0.05) var preview_progress_ratio := 0.75:
	set(value):
		preview_progress_ratio = clampf(value, 0.0, 1.0)
		_update_editor_preview()

var slot_index := -1
var _status_icon_views: Array[SlotStatusIcon] = []
var _progress_bar_ratio := 0.0


@onready var pot_view: PotView = $PotView
@onready var totem_view: TotemView = $TotemView
@onready var content_slot: Control = $ContentSlot
@onready var content_slot_preview: ColorRect = $ContentSlot/ContentSlotPreview
@onready var status_bar: Control = $ContentSlot/StatusBar
@onready var status_bar_preview: ColorRect = $ContentSlot/StatusBar/StatusBarPreview
@onready var status_icons_layer: Control = $ContentSlot/StatusBar/StatusIconsLayer
@onready var progress_bar: Control = $ContentSlot/ProgressBar
@onready var progress_bar_preview: ColorRect = $ContentSlot/ProgressBar/ProgressBarPreview
@onready var progress_bar_fill: ColorRect = $ContentSlot/ProgressBar/BarFill
@onready var coin_slot: Control = $ContentSlot/CoinSlot
@onready var coin_preview: ColorRect = $ContentSlot/CoinSlot/CoinPreview
@onready var floating_feedback_layer: Node2D = $FloatingFeedbackLayer


func _enter_tree() -> void:
	_queue_overlay_layout_update()


func _ready() -> void:
	pot_view.set_slot_index(slot_index)
	if not pot_view.pot_button_pressed.is_connected(_on_pot_button_pressed):
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
	if not pot_view.seed_button_pressed.is_connected(_on_seed_button_pressed):
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)
	_apply_overlay_layout()
	_rebuild_status_icon_views()
	_update_editor_preview()


func set_slot_index(value: int) -> void:
	slot_index = value
	if is_node_ready():
		pot_view.set_slot_index(value)


func show_pot(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	pot_view.visible = true
	totem_view.show_empty()
	pot_view.update_view(pot_instance, can_place_pot, can_plant_seed)
	pot_view.position = -pot_view.get_pot_baseline_local_position()
	_apply_overlay_layout()
	_update_progress_bar_for_slot(pot_instance, null)


func show_totem(totem_instance: TotemInstance) -> void:
	pot_view.visible = false
	totem_view.show_totem(totem_instance)
	totem_view.position = -totem_view.get_totem_baseline_local_position()
	_apply_overlay_layout()
	_update_progress_bar_for_slot(null, totem_instance)


func update_status_modifiers(modifiers: Array) -> void:
	_ensure_status_icon_views()

	for index in _status_icon_views.size():
		if index < modifiers.size():
			_status_icon_views[index].show_modifier(modifiers[index])
			continue
		_status_icon_views[index].clear()

	_update_editor_preview()


func play_feedback(feedback_events: Array[Dictionary]) -> void:
	for feedback_event in feedback_events:
		if String(feedback_event.get("type", "")) != "coin_gain":
			continue
		_spawn_coin_feedback()


func get_pot_view() -> PotView:
	return pot_view


func get_totem_view() -> TotemView:
	return totem_view


func get_status_icon_visible_count() -> int:
	var visible_count := 0
	for status_icon in _status_icon_views:
		if status_icon.visible:
			visible_count += 1
	return visible_count


func get_progress_bar() -> Control:
	return progress_bar


func _on_pot_button_pressed(_pressed_slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(_pressed_slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)


func _ensure_status_icon_views() -> void:
	if not is_node_ready():
		return
	if _status_icon_views.size() != status_icon_count or _status_icon_views.is_empty():
		_rebuild_status_icon_views()


func _rebuild_status_icon_views() -> void:
	if not is_node_ready():
		return

	for child in status_icons_layer.get_children():
		child.queue_free()

	_status_icon_views.clear()

	for index in range(status_icon_count):
		var status_icon: SlotStatusIcon = STATUS_ICON_SCENE.instantiate()
		status_icon.name = "StatusIcon%d" % index
		status_icons_layer.add_child(status_icon)
		_status_icon_views.append(status_icon)

	_update_status_icon_layout()
	_update_editor_preview()


func _update_status_icon_layout() -> void:
	if not is_node_ready():
		return

	var max_width := maxf(status_bar.size.x, status_icon_size.x)
	var resolved_columns := _get_status_icon_columns_for_width(max_width)

	for index in _status_icon_views.size():
		var status_icon := _status_icon_views[index]
		if status_icon == null:
			continue
		status_icon.position = _get_status_icon_position(index, resolved_columns)
		status_icon.custom_minimum_size = status_icon_size
		status_icon.size = status_icon_size


func _get_status_icon_position(index: int, resolved_columns: int) -> Vector2:
	var column := index % resolved_columns
	var row := int(index / resolved_columns)
	return Vector2(
		column * (status_icon_size.x + status_icon_gap.x),
		row * (status_icon_size.y + status_icon_gap.y)
	)


func _get_status_icon_columns_for_width(max_width: float) -> int:
	var cell_width := status_icon_size.x + status_icon_gap.x
	if cell_width <= 0.0:
		return 1
	var columns_that_fit := int(floor((max_width + status_icon_gap.x) / cell_width))
	return maxi(mini(columns_that_fit, status_icon_columns), 1)


func _spawn_coin_feedback() -> void:
	if COIN_TEXTURE == null:
		return

	var coin_sprite := Sprite2D.new()
	coin_sprite.texture = COIN_TEXTURE
	coin_sprite.centered = true
	coin_sprite.position = _get_coin_start_position()
	coin_sprite.scale = Vector2.ONE * coin_start_scale
	floating_feedback_layer.add_child(coin_sprite)

	var end_position := _get_coin_end_position(coin_sprite.position)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(coin_sprite, "position", end_position, coin_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_sprite, "scale", Vector2.ONE * coin_end_scale, coin_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_sprite, "modulate:a", 0.0, coin_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(coin_sprite.queue_free)


func _get_coin_start_position() -> Vector2:
	return content_slot.position + coin_slot.position + coin_slot.size * 0.5


func _get_coin_end_position(start_position: Vector2) -> Vector2:
	return Vector2(start_position.x, start_position.y - coin_float_distance)


func _get_slot_reference_rect() -> Rect2:
	if totem_view.visible:
		return Rect2(totem_view.position + totem_view.get_slot_footprint_local_rect().position, totem_view.get_slot_footprint_local_rect().size)
	if pot_view.visible:
		return Rect2(pot_view.position + pot_view.get_slot_footprint_local_rect().position, pot_view.get_slot_footprint_local_rect().size)
	return DEFAULT_SLOT_RECT


func _update_progress_bar_for_slot(pot_instance: PotInstance, totem_instance: TotemInstance) -> void:
	if totem_instance != null:
		_hide_progress_bar()
		return

	if pot_instance == null or pot_instance.active_plant == null:
		_hide_progress_bar()
		return

	var plant := pot_instance.active_plant
	var cycle_time := plant.get_cycle_time()
	if cycle_time <= 0.0:
		progress_bar.visible = true
		_set_progress_bar_value(1.0)
		progress_bar.tooltip_text = "%s progress: 100%%" % plant.definition.display_name
		return

	var progress_ratio := clampf(plant.progress_seconds / cycle_time, 0.0, 1.0)
	progress_bar.visible = true
	_set_progress_bar_value(progress_ratio)
	progress_bar.tooltip_text = "%s progress: %d%%" % [
		plant.definition.display_name,
		int(round(progress_ratio * 100.0)),
	]


func _hide_progress_bar() -> void:
	progress_bar.visible = false
	_progress_bar_ratio = 0.0
	progress_bar_fill.offset_right = 0.0
	progress_bar.tooltip_text = ""
	_update_editor_preview()


func _update_overlay_layout() -> void:
	_queue_overlay_layout_update()


func _queue_overlay_layout_update() -> void:
	if not is_node_ready():
		return
	call_deferred("_apply_overlay_layout")


func _apply_overlay_layout() -> void:
	if not is_node_ready():
		return

	var slot_rect := _get_slot_reference_rect()
	content_slot.position = slot_rect.position
	content_slot.custom_minimum_size = slot_rect.size
	content_slot.size = slot_rect.size

	content_slot_preview.size = content_slot.size
	status_bar_preview.size = status_bar.size
	progress_bar_preview.size = progress_bar.size
	coin_preview.size = coin_slot.size

	progress_bar_fill.offset_left = 0.0
	progress_bar_fill.offset_top = 0.0
	progress_bar_fill.offset_bottom = progress_bar.size.y
	progress_bar_fill.offset_right = progress_bar.size.x * _progress_bar_ratio

	_update_status_icon_layout()
	_update_editor_preview()

	if Engine.is_editor_hint():
		content_slot_preview.queue_redraw()
		status_bar_preview.queue_redraw()
		progress_bar_preview.queue_redraw()
		progress_bar_fill.queue_redraw()
		progress_bar.queue_redraw()
		status_icons_layer.queue_redraw()
		coin_preview.queue_redraw()
		queue_redraw()


func _set_progress_bar_value(target_value: float) -> void:
	_progress_bar_ratio = clampf(target_value, 0.0, 1.0)
	progress_bar_fill.offset_left = 0.0
	progress_bar_fill.offset_top = 0.0
	progress_bar_fill.offset_bottom = progress_bar.size.y
	progress_bar_fill.offset_right = progress_bar.size.x * _progress_bar_ratio
	_update_editor_preview()


func _update_editor_preview() -> void:
	if not is_node_ready():
		return
	if not Engine.is_editor_hint():
		return

	content_slot_preview.visible = show_overlay_preview_in_editor
	status_bar_preview.visible = show_overlay_preview_in_editor
	progress_bar_preview.visible = show_overlay_preview_in_editor
	coin_preview.visible = show_overlay_preview_in_editor

	var has_visible_status := false
	for status_icon in _status_icon_views:
		if status_icon.visible:
			has_visible_status = true
			break

	if show_overlay_preview_in_editor and not has_visible_status:
		for index in _status_icon_views.size():
			if index < preview_status_count:
				_status_icon_views[index].show_placeholder()
			else:
				_status_icon_views[index].clear()

	if show_overlay_preview_in_editor and not progress_bar.visible:
		progress_bar.visible = true
		progress_bar.tooltip_text = "Progress preview"
		_progress_bar_ratio = preview_progress_ratio
		progress_bar_fill.offset_left = 0.0
		progress_bar_fill.offset_top = 0.0
		progress_bar_fill.offset_bottom = progress_bar.size.y
		progress_bar_fill.offset_right = progress_bar.size.x * _progress_bar_ratio
