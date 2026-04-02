@tool
extends Control


@export var guide_color := Color(1.0, 0.2, 0.2, 0.95):
	set(value):
		guide_color = value
		queue_redraw()

@export_range(1.0, 8.0, 0.5) var line_width := 2.0:
	set(value):
		line_width = maxf(value, 1.0)
		queue_redraw()

@export_range(2.0, 24.0, 1.0) var dash_length := 8.0:
	set(value):
		dash_length = maxf(value, 1.0)
		queue_redraw()

@export_range(1.0, 24.0, 1.0) var gap_length := 5.0:
	set(value):
		gap_length = maxf(value, 0.0)
		queue_redraw()


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not visible:
		return

	var rect := Rect2(Vector2.ZERO, size)
	_draw_dashed_rect(rect, guide_color, line_width, dash_length, gap_length)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash: float, gap: float) -> void:
	_draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), color, width, dash, gap)
	_draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, color, width, dash, gap)
	_draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), color, width, dash, gap)
	_draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, color, width, dash, gap)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var segment := to - from
	var total_length := segment.length()
	if total_length <= 0.0:
		return

	var direction := segment / total_length
	var distance := 0.0
	while distance < total_length:
		var dash_start := from + direction * distance
		var dash_end := from + direction * minf(distance + dash, total_length)
		draw_line(dash_start, dash_end, color, width)
		distance += dash + gap
