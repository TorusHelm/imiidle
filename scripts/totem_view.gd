@tool
class_name TotemView
extends Control


@export var preview_definition: TotemDefinition = null:
	set(value):
		_disconnect_preview_resource(preview_definition)
		preview_definition = value
		_connect_preview_resource(preview_definition)
		_queue_preview_refresh()

var _current_definition: TotemDefinition = null
var _default_slot_size := Vector2(170.0, 280.0)


@onready var totem_texture: TextureRect = $TotemTexture


func _ready() -> void:
	_connect_preview_resource(preview_definition)
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and preview_definition != null:
		_refresh_preview()


func show_empty() -> void:
	visible = false
	tooltip_text = ""


func show_totem(totem: TotemInstance) -> void:
	if totem == null or totem.definition == null:
		show_empty()
		return

	var definition := totem.definition
	visible = true
	_apply_definition_layout(definition)
	tooltip_text = "%s\nTrigger: %s\nRule: %s" % [
		definition.display_name,
		definition.trigger_event_type,
		definition.target_rule,
	]


func get_slot_footprint_local_rect() -> Rect2:
	if _current_definition != null:
		return _current_definition.get_slot_footprint_local_rect()
	return Rect2(get_totem_baseline_local_position() + Vector2(-85.0, -202.0), _default_slot_size)


func get_totem_baseline_local_position() -> Vector2:
	var marker: Marker2D = $TotemBaseline
	return marker.position


func get_coin_anchor_local_position() -> Vector2:
	if _current_definition != null and _current_definition.coin_anchor.x >= 0.0 and _current_definition.coin_anchor.y >= 0.0:
		return _current_definition.coin_anchor

	return totem_texture.position + Vector2(
		maxf(totem_texture.size.x - 12.0, 0.0),
		clampf(totem_texture.size.y * 0.33, 0.0, totem_texture.size.y)
	)


func _apply_definition_layout(definition: TotemDefinition) -> void:
	if definition == null:
		return

	_current_definition = definition
	custom_minimum_size = definition.view_size
	size = definition.view_size

	totem_texture.position = definition.texture_position
	totem_texture.size = definition.texture_size
	totem_texture.texture = load(definition.texture_path) if not definition.texture_path.is_empty() else null
	$TotemBaseline.position = definition.totem_baseline
	queue_redraw()


func _queue_preview_refresh() -> void:
	if not is_node_ready():
		return
	call_deferred("_refresh_preview")


func _refresh_preview() -> void:
	if not is_node_ready():
		return

	if not Engine.is_editor_hint():
		return

	if preview_definition == null:
		show_empty()
		return

	show_totem(TotemInstance.new(preview_definition))


func _connect_preview_resource(definition: TotemDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)
	var slot_layout := _get_slot_layout_resource(definition)
	if slot_layout != null and not slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.connect(_on_preview_resource_changed)


func _disconnect_preview_resource(definition: TotemDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)
	var slot_layout := _get_slot_layout_resource(definition)
	if slot_layout != null and slot_layout.changed.is_connected(_on_preview_resource_changed):
		slot_layout.changed.disconnect(_on_preview_resource_changed)


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()


func _get_slot_layout_resource(definition: TotemDefinition) -> SlotLayout:
	if definition == null:
		return null
	return definition.get("slot_layout") as SlotLayout


func _get_slot_size(definition: TotemDefinition) -> Vector2:
	var slot_layout := _get_slot_layout_resource(definition)
	if slot_layout != null:
		return slot_layout.slot_area_size
	return _default_slot_size
