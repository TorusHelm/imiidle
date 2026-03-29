@tool
class_name PotView
extends Control


signal seed_button_pressed(slot_index: int)
signal pot_button_pressed(slot_index: int)


@export var preview_definition: PotDefinition = null:
	set(value):
		_disconnect_pot_resource(preview_definition)
		preview_definition = value
		_connect_pot_resource(preview_definition)
		_queue_preview_refresh()

@export var preview_plant_definition: PlantDefinition = null:
	set(value):
		_disconnect_plant_resource(preview_plant_definition)
		preview_plant_definition = value
		_connect_plant_resource(preview_plant_definition)
		_queue_preview_refresh()

@export var use_internal_preview := true:
	set(value):
		use_internal_preview = value
		if is_node_ready():
			plant_view.use_internal_preview = value
		_queue_preview_refresh()


var slot_index := -1


@onready var slot_button: Button = $SlotButton
@onready var slot_label: Label = $SlotLabel
@onready var pot_texture: TextureRect = $PotTexture
@onready var seed_button: Button = $SeedButton
@onready var plant_view: PlantView = $PlantView


func _ready() -> void:
	slot_button.grab_focus()
	_connect_pot_resource(preview_definition)
	_connect_plant_resource(preview_plant_definition)
	plant_view.use_internal_preview = use_internal_preview
	set_process(Engine.is_editor_hint())
	_refresh_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and use_internal_preview:
		_refresh_preview()


func set_slot_index(value: int) -> void:
	slot_index = value


func get_pot_baseline_local_position() -> Vector2:
	var marker: Marker2D = get_node("PotBaseline")
	return marker.position


func get_plant_attach_local_position() -> Vector2:
	var marker: Marker2D = get_node("PlantAttachPoint")
	return marker.position


func update_view(pot_instance: PotInstance, can_place_pot: bool, can_plant_seed: bool) -> void:
	var pot_definition: PotDefinition = pot_instance.definition if pot_instance != null else null
	_apply_definition_layout(pot_definition)

	if pot_instance == null:
		slot_button.visible = true
		slot_button.disabled = not can_place_pot
		slot_label.visible = true
		pot_texture.visible = false
		seed_button.visible = false
		plant_view.visible = false
		slot_button.tooltip_text = "Empty slot\nChoose a pot for this shelf slot."
		slot_label.tooltip_text = slot_button.tooltip_text
		tooltip_text = slot_button.tooltip_text
		return

	slot_button.visible = false
	slot_label.visible = false
	pot_texture.visible = true
	seed_button.visible = true
	plant_view.visible = true
	pot_texture.texture = load(pot_instance.definition.texture_path) if not pot_instance.definition.texture_path.is_empty() else null
	seed_button.disabled = not can_plant_seed

	var pot_details := "%s\nStatus: empty" % pot_instance.definition.display_name

	if pot_instance.active_plant == null:
		plant_view.show_empty()
		pot_texture.tooltip_text = pot_details
		seed_button.tooltip_text = "Choose a seed for %s." % pot_instance.definition.display_name
		tooltip_text = pot_details
		return

	if pot_instance.active_plant.is_mature():
		pot_details = "%s\nPlant: %s\nStatus: mature" % [
			pot_instance.definition.display_name,
			pot_instance.active_plant.definition.display_name,
		]
	else:
		pot_details = "%s\nPlant: %s\nStatus: growing" % [
			pot_instance.definition.display_name,
			pot_instance.active_plant.definition.display_name,
		]

	plant_view.show_plant(pot_instance.active_plant)
	pot_texture.tooltip_text = pot_details
	seed_button.tooltip_text = "This pot already has a plant."
	tooltip_text = pot_details


func _on_seed_button_pressed() -> void:
	seed_button_pressed.emit(slot_index)


func _on_slot_button_pressed() -> void:
	pot_button_pressed.emit(slot_index)


func _apply_definition_layout(definition: PotDefinition) -> void:
	if definition == null:
		return

	custom_minimum_size = definition.view_size
	size = definition.view_size
	pot_texture.position = definition.pot_texture_position
	pot_texture.size = definition.pot_texture_size
	var plant_view_top_left := definition.plant_attach_point - Vector2(
		definition.plant_view_size.x * 0.5,
		definition.plant_view_size.y
	)
	plant_view.position = plant_view_top_left + definition.plant_view_position
	plant_view.custom_minimum_size = definition.plant_view_size
	plant_view.size = definition.plant_view_size
	seed_button.position = definition.seed_button_position
	seed_button.size = definition.seed_button_size
	slot_button.position = definition.slot_button_position
	slot_button.size = definition.slot_button_size
	slot_label.position = definition.slot_label_position
	slot_label.size = definition.slot_label_size
	get_node("PlantAttachPoint").position = definition.plant_attach_point
	get_node("PotBaseline").position = definition.pot_baseline


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
		update_view(null, true, false)
		return

	var pot_instance := PotInstance.new(preview_definition)
	if preview_plant_definition != null:
		pot_instance.active_plant = PlantInstance.new(preview_plant_definition)

	update_view(pot_instance, true, preview_plant_definition == null)


func _connect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if not definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.connect(_on_preview_resource_changed)


func _disconnect_pot_resource(definition: PotDefinition) -> void:
	if definition == null:
		return
	if definition.changed.is_connected(_on_preview_resource_changed):
		definition.changed.disconnect(_on_preview_resource_changed)


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


func _on_preview_resource_changed() -> void:
	_queue_preview_refresh()
