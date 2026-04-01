class_name GameCatalog
extends Resource


@export_group("Definitions")
@export var room_definition: RoomDefinition
@export var plant_definitions: Array[PlantDefinition] = []
@export var pot_definitions: Array[PotDefinition] = []
@export var aura_definitions: Array[Resource] = []
@export var instant_effect_definitions: Array[Resource] = []
@export var modifier_definitions: Array[Resource] = []
@export var totem_definitions: Array[TotemDefinition] = []
@export var shelf_definitions: Array[ShelfDefinition] = []

@export_group("Presentation")
@export var active_shelf_id := ""
@export var background_color_hex := "#e3efdf"

@export_group("Starting Inventory")
## Starting seed counts keyed by PlantDefinition.id.
@export var starting_seed_inventory: Dictionary = {}
## Starting pot counts keyed by PotDefinition.id.
@export var starting_pot_inventory: Dictionary = {}
## Starting totem counts keyed by TotemDefinition.id.
@export var starting_totem_inventory: Dictionary = {}
## Starting shelf counts keyed by ShelfDefinition.id.
@export var starting_shelf_inventory: Dictionary = {}
