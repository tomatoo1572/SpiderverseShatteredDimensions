extends Control
class_name SSDMainMenu

const SETTINGS_PATH: String = "user://ssd_settings.cfg"
const BG_TEXTURE: Texture2D = preload("res://assets/textures/ui/main_menu_bg.png")
const SSD_PLAYER_PREVIEW_SCRIPT = preload("res://ui/SSDPlayerPreview.gd")

const SKIN_SWATCHES: PackedStringArray = [
	"f3d2b5",
	"ddb18f",
	"c99273",
	"aa7658",
	"8f5c45",
	"6b4537",
]

var _nav_panel: Panel
var _content_panel: Panel
var _home_panel: Control
var _singleplayer_panel: Control
var _multiplayer_panel: Control
var _character_panel: Control
var _settings_panel: Control

var _world_list: ItemList
var _world_name_edit: LineEdit
var _world_seed_edit: LineEdit
var _play_button: Button
var _delete_button: Button

var _preview: SSDPlayerPreview
var _body_type_option: OptionButton
var _skin_label: Label

var _fov_slider: HSlider
var _brightness_slider: HSlider
var _vsync_check: CheckBox
var _render_distance_slider: HSlider
var _multiplayer_player_name_edit: LineEdit
var _multiplayer_host_port_edit: LineEdit
var _multiplayer_join_address_edit: LineEdit
var _multiplayer_join_port_edit: LineEdit
var _multiplayer_status_label: Label

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_load_settings_into_controls()
	_refresh_world_list()
	_load_profile_into_controls()
	_refresh_random_seed_field()
	_show_panel(_singleplayer_panel)

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg: TextureRect = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = BG_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.03, 0.06, 0.45)
	add_child(overlay)

	_nav_panel = Panel.new()
	_nav_panel.position = Vector2(44.0, 46.0)
	_nav_panel.size = Vector2(300.0, 808.0)
	_nav_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.05, 0.10, 0.88)))
	add_child(_nav_panel)

	var title: Label = Label.new()
	title.text = "Spiderverse\nShattered Dimensions"
	title.position = Vector2(24.0, 24.0)
	title.size = Vector2(250.0, 90.0)
	title.add_theme_font_size_override("font_size", 28)
	_nav_panel.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Voxel action sandbox foundation"
	subtitle.position = Vector2(26.0, 98.0)
	subtitle.size = Vector2(240.0, 22.0)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.modulate = Color(0.88, 0.90, 0.98, 0.9)
	_nav_panel.add_child(subtitle)

	var button_y: float = 156.0
	_nav_panel.add_child(_make_nav_button("Singleplayer", button_y, func() -> void: _show_panel(_singleplayer_panel)))
	button_y += 50.0
	_nav_panel.add_child(_make_nav_button("Multiplayer", button_y, func() -> void: _show_panel(_multiplayer_panel)))
	button_y += 50.0
	_nav_panel.add_child(_make_nav_button("Settings", button_y, func() -> void: _show_panel(_settings_panel)))
	button_y += 50.0
	_nav_panel.add_child(_make_nav_button("Quit Game", button_y, func() -> void: get_tree().quit()))

	_content_panel = Panel.new()
	_content_panel.position = Vector2(374.0, 46.0)
	_content_panel.size = Vector2(1182.0, 808.0)
	_content_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.04, 0.08, 0.82)))
	add_child(_content_panel)

	_home_panel = Control.new()
	_home_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_panel.add_child(_home_panel)
	_build_home_panel()

	_singleplayer_panel = Control.new()
	_singleplayer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_panel.add_child(_singleplayer_panel)
	_build_singleplayer_panel()

	_multiplayer_panel = Control.new()
	_multiplayer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_panel.add_child(_multiplayer_panel)
	_build_multiplayer_panel()

	_character_panel = Control.new()
	_character_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_panel.add_child(_character_panel)
	_build_character_panel()

	_settings_panel = Control.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_panel.add_child(_settings_panel)
	_build_settings_panel()

	var info: AcceptDialog = AcceptDialog.new()
	info.name = "InfoPopup"
	info.dialog_text = "World action complete."
	add_child(info)

	var confirm_delete: ConfirmationDialog = ConfirmationDialog.new()
	confirm_delete.name = "DeletePopup"
	confirm_delete.dialog_text = "Delete selected world?"
	confirm_delete.confirmed.connect(_confirm_delete_world)
	add_child(confirm_delete)

