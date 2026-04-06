@tool
class_name ShelfSlotView
extends Node2D


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)
signal slot_item_drop_requested(source_room_slot_index: int, source_slot_index: int, target_room_slot_index: int, target_slot_index: int)
signal backpack_item_drop_requested(runtime_id: String, target_room_slot_index: int, target_slot_index: int)

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
@export_range(0.0, 64.0, 1.0) var coin_amount_spacing := 8.0

@export_group("Empty Pot Slot")
@export_multiline var empty_pot_slot_label_text := "Empty Slot\nChoose Pot":
	set(value):
		empty_pot_slot_label_text = value
		if is_node_ready():
			pot_view.empty_slot_label_text = value

@export_multiline var empty_pot_slot_tooltip_text := "Empty slot\nChoose a pot for this shelf slot.":
	set(value):
		empty_pot_slot_tooltip_text = value
		if is_node_ready():
			pot_view.empty_slot_tooltip_text = value

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
var _game_state: GameState = null
var _room_slot_index := -1
var _status_icon_views: Array[SlotStatusIcon] = []
var _progress_bar_ratio := 0.0


@onready var pot_view: PotView = $PotView
@onready var totem_view: TotemView = $TotemView
@onready var content_slot: Control = $ContentSlot
@onready var content_slot_preview: ColorRect = $ContentSlot/ContentSlotPreview
@onready var drop_preview_mount: Control = $ContentSlot/DropPreviewMount
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
	pot_view.empty_slot_label_text = empty_pot_slot_label_text
	pot_view.empty_slot_tooltip_text = empty_pot_slot_tooltip_text
	if not pot_view.pot_button_pressed.is_connected(_on_pot_button_pressed):
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
	if not pot_view.seed_button_pressed.is_connected(_on_seed_button_pressed):
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)
	if not pot_view.mouse_exited.is_connected(_on_drop_target_mouse_exited):
		pot_view.mouse_exited.connect(_on_drop_target_mouse_exited)
	if not pot_view.slot_button.mouse_exited.is_connected(_on_drop_target_mouse_exited):
		pot_view.slot_button.mouse_exited.connect(_on_drop_target_mouse_exited)
	if not pot_view.seed_button.mouse_exited.is_connected(_on_drop_target_mouse_exited):
		pot_view.seed_button.mouse_exited.connect(_on_drop_target_mouse_exited)
	if not totem_view.mouse_exited.is_connected(_on_drop_target_mouse_exited):
		totem_view.mouse_exited.connect(_on_drop_target_mouse_exited)
	_sync_content_view_positions()
	_apply_overlay_layout()
	_rebuild_status_icon_views()
	_update_editor_preview()


func set_slot_index(value: int) -> void:
	slot_index = value
	if is_node_ready():
		pot_view.set_slot_index(value)


func set_runtime_context(game_state: GameState, room_slot_index: int) -> void:
	_game_state = game_state
	_room_slot_index = room_slot_index
	_update_drag_payloads()


