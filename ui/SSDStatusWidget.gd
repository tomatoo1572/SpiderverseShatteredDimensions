extends Control
class_name SSDStatusWidget

var health_ratio: float = 1.0
var stamina_ratio: float = 1.0
var health_text: String = "100 / 100"
var stamina_text: String = "100 / 100"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(520.0, 128.0)
	queue_redraw()

func set_values(new_health_ratio: float, new_stamina_ratio: float, new_health_text: String, new_stamina_text: String) -> void:
	health_ratio = clampf(new_health_ratio, 0.0, 1.0)
	stamina_ratio = clampf(new_stamina_ratio, 0.0, 1.0)
	health_text = new_health_text
	stamina_text = new_stamina_text
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2(64.0, 58.0)
	var outer_radius: float = 47.0
	var inner_radius: float = 38.0

	var mahogany: Color = Color(0.34, 0.16, 0.10, 0.98)
	var navy: Color = Color(0.07, 0.11, 0.22, 0.98)
	var dark_purple: Color = Color(0.20, 0.08, 0.26, 0.98)
	var inner_fill: Color = Color(0.08, 0.10, 0.16, 0.96)
	var dark_gray: Color = Color(0.18, 0.18, 0.18, 0.98)

	_draw_polygon_frame(center, outer_radius, 9, dark_gray, dark_gray, navy)
	_draw_polygon_frame(center, outer_radius - 4.0, 9, mahogany, dark_purple, inner_fill, 2.0)
	_draw_polygon_frame(center, inner_radius, 9, dark_gray, dark_gray, Color(0.09, 0.10, 0.15, 0.96), 2.0)

	var health_rect: Rect2 = Rect2(120.0, 16.0, 284.0, 24.0)
	var stamina_rect: Rect2 = Rect2(120.0, 54.0, 248.0, 20.0)

	_draw_diagonal_bar(
		health_rect,
		health_ratio,
		Color(0.10, 0.10, 0.10, 0.90),
		Color(0.16, 0.16, 0.16, 0.92),
		Color(0.36, 0.04, 0.04, 1.0),
		Color(0.88, 0.08, 0.08, 1.0),
		dark_gray,
		dark_gray,
		20.0
	)
	_draw_diagonal_bar(
		stamina_rect,
		stamina_ratio,
		Color(0.10, 0.10, 0.10, 0.90),
		Color(0.16, 0.16, 0.16, 0.92),
		Color(0.98, 0.66, 0.20, 1.0),
		Color(0.98, 0.88, 0.12, 1.0),
		dark_gray,
		dark_gray,
		16.0
	)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	draw_string(font, Vector2(132.0, 34.0), "HP  %s" % health_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 1.0, 1.0, 0.96))
	draw_string(font, Vector2(132.0, 70.0), "ST  %s" % stamina_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 1.0, 1.0, 0.94))

func _draw_polygon_frame(center: Vector2, radius: float, sides: int, border_a: Color, border_b: Color, fill_color: Color, border_width: float = 3.0) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(sides):
		var angle: float = deg_to_rad((360.0 / float(sides)) * float(i) - 90.0)
		points.append(center + (Vector2(cos(angle), sin(angle)) * radius))

	var fill_colors: PackedColorArray = PackedColorArray()
	for _i: int in range(sides):
		fill_colors.append(fill_color)
	draw_polygon(points, fill_colors)

	var outline_colors: PackedColorArray = PackedColorArray()
	for i: int in range(sides + 1):
		outline_colors.append(border_a if i % 2 == 0 else border_b)

	var outline_points: PackedVector2Array = PackedVector2Array(points)
	outline_points.append(points[0])
	draw_polyline_colors(outline_points, outline_colors, border_width, true)

func _draw_diagonal_bar(
	rect: Rect2,
	ratio: float,
	back_left: Color,
	back_right: Color,
	fill_left: Color,
	fill_right: Color,
	border_left: Color,
	border_right: Color,
	slant: float
) -> void:
	var outer: PackedVector2Array = PackedVector2Array([
		rect.position + Vector2(0.0, 0.0),
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(rect.size.x - slant, rect.size.y),
		rect.position + Vector2(0.0, rect.size.y),
	])
	var outer_colors: PackedColorArray = PackedColorArray([back_left, back_right, back_right, back_left])
	draw_polygon(outer, outer_colors)

	var border_points: PackedVector2Array = PackedVector2Array(outer)
	border_points.append(outer[0])
	draw_polyline_colors(border_points, PackedColorArray([border_left, border_right, border_right, border_left, border_left]), 2.0, true)

	if ratio <= 0.001:
		return

	var inset: float = 3.0
	var inner_pos: Vector2 = rect.position + Vector2(inset, inset)
	var inner_size: Vector2 = rect.size - Vector2(inset * 2.0, inset * 2.0)
	var inner_slant: float = maxf(4.0, slant - inset)
	var fill_width: float = inner_size.x * ratio
	var fill_end: float = inner_pos.x + fill_width
	var min_fill: float = inner_pos.x + 8.0
	fill_end = maxf(fill_end, min_fill)
	fill_end = minf(fill_end, inner_pos.x + inner_size.x)

	var right_trim: float = clampf((fill_end - inner_pos.x) / maxf(0.001, inner_size.x), 0.0, 1.0) * inner_slant
	var fill_points: PackedVector2Array = PackedVector2Array([
		inner_pos,
		Vector2(fill_end, inner_pos.y),
		Vector2(fill_end - right_trim, inner_pos.y + inner_size.y),
		Vector2(inner_pos.x, inner_pos.y + inner_size.y),
	])
	var fill_colors: PackedColorArray = PackedColorArray([fill_left, fill_right, fill_right, fill_left])
	draw_polygon(fill_points, fill_colors)
