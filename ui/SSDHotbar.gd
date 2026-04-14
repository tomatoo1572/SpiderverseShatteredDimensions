extends CanvasLayer
class_name SSDHotbar

const SSD_HOTBAR_BLOCK_ICON_SCRIPT = preload("res://ui/SSDHotbarBlockIcon.gd")

const SLOT_COUNT: int = 9
const SLOT_SIZE: Vector2 = Vector2(40.0, 40.0)
const SLOT_SPACING: float = 4.0
const ICON_SIZE: Vector2 = Vector2(28.0, 28.0)
const NEED_ICON_SIZE: Vector2 = Vector2(24.0, 24.0)

var _inventory: SSDInventory
var _root_panel: Panel
var _slot_panels: Array[Panel] = []
var _slot_icons: Array[Control] = []
var _slot_number_labels: Array[Label] = []
var _slot_count_labels: Array[Label] = []
var _atlas_texture: Texture2D
var _vitals: SSDVitals
var _inventory_frame_texture: Texture2D
var _slot_normal_texture: Texture2D
var _slot_selected_texture: Texture2D
var _tooltip_panel: Panel
var _tooltip_label: Label
var _hover_slot_index: int = -1

var _hunger_widget: Control
var _thirst_widget: Control
var _break_panel: Panel
var _break_fill: ColorRect
var _break_label: Label

func _ready() -> void:
	layer = 2
	_atlas_texture = load("res://assets/textures/blocks/terrain_atlas.png") as Texture2D
	_inventory_frame_texture = load("res://assets/textures/ui/inventory_frame.png") as Texture2D
	_slot_normal_texture = load("res://assets/textures/ui/slot_normal.png") as Texture2D
	_slot_selected_texture = load("res://assets/textures/ui/slot_selected.png") as Texture2D
	_build_ui_if_needed()
	_refresh_ui()

func set_vitals(vitals: SSDVitals) -> void:
	_vitals = vitals
	_refresh_needs()

func set_break_progress(progress: float, text: String = "", visible_flag: bool = true) -> void:
	if _break_panel == null:
		return
	var clamped: float = clampf(progress, 0.0, 1.0)
	_break_panel.visible = visible_flag and clamped > 0.0
	_break_fill.size.x = 168.0 * clamped
	_break_label.text = text if not text.is_empty() else "%d%%" % int(round(clamped * 100.0))

func _process(_delta: float) -> void:
	_refresh_needs()
	if _tooltip_panel == null:
		return
	if _hover_slot_index < 0 or Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_tooltip_panel.visible = false
		return
	var block_id: int = SSDItemDefs.ITEM_AIR
	if _inventory != null:
		block_id = _inventory.get_slot_block_id(_hover_slot_index)
	_tooltip_panel.visible = block_id != SSDItemDefs.ITEM_AIR
	if _tooltip_panel.visible:
		_tooltip_panel.position = get_viewport().get_mouse_position() + Vector2(-24.0, -42.0)

func set_inventory(inventory: SSDInventory) -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(Callable(self, "_refresh_ui")):
		_inventory.inventory_changed.disconnect(Callable(self, "_refresh_ui"))
	if _inventory != null and _inventory.selected_hotbar_changed.is_connected(Callable(self, "_on_selected_hotbar_changed")):
		_inventory.selected_hotbar_changed.disconnect(Callable(self, "_on_selected_hotbar_changed"))

	_inventory = inventory
	if _inventory != null:
		_inventory.inventory_changed.connect(Callable(self, "_refresh_ui"))
		_inventory.selected_hotbar_changed.connect(Callable(self, "_on_selected_hotbar_changed"))
	_refresh_ui()

func select_index(index: int) -> void:
	if _inventory == null:
		return
	_inventory.set_selected_hotbar_index(index)

func cycle(direction: int) -> void:
	if _inventory == null:
		return
	_inventory.cycle_hotbar(direction)

func get_selected_block_id() -> int:
	if _inventory == null:
		return SSDItemDefs.ITEM_AIR
	return _inventory.get_selected_block_id()

func get_selected_block_name() -> String:
	if _inventory == null:
		return "air"
	return _inventory.get_selected_block_name()

func pick_block_id(block_id: int) -> void:
	if _inventory == null:
		return
	_inventory.pick_block_creative(block_id)

func get_selected_slot_index() -> int:
	if _inventory == null:
		return 0
	return _inventory.get_selected_hotbar_index()

func _on_selected_hotbar_changed(_index: int) -> void:
	_refresh_ui()