func _build_home_panel() -> void:
	var title: Label = Label.new()
	title.text = "Singleplayer Hub"
	title.position = Vector2(36.0, 28.0)
	title.size = Vector2(220.0, 32.0)
	title.add_theme_font_size_override("font_size", 26)
	_home_panel.add_child(title)

	var desc: Label = Label.new()
	desc.text = "Create, delete, and launch worlds. Character creation now lives inside the in-game pause menu per world."
	desc.position = Vector2(38.0, 72.0)
	desc.size = Vector2(760.0, 48.0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	_home_panel.add_child(desc)

	var world_name: Label = Label.new()
	world_name.text = "Current World: %s" % SSDCore.get_current_world_name()
	world_name.position = Vector2(40.0, 152.0)
	world_name.size = Vector2(500.0, 24.0)
	world_name.add_theme_font_size_override("font_size", 17)
	_home_panel.add_child(world_name)

	var world_seed: Label = Label.new()
	world_seed.text = "Seed: %d" % SSDCore.get_current_world_seed()
	world_seed.position = Vector2(40.0, 182.0)
	world_seed.size = Vector2(300.0, 22.0)
	world_seed.add_theme_font_size_override("font_size", 15)
	_home_panel.add_child(world_seed)

	var quick_play: Button = Button.new()
	quick_play.text = "Play Current World"
	quick_play.position = Vector2(40.0, 244.0)
	quick_play.size = Vector2(224.0, 40.0)
	quick_play.pressed.connect(func() -> void:
		SSDCore.configure_offline_session()
		SSDCore.go_to_game()
	)
	_home_panel.add_child(quick_play)

func _build_singleplayer_panel() -> void:
	var title: Label = Label.new()
	title.text = "Singleplayer"
	title.position = Vector2(36.0, 28.0)
	title.size = Vector2(240.0, 30.0)
	title.add_theme_font_size_override("font_size", 24)
	_singleplayer_panel.add_child(title)

	_world_list = ItemList.new()
	_world_list.position = Vector2(36.0, 86.0)
	_world_list.size = Vector2(500.0, 540.0)
	_world_list.item_selected.connect(_on_world_selected)
	_singleplayer_panel.add_child(_world_list)

	var name_label: Label = Label.new()
	name_label.text = "World Name"
	name_label.position = Vector2(574.0, 96.0)
	name_label.size = Vector2(180.0, 18.0)
	_singleplayer_panel.add_child(name_label)

	_world_name_edit = LineEdit.new()
	_world_name_edit.position = Vector2(574.0, 118.0)
	_world_name_edit.size = Vector2(280.0, 32.0)
	_world_name_edit.placeholder_text = "Enter world name"
	_singleplayer_panel.add_child(_world_name_edit)

	var seed_label: Label = Label.new()
	seed_label.text = "Seed"
	seed_label.position = Vector2(574.0, 168.0)
	seed_label.size = Vector2(100.0, 18.0)
	_singleplayer_panel.add_child(seed_label)

	_world_seed_edit = LineEdit.new()
	_world_seed_edit.position = Vector2(574.0, 190.0)
	_world_seed_edit.size = Vector2(208.0, 32.0)
	_world_seed_edit.placeholder_text = "Randomized each time"
	_singleplayer_panel.add_child(_world_seed_edit)

	var random_seed_button: Button = Button.new()
	random_seed_button.text = "Randomize"
	random_seed_button.position = Vector2(790.0, 190.0)
	random_seed_button.size = Vector2(104.0, 32.0)
	random_seed_button.pressed.connect(_refresh_random_seed_field)
	_singleplayer_panel.add_child(random_seed_button)

	var create_button: Button = Button.new()
	create_button.text = "Create World"
	create_button.position = Vector2(574.0, 256.0)
	create_button.size = Vector2(180.0, 38.0)
	create_button.pressed.connect(_on_create_world_pressed)
	_singleplayer_panel.add_child(create_button)

	_play_button = Button.new()
	_play_button.text = "Play Selected"
	_play_button.position = Vector2(574.0, 308.0)
	_play_button.size = Vector2(180.0, 38.0)
	_play_button.pressed.connect(_on_play_world_pressed)
	_singleplayer_panel.add_child(_play_button)

	_delete_button = Button.new()
	_delete_button.text = "Delete Selected"
	_delete_button.position = Vector2(574.0, 360.0)
	_delete_button.size = Vector2(180.0, 38.0)
	_delete_button.pressed.connect(_on_delete_world_pressed)
	_singleplayer_panel.add_child(_delete_button)

	var info: Label = Label.new()
	info.text = "Create worlds with randomized seeds like Minecraft, rename them, delete them, and jump back in fast."
	info.position = Vector2(574.0, 426.0)
	info.size = Vector2(420.0, 64.0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	_singleplayer_panel.add_child(info)

func _build_multiplayer_panel() -> void:
	var title: Label = Label.new()
	title.text = "Multiplayer"
	title.position = Vector2(36.0, 28.0)
	title.size = Vector2(220.0, 30.0)
	title.add_theme_font_size_override("font_size", 24)
	_multiplayer_panel.add_child(title)

	var info: Label = Label.new()
	info.text = "Minecraft-style friend test flow: host your current world on your PC, then have your friend join with your Tailscale IP and the same port. The host is the world authority in this build."
	info.position = Vector2(40.0, 80.0)
	info.size = Vector2(900.0, 72.0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 16)
	_multiplayer_panel.add_child(info)

	var player_name_label: Label = Label.new()
	player_name_label.text = "Player Name"
	player_name_label.position = Vector2(40.0, 176.0)
	player_name_label.size = Vector2(160.0, 18.0)
	_multiplayer_panel.add_child(player_name_label)

	_multiplayer_player_name_edit = LineEdit.new()
	_multiplayer_player_name_edit.position = Vector2(40.0, 198.0)
	_multiplayer_player_name_edit.size = Vector2(250.0, 32.0)
	_multiplayer_player_name_edit.placeholder_text = "Player"
	_multiplayer_player_name_edit.text = SSDCore.get_network_player_name()
	_multiplayer_panel.add_child(_multiplayer_player_name_edit)

	var host_frame: Panel = Panel.new()
	host_frame.position = Vector2(40.0, 256.0)
	host_frame.size = Vector2(470.0, 260.0)
	host_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.12, 0.88)))
	_multiplayer_panel.add_child(host_frame)

	var host_title: Label = Label.new()
	host_title.text = "Host Current World"
	host_title.position = Vector2(20.0, 18.0)
	host_title.size = Vector2(220.0, 24.0)
	host_title.add_theme_font_size_override("font_size", 18)
	host_frame.add_child(host_title)

	var host_world_label: Label = Label.new()
	host_world_label.text = "World: %s" % SSDCore.get_current_world_name()
	host_world_label.position = Vector2(20.0, 54.0)
	host_world_label.size = Vector2(420.0, 20.0)
	host_world_label.name = "HostWorldLabel"
	host_frame.add_child(host_world_label)

	var host_port_label: Label = Label.new()
	host_port_label.text = "Port"
	host_port_label.position = Vector2(20.0, 92.0)
	host_port_label.size = Vector2(90.0, 18.0)
	host_frame.add_child(host_port_label)

	_multiplayer_host_port_edit = LineEdit.new()
	_multiplayer_host_port_edit.position = Vector2(20.0, 114.0)
	_multiplayer_host_port_edit.size = Vector2(130.0, 32.0)
	_multiplayer_host_port_edit.text = str(SSDCore.get_network_port())
	_multiplayer_host_port_edit.placeholder_text = "24500"
	host_frame.add_child(_multiplayer_host_port_edit)

	var host_note: Label = Label.new()
	host_note.text = "Start the world here, then give your friend your Tailscale IP and port."
	host_note.position = Vector2(20.0, 160.0)
	host_note.size = Vector2(420.0, 44.0)
	host_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host_frame.add_child(host_note)

	var host_button: Button = Button.new()
	host_button.text = "Host World"
	host_button.position = Vector2(20.0, 212.0)
	host_button.size = Vector2(180.0, 36.0)
	host_button.pressed.connect(_on_host_world_pressed)
	host_frame.add_child(host_button)

	var join_frame: Panel = Panel.new()
	join_frame.position = Vector2(548.0, 256.0)
	join_frame.size = Vector2(500.0, 260.0)
	join_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.12, 0.88)))
	_multiplayer_panel.add_child(join_frame)

	var join_title: Label = Label.new()
	join_title.text = "Join Friend"
	join_title.position = Vector2(20.0, 18.0)
	join_title.size = Vector2(220.0, 24.0)
	join_title.add_theme_font_size_override("font_size", 18)
	join_frame.add_child(join_title)

	var join_ip_label: Label = Label.new()
	join_ip_label.text = "Host IP / Tailscale IP"
	join_ip_label.position = Vector2(20.0, 54.0)
	join_ip_label.size = Vector2(220.0, 18.0)
	join_frame.add_child(join_ip_label)

	_multiplayer_join_address_edit = LineEdit.new()
	_multiplayer_join_address_edit.position = Vector2(20.0, 76.0)
	_multiplayer_join_address_edit.size = Vector2(280.0, 32.0)
	_multiplayer_join_address_edit.placeholder_text = "100.x.x.x"
	_multiplayer_join_address_edit.text = SSDCore.get_network_address() if SSDCore.get_network_mode() == SSDCore.NetworkMode.CLIENT else ""
	join_frame.add_child(_multiplayer_join_address_edit)

	var join_port_label: Label = Label.new()
	join_port_label.text = "Port"
	join_port_label.position = Vector2(320.0, 54.0)
	join_port_label.size = Vector2(80.0, 18.0)
	join_frame.add_child(join_port_label)

	_multiplayer_join_port_edit = LineEdit.new()
	_multiplayer_join_port_edit.position = Vector2(320.0, 76.0)
	_multiplayer_join_port_edit.size = Vector2(120.0, 32.0)
	_multiplayer_join_port_edit.text = str(SSDCore.get_network_port())
	_multiplayer_join_port_edit.placeholder_text = "24500"
	join_frame.add_child(_multiplayer_join_port_edit)

	var join_note: Label = Label.new()
	join_note.text = "Use the exact Tailscale IP your friend sees on their host PC. Both of you should already be connected through Tailscale."
	join_note.position = Vector2(20.0, 126.0)
	join_note.size = Vector2(440.0, 60.0)
	join_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	join_frame.add_child(join_note)

	var join_button: Button = Button.new()
	join_button.text = "Join Server"
	join_button.position = Vector2(20.0, 212.0)
	join_button.size = Vector2(180.0, 36.0)
	join_button.pressed.connect(_on_join_world_pressed)
	join_frame.add_child(join_button)

	_multiplayer_status_label = Label.new()
	_multiplayer_status_label.position = Vector2(40.0, 548.0)
	_multiplayer_status_label.size = Vector2(980.0, 48.0)
	_multiplayer_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_multiplayer_status_label.text = "Select a world in Singleplayer first if you want to host a specific save."
	_multiplayer_panel.add_child(_multiplayer_status_label)

