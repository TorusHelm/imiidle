@tool
class_name TotemView
extends Control


@export var preview_definition: TotemDefinition = null:
	set(value):
		_disconnect_preview_resource(preview_definition)
		preview_definition = value
		_connect_preview_resource(preview_definition)
		_queue_preview_refresh()

@export var use_internal_preview := true:
	set(value):
		use_internal_preview = value
		_queue_preview_refresh()

var _current_definition: TotemDefinition = null
var _default_slot_size := Vector2(170.0, 280.0)


@onready var frame: Panel = $Frame
@onready var icon: Label = $Frame/Icon
@onready var title: Label = $Frame/Title
@onready var subtitle: Label = $Frame/Subtitle


func _ready() -> void:
	_connect_preview_resource(preview_definition)
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and use_internal_preview:
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
		_string_property(definition, "display_name"),
		_string_property(definition, "trigger_event_type"),
		_string_property(definition, "target_rule"),
	]


func get_slot_footprint_local_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _get_slot_size(_current_definition))


func _apply_definition_layout(definition: TotemDefinition) -> void:
	if definition == null:
		return

	_current_definition = definition
	var slot_size := _get_slot_size(definition)
	custom_minimum_size = slot_size
	size = slot_size

	frame.position = Vector2(19.0, 34.0)
	frame.size = Vector2(slot_size.x - 38.0, slot_size.y - 72.0)
	frame.modulate = _color_property(definition, "accent_color", Color(0.87, 0.66, 0.26, 1.0))
	var icon_text := _string_property(definition, "icon_text", "T")
	icon.text = icon_text if not icon_text.is_empty() else "T"
	title.text = _string_property(definition, "display_name")
	subtitle.text = "reacts via Shelf"


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


func _string_property(resource: Resource, property_name: String, fallback := "") -> String:
	if resource == null:
		return fallback
	var value = resource.get(property_name)
	return fallback if value == null else String(value)


func _color_property(resource: Resource, property_name: String, fallback: Color) -> Color:
	if resource == null:
		return fallback
	var value = resource.get(property_name)
	return value if value is Color else fallback