func _build_ui_if_needed() -> void:
	if _root_panel != null:
		return

	_root_panel = Panel.new()
	_root_panel.name = "RootPanel"
	_root_panel.anchor_left = 0.5
	_root_panel.anchor_top = 1.0
	_root_panel.anchor_right = 0.5
	_root_panel.anchor_bottom = 1.0
	_root_panel.position = Vector2(-202.0, -58.0)
	_root_panel.size = Vector2(404.0, 48.0)
	_root_panel.add_theme_stylebox_override("panel", _make_root_style())
	add_child(_root_panel)

	for slot_index: int in range(SLOT_COUNT):
		var panel: Panel = Panel.new()
		var captured_slot: int = slot_index
		panel.name = "Slot%d" % (slot_index + 1)
		panel.position = Vector2(4.0 + slot_index * (SLOT_SIZE.x + SLOT_SPACING), 4.0)
		panel.size = SLOT_SIZE
		panel.custom_minimum_size = SLOT_SIZE
		panel.add_theme_stylebox_override("panel", _make_slot_style(false))
		panel.mouse_entered.connect(func() -> void:
			_set_hover_slot(captured_slot)
		)
		panel.mouse_exited.connect(func() -> void:
			if _hover_slot_index == captured_slot:
				_set_hover_slot(-1)
		)
		_root_panel.add_child(panel)
		_slot_panels.append(panel)

		var icon: Control = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as Control
		icon.name = "Icon"
		icon.position = Vector2(5.0, 5.0)
		icon.custom_minimum_size = ICON_SIZE
		icon.size = ICON_SIZE
		panel.add_child(icon)
		_slot_icons.append(icon)

		var number_label: Label = Label.new()
		number_label.name = "Number"
		number_label.text = str(slot_index + 1)
		number_label.position = Vector2(27.0, 1.0)
		number_label.size = Vector2(10.0, 8.0)
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		number_label.add_theme_font_size_override("font_size", 8)
		panel.add_child(number_label)
		_slot_number_labels.append(number_label)

		var count_label: Label = Label.new()
		count_label.name = "Count"
		count_label.position = Vector2(2.0, 26.0)
		count_label.size = Vector2(34.0, 11.0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_font_size_override("font_size", 10)
		panel.add_child(count_label)
		_slot_count_labels.append(count_label)

	_hunger_widget = _create_need_widget(Vector2(-54.0, -14.0), load("res://assets/textures/items/steak.png") as Texture2D)
	_root_panel.add_child(_hunger_widget)
	_thirst_widget = _create_need_widget(Vector2(_root_panel.size.x + 6.0, -14.0), load("res://assets/textures/items/water_bottle.png") as Texture2D)
	_root_panel.add_child(_thirst_widget)

	_break_panel = Panel.new()
	_break_panel.visible = false
	_break_panel.anchor_left = 0.5
	_break_panel.anchor_top = 1.0
	_break_panel.anchor_right = 0.5
	_break_panel.anchor_bottom = 1.0
	_break_panel.position = Vector2(-90.0, -84.0)
	_break_panel.size = Vector2(180.0, 18.0)
	_break_panel.add_theme_stylebox_override("panel", _make_tooltip_style())
	add_child(_break_panel)

	var break_back: ColorRect = ColorRect.new()
	break_back.position = Vector2(6.0, 5.0)
	break_back.size = Vector2(168.0, 8.0)
	break_back.color = Color(0.12, 0.12, 0.12, 0.95)
	_break_panel.add_child(break_back)

	_break_fill = ColorRect.new()
	_break_fill.position = Vector2(6.0, 5.0)
	_break_fill.size = Vector2.ZERO
	_break_fill.color = Color(0.95, 0.95, 0.95, 0.98)
	_break_panel.add_child(_break_fill)

	_break_label = Label.new()
	_break_label.position = Vector2(0.0, -2.0)
	_break_label.size = Vector2(180.0, 18.0)
	_break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_break_label.add_theme_font_size_override("font_size", 10)
	_break_panel.add_child(_break_label)

	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	_tooltip_panel.size = Vector2(132.0, 36.0)
	_tooltip_panel.add_theme_stylebox_override("panel", _make_tooltip_style())
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.offset_left = 6.0
	_tooltip_label.offset_top = 4.0
	_tooltip_label.offset_right = 126.0
	_tooltip_label.offset_bottom = 32.0
	_tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tooltip_label.add_theme_font_size_override("font_size", 11)
	_tooltip_panel.add_child(_tooltip_label)

func _create_need_widget(pos: Vector2, icon_texture: Texture2D) -> Control:
	var root: Control = Control.new()
	root.position = pos
	root.size = Vector2(58.0, 28.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ghost: TextureRect = TextureRect.new()
	ghost.name = "GhostIcon"
	ghost.position = Vector2(0.0, 2.0)
	ghost.size = NEED_ICON_SIZE
	ghost.texture = icon_texture
	ghost.stretch_mode = TextureRect.STRETCH_SCALE
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.18)
	root.add_child(ghost)

	var clip: Control = Control.new()
	clip.name = "Clip"
	clip.position = Vector2(0.0, 2.0)
	clip.size = Vector2(NEED_ICON_SIZE.x, NEED_ICON_SIZE.y)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(clip)

	var fill_icon: TextureRect = TextureRect.new()
	fill_icon.name = "FillIcon"
	fill_icon.position = Vector2.ZERO
	fill_icon.size = NEED_ICON_SIZE
	fill_icon.texture = icon_texture
	fill_icon.stretch_mode = TextureRect.STRETCH_SCALE
	clip.add_child(fill_icon)

	var percent_label: Label = Label.new()
	percent_label.name = "PercentLabel"
	percent_label.position = Vector2(27.0, 4.0)
	percent_label.size = Vector2(30.0, 18.0)
	percent_label.add_theme_font_size_override("font_size", 10)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(percent_label)
	return root

func _refresh_needs() -> void:
	if _vitals == null or _hunger_widget == null or _thirst_widget == null:
		return
	var hunger_ratio: float = 0.0 if _vitals.max_hunger <= 0.0 else (_vitals.current_hunger / _vitals.max_hunger)
	var thirst_ratio: float = 0.0 if _vitals.max_thirst <= 0.0 else (_vitals.current_thirst / _vitals.max_thirst)
	_apply_need_ratio(_hunger_widget, hunger_ratio)
	_apply_need_ratio(_thirst_widget, thirst_ratio)

func _apply_need_ratio(widget: Control, ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	var clip: Control = widget.get_node("Clip") as Control
	var fill_icon: TextureRect = clip.get_node("FillIcon") as TextureRect
	var percent_label: Label = widget.get_node("PercentLabel") as Label
	var fill_height: float = maxf(1.0, floorf(NEED_ICON_SIZE.y * clamped)) if clamped > 0.0 else 0.0
	clip.size = Vector2(NEED_ICON_SIZE.x, fill_height)
	clip.position.y = 8.0 + (NEED_ICON_SIZE.y - fill_height)
	fill_icon.position = Vector2(0.0, -(NEED_ICON_SIZE.y - fill_height))
	percent_label.text = "%d%%" % int(round(clamped * 100.0))

func _refresh_ui() -> void:
	if _slot_panels.is_empty() or _inventory == null:
		return

	var selected_index: int = _inventory.get_selected_hotbar_index()
	for i: int in range(SLOT_COUNT):
		var block_id: int = _inventory.get_slot_block_id(i)
		var count: int = _inventory.get_slot_count_value(i)
		var panel: Panel = _slot_panels[i]
		var icon: SSDHotbarBlockIcon = _slot_icons[i] as SSDHotbarBlockIcon
		var number_label: Label = _slot_number_labels[i]
		var count_label: Label = _slot_count_labels[i]
		var selected: bool = i == selected_index

		panel.position.y = 2.0 if selected else 4.0
		panel.add_theme_stylebox_override("panel", _make_slot_style(selected))
		number_label.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.75, 0.75, 0.75, 0.95)
		count_label.text = str(count) if count > 1 else ""
		count_label.modulate = Color(1.0, 1.0, 1.0, 0.95)

		if icon != null:
			icon.set_atlas_texture(_atlas_texture)
			icon.set_block_id(block_id)
			icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if block_id != SSDItemDefs.ITEM_AIR else Color(1.0, 1.0, 1.0, 0.0)

	_update_tooltip()

func _set_hover_slot(slot_index: int) -> void:
	_hover_slot_index = slot_index
	_update_tooltip()

func _update_tooltip() -> void:
	if _tooltip_panel == null or _tooltip_label == null or _inventory == null:
		return
	if _hover_slot_index < 0 or _hover_slot_index >= SLOT_COUNT:
		_tooltip_panel.visible = false
		return

	var block_id: int = _inventory.get_slot_block_id(_hover_slot_index)
	if block_id == SSDItemDefs.ITEM_AIR:
		_tooltip_panel.visible = false
		return

	_tooltip_label.text = SSDItemDefs.get_display_name(block_id)
	_tooltip_panel.visible = true

func _make_root_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _inventory_frame_texture
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	return style

func _make_slot_style(selected: bool) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _slot_selected_texture if selected else _slot_normal_texture
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	return style

func _make_tooltip_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.03, 0.94)
	style.border_color = Color(0.18, 0.18, 0.18, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style