func _build_character_panel() -> void:
	var title: Label = Label.new()
	title.text = "Character Creator"
	title.position = Vector2(36.0, 28.0)
	title.size = Vector2(280.0, 30.0)
	title.add_theme_font_size_override("font_size", 24)
	_character_panel.add_child(title)

	var preview_frame: Panel = Panel.new()
	preview_frame.position = Vector2(44.0, 94.0)
	preview_frame.size = Vector2(260.0, 420.0)
	preview_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.07, 0.12, 0.88)))
	_character_panel.add_child(preview_frame)

	_preview = SSD_PLAYER_PREVIEW_SCRIPT.new()
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_frame.add_child(_preview)

	var body_label: Label = Label.new()
	body_label.text = "Body Type"
	body_label.position = Vector2(350.0, 110.0)
	body_label.size = Vector2(120.0, 18.0)
	_character_panel.add_child(body_label)

	_body_type_option = OptionButton.new()
	_body_type_option.position = Vector2(350.0, 132.0)
	_body_type_option.size = Vector2(180.0, 30.0)
	_body_type_option.add_item("Body 1", 0)
	_body_type_option.add_item("Body 2", 1)
	_body_type_option.add_item("Body 3", 2)
	_body_type_option.add_item("Body 4", 3)
	_body_type_option.item_selected.connect(func(index: int) -> void:
		_preview.set_body_type(_body_type_option.get_item_id(index))
	)
	_character_panel.add_child(_body_type_option)

	var skin_title: Label = Label.new()
	skin_title.text = "Skin Tone"
	skin_title.position = Vector2(350.0, 188.0)
	skin_title.size = Vector2(120.0, 18.0)
	_character_panel.add_child(skin_title)

	_skin_label = Label.new()
	_skin_label.position = Vector2(350.0, 294.0)
	_skin_label.size = Vector2(220.0, 18.0)
	_character_panel.add_child(_skin_label)

	for i: int in range(SKIN_SWATCHES.size()):
		var swatch: Button = Button.new()
		swatch.position = Vector2(350.0 + float(i % 3) * 58.0, 214.0 + floorf(float(i) / 3.0) * 58.0)
		swatch.size = Vector2(44.0, 44.0)
		swatch.text = ""
		swatch.set_meta("skin_hex", SKIN_SWATCHES[i])
		swatch.add_theme_stylebox_override("normal", _make_color_swatch(Color("#" + SKIN_SWATCHES[i])))
		swatch.add_theme_stylebox_override("hover", _make_color_swatch(Color("#" + SKIN_SWATCHES[i])).duplicate())
		swatch.pressed.connect(_on_skin_swatch_pressed.bind(swatch))
		_character_panel.add_child(swatch)

	var clothing_note: Label = Label.new()
	clothing_note.text = "Clothing is equipped in-game through the Shirt and Jacket slots."
	clothing_note.position = Vector2(350.0, 338.0)
	clothing_note.size = Vector2(360.0, 40.0)
	clothing_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_panel.add_child(clothing_note)

	var save_button: Button = Button.new()
	save_button.text = "Save Character"
	save_button.position = Vector2(350.0, 430.0)
	save_button.size = Vector2(190.0, 38.0)
	save_button.pressed.connect(_on_save_profile_pressed)
	_character_panel.add_child(save_button)