func show_pot(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	pot_view.visible = true
	totem_view.show_empty()
	pot_view.update_view(pot_instance, can_place_pot, can_plant_seed)
	_update_drag_payloads()
	_sync_content_view_positions()
	_apply_overlay_layout()
	_update_progress_bar_for_slot(pot_instance, null)


func show_totem(totem_instance: TotemInstance) -> void:
	pot_view.visible = false
	totem_view.show_totem(totem_instance)
	_update_drag_payloads()
	_sync_content_view_positions()
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
		_spawn_coin_feedback(float(feedback_event.get("amount", 0.0)))


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


func _on_drop_target_mouse_exited() -> void:
	_clear_drop_preview()


func can_drop_slot_item_data(data: Variant) -> bool:
	if not (data is Dictionary):
		_clear_drop_preview()
		return false
	if _game_state == null or _room_slot_index < 0:
		_clear_drop_preview()
		return false
	var can_drop := false
	match String(data.get("type", "")):
		"shelf_slot_item":
			var source_room_slot_index := int(data.get("source_room_slot_index", -1))
			var source_slot_index := int(data.get("source_slot_index", -1))
			if source_room_slot_index != _room_slot_index:
				_clear_drop_preview()
				return false
			can_drop = _game_state.can_move_item_in_room_shelf_slot(_room_slot_index, source_slot_index, slot_index)
		"inventory_item":
			can_drop = _game_state.can_place_backpack_item_in_room_shelf_slot(String(data.get("runtime_id", "")), _room_slot_index, slot_index)
		_:
			_clear_drop_preview()
			return false
	_show_drop_preview(data, can_drop)
	return can_drop


func drop_slot_item_data(data: Variant) -> void:
	if not can_drop_slot_item_data(data):
		return
	match String(data.get("type", "")):
		"shelf_slot_item":
			slot_item_drop_requested.emit(
				int(data.get("source_room_slot_index", -1)),
				int(data.get("source_slot_index", -1)),
				_room_slot_index,
				slot_index
			)
		"inventory_item":
			backpack_item_drop_requested.emit(String(data.get("runtime_id", "")), _room_slot_index, slot_index)
	_clear_drop_preview()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_drop_preview()


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
	var row := int(index / float(resolved_columns))
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


func _spawn_coin_feedback(amount: float) -> void:
	if COIN_TEXTURE == null:
		return

	var start_position := _get_coin_start_position()
	var coin_sprite := Sprite2D.new()
	coin_sprite.texture = COIN_TEXTURE
	coin_sprite.centered = true
	coin_sprite.position = start_position
	coin_sprite.scale = Vector2.ONE * coin_start_scale
	floating_feedback_layer.add_child(coin_sprite)

	var coin_amount_label := Label.new()
	coin_amount_label.text = _format_coin_feedback_amount(amount)
	coin_amount_label.position = _get_coin_amount_label_position(start_position, coin_amount_label.get_minimum_size())
	coin_amount_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	floating_feedback_layer.add_child(coin_amount_label)

	var end_position := _get_coin_end_position(start_position)
	var label_end_position := Vector2(coin_amount_label.position.x, end_position.y - coin_amount_label.get_minimum_size().y * 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(coin_sprite, "position", end_position, coin_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_sprite, "scale", Vector2.ONE * coin_end_scale, coin_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_sprite, "modulate:a", 0.0, coin_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(coin_amount_label, "position", label_end_position, coin_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_amount_label, "modulate:a", 0.0, coin_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(coin_sprite.queue_free)
	tween.finished.connect(coin_amount_label.queue_free)


func _get_coin_start_position() -> Vector2:
	return content_slot.position + coin_slot.position + coin_slot.size * 0.5


func _get_coin_end_position(start_position: Vector2) -> Vector2:
	return Vector2(start_position.x, start_position.y - coin_float_distance)


func _get_coin_amount_label_position(coin_position: Vector2, label_size: Vector2) -> Vector2:
	var coin_half_width := COIN_TEXTURE.get_size().x * coin_start_scale * 0.5
	return Vector2(
		coin_position.x - coin_half_width - coin_amount_spacing - label_size.x,
		coin_position.y - label_size.y * 0.5
	)


func _format_coin_feedback_amount(amount: float) -> String:
	return "+%.1f" % amount


func _get_slot_reference_rect() -> Rect2:
	if totem_view.visible:
		return Rect2(totem_view.position + totem_view.get_slot_footprint_local_rect().position, totem_view.get_slot_footprint_local_rect().size)
	if pot_view.visible:
		return Rect2(pot_view.position + pot_view.get_slot_footprint_local_rect().position, pot_view.get_slot_footprint_local_rect().size)
	return DEFAULT_SLOT_RECT


func _sync_content_view_positions() -> void:
	if not is_node_ready():
		return

	pot_view.position = -pot_view.get_pot_baseline_local_position()
	totem_view.position = -totem_view.get_totem_baseline_local_position()


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
	drop_preview_mount.size = content_slot.size
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


func _update_drag_payloads() -> void:
	var payload := {}
	if _room_slot_index >= 0:
		payload = {
			"type": "shelf_slot_item",
			"source_room_slot_index": _room_slot_index,
			"source_slot_index": slot_index,
		}
	pot_view.drag_payload = payload.duplicate(true)
	totem_view.drag_payload = payload.duplicate(true)


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


func _show_drop_preview(data: Dictionary, is_valid: bool) -> void:
	if not is_valid:
		_clear_drop_preview_visuals()
		return
	var shelf_view = _get_parent_shelf_view()
	var room_view = _get_parent_room_view()
	if room_view != null and room_view.has_method("clear_shelf_drop_previews_except"):
		room_view.clear_shelf_drop_previews_except(shelf_view)
	if shelf_view != null and shelf_view.has_method("set_active_drop_preview_slot"):
		shelf_view.set_active_drop_preview_slot(slot_index)
	content_slot_preview.visible = true
	content_slot_preview.color = Color(0.32, 0.84, 0.45, 0.14)
	content_slot_preview.guide_color = Color(0.32, 0.84, 0.45, 0.95)


func _clear_drop_preview() -> void:
	var shelf_view = _get_parent_shelf_view()
	if shelf_view != null and shelf_view.has_method("clear_active_drop_preview_slot"):
		shelf_view.clear_active_drop_preview_slot(slot_index)
	_clear_drop_preview_visuals()


func clear_drop_preview_from_parent() -> void:
	_clear_drop_preview_visuals()


func _clear_drop_preview_visuals() -> void:
	if Engine.is_editor_hint():
		_update_editor_preview()
		return
	content_slot_preview.visible = false
	content_slot_preview.color = Color(1.0, 1.0, 1.0, 0.0)
	for child in drop_preview_mount.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		child.queue_free()


func _get_parent_shelf_view():
	var current: Node = get_parent()
	while current != null:
		if current is ShelfView:
			return current
		current = current.get_parent()
	return null


func _get_parent_room_view():
	var current: Node = get_parent()
	while current != null:
		if current is RoomView:
			return current
		current = current.get_parent()
	return null
