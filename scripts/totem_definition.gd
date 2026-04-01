@tool
class_name TotemDefinition
extends Resource

const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")
const DEFAULT_FALLBACK_MODIFIER_SCRIPT := preload("res://scripts/modifier_definition.gd")

@export_group("Identity")
## Stable internal id used by saves, inventory, and lookups.
@export var id := ""
## Human-readable name shown in UI.
@export var display_name := ""

@export_group("Visual")
## PNG used for the totem sprite.
@export_file("*.png") var texture_path := ""
## Overall size of the whole totem widget.
@export var view_size := Vector2(170.0, 280.0)
## Top-left position of the totem sprite inside the totem widget.
@export var texture_position := Vector2(23.0, 48.0)
## Rendered size of the totem sprite.
@export var texture_size := Vector2(124.0, 150.0)

@export_group("Anchors")
## Bottom anchor used to place the totem onto a shelf slot.
@export var totem_baseline := Vector2(85.0, 202.0)
## Optional local anchor inside the TotemView used for floating coin feedback.
## Negative values fall back to the auto-derived top-right anchor of the rendered totem.
@export var coin_anchor := Vector2(-1.0, -1.0)

@export_group("Slot Fit")
@export var slot_layout: SlotLayout
## Fixed slot work area this totem is designed to fit against. Uses shared slot layout when assigned.
@export var slot_footprint_size := Vector2(170.0, 280.0)
## Top-left slot offset relative to the totem baseline.
@export var slot_footprint_offset := Vector2(-85.0, -202.0)

@export_group("Reaction")
@export var trigger_event_type := "plant_activated"
@export var target_rule := "mirror_from_source"
@export var modifier_definition: Resource
@export var modifier_type := "haste"
@export var modifier_multiplier := 2.0
@export var modifier_duration := 1.0


func get_slot_footprint_local_rect() -> Rect2:
	return Rect2(totem_baseline + get_slot_footprint_offset(), get_slot_footprint_size())


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


func get_modifier_definition() -> Resource:
	if modifier_definition != null:
		return modifier_definition
	if modifier_type.is_empty():
		return null

	var fallback_definition = DEFAULT_FALLBACK_MODIFIER_SCRIPT.new()
	fallback_definition.id = modifier_type
	fallback_definition.modifier_type = modifier_type
	fallback_definition.display_name = modifier_type.capitalize()
	fallback_definition.duration = modifier_duration
	match modifier_type:
		"haste", "slow":
			fallback_definition.speed_multiplier = modifier_multiplier
		"rich_harvest_percent":
			fallback_definition.reward_multiplier = modifier_multiplier
		"rich_harvest_flat":
			fallback_definition.flat_reward_bonus = modifier_multiplier
		_:
			fallback_definition.speed_multiplier = modifier_multiplier
	return fallback_definition
