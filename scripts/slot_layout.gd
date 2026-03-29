@tool
class_name SlotLayout
extends Resource


@export_group("Slot Area")
## Fixed work area size for one slot.
@export var slot_area_size := Vector2(170.0, 280.0)
## Baseline anchor inside one slot work area.
@export var slot_anchor_offset := Vector2(85.0, 202.0)


func get_slot_area_rect() -> Rect2:
	return Rect2(Vector2.ZERO, slot_area_size)
