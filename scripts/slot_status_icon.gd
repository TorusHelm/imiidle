@tool
class_name SlotStatusIcon
extends Control


@onready var frame: Panel = $Frame
@onready var icon_texture: TextureRect = $Frame/IconTexture


func _ready() -> void:
	_apply_frame_style()
	clear()


func show_modifier(modifier: Dictionary) -> void:
	visible = true
	tooltip_text = _build_tooltip(modifier)
	frame.tooltip_text = tooltip_text
	icon_texture.tooltip_text = tooltip_text


func clear() -> void:
	visible = false
	tooltip_text = ""
	if is_node_ready():
		frame.tooltip_text = ""
		icon_texture.tooltip_text = ""
		icon_texture.texture = null


func _apply_frame_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.95, 0.84, 0.92)
	style.border_color = Color(0.45, 0.33, 0.18, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	frame.add_theme_stylebox_override("panel", style)


func _build_tooltip(modifier: Dictionary) -> String:
	var modifier_type := String(modifier.get("modifier_type", "modifier"))
	var remaining_duration := float(modifier.get("remaining_duration", 0.0))
	if remaining_duration > 0.0:
		return "%s\nRemaining: %.1fs" % [modifier_type.capitalize(), remaining_duration]
	return modifier_type.capitalize()
