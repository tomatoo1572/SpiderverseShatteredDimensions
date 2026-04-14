extends CanvasLayer
class_name SSDInventoryUI

signal request_drop_stack(block_id: int, count: int)

const SSD_HOTBAR_BLOCK_ICON_SCRIPT = preload("res://ui/SSDHotbarBlockIcon.gd")
const SSD_PLAYER_PREVIEW_SCRIPT = preload("res://ui/SSDPlayerPreview.gd")
const SSD_CRAFTING_SCRIPT = preload("res://shared/gameplay/SSDCrafting.gd")

const SLOT_SIZE: Vector2 = Vector2(40.0, 40.0)
const TAB_INVENTORY: int = 0
const TAB_EQUIPMENT: int = 1
const TAB_ATTRIBUTES: int = 2
const TAB_STORY: int = 3

var _inventory: SSDInventory
var _game_mode: SSDGameMode
var _world: SSDWorld
var _furnace_manager: SSDFurnaceManager
var _vitals: SSDVitals

var _dimmer: ColorRect
var _panel: Panel
var _title_label: Label
var _mode_label: Label
var _tab_buttons: Array[Button] = []
var _tab_roots: Array[Control] = []
var _current_tab: int = TAB_INVENTORY

var _inventory_root: Control
var _equipment_root: Control
var _attributes_root: Control
var _story_root: Control
var _preview_widget: SSDPlayerPreview
var _attribute_health_label: Label
var _attribute_stamina_label: Label

var _slot_panels: Array[Panel] = []
var _slot_icons: Array[SSDHotbarBlockIcon] = []
var _slot_count_labels: Array[Label] = []
var _slot_number_labels: Array[Label] = []

var _cursor_panel: Panel
var _cursor_icon: SSDHotbarBlockIcon
var _cursor_count_label: Label
var _tooltip_panel: Panel
var _tooltip_title: Label
var _tooltip_id: Label
var _hover_slot_index: int = -1

var _atlas_texture: Texture2D
var _inventory_frame_texture: Texture2D
var _slot_normal_texture: Texture2D
var _slot_selected_texture: Texture2D
var _tab_normal_texture: Texture2D
var _tab_active_texture: Texture2D
var _tab_arrow_texture: Texture2D
var _creative_panel_texture: Texture2D

var _cursor_block_id: int = SSDItemDefs.ITEM_AIR
var _cursor_count: int = 0

var _creative_header_root: Control
var _creative_panel: Panel
var _creative_left_arrow: Button
var _creative_right_arrow: Button
var _creative_category_label: Label
var _creative_search_input: LineEdit
var _creative_page_label: Label
var _creative_empty_label: Label
var _creative_category_index: int = 0
var _creative_page_index: int = 0
var _creative_slot_panels: Array[Panel] = []
var _creative_slot_icons: Array[SSDHotbarBlockIcon] = []
var _creative_slot_item_ids: PackedInt32Array = PackedInt32Array()

var _craft2_ids: PackedInt32Array = PackedInt32Array()
var _craft2_counts: PackedInt32Array = PackedInt32Array()
var _craft2_slot_panels: Array[Panel] = []
var _craft2_slot_icons: Array[SSDHotbarBlockIcon] = []
var _craft2_slot_counts: Array[Label] = []
var _craft2_result_panel: Panel
var _craft2_result_icon: SSDHotbarBlockIcon
var _craft2_result_count: Label

var _craft3_ids: PackedInt32Array = PackedInt32Array()
var _craft3_counts: PackedInt32Array = PackedInt32Array()
var _craft3_slot_panels: Array[Panel] = []
var _craft3_slot_icons: Array[SSDHotbarBlockIcon] = []
var _craft3_slot_counts: Array[Label] = []
var _craft3_panel: Panel
var _craft3_result_panel: Panel
var _craft3_result_icon: SSDHotbarBlockIcon
var _craft3_result_count: Label

var _furnace_panel: Panel
var _furnace_slot_panels: Array[Panel] = []
var _furnace_slot_icons: Array[SSDHotbarBlockIcon] = []
var _furnace_slot_counts: Array[Label] = []
var _furnace_burn_fill: ColorRect
var _furnace_cook_fill: ColorRect
var _open_furnace_pos: Vector3i = Vector3i.ZERO

var _right_drag_active: bool = false
var _right_drag_targets: Dictionary = {}

func _ready() -> void:
	layer = 3
	_atlas_texture = load("res://assets/textures/blocks/terrain_atlas.png") as Texture2D
	_inventory_frame_texture = load("res://assets/textures/ui/inventory_frame.png") as Texture2D
	_slot_normal_texture = load("res://assets/textures/ui/slot_normal.png") as Texture2D
	_slot_selected_texture = load("res://assets/textures/ui/slot_selected.png") as Texture2D
	_tab_normal_texture = load("res://assets/textures/ui/tab_normal.png") as Texture2D
	_tab_active_texture = load("res://assets/textures/ui/tab_active.png") as Texture2D
	_tab_arrow_texture = load("res://assets/textures/ui/tab_arrow.png") as Texture2D
	_creative_panel_texture = load("res://assets/textures/ui/creative_panel.png") as Texture2D

	_slot_panels.resize(SSDInventory.SLOT_COUNT)
	_slot_icons.resize(SSDInventory.SLOT_COUNT)
	_slot_count_labels.resize(SSDInventory.SLOT_COUNT)
	_slot_number_labels.resize(SSDInventory.SLOT_COUNT)

	_craft2_ids.resize(4)
	_craft2_counts.resize(4)
	_craft3_ids.resize(9)
	_craft3_counts.resize(9)

	visible = false
	_build_ui()
	set_process(true)

func set_inventory(inventory: SSDInventory) -> void:
	if _inventory != null and _inventory.inventory_changed.is_connected(Callable(self, "_refresh_ui")):
		_inventory.inventory_changed.disconnect(Callable(self, "_refresh_ui"))
	_inventory = inventory
	if _inventory != null:
		_inventory.inventory_changed.connect(Callable(self, "_refresh_ui"))
	if _preview_widget != null:
		_preview_widget.set_inventory(_inventory)
	_refresh_ui()

func set_game_mode(game_mode: SSDGameMode) -> void:
	_game_mode = game_mode
	_refresh_ui()

func set_world(world: SSDWorld) -> void:
	_world = world

func set_furnace_manager(furnace_manager: SSDFurnaceManager) -> void:
	_furnace_manager = furnace_manager


func set_vitals(vitals: SSDVitals) -> void:
	_vitals = vitals
	_refresh_ui()


func is_open() -> bool:
	return visible

func is_text_input_focused() -> bool:
	if _creative_search_input != null and _creative_search_input.has_focus():
		return true
	return false

func toggle_open() -> void:
	visible = not visible
	if visible:
		_current_tab = TAB_INVENTORY
		_set_tab(TAB_INVENTORY)
		_refresh_ui()
	else:
		_return_cursor_to_inventory()
		_hide_tooltip()
		_craft3_panel.visible = false

func close() -> void:
	visible = false
	_return_cursor_to_inventory()
	_hide_tooltip()
	_craft3_panel.visible = false
	if _furnace_panel != null:
		_furnace_panel.visible = false