func _build_settings_panel() -> void:
	var title: Label = Label.new()
	title.text = "Menu Settings"
	title.position = Vector2(36.0, 28.0)
	title.size = Vector2(260.0, 30.0)
	title.add_theme_font_size_override("font_size", 24)
	_settings_panel.add_child(title)

	_fov_slider = _create_slider_row(_settings_panel, "FOV", Vector2(40.0, 100.0), 50.0, 110.0, 1.0)
	_brightness_slider = _create_slider_row(_settings_panel, "Brightness", Vector2(40.0, 172.0), 0.0, 100.0, 1.0)
	_render_distance_slider = _create_slider_row(_settings_panel, "Render Distance", Vector2(40.0, 244.0), 2.0, 20.0, 1.0)

	_vsync_check = CheckBox.new()
	_vsync_check.text = "Enable VSync"
	_vsync_check.position = Vector2(40.0, 324.0)
	_settings_panel.add_child(_vsync_check)

	var save_button: Button = Button.new()
	save_button.text = "Save Settings"
	save_button.position = Vector2(40.0, 380.0)
	save_button.size = Vector2(180.0, 38.0)
	save_button.pressed.connect(_save_settings_from_controls)
	_settings_panel.add_child(save_button)

func _show_panel(panel_to_show: Control) -> void:
	for panel: Control in [_home_panel, _singleplayer_panel, _multiplayer_panel, _character_panel, _settings_panel]:
		panel.visible = panel == panel_to_show

