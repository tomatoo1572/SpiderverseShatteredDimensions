extends CanvasLayer
class_name SSDProximityChat

signal chat_submitted(message: String, sender_position: Vector3)

const CHAT_RADIUS_BLOCKS: float = 20.0
const MAX_LINES: int = 80

var _player: Node3D
var _history_panel: Panel
var _history_label: RichTextLabel
var _input_panel: Panel
var _input_label: Label
var _input_line: LineEdit
var _lines: Array[String] = []

func _ready() -> void:
	layer = 6
	_build_ui()

func set_player(player: Node3D) -> void:
	_player = player

func is_open() -> bool:
	return _input_panel != null and _input_panel.visible

func open_chat() -> void:
	if _input_panel == null:
		return
	_input_panel.visible = true
	_input_line.editable = true
	_input_line.text = ""
	_input_line.grab_focus()
	_input_line.caret_column = 0

func close_chat() -> void:
	if _input_panel == null:
		return
	_input_line.text = ""
	_input_panel.visible = false
	_input_line.release_focus()

func add_system_message(text: String) -> void:
	_append_line("[color=#b0c4de][System][/color] %s" % text)

func receive_message(sender_name: String, text: String, sender_position: Vector3, listener_position: Vector3) -> void:
	if sender_name != "System":
		if sender_position.distance_to(listener_position) > CHAT_RADIUS_BLOCKS:
			return
	var speaker: String = sender_name
	var safe_text: String = text.replace("[", "\\[")
	_append_line("[color=#d8d8d8]<%s>[/color] %s" % [speaker, safe_text])

func _build_ui() -> void:
	_history_panel = Panel.new()
	_history_panel.anchor_left = 0.0
	_history_panel.anchor_top = 1.0
	_history_panel.anchor_right = 0.0
	_history_panel.anchor_bottom = 1.0
	_history_panel.offset_left = 12.0
	_history_panel.offset_top = -196.0
	_history_panel.offset_right = 420.0
	_history_panel.offset_bottom = -52.0
	_history_panel.clip_contents = true
	_history_panel.add_theme_stylebox_override("panel", _make_panel_style(0.20))
	add_child(_history_panel)

	_history_label = RichTextLabel.new()
	_history_label.bbcode_enabled = true
	_history_label.scroll_active = true
	_history_label.scroll_following = true
	_history_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_history_label.fit_content = false
	_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history_label.anchor_right = 1.0
	_history_label.anchor_bottom = 1.0
	_history_label.offset_left = 8.0
	_history_label.offset_top = 6.0
	_history_label.offset_right = -8.0
	_history_label.offset_bottom = -6.0
	_history_label.add_theme_font_size_override("normal_font_size", 14)
	_history_panel.add_child(_history_label)

	_input_panel = Panel.new()
	_input_panel.anchor_left = 0.0
	_input_panel.anchor_top = 1.0
	_input_panel.anchor_right = 0.0
	_input_panel.anchor_bottom = 1.0
	_input_panel.offset_left = 12.0
	_input_panel.offset_top = -44.0
	_input_panel.offset_right = 420.0
	_input_panel.offset_bottom = -12.0
	_input_panel.clip_contents = true
	_input_panel.add_theme_stylebox_override("panel", _make_panel_style(0.85))
	_input_panel.visible = false
	add_child(_input_panel)

	_input_label = Label.new()
	_input_label.text = ">"
	_input_label.position = Vector2(10.0, 6.0)
	_input_label.size = Vector2(12.0, 20.0)
	_input_panel.add_child(_input_label)

	_input_line = LineEdit.new()
	_input_line.position = Vector2(24.0, 4.0)
	_input_line.size = Vector2(384.0, 24.0)
	_input_line.max_length = 160
	_input_line.text_submitted.connect(_on_text_submitted)
	_input_panel.add_child(_input_line)


func _unhandled_input(event: InputEvent) -> void:
	if _history_label == null:
		return
	var vbar: VScrollBar = _history_label.get_v_scroll_bar()
	if vbar == null:
		return
	var handled: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			var hovering_history: bool = _history_panel != null and _history_panel.get_global_rect().has_point(mouse_pos)
			if hovering_history or is_open():
				if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
					vbar.value = max(vbar.min_value, vbar.value - 48.0)
					handled = true
				elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					vbar.value = min(vbar.max_value, vbar.value + 48.0)
					handled = true
	if event.is_action_pressed("ui_page_up"):
		vbar.value = max(vbar.min_value, vbar.value - 96.0)
		handled = true
	elif event.is_action_pressed("ui_page_down"):
		vbar.value = min(vbar.max_value, vbar.value + 96.0)
		handled = true
	if handled:
		get_viewport().set_input_as_handled()

func _on_text_submitted(text: String) -> void:
	var trimmed: String = text.strip_edges()
	if trimmed.is_empty():
		close_chat()
		return
	var sender_pos: Vector3 = Vector3.ZERO
	if _player != null:
		sender_pos = _player.global_position
	chat_submitted.emit(trimmed, sender_pos)
	close_chat()

func _append_line(bbcode_text: String) -> void:
	_lines.append(bbcode_text)
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_history_label.clear()
	for line: String in _lines:
		_history_label.append_text(line + "\n")
	_history_label.scroll_to_line(max(0, _history_label.get_line_count() - 1))

func _make_panel_style(alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, alpha)
	style.border_color = Color(0.22, 0.22, 0.22, min(1.0, alpha + 0.35))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style