func open_crafting_table() -> void:
	visible = true
	_current_tab = TAB_INVENTORY
	_set_tab(TAB_INVENTORY)
	_craft3_panel.visible = true
	if _furnace_panel != null:
		_furnace_panel.visible = false
	_refresh_ui()

func open_furnace(block_pos: Vector3i) -> void:
	if _furnace_manager == null:
		return
	visible = true
	_current_tab = TAB_INVENTORY
	_set_tab(TAB_INVENTORY)
	_craft3_panel.visible = false
	_open_furnace_pos = block_pos
	if _furnace_panel != null:
		_furnace_panel.visible = true
	_refresh_ui()

func _process(_delta: float) -> void:
	if _furnace_panel != null and _furnace_panel.visible:
		_refresh_furnace_ui()
	if _cursor_panel != null:
		_cursor_panel.visible = visible and _cursor_count > 0 and _cursor_block_id != SSDItemDefs.ITEM_AIR
		if _cursor_panel.visible:
			_cursor_panel.position = get_viewport().get_mouse_position() + Vector2(12.0, 12.0)
	if _tooltip_panel != null:
		_tooltip_panel.visible = _tooltip_panel.visible and visible and not _cursor_panel.visible
		if _tooltip_panel.visible:
			_tooltip_panel.position = get_viewport().get_mouse_position() + Vector2(18.0, -50.0)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and is_text_input_focused():
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
			_right_drag_active = false
			_right_drag_targets.clear()
		if mb.pressed:
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			var inside_main: bool = _panel != null and _panel.get_global_rect().has_point(mouse_pos)
			var inside_craft: bool = _craft3_panel != null and _craft3_panel.visible and _craft3_panel.get_global_rect().has_point(mouse_pos)
			var inside_furnace: bool = _furnace_panel != null and _furnace_panel.visible and _furnace_panel.get_global_rect().has_point(mouse_pos)
			var inside_creative: bool = _creative_panel != null and _creative_panel.visible and _creative_panel.get_global_rect().has_point(mouse_pos)
			if inside_creative:
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
					_creative_page_index = max(0, _creative_page_index - 1)
					_refresh_creative_slots()
					get_viewport().set_input_as_handled()
					return
				elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_creative_page_index += 1
					_refresh_creative_slots()
					get_viewport().set_input_as_handled()
					return
			if not inside_main and not inside_craft and not inside_furnace:
				if mb.button_index == MOUSE_BUTTON_LEFT:
					_drop_cursor_stack(false)
					get_viewport().set_input_as_handled()
				elif mb.button_index == MOUSE_BUTTON_RIGHT:
					_drop_cursor_stack(true)
					get_viewport().set_input_as_handled()

func _build_ui() -> void:
	_dimmer = ColorRect.new()
	_dimmer.anchor_right = 1.0
	_dimmer.anchor_bottom = 1.0
	_dimmer.color = Color(0.0, 0.0, 0.0, 0.22)
	add_child(_dimmer)

	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.position = Vector2(-380.0, -230.0)
	_panel.size = Vector2(760.0, 460.0)
	_panel.add_theme_stylebox_override("panel", _make_root_style())
	add_child(_panel)

	_title_label = Label.new()
	_title_label.text = "Inventory"
	_title_label.position = Vector2(18.0, 14.0)
	_title_label.size = Vector2(220.0, 24.0)
	_title_label.add_theme_font_size_override("font_size", 18)
	_panel.add_child(_title_label)

	_mode_label = Label.new()
	_mode_label.position = Vector2(18.0, 36.0)
	_mode_label.size = Vector2(240.0, 18.0)
	_mode_label.add_theme_font_size_override("font_size", 11)
	_panel.add_child(_mode_label)

	var tab_names: PackedStringArray = ["Inventory", "Equipment", "Attributes", "Story mode"]
	var x_pos: float = 16.0
	for i: int in range(tab_names.size()):
		var button: Button = Button.new()
		button.text = tab_names[i]
		button.position = Vector2(x_pos, 64.0)
		button.size = Vector2(112.0 if i == 0 else 150.0 if i == 1 else 140.0 if i == 2 else 150.0, 32.0)
		button.focus_mode = Control.FOCUS_NONE
		var idx: int = i
		button.pressed.connect(func() -> void:
			_set_tab(idx)
		)
		_panel.add_child(button)
		_tab_buttons.append(button)
		x_pos += button.size.x - 6.0

	_inventory_root = Control.new()
	_inventory_root.position = Vector2(16.0, 110.0)
	_inventory_root.size = Vector2(728.0, 332.0)
	_panel.add_child(_inventory_root)

	_equipment_root = Control.new()
	_equipment_root.position = _inventory_root.position
	_equipment_root.size = _inventory_root.size
	_panel.add_child(_equipment_root)

	_attributes_root = Control.new()
	_attributes_root.position = _inventory_root.position
	_attributes_root.size = _inventory_root.size
	_panel.add_child(_attributes_root)

	_story_root = Control.new()
	_story_root.position = _inventory_root.position
	_story_root.size = _inventory_root.size
	_panel.add_child(_story_root)

	_tab_roots = [_inventory_root, _equipment_root, _attributes_root, _story_root]
	_build_inventory_tab()
	_build_equipment_tab()
	_build_attributes_tab()
	_build_placeholder_tab(_story_root, "Story mode panel coming next.")

	_build_cursor_and_tooltip()
	_build_crafting_table_panel()
	_build_furnace_panel()
	_set_tab(TAB_INVENTORY)

