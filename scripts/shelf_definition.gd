class_name ShelfDefinition
extends Resource


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
## Anchor points on the shelf where pot baselines are placed.
@export var slot_positions: Array[Vector2] = []
