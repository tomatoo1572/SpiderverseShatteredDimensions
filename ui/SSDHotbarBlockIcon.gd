extends Control
class_name SSDHotbarBlockIcon

var _atlas_texture: Texture2D
var _block_id: int = SSDVoxelDefs.BlockId.AIR

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_atlas_texture(texture: Texture2D) -> void:
	_atlas_texture = texture
	queue_redraw()

func set_block_id(block_id: int) -> void:
	_block_id = block_id
	queue_redraw()

func _draw() -> void:
	if _block_id == SSDItemDefs.ITEM_AIR:
		return

	var custom_texture: Texture2D = SSDItemDefs.get_inventory_icon_texture(_block_id)
	if custom_texture != null:
		var icon_rect: Rect2 = Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0))
		draw_texture_rect(custom_texture, icon_rect, false)
		draw_rect(icon_rect, Color(0.03, 0.03, 0.03, 0.85), false, 1.0)
		return

	if _atlas_texture == null:
		return

	var icon_size: float = minf(size.x, size.y) - 2.0
	icon_size = minf(icon_size, 30.0)
	var body_width: float = floorf(icon_size * 0.56)
	var body_height: float = floorf(icon_size * 0.56)
	var side_width: float = floorf(icon_size * 0.22)
	var top_height: float = floorf(icon_size * 0.18)
	var total_width: float = body_width + side_width
	var total_height: float = body_height + top_height
	var origin: Vector2 = Vector2(
		floorf((size.x - total_width) * 0.5),
		floorf((size.y - total_height) * 0.5) + 1.0
	)

	var front_tl: Vector2 = origin + Vector2(side_width, top_height)
	var front_tr: Vector2 = front_tl + Vector2(body_width, 0.0)
	var front_br: Vector2 = front_tr + Vector2(0.0, body_height)
	var front_bl: Vector2 = front_tl + Vector2(0.0, body_height)

	var top_bl: Vector2 = front_tl
	var top_br: Vector2 = front_tr
	var top_tr: Vector2 = origin + Vector2(total_width, 0.0)
	var top_tl: Vector2 = origin + Vector2(side_width, 0.0)

	var side_tl: Vector2 = front_tr
	var side_tr: Vector2 = top_tr
	var side_br: Vector2 = top_tr + Vector2(0.0, body_height)
	var side_bl: Vector2 = front_br

	var front_points: PackedVector2Array = PackedVector2Array([front_tl, front_tr, front_br, front_bl])
	var top_points: PackedVector2Array = PackedVector2Array([top_tl, top_tr, top_br, top_bl])
	var side_points: PackedVector2Array = PackedVector2Array([side_tl, side_tr, side_br, side_bl])

	_draw_face(front_points, SSDVoxelDefs.get_face_region_pixels(_block_id, 4), Color(1.0, 1.0, 1.0, 1.0))
	_draw_face(side_points, SSDVoxelDefs.get_face_region_pixels(_block_id, 0), Color(0.82, 0.82, 0.82, 1.0))
	_draw_face(top_points, SSDVoxelDefs.get_face_region_pixels(_block_id, 2), Color(1.08, 1.08, 1.08, 1.0))

	_draw_outline(top_points)
	_draw_outline(side_points)
	_draw_outline(front_points)

func _draw_face(points: PackedVector2Array, region: Rect2, tint: Color) -> void:
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return

	var colors: PackedColorArray = PackedColorArray([tint, tint, tint, tint])
	var uvs: PackedVector2Array = PackedVector2Array([
		Vector2(region.position.x, region.position.y),
		Vector2(region.position.x + region.size.x, region.position.y),
		Vector2(region.position.x + region.size.x, region.position.y + region.size.y),
		Vector2(region.position.x, region.position.y + region.size.y),
	])
	draw_polygon(points, colors, uvs, _atlas_texture)

func _draw_outline(points: PackedVector2Array) -> void:
	var outline: PackedVector2Array = PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(0.02, 0.02, 0.02, 1.0), 1.35, true)
