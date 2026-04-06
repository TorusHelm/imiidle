@tool
class_name SlotStatusIcon
extends Control


@onready var frame: Panel = $Frame
@onready var icon_texture: TextureRect = $Frame/IconTexture


func _ready() -> void:
	clear()


func show_modifier(modifier: Variant) -> void:
	var effect_snapshot := _to_snapshot(modifier)
	if effect_snapshot.is_empty():
		clear()
		return
	visible = true
	modulate = Color.WHITE
	tooltip_text = _build_tooltip(effect_snapshot)
	frame.tooltip_text = tooltip_text
	icon_texture.tooltip_text = tooltip_text
	var icon_path := String(effect_snapshot.get("icon_path", ""))
	icon_texture.texture = load(icon_path) if not icon_path.is_empty() else null


func clear() -> void:
	visible = false
	modulate = Color.WHITE
	tooltip_text = ""
	if is_node_ready():
		frame.tooltip_text = ""
		icon_texture.tooltip_text = ""
		icon_texture.texture = null


func show_placeholder() -> void:
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.45)
	tooltip_text = "Status slot preview"
	if is_node_ready():
		frame.tooltip_text = tooltip_text
		icon_texture.tooltip_text = tooltip_text
		icon_texture.texture = null

func _build_tooltip(modifier: Dictionary) -> String:
	var effect_type := String(modifier.get("modifier_type", modifier.get("aura_type", "effect")))
	var display_name := String(modifier.get("display_name", effect_type.capitalize()))
	var remaining_duration := float(modifier.get("remaining_duration", 0.0))
	if remaining_duration > 0.0:
		return "%s\nRemaining: %.1fs" % [display_name, remaining_duration]
	return display_name


func _to_snapshot(modifier: Variant) -> Dictionary:
	if modifier is Object and modifier.has_method("to_snapshot"):
		return modifier.to_snapshot()
	if modifier is Dictionary:
		return (modifier as Dictionary).duplicate(true)
	return {}
