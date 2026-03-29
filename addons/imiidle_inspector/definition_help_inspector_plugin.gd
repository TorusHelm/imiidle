@tool
extends EditorInspectorPlugin


const HELP_BY_CLASS := {
	"PlantDefinition": {
		"id": "Stable internal id used by saves, inventory, and lookups.",
		"display_name": "Human-readable name shown in UI.",
		"growth_duration": "How many seconds the plant needs to reach maturity.",
		"coins_per_second": "Income produced after the plant is fully grown.",
		"display_color": "Tint applied on top of the texture. Use white to keep original colors.",
		"texture_path": "PNG used for the plant sprite.",
		"texture_offset": "Fine offset from the default bottom-center planting position.",
		"texture_size": "Rendered size of the plant sprite inside the plant area."
	},
	"PotDefinition": {
		"id": "Stable internal id used by saves, inventory, and lookups.",
		"display_name": "Human-readable name shown in UI.",
		"texture_path": "PNG used for the pot sprite.",
		"view_size": "Overall size of the whole pot widget.",
		"pot_texture_position": "Top-left position of the pot sprite inside the pot widget.",
		"pot_texture_size": "Rendered size of the pot sprite.",
		"plant_view_position": "Extra local offset for the plant area after anchor placement from attach point.",
		"plant_view_size": "Size of the area reserved for the plant sprite.",
		"plant_attach_point": "Anchor point where the plant grows from. Plant area is built from this point.",
		"seed_button_position": "Top-left position of the seed button.",
		"seed_button_size": "Size of the seed button.",
		"slot_button_position": "Top-left position of the empty-slot button.",
		"slot_button_size": "Size of the empty-slot button.",
		"slot_label_position": "Top-left position of the empty-slot label.",
		"slot_label_size": "Size of the empty-slot label.",
		"pot_baseline": "Bottom anchor used to place the pot onto a shelf slot."
	},
	"ShelfDefinition": {
		"id": "Stable internal id used by catalogs and lookups.",
		"display_name": "Human-readable shelf name shown in UI.",
		"texture_path": "PNG used for the shelf sprite.",
		"view_size": "Overall size of the whole shelf widget.",
		"texture_position": "Top-left position of the shelf sprite inside the shelf widget.",
		"texture_size": "Rendered size of the shelf sprite.",
		"title_position": "Top-left position of the title label.",
		"title_size": "Size of the title label area.",
		"slot_positions": "Anchor points on the shelf where pot baselines are placed."
	}
}


func _can_handle(object: Object) -> bool:
	return object is PlantDefinition or object is PotDefinition or object is ShelfDefinition


func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, usage_flags: int, _wide: bool) -> bool:
	if (usage_flags & PROPERTY_USAGE_EDITOR) == 0:
		return false

	var class_key := ""
	if object is PlantDefinition:
		class_key = "PlantDefinition"
	elif object is PotDefinition:
		class_key = "PotDefinition"
	elif object is ShelfDefinition:
		class_key = "ShelfDefinition"

	var help_map: Dictionary = HELP_BY_CLASS.get(class_key, {})
	if not help_map.has(name):
		return false

	var help_text := String(help_map[name])
	var panel := PanelContainer.new()
	panel.tooltip_text = help_text
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var label := Label.new()
	label.text = "Hint: %s" % help_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.tooltip_text = help_text
	label.mouse_default_cursor_shape = Control.CURSOR_HELP

	panel.add_theme_constant_override("margin_left", 8)
	panel.add_theme_constant_override("margin_top", 2)
	panel.add_theme_constant_override("margin_right", 8)
	panel.add_theme_constant_override("margin_bottom", 4)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)
	add_custom_control(panel)
	return false