func _build_inventory_tab() -> void:
	_creative_header_root = Control.new()
	_creative_header_root.position = Vector2(8.0, 0.0)
	_creative_header_root.size = Vector2(360.0, 30.0)
	_inventory_root.add_child(_creative_header_root)

	_creative_left_arrow = _make_arrow_button("<", Vector2(0.0, 0.0))
	_creative_left_arrow.pressed.connect(func() -> void:
		_cycle_creative_category(-1)
	)
	_creative_header_root.add_child(_creative_left_arrow)

	_creative_category_label = Label.new()
	_creative_category_label.position = Vector2(44.0, 2.0)
	_creative_category_label.size = Vector2(160.0, 24.0)
	_creative_category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_creative_header_root.add_child(_creative_category_label)

	_creative_right_arrow = _make_arrow_button(">", Vector2(212.0, 0.0))
	_creative_right_arrow.pressed.connect(func() -> void:
		_cycle_creative_category(1)
	)
	_creative_header_root.add_child(_creative_right_arrow)

	_creative_search_input = LineEdit.new()
	_creative_search_input.position = Vector2(256.0, 0.0)
	_creative_search_input.size = Vector2(108.0, 24.0)
	_creative_search_input.placeholder_text = "Search"
	_creative_search_input.text_changed.connect(func(_value: String) -> void:
		_creative_page_index = 0
		_refresh_creative_slots()
	)
	_creative_header_root.add_child(_creative_search_input)

	var page_left: Button = _make_arrow_button("<", Vector2(368.0, 0.0))
	page_left.size = Vector2(20.0, 24.0)
	page_left.pressed.connect(func() -> void:
		_creative_page_index = max(0, _creative_page_index - 1)
		_refresh_creative_slots()
	)
	_creative_header_root.add_child(page_left)

	_creative_page_label = Label.new()
	_creative_page_label.position = Vector2(390.0, 2.0)
	_creative_page_label.size = Vector2(44.0, 20.0)
	_creative_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_creative_header_root.add_child(_creative_page_label)

	var page_right: Button = _make_arrow_button(">", Vector2(436.0, 0.0))
	page_right.size = Vector2(20.0, 24.0)
	page_right.pressed.connect(func() -> void:
		_creative_page_index += 1
		_refresh_creative_slots()
	)
	_creative_header_root.add_child(page_right)

	_creative_panel = Panel.new()
	_creative_panel.position = Vector2(8.0, 30.0)
	_creative_panel.size = Vector2(420.0, 136.0)
	_creative_panel.add_theme_stylebox_override("panel", _make_creative_panel_style())
	_inventory_root.add_child(_creative_panel)

	var creative_index: int = 0
	for row: int in range(2):
		for column: int in range(8):
			var panel: Panel = Panel.new()
			panel.position = Vector2(12.0 + column * 50.0, 14.0 + row * 50.0)
			panel.size = SLOT_SIZE
			panel.add_theme_stylebox_override("panel", _make_slot_style(false))
			_creative_panel.add_child(panel)
			_creative_slot_panels.append(panel)

			var button: Button = Button.new()
			button.flat = true
			button.focus_mode = Control.FOCUS_NONE
			button.set_anchors_preset(Control.PRESET_FULL_RECT)
			var cap_idx: int = creative_index
			button.gui_input.connect(func(event: InputEvent) -> void:
				_on_creative_slot_input(cap_idx, event)
			)
			button.mouse_entered.connect(func() -> void:
				_show_tooltip_for_creative_slot(cap_idx)
			)
			button.mouse_exited.connect(func() -> void:
				_hide_tooltip()
			)
			panel.add_child(button)

			var icon: SSDHotbarBlockIcon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
			icon.position = Vector2(4.0, 4.0)
			icon.size = Vector2(30.0, 30.0)
			icon.custom_minimum_size = Vector2(30.0, 30.0)
			icon.set_atlas_texture(_atlas_texture)
			panel.add_child(icon)
			_creative_slot_icons.append(icon)
			creative_index += 1

	_creative_empty_label = Label.new()
	_creative_empty_label.position = Vector2(12.0, 54.0)
	_creative_empty_label.size = Vector2(240.0, 24.0)
	_creative_empty_label.text = "No items in this category yet."
	_creative_panel.add_child(_creative_empty_label)

	var craft_title: Label = Label.new()
	craft_title.text = "Crafting"
	craft_title.position = Vector2(500.0, 10.0)
	craft_title.size = Vector2(80.0, 20.0)
	_inventory_root.add_child(craft_title)

	for row: int in range(2):
		for column: int in range(2):
			_create_craft_slot(_inventory_root, "2x2", row * 2 + column, Vector2(474.0 + column * 46.0, 34.0 + row * 46.0))

	var arrow_label: Label = Label.new()
	arrow_label.text = ">"
	arrow_label.position = Vector2(570.0, 58.0)
	arrow_label.size = Vector2(20.0, 20.0)
	_inventory_root.add_child(arrow_label)

	_craft2_result_panel = _create_result_slot(_inventory_root, "2x2", Vector2(598.0, 57.0))
	_craft2_result_icon = _craft2_result_panel.get_node("Icon") as SSDHotbarBlockIcon
	_craft2_result_count = _craft2_result_panel.get_node("Count") as Label

	var main_origin: Vector2 = Vector2(18.0, 176.0)
	var main_slot_index: int = SSDInventory.MAIN_SLOT_START
	for row: int in range(3):
		for column: int in range(9):
			_create_inventory_slot(_inventory_root, main_slot_index, main_origin + Vector2(column * 44.0, row * 44.0), false)
			main_slot_index += 1

	var hotbar_origin: Vector2 = Vector2(18.0, 310.0)
	for hotbar_index: int in range(SSDInventory.HOTBAR_COUNT):
		_create_inventory_slot(_inventory_root, hotbar_index, hotbar_origin + Vector2(hotbar_index * 44.0, 0.0), true)

