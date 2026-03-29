@tool
class_name PotDefinition
extends Resource

const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")

@export_group("Identity")
## Stable internal id used by saves, inventory, and lookups.
@export var id := ""
## Human-readable name shown in UI.
@export var display_name := ""

@export_group("Visual")
## PNG used for the pot sprite.
@export_file("*.png") var texture_path := ""
## Overall size of the whole pot widget.
@export var view_size := Vector2(220.0, 320.0)
## Top-left position of the pot sprite inside the pot widget.
@export var pot_texture_position := Vector2(50.0, 190.0)
## Rendered size of the pot sprite.
@export var pot_texture_size := Vector2(120.0, 110.0)

@export_group("Plant Area")
## Extra local offset for the plant area after anchor placement from attach point.
@export var plant_view_position := Vector2(30.0, 0.0)
## Size of the area reserved for the plant sprite.
@export var plant_view_size := Vector2(160.0, 190.0)
## Anchor point where the plant grows from. Plant area is built from this point.
@export var plant_attach_point := Vector2(110.0, 190.0)

@export_group("UI")
## Top-left position of the seed button.
@export var seed_button_position := Vector2(66.0, 228.0)
## Size of the seed button.
@export var seed_button_size := Vector2(88.0, 36.0)
## Top-left position of the empty-slot button.
@export var slot_button_position := Vector2(34.0, 178.0)
## Size of the empty-slot button.
@export var slot_button_size := Vector2(154.0, 114.0)
## Top-left position of the empty-slot label.
@export var slot_label_position := Vector2(18.0, 210.0)
## Size of the empty-slot label.
@export var slot_label_size := Vector2(184.0, 49.0)

@export_group("Anchors")
## Bottom anchor used to place the pot onto a shelf slot.
@export var pot_baseline := Vector2(110.0, 300.0)

@export_group("Slot Fit")
## Shared slot layout used as the base unit for this pot.
@export var slot_layout: SlotLayout
## Fixed slot work area this pot is designed to fit against. Uses shared slot layout when assigned.
@export var slot_footprint_size := Vector2(170.0, 280.0)
## Top-left slot offset relative to the pot baseline.
@export var slot_footprint_offset := Vector2(-85.0, -202.0)


func get_slot_footprint_local_rect() -> Rect2:
	return Rect2(pot_baseline + get_slot_footprint_offset(), get_slot_footprint_size())


func get_slot_layout() -> SlotLayout:
	return slot_layout if slot_layout != null else DEFAULT_SLOT_LAYOUT


func get_slot_footprint_size() -> Vector2:
	if slot_layout != null:
		return slot_layout.slot_area_size
	if slot_footprint_size != Vector2(170.0, 280.0):
		return slot_footprint_size
	return get_slot_layout().slot_area_size


func get_slot_footprint_offset() -> Vector2:
	if slot_layout != null:
		return -get_slot_layout().slot_anchor_offset
	if slot_footprint_offset != Vector2(-85.0, -202.0):
		return slot_footprint_offset
	return -get_slot_layout().slot_anchor_offset
