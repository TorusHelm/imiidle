class_name PotDefinition
extends Resource


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