func _build_equipment_tab() -> void:
	var preview_frame: Panel = Panel.new()
	preview_frame.position = Vector2(24.0, 24.0)
	preview_frame.size = Vector2(198.0, 232.0)
	preview_frame.clip_contents = true
	preview_frame.add_theme_stylebox_override("panel", _make_preview_style())
	_equipment_root.add_child(preview_frame)

	_preview_widget = SSD_PLAYER_PREVIEW_SCRIPT.new() as SSDPlayerPreview
	_preview_widget.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_widget.set_rotate_model(false)
	_preview_widget.set_upper_body_only(true)
	_preview_widget.set_yaw_degrees(0.0)
	preview_frame.add_child(_preview_widget)

	var positions: Dictionary = {
		SSDInventory.EQUIPMENT_START_INDEX + 0: Vector2(332.0, 36.0),
		SSDInventory.EQUIPMENT_START_INDEX + 1: Vector2(256.0, 104.0),
		SSDInventory.EQUIPMENT_START_INDEX + 2: Vector2(332.0, 104.0),
		SSDInventory.EQUIPMENT_START_INDEX + 3: Vector2(408.0, 104.0),
		SSDInventory.EQUIPMENT_START_INDEX + 4: Vector2(332.0, 172.0),
		SSDInventory.EQUIPMENT_START_INDEX + 5: Vector2(408.0, 172.0),
		SSDInventory.EQUIPMENT_START_INDEX + 6: Vector2(332.0, 240.0),
	}
	var labels: Dictionary = {
		SSDInventory.EQUIPMENT_START_INDEX + 0: "Head",
		SSDInventory.EQUIPMENT_START_INDEX + 1: "Gloves",
		SSDInventory.EQUIPMENT_START_INDEX + 2: "Shirt",
		SSDInventory.EQUIPMENT_START_INDEX + 3: "Jacket",
		SSDInventory.EQUIPMENT_START_INDEX + 4: "Pants",
		SSDInventory.EQUIPMENT_START_INDEX + 5: "Belt",
		SSDInventory.EQUIPMENT_START_INDEX + 6: "Boots",
	}
	for slot_index: int in positions.keys():
		var slot_pos: Vector2 = positions[slot_index]
		var label: Label = Label.new()
		label.text = labels[slot_index]
		label.position = slot_pos + Vector2(6.0, -18.0)
		label.size = Vector2(76.0, 16.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		_equipment_root.add_child(label)
		_create_inventory_slot(_equipment_root, slot_index, slot_pos, false)

func _build_attributes_tab() -> void:
	var title: Label = Label.new()
	title.text = "Attributes"
	title.position = Vector2(18.0, 18.0)
	title.size = Vector2(180.0, 24.0)
	title.add_theme_font_size_override("font_size", 18)
	_attributes_root.add_child(title)

	_attribute_health_label = Label.new()
	_attribute_health_label.position = Vector2(18.0, 58.0)
	_attribute_health_label.size = Vector2(520.0, 22.0)
	_attributes_root.add_child(_attribute_health_label)

	_attribute_stamina_label = Label.new()
	_attribute_stamina_label.position = Vector2(18.0, 168.0)
	_attribute_stamina_label.size = Vector2(520.0, 22.0)
	_attributes_root.add_child(_attribute_stamina_label)

	var increments: Array[int] = [1, 5, 10, 20, 50, 100, 1000]
	for i: int in range(increments.size()):
		var value: int = increments[i]
		var amount_value: int = value
		var hp_button: Button = Button.new()
		hp_button.text = "+%d" % value
		hp_button.position = Vector2(18.0 + float(i) * 68.0, 92.0)
		hp_button.size = Vector2(60.0, 28.0)
		hp_button.focus_mode = Control.FOCUS_NONE
		hp_button.pressed.connect(func() -> void:
			_upgrade_attribute("health", float(amount_value))
		)
		_attributes_root.add_child(hp_button)

		var st_button: Button = Button.new()
		st_button.text = "+%d" % value
		st_button.position = Vector2(18.0 + float(i) * 68.0, 202.0)
		st_button.size = Vector2(60.0, 28.0)
		st_button.focus_mode = Control.FOCUS_NONE
		st_button.pressed.connect(func() -> void:
			_upgrade_attribute("stamina", float(amount_value))
		)
		_attributes_root.add_child(st_button)

func _upgrade_attribute(attribute_name: String, amount: float) -> void:
	if _vitals == null:
		return
	SSDCore.adjust_current_world_attribute(attribute_name, amount)
	_vitals.apply_profile(SSDCore.get_current_world_profile())
	_refresh_ui()

func _build_placeholder_tab(root: Control, text_value: String) -> void:
	var label: Label = Label.new()
	label.text = text_value
	label.position = Vector2(18.0, 18.0)
	label.size = Vector2(420.0, 24.0)
	root.add_child(label)

func _build_cursor_and_tooltip() -> void:
	_cursor_panel = Panel.new()
	_cursor_panel.size = SLOT_SIZE
	_cursor_panel.add_theme_stylebox_override("panel", _make_slot_style(true))
	add_child(_cursor_panel)

	_cursor_icon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
	_cursor_icon.position = Vector2(4.0, 4.0)
	_cursor_icon.size = Vector2(30.0, 30.0)
	_cursor_icon.custom_minimum_size = Vector2(30.0, 30.0)
	_cursor_icon.set_atlas_texture(_atlas_texture)
	_cursor_panel.add_child(_cursor_icon)

	_cursor_count_label = Label.new()
	_cursor_count_label.position = Vector2(2.0, 26.0)
	_cursor_count_label.size = Vector2(34.0, 10.0)
	_cursor_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cursor_panel.add_child(_cursor_count_label)

	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	_tooltip_panel.size = Vector2(180.0, 46.0)
	_tooltip_panel.add_theme_stylebox_override("panel", _make_tooltip_style())
	add_child(_tooltip_panel)

	_tooltip_title = Label.new()
	_tooltip_title.position = Vector2(6.0, 4.0)
	_tooltip_title.size = Vector2(168.0, 18.0)
	_tooltip_panel.add_child(_tooltip_title)

	_tooltip_id = Label.new()
	_tooltip_id.position = Vector2(6.0, 22.0)
	_tooltip_id.size = Vector2(168.0, 18.0)
	_tooltip_id.add_theme_font_size_override("font_size", 10)
	_tooltip_id.modulate = Color(0.75, 0.75, 0.75, 0.92)
	_tooltip_panel.add_child(_tooltip_id)

func _build_crafting_table_panel() -> void:
	_craft3_panel = Panel.new()
	_craft3_panel.anchor_left = 0.5
	_craft3_panel.anchor_top = 0.5
	_craft3_panel.anchor_right = 0.5
	_craft3_panel.anchor_bottom = 0.5
	_craft3_panel.position = Vector2(-214.0, -170.0)
	_craft3_panel.size = Vector2(428.0, 340.0)
	_craft3_panel.visible = false
	_craft3_panel.add_theme_stylebox_override("panel", _make_root_style())
	add_child(_craft3_panel)

	var title: Label = Label.new()
	title.text = "Crafting Table"
	title.position = Vector2(16.0, 12.0)
	title.size = Vector2(180.0, 22.0)
	_craft3_panel.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(384.0, 10.0)
	close_button.size = Vector2(28.0, 24.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void:
		_craft3_panel.visible = false
	)
	_craft3_panel.add_child(close_button)

	for row: int in range(3):
		for column: int in range(3):
			_create_craft_slot(_craft3_panel, "3x3", row * 3 + column, Vector2(78.0 + column * 46.0, 72.0 + row * 46.0))
	var arrow_label: Label = Label.new()
	arrow_label.text = ">"
	arrow_label.position = Vector2(232.0, 124.0)
	arrow_label.size = Vector2(20.0, 20.0)
	_craft3_panel.add_child(arrow_label)
	_craft3_result_panel = _create_result_slot(_craft3_panel, "3x3", Vector2(268.0, 120.0))
	_craft3_result_icon = _craft3_result_panel.get_node("Icon") as SSDHotbarBlockIcon
	_craft3_result_count = _craft3_result_panel.get_node("Count") as Label

func _create_inventory_slot(parent: Control, slot_index: int, slot_position: Vector2, is_hotbar: bool) -> void:
	var panel: Panel = Panel.new()
	panel.position = slot_position
	panel.size = SLOT_SIZE
	panel.add_theme_stylebox_override("panel", _make_slot_style(false))
	parent.add_child(panel)
	_slot_panels[slot_index] = panel

	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cap_slot: int = slot_index
	button.gui_input.connect(func(event: InputEvent) -> void:
		_on_slot_gui_input(cap_slot, event)
	)
	button.mouse_entered.connect(func() -> void:
		_show_tooltip_for_slot(cap_slot)
		if _right_drag_active:
			_right_drag_place_inventory_slot(cap_slot)
	)
	button.mouse_exited.connect(func() -> void:
		if _hover_slot_index == cap_slot:
			_hide_tooltip()
	)
	panel.add_child(button)

	var icon: SSDHotbarBlockIcon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
	icon.position = Vector2(4.0, 4.0)
	icon.size = Vector2(30.0, 30.0)
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.set_atlas_texture(_atlas_texture)
	panel.add_child(icon)
	_slot_icons[slot_index] = icon

	var count_label: Label = Label.new()
	count_label.position = Vector2(2.0, 26.0)
	count_label.size = Vector2(34.0, 10.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(count_label)
	_slot_count_labels[slot_index] = count_label

	var number_label: Label = Label.new()
	number_label.position = Vector2(26.0, 1.0)
	number_label.size = Vector2(12.0, 10.0)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number_label.add_theme_font_size_override("font_size", 8)
	number_label.text = str(slot_index + 1) if is_hotbar else ""
	panel.add_child(number_label)
	_slot_number_labels[slot_index] = number_label

func _create_craft_slot(parent: Control, grid_name: String, index: int, pos: Vector2) -> void:
	var panel: Panel = Panel.new()
	panel.position = pos
	panel.size = SLOT_SIZE
	panel.add_theme_stylebox_override("panel", _make_slot_style(false))
	parent.add_child(panel)
	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.gui_input.connect(func(event: InputEvent) -> void:
		_on_craft_slot_gui_input(grid_name, index, event)
	)
	button.mouse_entered.connect(func() -> void:
		if _right_drag_active:
			_right_drag_place_craft_slot(grid_name, index)
	)
	panel.add_child(button)
	var icon: SSDHotbarBlockIcon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
	icon.position = Vector2(4.0, 4.0)
	icon.size = Vector2(30.0, 30.0)
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.set_atlas_texture(_atlas_texture)
	panel.add_child(icon)
	var count_label: Label = Label.new()
	count_label.position = Vector2(2.0, 26.0)
	count_label.size = Vector2(34.0, 10.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(count_label)
	if grid_name == "2x2":
		_craft2_slot_panels.append(panel)
		_craft2_slot_icons.append(icon)
		_craft2_slot_counts.append(count_label)
	else:
		_craft3_slot_panels.append(panel)
		_craft3_slot_icons.append(icon)
		_craft3_slot_counts.append(count_label)

func _create_result_slot(parent: Control, grid_name: String, pos: Vector2) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = pos
	panel.size = SLOT_SIZE
	panel.add_theme_stylebox_override("panel", _make_slot_style(true))
	parent.add_child(panel)
	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.gui_input.connect(func(event: InputEvent) -> void:
		_on_craft_result_gui_input(grid_name, event)
	)
	panel.add_child(button)
	var icon: SSDHotbarBlockIcon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
	icon.name = "Icon"
	icon.position = Vector2(4.0, 4.0)
	icon.size = Vector2(30.0, 30.0)
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.set_atlas_texture(_atlas_texture)
	panel.add_child(icon)
	var count_label: Label = Label.new()
	count_label.name = "Count"
	count_label.position = Vector2(2.0, 26.0)
	count_label.size = Vector2(34.0, 10.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(count_label)
	return panel

func _set_tab(index: int) -> void:
	_current_tab = index
	for i: int in range(_tab_roots.size()):
		_tab_roots[i].visible = i == index
	for i: int in range(_tab_buttons.size()):
		var selected: bool = i == index
		_tab_buttons[i].add_theme_stylebox_override("normal", _make_tab_style(selected))
		_tab_buttons[i].add_theme_stylebox_override("hover", _make_tab_style(selected))
		_tab_buttons[i].add_theme_stylebox_override("pressed", _make_tab_style(true))
	_refresh_ui()

func _on_slot_gui_input(slot_index: int, event: InputEvent) -> void:
	if _inventory == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				_inventory.quick_move(slot_index)
				_refresh_ui()
			else:
				_handle_left_click(slot_index)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(slot_index)
			if _cursor_count > 0:
				_right_drag_active = true
				_right_drag_targets.clear()
				_right_drag_targets["inv_%d" % slot_index] = true

func _handle_left_click(slot_index: int) -> void:
	var slot_item_id: int = _inventory.get_slot_block_id(slot_index)
	var slot_count: int = _inventory.get_slot_count_value(slot_index)

	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		_cursor_block_id = slot_item_id
		_cursor_count = slot_count
		_inventory.clear_slot(slot_index)
		_refresh_ui()
		return

	if not _inventory.can_place_item_in_slot(_cursor_block_id, slot_index):
		return

	if slot_count > 0 and slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
		var transfer: int = min(SSDInventory.MAX_STACK - slot_count, _cursor_count)
		_inventory.set_slot(slot_index, slot_item_id, slot_count + transfer)
		_cursor_count -= transfer
		if _cursor_count <= 0:
			_cursor_block_id = SSDItemDefs.ITEM_AIR
			_cursor_count = 0
		_refresh_ui()
		return

	var previous_item_id: int = slot_item_id
	var previous_count: int = slot_count
	_inventory.set_slot(slot_index, _cursor_block_id, _cursor_count)
	_cursor_block_id = previous_item_id
	_cursor_count = previous_count
	if _cursor_count <= 0:
		_cursor_block_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _handle_right_click(slot_index: int) -> void:
	var slot_item_id: int = _inventory.get_slot_block_id(slot_index)
	var slot_count: int = _inventory.get_slot_count_value(slot_index)

	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		var half: Dictionary = _inventory.take_half(slot_index)
		_cursor_block_id = int(half.get("block_id", SSDItemDefs.ITEM_AIR))
		_cursor_count = int(half.get("count", 0))
		_refresh_ui()
		return

	if not _inventory.can_place_item_in_slot(_cursor_block_id, slot_index):
		return

	if slot_count <= 0:
		_inventory.set_slot(slot_index, _cursor_block_id, 1)
		_cursor_count -= 1
	elif slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
		_inventory.set_slot(slot_index, slot_item_id, slot_count + 1)
		_cursor_count -= 1
	else:
		return

	if _cursor_count <= 0:
		_cursor_block_id = SSDItemDefs.ITEM_AIR
		_cursor_count = 0
	_refresh_ui()

func _right_drag_place_inventory_slot(slot_index: int) -> void:
	var key: String = "inv_%d" % slot_index
	if _right_drag_targets.has(key):
		return
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		return
	_right_drag_targets[key] = true
	_handle_right_click(slot_index)

func _on_craft_slot_gui_input(grid_name: String, index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_craft_slot_left_click(grid_name, index)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_craft_slot_right_click(grid_name, index)
			if _cursor_count > 0:
				_right_drag_active = true
				_right_drag_targets.clear()
				_right_drag_targets["%s_%d" % [grid_name, index]] = true

func _right_drag_place_craft_slot(grid_name: String, index: int) -> void:
	var key: String = "%s_%d" % [grid_name, index]
	if _right_drag_targets.has(key):
		return
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		return
	_right_drag_targets[key] = true
	_craft_slot_right_click(grid_name, index)

func _craft_slot_left_click(grid_name: String, index: int) -> void:
	var ids: PackedInt32Array = _craft2_ids if grid_name == "2x2" else _craft3_ids
	var counts: PackedInt32Array = _craft2_counts if grid_name == "2x2" else _craft3_counts
	var slot_item_id: int = ids[index]
	var slot_count: int = counts[index]

	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		_cursor_block_id = slot_item_id
		_cursor_count = slot_count
		ids[index] = SSDItemDefs.ITEM_AIR
		counts[index] = 0
		_refresh_ui()
		return

	if slot_count > 0 and slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
		var transfer: int = min(SSDInventory.MAX_STACK - slot_count, _cursor_count)
		counts[index] += transfer
		_cursor_count -= transfer
		if _cursor_count <= 0:
			_cursor_block_id = SSDItemDefs.ITEM_AIR
			_cursor_count = 0
		_refresh_ui()
		return

	ids[index] = _cursor_block_id
	counts[index] = _cursor_count
	_cursor_block_id = slot_item_id
	_cursor_count = slot_count
	if _cursor_count <= 0:
		_cursor_block_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _craft_slot_right_click(grid_name: String, index: int) -> void:
	var ids: PackedInt32Array = _craft2_ids if grid_name == "2x2" else _craft3_ids
	var counts: PackedInt32Array = _craft2_counts if grid_name == "2x2" else _craft3_counts
	var slot_item_id: int = ids[index]
	var slot_count: int = counts[index]

	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		if slot_count <= 0:
			return
		var take_count: int = int(ceil(float(slot_count) * 0.5))
		_cursor_block_id = slot_item_id
		_cursor_count = take_count
		counts[index] = slot_count - take_count
		if counts[index] <= 0:
			ids[index] = SSDItemDefs.ITEM_AIR
			counts[index] = 0
		_refresh_ui()
		return

	if slot_count <= 0:
		ids[index] = _cursor_block_id
		counts[index] = 1
		_cursor_count -= 1
	elif slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
		counts[index] += 1
		_cursor_count -= 1
	else:
		return

	if _cursor_count <= 0:
		_cursor_block_id = SSDItemDefs.ITEM_AIR
		_cursor_count = 0
	_refresh_ui()

func _on_craft_result_gui_input(grid_name: String, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			_take_craft_result(grid_name)

func _take_craft_result(grid_name: String) -> void:
	var ids: PackedInt32Array = _craft2_ids if grid_name == "2x2" else _craft3_ids
	var counts: PackedInt32Array = _craft2_counts if grid_name == "2x2" else _craft3_counts
	var width: int = 2 if grid_name == "2x2" else 3
	var height: int = width
	var result: Dictionary = SSD_CRAFTING_SCRIPT.compute_result(ids, width, height)
	var item_id: int = int(result.get("item_id", SSDItemDefs.ITEM_AIR))
	var count: int = int(result.get("count", 0))
	if item_id == SSDItemDefs.ITEM_AIR or count <= 0:
		return
	if _cursor_count > 0 and _cursor_block_id != item_id:
		return
	if _cursor_block_id == item_id and _cursor_count + count > SSDInventory.MAX_STACK:
		return
	_cursor_block_id = item_id
	_cursor_count += count
	SSD_CRAFTING_SCRIPT.consume_ingredients(ids, counts, width, height)
	_refresh_ui()

func _drop_cursor_stack(drop_single: bool) -> void:
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		return
	var drop_count: int = 1 if drop_single else _cursor_count
	request_drop_stack.emit(_cursor_block_id, drop_count)
	_cursor_count -= drop_count
	if _cursor_count <= 0:
		_cursor_count = 0
		_cursor_block_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _return_cursor_to_inventory() -> void:
	if _inventory == null:
		return
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		return
	var remaining: int = _inventory.try_return_cursor_stack(_cursor_block_id, _cursor_count)
	_cursor_count = remaining
	if _cursor_count <= 0:
		_cursor_block_id = SSDItemDefs.ITEM_AIR
		_cursor_count = 0
	_refresh_ui()

func _refresh_ui() -> void:
	if _inventory == null or _slot_panels.is_empty():
		return
	_mode_label.text = "Mode: %s" % (_game_mode.get_mode_name().capitalize() if _game_mode != null else "Survival")
	if _attribute_health_label != null and _vitals != null:
		_attribute_health_label.text = "Health: %d / %d   Bonus: +%d" % [roundi(_vitals.health), roundi(_vitals.max_health), roundi(_vitals.get_health_bonus())]
	if _attribute_stamina_label != null and _vitals != null:
		_attribute_stamina_label.text = "Stamina: %d / %d   Bonus: +%d" % [roundi(_vitals.current_stamina), roundi(_vitals.max_stamina), roundi(_vitals.get_stamina_bonus())]
	_refresh_creative_visibility()
	_refresh_creative_slots()

	for i: int in range(SSDInventory.SLOT_COUNT):
		var panel: Panel = _slot_panels[i]
		if panel == null:
			continue
		var item_id: int = _inventory.get_slot_block_id(i)
		var count: int = _inventory.get_slot_count_value(i)
		var selected: bool = _inventory.is_hotbar_slot(i) and i == _inventory.get_selected_hotbar_index()
		panel.add_theme_stylebox_override("panel", _make_slot_style(selected))
		var icon: SSDHotbarBlockIcon = _slot_icons[i]
		if icon != null:
			icon.set_atlas_texture(_atlas_texture)
			icon.set_block_id(item_id)
			icon.modulate = Color(1,1,1,1) if item_id != SSDItemDefs.ITEM_AIR else Color(1,1,1,0)
		if _slot_count_labels[i] != null:
			_slot_count_labels[i].text = str(count) if count > 1 else ""
		if _slot_number_labels[i] != null and _inventory.is_hotbar_slot(i):
			_slot_number_labels[i].text = str(i + 1)

	_refresh_crafting_grid("2x2")
	_refresh_crafting_grid("3x3")
	_refresh_furnace_ui()

	_cursor_icon.set_block_id(_cursor_block_id)
	_cursor_count_label.text = str(_cursor_count) if _cursor_count > 1 else ""

func _refresh_crafting_grid(grid_name: String) -> void:
	var ids: PackedInt32Array = _craft2_ids if grid_name == "2x2" else _craft3_ids
	var counts: PackedInt32Array = _craft2_counts if grid_name == "2x2" else _craft3_counts
	var icons: Array[SSDHotbarBlockIcon] = _craft2_slot_icons if grid_name == "2x2" else _craft3_slot_icons
	var labels: Array[Label] = _craft2_slot_counts if grid_name == "2x2" else _craft3_slot_counts
	for i: int in range(ids.size()):
		icons[i].set_block_id(ids[i])
		icons[i].modulate = Color(1,1,1,1) if ids[i] != SSDItemDefs.ITEM_AIR else Color(1,1,1,0)
		labels[i].text = str(counts[i]) if counts[i] > 1 else ""
	var width: int = 2 if grid_name == "2x2" else 3
	var result: Dictionary = SSD_CRAFTING_SCRIPT.compute_result(ids, width, width)
	var item_id: int = int(result.get("item_id", SSDItemDefs.ITEM_AIR))
	var count: int = int(result.get("count", 0))
	if grid_name == "2x2":
		_craft2_result_icon.set_block_id(item_id)
		_craft2_result_icon.modulate = Color(1,1,1,1) if item_id != SSDItemDefs.ITEM_AIR else Color(1,1,1,0)
		_craft2_result_count.text = str(count) if count > 1 else ""
	else:
		_craft3_result_icon.set_block_id(item_id)
		_craft3_result_icon.modulate = Color(1,1,1,1) if item_id != SSDItemDefs.ITEM_AIR else Color(1,1,1,0)
		_craft3_result_count.text = str(count) if count > 1 else ""

func _refresh_creative_visibility() -> void:
	var show_creative: bool = _current_tab == TAB_INVENTORY and _game_mode != null and _game_mode.is_creative()
	_creative_header_root.visible = show_creative
	_creative_panel.visible = show_creative
	_craft2_result_panel.visible = not show_creative
	for panel in _craft2_slot_panels:
		panel.visible = not show_creative
	if _creative_category_label != null:
		_creative_category_label.text = SSDItemDefs.get_creative_category_name(_creative_category_index)

func _refresh_creative_slots() -> void:
	if _creative_slot_icons.is_empty():
		return
	var filtered: Array[int] = []
	var search_text: String = ""
	if _creative_search_input != null:
		search_text = _creative_search_input.text.strip_edges().to_lower()
	for item_id: int in SSDItemDefs.get_creative_item_ids(_creative_category_index):
		if item_id == SSDItemDefs.ITEM_AIR:
			continue
		if search_text.is_empty():
			filtered.append(item_id)
			continue
		var display_name: String = SSDItemDefs.get_display_name(item_id).to_lower()
		var display_id: String = SSDItemDefs.get_display_id(item_id).to_lower()
		if display_name.contains(search_text) or display_id.contains(search_text):
			filtered.append(item_id)

	var page_size: int = _creative_slot_icons.size()
	var page_count: int = max(1, int(ceil(float(filtered.size()) / float(max(1, page_size)))))
	_creative_page_index = clampi(_creative_page_index, 0, page_count - 1)
	if _creative_page_label != null:
		_creative_page_label.text = "%d/%d" % [_creative_page_index + 1, page_count]

	var page_start: int = _creative_page_index * page_size
	var page_items: Array[int] = []
	for i: int in range(page_start, min(page_start + page_size, filtered.size())):
		page_items.append(filtered[i])
	_creative_slot_item_ids = PackedInt32Array(page_items)

	var has_any: bool = false
	for i: int in range(_creative_slot_icons.size()):
		var item_id: int = SSDItemDefs.ITEM_AIR
		if i < _creative_slot_item_ids.size():
			item_id = _creative_slot_item_ids[i]
			has_any = true
		_creative_slot_panels[i].visible = _creative_panel.visible and item_id != SSDItemDefs.ITEM_AIR
		_creative_slot_icons[i].set_block_id(item_id)
		_creative_slot_icons[i].visible = item_id != SSDItemDefs.ITEM_AIR
	if _creative_empty_label != null:
		_creative_empty_label.text = "No items match this filter." if not search_text.is_empty() else "No items in this category yet."
		_creative_empty_label.visible = _creative_panel.visible and not has_any

func _cycle_creative_category(direction: int) -> void:
	_creative_category_index = posmod(_creative_category_index + direction, SSDItemDefs.CREATIVE_CATEGORY_NAMES.size())
	_creative_page_index = 0
	_refresh_ui()

func _on_creative_slot_input(index: int, event: InputEvent) -> void:
	if _game_mode == null or not _game_mode.is_creative():
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return
		var item_id: int = SSDItemDefs.ITEM_AIR
		if index >= 0 and index < _creative_slot_item_ids.size():
			item_id = _creative_slot_item_ids[index]
		if item_id == SSDItemDefs.ITEM_AIR:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_cursor_block_id = item_id
			_cursor_count = SSDInventory.MAX_STACK if not SSDItemDefs.is_equipment_item(item_id) else 1
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_cursor_block_id = item_id
			_cursor_count = 1
		_refresh_ui()

func _show_tooltip_for_creative_slot(index: int) -> void:
	if index < 0 or index >= _creative_slot_item_ids.size():
		_hide_tooltip()
		return
	var item_id: int = _creative_slot_item_ids[index]
	if item_id == SSDItemDefs.ITEM_AIR:
		_hide_tooltip()
		return
	_tooltip_title.text = SSDItemDefs.get_display_name(item_id)
	_tooltip_id.text = SSDItemDefs.get_display_id(item_id)
	_tooltip_panel.visible = true

func _show_tooltip_for_slot(slot_index: int) -> void:
	_hover_slot_index = slot_index
	if _tooltip_panel == null or _inventory == null:
		return
	if _inventory.is_equipment_slot(slot_index) and _inventory.get_slot_block_id(slot_index) == SSDItemDefs.ITEM_AIR:
		_tooltip_title.text = _inventory.get_equipment_slot_label(slot_index)
		_tooltip_id.text = "Empty slot"
		_tooltip_panel.visible = true
		return
	var item_id: int = _inventory.get_slot_block_id(slot_index)
	if item_id == SSDItemDefs.ITEM_AIR:
		_hide_tooltip()
		return
	_tooltip_title.text = SSDItemDefs.get_display_name(item_id)
	_tooltip_id.text = SSDItemDefs.get_display_id(item_id)
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	_hover_slot_index = -1
	if _tooltip_panel != null:
		_tooltip_panel.visible = false


func _build_furnace_panel() -> void:
	_furnace_panel = Panel.new()
	_furnace_panel.anchor_left = 0.5
	_furnace_panel.anchor_top = 0.5
	_furnace_panel.anchor_right = 0.5
	_furnace_panel.anchor_bottom = 0.5
	_furnace_panel.position = Vector2(-190.0, -120.0)
	_furnace_panel.size = Vector2(380.0, 240.0)
	_furnace_panel.visible = false
	_furnace_panel.add_theme_stylebox_override("panel", _make_root_style())
	add_child(_furnace_panel)

	var title: Label = Label.new()
	title.text = "Furnace"
	title.position = Vector2(16.0, 12.0)
	title.size = Vector2(120.0, 20.0)
	_furnace_panel.add_child(title)

	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(336.0, 10.0)
	close_button.size = Vector2(28.0, 24.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void:
		_furnace_panel.visible = false
	)
	_furnace_panel.add_child(close_button)

	_furnace_slot_panels.clear()
	_furnace_slot_icons.clear()
	_furnace_slot_counts.clear()
	_create_furnace_slot(0, Vector2(62.0, 82.0))
	_create_furnace_slot(1, Vector2(62.0, 144.0))
	_create_furnace_slot(2, Vector2(274.0, 112.0), true)

	var burn_bg: ColorRect = ColorRect.new()
	burn_bg.color = Color(0.14, 0.14, 0.14, 1.0)
	burn_bg.position = Vector2(126.0, 124.0)
	burn_bg.size = Vector2(18.0, 46.0)
	_furnace_panel.add_child(burn_bg)
	_furnace_burn_fill = ColorRect.new()
	_furnace_burn_fill.color = Color(1.0, 0.58, 0.18, 1.0)
	_furnace_burn_fill.position = Vector2(128.0, 166.0)
	_furnace_burn_fill.size = Vector2(14.0, 0.0)
	_furnace_panel.add_child(_furnace_burn_fill)

	var cook_bg: ColorRect = ColorRect.new()
	cook_bg.color = Color(0.14, 0.14, 0.14, 1.0)
	cook_bg.position = Vector2(170.0, 118.0)
	cook_bg.size = Vector2(74.0, 12.0)
	_furnace_panel.add_child(cook_bg)
	_furnace_cook_fill = ColorRect.new()
	_furnace_cook_fill.color = Color(0.96, 0.86, 0.24, 1.0)
	_furnace_cook_fill.position = Vector2(172.0, 120.0)
	_furnace_cook_fill.size = Vector2(0.0, 8.0)
	_furnace_panel.add_child(_furnace_cook_fill)

func _create_furnace_slot(slot_index: int, pos: Vector2, is_output: bool = false) -> void:
	var panel: Panel = Panel.new()
	panel.position = pos
	panel.size = SLOT_SIZE
	panel.add_theme_stylebox_override("panel", _make_slot_style(is_output))
	_furnace_panel.add_child(panel)
	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.gui_input.connect(func(event: InputEvent) -> void:
		_on_furnace_slot_gui_input(slot_index, event)
	)
	panel.add_child(button)
	var icon: SSDHotbarBlockIcon = SSD_HOTBAR_BLOCK_ICON_SCRIPT.new() as SSDHotbarBlockIcon
	icon.position = Vector2(4.0, 4.0)
	icon.size = Vector2(30.0, 30.0)
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.set_atlas_texture(_atlas_texture)
	panel.add_child(icon)
	var count_label: Label = Label.new()
	count_label.position = Vector2(2.0, 26.0)
	count_label.size = Vector2(34.0, 10.0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(count_label)
	_furnace_slot_panels.append(panel)
	_furnace_slot_icons.append(icon)
	_furnace_slot_counts.append(count_label)

func _get_open_furnace_state() -> SSDFurnaceState:
	if _furnace_manager == null:
		return null
	return _furnace_manager.get_state(_open_furnace_pos)

func _on_furnace_slot_gui_input(slot_index: int, event: InputEvent) -> void:
	var state: SSDFurnaceState = _get_open_furnace_state()
	if state == null or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed:
		return
	if slot_index == 2:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_take_furnace_output(false)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_take_furnace_output(true)
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		_furnace_left_click(state, slot_index)
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		_furnace_right_click(state, slot_index)

func _furnace_left_click(state: SSDFurnaceState, slot_index: int) -> void:
	var slot_item_id: int = state.input_item_id if slot_index == 0 else state.fuel_item_id
	var slot_count: int = state.input_count if slot_index == 0 else state.fuel_count
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		_cursor_block_id = slot_item_id
		_cursor_count = slot_count
		if slot_index == 0:
			state.input_item_id = SSDItemDefs.ITEM_AIR
			state.input_count = 0
		else:
			state.fuel_item_id = SSDItemDefs.ITEM_AIR
			state.fuel_count = 0
		_refresh_ui()
		return
	if slot_index == 0 and not state.can_place_input(_cursor_block_id):
		return
	if slot_index == 1 and not state.can_place_fuel(_cursor_block_id):
		return
	if slot_count > 0 and slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
		var transfer: int = min(SSDInventory.MAX_STACK - slot_count, _cursor_count)
		slot_count += transfer
		_cursor_count -= transfer
		if slot_index == 0:
			state.input_item_id = slot_item_id
			state.input_count = slot_count
		else:
			state.fuel_item_id = slot_item_id
			state.fuel_count = slot_count
	else:
		if slot_index == 0:
			state.input_item_id = _cursor_block_id
			state.input_count = _cursor_count
		else:
			state.fuel_item_id = _cursor_block_id
			state.fuel_count = _cursor_count
		_cursor_block_id = slot_item_id
		_cursor_count = slot_count
	if _cursor_count <= 0:
		_cursor_count = 0
		_cursor_block_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _furnace_right_click(state: SSDFurnaceState, slot_index: int) -> void:
	var slot_item_id: int = state.input_item_id if slot_index == 0 else state.fuel_item_id
	var slot_count: int = state.input_count if slot_index == 0 else state.fuel_count
	if _cursor_count <= 0 or _cursor_block_id == SSDItemDefs.ITEM_AIR:
		if slot_count <= 0:
			return
		var take_count: int = int(ceil(float(slot_count) * 0.5))
		_cursor_block_id = slot_item_id
		_cursor_count = take_count
		slot_count -= take_count
		if slot_count <= 0:
			slot_item_id = SSDItemDefs.ITEM_AIR
			slot_count = 0
	else:
		if slot_index == 0 and not state.can_place_input(_cursor_block_id):
			return
		if slot_index == 1 and not state.can_place_fuel(_cursor_block_id):
			return
		if slot_count <= 0:
			slot_item_id = _cursor_block_id
			slot_count = 1
			_cursor_count -= 1
		elif slot_item_id == _cursor_block_id and slot_count < SSDInventory.MAX_STACK:
			slot_count += 1
			_cursor_count -= 1
		else:
			return
	if slot_index == 0:
		state.input_item_id = slot_item_id
		state.input_count = slot_count
	else:
		state.fuel_item_id = slot_item_id
		state.fuel_count = slot_count
	if _cursor_count <= 0:
		_cursor_count = 0
		_cursor_block_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _take_furnace_output(single: bool) -> void:
	var state: SSDFurnaceState = _get_open_furnace_state()
	if state == null or state.output_count <= 0 or state.output_item_id == SSDItemDefs.ITEM_AIR:
		return
	var take_count: int = 1 if single else state.output_count
	if _cursor_count > 0 and _cursor_block_id != state.output_item_id:
		return
	if _cursor_count + take_count > SSDInventory.MAX_STACK:
		return
	_cursor_block_id = state.output_item_id
	_cursor_count += take_count
	state.output_count -= take_count
	if state.output_count <= 0:
		state.output_count = 0
		state.output_item_id = SSDItemDefs.ITEM_AIR
	_refresh_ui()

func _refresh_furnace_ui() -> void:
	if _furnace_panel == null:
		return
	var state: SSDFurnaceState = _get_open_furnace_state()
	if state == null:
		_furnace_panel.visible = false
		return
	var ids: Array[int] = [state.input_item_id, state.fuel_item_id, state.output_item_id]
	var counts: Array[int] = [state.input_count, state.fuel_count, state.output_count]
	for i: int in range(3):
		if i >= _furnace_slot_icons.size():
			continue
		_furnace_slot_icons[i].set_block_id(ids[i])
		_furnace_slot_icons[i].modulate = Color(1, 1, 1, 1) if ids[i] != SSDItemDefs.ITEM_AIR else Color(1, 1, 1, 0)
		_furnace_slot_counts[i].text = str(counts[i]) if counts[i] > 1 else ""
	var burn_ratio: float = 0.0 if state.burn_total <= 0.0 else clampf(state.burn_time / state.burn_total, 0.0, 1.0)
	_furnace_burn_fill.position.y = 166.0 - (42.0 * burn_ratio)
	_furnace_burn_fill.size.y = 42.0 * burn_ratio
	var cook_ratio: float = 0.0 if state.cook_total <= 0.0 else clampf(state.cook_time / state.cook_total, 0.0, 1.0)
	_furnace_cook_fill.size.x = 70.0 * cook_ratio

func _make_root_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _inventory_frame_texture
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	return style

func _make_preview_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _creative_panel_texture
	style.texture_margin_left = 6.0
	style.texture_margin_top = 6.0
	style.texture_margin_right = 6.0
	style.texture_margin_bottom = 6.0
	return style

func _make_slot_style(selected: bool) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _slot_selected_texture if selected else _slot_normal_texture
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	return style

func _make_tab_style(selected: bool) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _tab_active_texture if selected else _tab_normal_texture
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	return style

func _make_creative_panel_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _creative_panel_texture
	style.texture_margin_left = 6.0
	style.texture_margin_top = 6.0
	style.texture_margin_right = 6.0
	style.texture_margin_bottom = 6.0
	return style

func _make_arrow_button(text_value: String, pos: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.position = pos
	button.size = Vector2(36.0, 26.0)
	button.focus_mode = Control.FOCUS_NONE
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = _tab_arrow_texture
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	return button

func _make_tooltip_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.03, 0.95)
	style.border_color = Color(0.18, 0.18, 0.18, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style
