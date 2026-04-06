class_name DraggableBackpackItemView
extends Control

const POT_SCENE := preload("res://Pots/_shared/sceens/Pot.tscn")
const TOTEM_SCENE := preload("res://Totems/_shared/sceens/Totem.tscn")

var runtime_id := ""
var kind := ""
var pot_instance: PotInstance = null
var totem_instance: TotemInstance = null
var seed_definition: PlantDefinition = null
var _target_size := Vector2.ZERO

@onready var frame: Panel = $Frame
@onready var item_mount: Control = $Frame/ItemMount


func configure(backpack_item, target_size: Vector2) -> void:
	if backpack_item == null:
		return
	runtime_id = String(backpack_item.runtime_id)
	kind = String(backpack_item.kind)
	pot_instance = backpack_item.pot
	totem_instance = backpack_item.totem
	seed_definition = backpack_item.seed_definition
	_target_size = target_size
	if is_node_ready():
		_apply_config()


func _ready() -> void:
	_apply_config()


func _get_drag_data(_at_position: Vector2):
	if runtime_id.is_empty():
		return null

	set_drag_preview(_build_drag_preview_control())
	return {
		"type": "inventory_item",
		"runtime_id": runtime_id,
	}


func _apply_config() -> void:
	custom_minimum_size = _target_size
	size = _target_size
	if frame != null:
		frame.size = _target_size
	_rebuild_preview()


func _rebuild_preview() -> void:
	for child in item_mount.get_children():
		child.queue_free()

	var mounted_view := _build_mounted_preview_view()
	if mounted_view == null:
		return

	item_mount.add_child(mounted_view)
	_set_control_tree_mouse_filter(mounted_view, Control.MOUSE_FILTER_IGNORE)
	mounted_view.position = Vector2.ZERO
	mounted_view.scale = _build_item_scale(_resolve_base_view_size())


func _build_mounted_preview_view() -> Control:
	match kind:
		"pot":
			var pot_view: PotView = POT_SCENE.instantiate()
			_prepare_pot_view_for_preview(pot_view)
			return pot_view
		"totem":
			var totem_view: TotemView = TOTEM_SCENE.instantiate()
			_prepare_totem_view_for_preview(totem_view)
			return totem_view
		"seed":
			return _build_seed_preview_view()
		_:
			return null


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

	var preview_view := _build_mounted_preview_view()
	if preview_view == null:
		return preview

	frame_panel.add_child(preview_view)
	_set_control_tree_mouse_filter(preview_view, Control.MOUSE_FILTER_IGNORE)
	preview_view.position = Vector2(2.0, 2.0)
	preview_view.scale = _build_item_scale(_resolve_base_view_size())
	return preview


func _prepare_pot_view_for_preview(pot_view: PotView) -> void:
	if pot_view == null or pot_instance == null or pot_instance.definition == null:
		return
	pot_view.preview_definition = pot_instance.definition
	pot_view.preview_plant_definition = pot_instance.active_plant.definition if pot_instance.active_plant != null else null
	pot_view.custom_minimum_size = pot_instance.definition.view_size
	pot_view.size = pot_instance.definition.view_size


func _prepare_totem_view_for_preview(totem_view: TotemView) -> void:
	if totem_view == null or totem_instance == null or totem_instance.definition == null:
		return
	totem_view.preview_definition = totem_instance.definition
	totem_view.custom_minimum_size = totem_instance.definition.view_size
	totem_view.size = totem_instance.definition.view_size


func _resolve_base_view_size() -> Vector2:
	if kind == "pot" and pot_instance != null and pot_instance.definition != null:
		return pot_instance.definition.view_size
	if kind == "totem" and totem_instance != null and totem_instance.definition != null:
		return totem_instance.definition.view_size
	if kind == "seed" and seed_definition != null:
		return Vector2(64.0, 64.0)
	return Vector2.ZERO


func _build_item_scale(base_size: Vector2) -> Vector2:
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		return Vector2.ONE
	var available_size := size - Vector2(4.0, 4.0)
	var scale_factor := minf(available_size.x / base_size.x, available_size.y / base_size.y)
	return Vector2.ONE * maxf(scale_factor, 0.05)


func _set_control_tree_mouse_filter(node: Node, mouse_filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = mouse_filter
	for child in node.get_children():
		_set_control_tree_mouse_filter(child, mouse_filter)


func _build_seed_preview_view() -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(64.0, 64.0)
	root.size = root.custom_minimum_size

	var texture := TextureRect.new()
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.position = Vector2(6.0, 6.0)
	texture.size = Vector2(52.0, 52.0)
	if seed_definition != null and not seed_definition.texture_path.is_empty():
		texture.texture = load(seed_definition.texture_path)
	root.add_child(texture)

	var label := Label.new()
	label.text = "S"
	if seed_definition != null and not seed_definition.display_name.is_empty():
		label.text = seed_definition.display_name.left(1).to_upper()
	label.position = Vector2(4.0, 40.0)
	label.size = Vector2(56.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)

	return root
