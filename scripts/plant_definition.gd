@tool
class_name PlantDefinition
extends Resource


@export_group("Identity")
## Stable internal id used by saves, inventory, and lookups.
@export var id := ""
## Human-readable name shown in UI.
@export var display_name := ""
## Optional gameplay tags used by targeting filters.
@export var tags: Array[String] = []

@export_group("Gameplay")
## How many seconds the plant needs to reach maturity.
@export var growth_duration := 10.0
## Income produced after the plant is fully grown.
@export var coins_per_second := 1.0

@export_group("Visual")
## Tint applied on top of the texture. Use white to keep original colors.
@export var display_color := Color(1, 1, 1, 1)
## PNG used for the plant sprite.
@export_file("*.png") var texture_path := ""
## Fine offset from the default bottom-center planting position.
@export var texture_offset := Vector2.ZERO
## Rendered size of the plant sprite inside the plant area.
@export var texture_size := Vector2(160.0, 190.0)

@export_group("Anchors")
## Optional local anchor inside the PlantView used for floating coin feedback.
## Negative values fall back to the auto-derived top-right anchor of the rendered plant.
@export var coin_anchor := Vector2(-1.0, -1.0)
