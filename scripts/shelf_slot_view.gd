@tool
class_name ShelfSlotView
extends Node2D


signal pot_slot_pressed(slot_index: int)
signal seed_slot_pressed(slot_index: int)

const STATUS_ICON_SCENE := preload("res://Ui/SlotStatusIcon.tscn")
const COIN_TEXTURE := preload("res://assets/coin.png")
const DEFAULT_SLOT_RECT := Rect2(Vector2(-85.0, -202.0), Vector2(170.0, 280.0))

@export_group("Status Overlay")
@export_range(1, 12, 1) var status_icon_count := 6:
	set(value):
		status_icon_count = max(value, 1)
		_rebuild_status_icon_views()

@export_range(1, 6, 1) var status_icon_columns := 3:
	set(value):
		status_icon_columns = max(value, 1)
		_update_status_icon_layout()

@export var status_grid_origin := Vector2(-77.0, -194.0):
	set(value):
		status_grid_origin = value
		_update_status_icon_layout()

@export var status_icon_size := Vector2(20.0, 20.0):
	set(value):
		status_icon_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_update_status_icon_layout()

@export var status_icon_gap := Vector2(4.0, 4.0):
	set(value):
		status_icon_gap = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_update_status_icon_layout()

@export_group("Coin Feedback")
@export var coin_fallback_padding := Vector2(14.0, 12.0):
	set(value):
		coin_fallback_padding = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))

@export_range(0.1, 2.0, 0.05) var coin_animation_duration := 0.5
@export_range(4.0, 120.0, 1.0) var coin_float_distance := 40.0
@export_range(0.1, 2.0, 0.05) var coin_start_scale := 0.9
@export_range(0.1, 2.0, 0.05) var coin_end_scale := 1.0

var slot_index := -1
var _status_icon_views: Array[SlotStatusIcon] = []


@onready var pot_view: PotView = $PotView
@onready var totem_view: TotemView = $TotemView
@onready var status_icons_layer: Control = $StatusIconsLayer
@onready var floating_feedback_layer: Node2D = $FloatingFeedbackLayer


func _ready() -> void:
	pot_view.set_slot_index(slot_index)
	if not pot_view.pot_button_pressed.is_connected(_on_pot_button_pressed):
		pot_view.pot_button_pressed.connect(_on_pot_button_pressed)
	if not pot_view.seed_button_pressed.is_connected(_on_seed_button_pressed):
		pot_view.seed_button_pressed.connect(_on_seed_button_pressed)
	_rebuild_status_icon_views()


func set_slot_index(value: int) -> void:
	slot_index = value
	if is_node_ready():
		pot_view.set_slot_index(value)


func show_pot(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	pot_view.visible = true
	totem_view.show_empty()
	pot_view.update_view(pot_instance, can_place_pot, can_plant_seed)
	pot_view.position = -pot_view.get_pot_baseline_local_position()


func show_totem(totem_instance: TotemInstance) -> void:
	pot_view.visible = false
	totem_view.show_totem(totem_instance)
	totem_view.position = -totem_view.get_totem_baseline_local_position()


func update_status_modifiers(modifiers: Array[Dictionary]) -> void:
	_ensure_status_icon_views()

	for index in _status_icon_views.size():
		if index < modifiers.size():
			_status_icon_views[index].show_modifier(modifiers[index])
			continue
		_status_icon_views[index].clear()


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


func _on_pot_button_pressed(_pressed_slot_index: int) -> void:
	pot_slot_pressed.emit(slot_index)


func _on_seed_button_pressed(_pressed_slot_index: int) -> void:
	seed_slot_pressed.emit(slot_index)


func _ensure_status_icon_views() -> void:
	if not is_node_ready():
		return
	if _status_icon_views.size() != status_icon_count:
		_rebuild_status_icon_views()
		return

	if _status_icon_views.is_empty():
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


func _update_status_icon_layout() -> void:
	if not is_node_ready():
		return

	for index in _status_icon_views.size():
		var status_icon := _status_icon_views[index]
		if status_icon == null:
			continue
		status_icon.position = _get_status_icon_position(index)
		status_icon.custom_minimum_size = status_icon_size
		status_icon.size = status_icon_size


func _get_status_icon_position(index: int) -> Vector2:
	var column := index % status_icon_columns
	var row := int(index / status_icon_columns)
	return status_grid_origin + Vector2(
		column * (status_icon_size.x + status_icon_gap.x),
		row * (status_icon_size.y + status_icon_gap.y)
	)


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
	if totem_view.visible:
		return totem_view.position + totem_view.get_coin_anchor_local_position()
	if pot_view.visible:
		return pot_view.position + pot_view.get_coin_anchor_local_position()

	var slot_rect := _get_slot_reference_rect()
	return slot_rect.position + Vector2(
		maxf(slot_rect.size.x - coin_fallback_padding.x, 0.0),
		maxf(coin_fallback_padding.y, 0.0)
	)


func _get_coin_end_position(start_position: Vector2) -> Vector2:
	return Vector2(start_position.x, start_position.y - coin_float_distance)


func _get_slot_reference_rect() -> Rect2:
	if totem_view.visible:
		return Rect2(totem_view.position + totem_view.get_slot_footprint_local_rect().position, totem_view.get_slot_footprint_local_rect().size)
	if pot_view.visible:
		return Rect2(pot_view.position + pot_view.get_slot_footprint_local_rect().position, pot_view.get_slot_footprint_local_rect().size)
	return DEFAULT_SLOT_RECT
