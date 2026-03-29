class_name GameCatalog
extends Resource


@export var plant_definitions: Array[PlantDefinition] = []
@export var pot_definitions: Array[PotDefinition] = []
@export var shelf_definitions: Array[ShelfDefinition] = []
@export var active_shelf_id := ""
@export var background_color_hex := "#e3efdf"
@export var starting_seed_inventory: Dictionary = {}
@export var starting_pot_inventory: Dictionary = {}
@export var starting_shelf_inventory: Dictionary = {}
