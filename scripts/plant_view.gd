@tool
class_name PlantView
extends Control


@export var preview_definition: PlantDefinition = null:
	set(value):
		_disconnect_preview_resource(preview_definition)
		preview_definition = value
		_connect_preview_resource(preview_definition)
		_queue_preview_refresh()

@export var use_internal_preview := true:
	set(value):
		use_internal_preview = value
		_queue_preview_refresh()


@onready var plant_texture: TextureRect = $PlantTexture


func _ready() -> void:
	_connect_preview_resource(preview_definition)
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and use_internal_preview:
		_refresh_preview()


func show_empty() -> void:
	plant_texture.visible = false
	plant_texture.texture = null
	tooltip_text = "No plant\nPlant a seed to start growing."
	plant_texture.tooltip_text = tooltip_text


func show_plant(plant: PlantInstance) -> void:
	if plant == null or plant.definition == null:
		show_empty()
		return

	_apply_definition_layout(plant.definition)
	plant_texture.visible = true
	plant_texture.texture = load(plant.definition.texture_path) if not plant.definition.texture_path.is_empty() else null
	plant_texture.modulate = plant.definition.display_color

	var status_text := "Status: growing"
	var details_text := "Growth: %d%%" % plant.get_growth_percent()

	if plant.is_mature():
		status_text = "Status: mature"
		details_text = _get_income_tooltip_text(plant)

	tooltip_text = "%s\n%s\n%s" % [plant.definition.display_name, status_text, details_text]
	plant_texture.tooltip_text = tooltip_text


func _apply_definition_layout(definition: PlantDefinition) -> void:
	if definition == null:
		return

	if size.x <= 0.0 or size.y <= 0.0:
		custom_minimum_size = definition.texture_size
		size = definition.texture_size

	var plant_area_size: Vector2 = size
	var base_position := Vector2(
		(plant_area_size.x - definition.texture_size.x) * 0.5,
		plant_area_size.y - definition.texture_size.y
	)

	plant_texture.position = base_position + definition.texture_offset
	plant_texture.size = definition.texture_size


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

	show_plant(PlantInstance.new(preview_definition))


func _connect_preview_resource(definition: PlantDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)


func _disconnect_preview_resource(definition: PlantDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()


func _get_income_tooltip_text(plant: PlantInstance) -> String:
	if plant == null or plant.definition == null:
		return ""

	var reward := plant.get_activation_reward()
	var interval := plant.get_cycle_time()
	return "Income: %.1f coins every %.1f sec" % [reward, interval]
