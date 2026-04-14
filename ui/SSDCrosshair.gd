extends Control
class_name SSDCrosshair

const CROSSHAIR_TEXTURE: Texture2D = preload("res://assets/textures/ui/crosshair_caret.png")

@export var draw_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	var tex_size: Vector2 = Vector2(16.0, 16.0)
	if CROSSHAIR_TEXTURE != null:
		tex_size = CROSSHAIR_TEXTURE.get_size() * draw_scale
	offset_left = -tex_size.x * 0.5
	offset_top = -tex_size.y * 0.5
	offset_right = tex_size.x * 0.5
	offset_bottom = tex_size.y * 0.5
	queue_redraw()

func _draw() -> void:
	if CROSSHAIR_TEXTURE == null:
		return
	draw_texture_rect(CROSSHAIR_TEXTURE, Rect2(Vector2.ZERO, size), false)
