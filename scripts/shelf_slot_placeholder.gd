extends Control


@export var border_color := Color(0.3, 0.42, 0.36, 0.9)
@export var dash_length := 14.0
@export var gap_length := 8.0
@export var line_width := 3.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0.0))
	_draw_dashed_line(rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size)
	_draw_dashed_line(rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y))
	_draw_dashed_line(rect.position + Vector2(0.0, rect.size.y), rect.position)


func _draw_dashed_line(start: Vector2, end: Vector2) -> void:
	var distance := start.distance_to(end)
	if distance <= 0.0:
		return

	var direction := (end - start).normalized()
	var progress := 0.0

	while progress < distance:
		var dash_end: float = minf(progress + dash_length, distance)
		draw_line(
			start + direction * progress,
			start + direction * dash_end,
			border_color,
			line_width
		)
		progress += dash_length + gap_length