func _make_nav_button(text_value: String, y_pos: float, pressed_callable: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.position = Vector2(22.0, y_pos)
	button.size = Vector2(252.0, 40.0)
	button.pressed.connect(pressed_callable)
	return button

func _refresh_world_list() -> void:
	if _world_list == null:
		return
	_world_list.clear()
	var worlds: Array[Dictionary] = SSDCore.get_worlds()
	var current_id: String = str(SSDCore.get_current_world().get("id", ""))
	var selected_index: int = 0
	for i: int in range(worlds.size()):
		var entry: Dictionary = worlds[i]
		_world_list.add_item("%s  |  Seed %d" % [str(entry.get("name", "World")), int(entry.get("seed", 0))])
		if str(entry.get("id", "")) == current_id:
			selected_index = i
	if not worlds.is_empty():
		_world_list.select(selected_index)
		_on_world_selected(selected_index)


func _refresh_random_seed_field() -> void:
	if _world_seed_edit == null:
		return
	_world_seed_edit.text = str(SSDCore.generate_random_seed())

func _on_world_selected(index: int) -> void:
	var worlds: Array[Dictionary] = SSDCore.get_worlds()
	if index < 0 or index >= worlds.size():
		return
	var entry: Dictionary = worlds[index]
	_world_name_edit.text = str(entry.get("name", ""))
	_world_seed_edit.text = str(int(entry.get("seed", 0)))
	SSDCore.set_current_world(entry)
	var host_world_label: Label = _multiplayer_panel.get_node_or_null("HostWorldLabel") as Label
	if host_world_label != null:
		host_world_label.text = "World: %s" % SSDCore.get_current_world_name()
	_load_profile_into_controls(SSDCore.get_current_world_profile())

func _on_create_world_pressed() -> void:
	var created: Dictionary = SSDCore.create_world(_world_name_edit.text, _world_seed_edit.text)
	SSDCore.set_current_world(created)
	_refresh_world_list()
	_load_profile_into_controls(SSDCore.get_current_world_profile())
	_refresh_random_seed_field()
	var popup := get_node_or_null("InfoPopup") as AcceptDialog
	if popup != null:
		popup.dialog_text = "Created world: %s" % str(created.get("name", "World"))
		popup.popup_centered()

func _on_delete_world_pressed() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty():
		return
	var popup := get_node_or_null("DeletePopup") as ConfirmationDialog
	if popup != null:
		popup.popup_centered()

func _confirm_delete_world() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty():
		return
	var worlds: Array[Dictionary] = SSDCore.get_worlds()
	var index: int = selected[0]
	if index >= 0 and index < worlds.size():
		SSDCore.delete_world_by_id(str(worlds[index].get("id", "")))
		_refresh_world_list()
		_refresh_random_seed_field()

func _on_play_world_pressed() -> void:
	var selected: PackedInt32Array = _world_list.get_selected_items()
	if selected.is_empty():
		if _world_name_edit.text.strip_edges().is_empty():
			return
		var created: Dictionary = SSDCore.create_world(_world_name_edit.text, _world_seed_edit.text)
		SSDCore.set_current_world(created)
	else:
		var worlds: Array[Dictionary] = SSDCore.get_worlds()
		var index: int = selected[0]
		if index < 0 or index >= worlds.size():
			return
		SSDCore.set_current_world(worlds[index])
	SSDCore.configure_offline_session()
	SSDCore.go_to_game()

func _get_multiplayer_player_name() -> String:
	if _multiplayer_player_name_edit == null:
		return SSDCore.get_network_player_name()
	return _multiplayer_player_name_edit.text.strip_edges()

func _parse_port_from_edit(edit: LineEdit) -> int:
	if edit == null:
		return SSDCore.get_network_port()
	var raw: String = edit.text.strip_edges()
	if raw.is_empty() or not raw.is_valid_int():
		return SSDCore.DEFAULT_SERVER_PORT
	return clampi(int(raw.to_int()), 1024, 65535)

func _on_host_world_pressed() -> void:
	SSDCore.configure_host_session(_get_multiplayer_player_name(), _parse_port_from_edit(_multiplayer_host_port_edit))
	if _multiplayer_status_label != null:
		_multiplayer_status_label.text = "Hosting %s on port %d..." % [SSDCore.get_current_world_name(), SSDCore.get_network_port()]
	SSDCore.go_to_game()

func _on_join_world_pressed() -> void:
	var address: String = ""
	if _multiplayer_join_address_edit != null:
		address = _multiplayer_join_address_edit.text.strip_edges()
	if address.is_empty():
		if _multiplayer_status_label != null:
			_multiplayer_status_label.text = "Enter your friend's Tailscale IP first."
		return
	SSDCore.configure_join_session(address, _get_multiplayer_player_name(), _parse_port_from_edit(_multiplayer_join_port_edit))
	if _multiplayer_status_label != null:
		_multiplayer_status_label.text = "Joining %s:%d..." % [address, SSDCore.get_network_port()]
	SSDCore.go_to_game()

func _load_profile_into_controls(profile: Dictionary = {}) -> void:
	var source_profile: Dictionary = profile if not profile.is_empty() else SSDCore.get_current_world_profile()
	var body_index: int = clampi(int(source_profile.get("body_type_index", 0)), 0, 3)
	_body_type_option.select(body_index)
	_preview.set_body_type(body_index)
	var skin_hex: String = str(source_profile.get("skin_tone", "d3af92"))
	_preview.set_skin_tone(Color("#" + skin_hex))
	_skin_label.text = "Selected: #%s" % skin_hex.to_upper()

func _on_skin_swatch_pressed(button: Button) -> void:
	var skin_hex: String = str(button.get_meta("skin_hex", "d3af92"))
	_preview.set_skin_tone(Color("#" + skin_hex))
	_skin_label.text = "Selected: #%s" % skin_hex.to_upper()

func _on_save_profile_pressed() -> void:
	var selected_skin: String = _skin_label.text.replace("Selected: #", "").strip_edges().to_lower()
	if selected_skin.is_empty():
		selected_skin = "d3af92"
	SSDCore.set_current_world_profile({
		"skin_tone": selected_skin,
		"body_type_index": _body_type_option.get_selected_id(),
	})

func _load_settings_into_controls() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var fov: float = 75.0
	var brightness: float = 50.0
	var render_distance: int = 2
	var vsync_enabled: bool = false
	if cfg.load(SETTINGS_PATH) == OK:
		fov = float(cfg.get_value("video", "fov", fov))
		brightness = float(cfg.get_value("video", "brightness", brightness))
		render_distance = int(cfg.get_value("world", "render_distance", render_distance))
		vsync_enabled = bool(cfg.get_value("video", "vsync", vsync_enabled))
	_fov_slider.value = fov
	_brightness_slider.value = brightness
	_render_distance_slider.value = render_distance
	_vsync_check.button_pressed = vsync_enabled

func _save_settings_from_controls() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("video", "fov", _fov_slider.value)
	cfg.set_value("video", "brightness", _brightness_slider.value)
	cfg.set_value("world", "render_distance", int(round(_render_distance_slider.value)))
	cfg.set_value("video", "vsync", _vsync_check.button_pressed)
	cfg.save(SETTINGS_PATH)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED)

func _create_slider_row(parent_node: Control, label_text: String, position_value: Vector2, min_value: float, max_value: float, step_value: float) -> HSlider:
	var label: Label = Label.new()
	label.text = label_text
	label.position = position_value
	label.size = Vector2(220.0, 18.0)
	parent_node.add_child(label)

	var slider: HSlider = HSlider.new()
	slider.position = position_value + Vector2(0.0, 24.0)
	slider.size = Vector2(320.0, 18.0)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step_value
	parent_node.add_child(slider)
	return slider

func _make_panel_style(color_value: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color_value
	style.border_color = Color(0.18, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _make_color_swatch(color_value: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color_value
	style.border_color = Color(0.18, 0.18, 0.18, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style
