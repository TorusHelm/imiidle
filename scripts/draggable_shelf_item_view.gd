class_name DraggableShelfItemView
extends Control

const SHELF_SCENE := preload("res://Shelfs/_shared/sceens/Shelf.tscn")

var runtime_id := ""
var definition: ShelfDefinition = null
var footprint := Vector2i.ONE
var _target_size := Vector2.ZERO

@onready var frame: Panel = $Frame
@onready var shelf_mount: Control = $Frame/ShelfMount


func configure(runtime_id_value: String, shelf_definition: ShelfDefinition, footprint_value: Vector2i, target_size: Vector2) -> void:
	runtime_id = runtime_id_value
	definition = shelf_definition
	footprint = footprint_value
	_target_size = target_size
	if is_node_ready():
		_apply_config()


func _ready() -> void:
	_apply_config()


func _get_drag_data(_at_position: Vector2):
	if runtime_id.is_empty() or definition == null:
		return null

	set_drag_preview(_build_drag_preview_control())

	return {
		"type": "shelf",
		"runtime_id": runtime_id,
	}


func _rebuild_preview() -> void:
	for child in shelf_mount.get_children():
		child.queue_free()

	if definition == null:
		return

	var shelf_view: ShelfView = SHELF_SCENE.instantiate()
	shelf_mount.add_child(shelf_view)
	_prepare_shelf_view_for_preview(shelf_view)
	_set_control_tree_mouse_filter(shelf_view, Control.MOUSE_FILTER_IGNORE)
	shelf_view.position = Vector2.ZERO
	shelf_view.scale = _build_shelf_scale(definition.get_resolved_view_size())


func _apply_config() -> void:
	custom_minimum_size = _target_size
	size = _target_size
	if frame != null:
		frame.size = _target_size
	_rebuild_preview()


func _build_shelf_scale(base_size: Vector2) -> Vector2:
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		return Vector2.ONE
	var available_size := size - Vector2(8.0, 8.0)
	var scale_factor := minf(available_size.x / base_size.x, available_size.y / base_size.y)
	return Vector2.ONE * maxf(scale_factor, 0.05)


func _build_drag_preview_control() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame_panel := Panel.new()
	frame_panel.custom_minimum_size = size
	frame_panel.size = size
	frame_panel.self_modulate = Color(1.0, 1.0, 1.0, 0.92)
	preview.add_child(frame_panel)

	var preview_shelf: ShelfView = SHELF_SCENE.instantiate()
	frame_panel.add_child(preview_shelf)
	_prepare_shelf_view_for_preview(preview_shelf)
	_set_control_tree_mouse_filter(preview_shelf, Control.MOUSE_FILTER_IGNORE)
	preview_shelf.position = Vector2(4.0, 4.0)
	preview_shelf.scale = _build_shelf_scale(definition.get_resolved_view_size())

	return preview


func _prepare_shelf_view_for_preview(shelf_view: ShelfView) -> void:
	shelf_view.preview_shelf_definition = definition
	shelf_view.custom_minimum_size = definition.get_resolved_view_size()
	shelf_view.size = definition.get_resolved_view_size()


func _set_control_tree_mouse_filter(node: Node, mouse_filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = mouse_filter
	for child in node.get_children():
		_set_control_tree_mouse_filter(child, mouse_filter)
