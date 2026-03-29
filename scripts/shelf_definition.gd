@tool
class_name ShelfDefinition
extends Resource

const DEFAULT_SLOT_LAYOUT_METRICS: SlotLayoutMetrics = preload("res://Game/data/default_slot_layout_metrics.tres")

@export_group("Identity")
## Stable internal id used by catalogs and lookups.
@export var id := ""
## Human-readable shelf name shown in UI.
@export var display_name := ""

@export_group("Visual")
## PNG used for the shelf sprite.
@export_file("*.png") var texture_path := ""
## Overall size of the whole shelf widget.
@export var view_size := Vector2(700.0, 300.0)
## Top-left position of the shelf sprite inside the shelf widget.
@export var texture_position := Vector2(64.0, 198.0)
## Rendered size of the shelf sprite.
@export var texture_size := Vector2(572.0, 54.0)

@export_group("Title")
## Top-left position of the title label.
@export var title_position := Vector2(0.0, 260.0)
## Size of the title label area.
@export var title_size := Vector2(700.0, 24.0)

@export_group("Slots")
## Shared slot metrics used as the base unit for shelf work areas.
@export var slot_layout_metrics: SlotLayoutMetrics
## When enabled, slot anchors are generated from a fixed slot grid instead of manual positions.
@export var use_slot_grid := false
## Number of slot columns in the working area.
@export_range(0, 32, 1) var slot_grid_columns := 0
## Number of slot rows in the working area.
@export_range(0, 32, 1) var slot_grid_rows := 1
## Top-left origin of the first slot work area.
@export var slot_area_origin := Vector2.ZERO
## Fixed work area size for one slot. Uses shared metrics when left empty.
@export var slot_area_size := Vector2(170.0, 281.0)
## Gap between slot work areas.
@export var slot_area_gap := Vector2.ZERO
## Baseline anchor inside one slot work area. Uses shared metrics when left empty.
@export var slot_anchor_offset := Vector2(85.0, 202.0)
## Manual anchor points on the shelf where pot baselines are placed.
@export var slot_positions: Array[Vector2] = []


func get_slot_count() -> int:
	if use_slot_grid:
		return maxi(slot_grid_columns, 0) * maxi(slot_grid_rows, 0)
	return slot_positions.size()


func get_slot_positions() -> Array[Vector2]:
	if not use_slot_grid:
		return slot_positions.duplicate()

	var positions: Array[Vector2] = []
	var resolved_slot_area_size := get_slot_area_size()
	var resolved_slot_anchor_offset := get_slot_anchor_offset()

	for row in maxi(slot_grid_rows, 0):
		for column in maxi(slot_grid_columns, 0):
			var slot_origin := slot_area_origin + Vector2(
				column * (resolved_slot_area_size.x + slot_area_gap.x),
				row * (resolved_slot_area_size.y + slot_area_gap.y)
			)
			positions.append(slot_origin + resolved_slot_anchor_offset)

	return positions


func get_slot_work_area_size() -> Vector2:
	if not use_slot_grid:
		return Vector2.ZERO

	var columns := maxi(slot_grid_columns, 0)
	var rows := maxi(slot_grid_rows, 0)
	if columns == 0 or rows == 0:
		return Vector2.ZERO

	var resolved_slot_area_size := get_slot_area_size()
	return Vector2(
		columns * resolved_slot_area_size.x + maxi(columns - 1, 0) * slot_area_gap.x,
		rows * resolved_slot_area_size.y + maxi(rows - 1, 0) * slot_area_gap.y
	)


func get_resolved_view_size() -> Vector2:
	var slot_end := slot_area_origin + get_slot_work_area_size()
	var texture_end := texture_position + texture_size
	var title_end := title_position + title_size
	return Vector2(
		maxf(view_size.x, maxf(slot_end.x, maxf(texture_end.x, title_end.x))),
		maxf(view_size.y, maxf(slot_end.y, maxf(texture_end.y, title_end.y)))
	)


func get_slot_layout_metrics() -> SlotLayoutMetrics:
	return slot_layout_metrics if slot_layout_metrics != null else DEFAULT_SLOT_LAYOUT_METRICS


func get_slot_area_size() -> Vector2:
	if slot_layout_metrics != null:
		return slot_layout_metrics.slot_area_size
	if slot_area_size != Vector2(170.0, 281.0):
		return slot_area_size
	return get_slot_layout_metrics().slot_area_size


func get_slot_anchor_offset() -> Vector2:
	if slot_layout_metrics != null:
		return slot_layout_metrics.slot_anchor_offset
	if slot_anchor_offset != Vector2(85.0, 202.0):
		return slot_anchor_offset
	return get_slot_layout_metrics().slot_anchor_offset
