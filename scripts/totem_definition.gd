@tool
class_name TotemDefinition
extends Resource

const DEFAULT_SLOT_LAYOUT: SlotLayout = preload("res://Game/data/default_slot_layout.tres")

@export_group("Identity")
@export var id := ""
@export var display_name := ""

@export_group("Visual")
@export var accent_color := Color(0.87, 0.66, 0.26, 1.0)
@export var icon_text := "T"

@export_group("Slot Fit")
@export var slot_layout: SlotLayout

@export_group("Reaction")
@export var trigger_event_type := "plant_activated"
@export var target_rule := "mirror_from_source"
@export var modifier_type := "haste"
@export var modifier_multiplier := 2.0
@export var modifier_duration := 1.0


func get_slot_layout() -> SlotLayout:
	return slot_layout if slot_layout != null else DEFAULT_SLOT_LAYOUT
