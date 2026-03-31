class_name RoomView
extends Control

signal choose_shelf_pressed(room_slot_index: int)
signal pot_slot_pressed(room_slot_index: int, shelf_slot_index: int)
signal seed_slot_pressed(room_slot_index: int, shelf_slot_index: int)

const ROOM_SLOT_SCENE := preload("res://Ui/RoomShelfSlot.tscn")
const DEFAULT_ROOM_DEFINITION: RoomDefinition = preload("res://Game/data/default_room.tres")

@export var room_definition: RoomDefinition = DEFAULT_ROOM_DEFINITION

var _room_slot_views: Array[RoomSlotView] = []
var _current_room_id := ""

@onready var world_root: Control = $WorldRoot
@onready var slots_root: Control = $WorldRoot/SlotsRoot


func _ready() -> void:
	_rebuild_slot_views()


func configure(definition: RoomDefinition) -> void:
	var resolved_definition := definition if definition != null else DEFAULT_ROOM_DEFINITION
	var next_room_id := resolved_definition.id
	var needs_rebuild := _current_room_id != next_room_id or _room_slot_views.size() != resolved_definition.get_slot_count()
	room_definition = resolved_definition
	_current_room_id = next_room_id
	if not needs_rebuild:
		return
	_rebuild_slot_views()


func update_view(game_state: GameState) -> void:
	configure(game_state.get_room_definition())

	for room_slot_index in _room_slot_views.size():
		var slot_view := _room_slot_views[room_slot_index]
		var shelf := game_state.get_shelf_in_room_slot(room_slot_index)
		if shelf == null:
			slot_view.show_empty(room_definition.slot_area_size)
			continue

		slot_view.show_shelf(room_definition.slot_area_size, shelf.definition, game_state, room_slot_index)


func position_content(_viewport_size: Vector2) -> void:
	pass


func _rebuild_slot_views() -> void:
	if not is_node_ready():
		return

	for child in slots_root.get_children():
		child.queue_free()

	_room_slot_views.clear()

	var resolved_definition := room_definition if room_definition != null else DEFAULT_ROOM_DEFINITION
	var room_model := resolved_definition.get_room_model()

	for slot_data in room_model.slots:
		var slot_view: RoomSlotView = ROOM_SLOT_SCENE.instantiate()
		slot_view.name = "RoomSlot%d" % int(slot_data.get("index", -1))
		slot_view.position = slot_data.get("position", Vector2.ZERO)
		slot_view.set_room_slot_index(int(slot_data.get("index", -1)))
		slot_view.choose_shelf_pressed.connect(_on_choose_shelf_pressed)
		slot_view.pot_slot_pressed.connect(_on_pot_slot_pressed)
		slot_view.seed_slot_pressed.connect(_on_seed_slot_pressed)
		slots_root.add_child(slot_view)
		_room_slot_views.append(slot_view)


func _on_choose_shelf_pressed(room_slot_index: int) -> void:
	choose_shelf_pressed.emit(room_slot_index)


func _on_pot_slot_pressed(room_slot_index: int, shelf_slot_index: int) -> void:
	pot_slot_pressed.emit(room_slot_index, shelf_slot_index)


func _on_seed_slot_pressed(room_slot_index: int, shelf_slot_index: int) -> void:
	seed_slot_pressed.emit(room_slot_index, shelf_slot_index)
