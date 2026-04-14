
extends CanvasLayer
class_name SSDSettingsMenu

signal menu_closed

const SETTINGS_PATH: String = "user://ssd_settings.cfg"

var _player: SSDFlyPlayer
var _camera: Camera3D
var _world: SSDWorld
var _game_mode: SSDGameMode
var _day_night: SSDDayNightCycle

var _dimmer: ColorRect
var _panel: Panel
var _page_options: Control
var _page_character: Control
var _page_controls: Control
var _preview: SSDPlayerPreview
var _body_option: OptionButton
var _skin_label: Label

var _fov_slider: HSlider
var _fov_value: Label
var _sense_slider: HSlider
var _sense_value: Label
var _render_slider: HSlider
var _render_value: Label
var _brightness_slider: HSlider
var _brightness_value: Label
var _vsync_check: CheckBox
var _block_break_check: CheckBox
var _mode_option: OptionButton
var _control_buttons: Dictionary = {}
var _waiting_rebind_action: String = ""

var _stored_fov: float = 75.0
var _stored_sensitivity: float = 19.5
var _stored_render_distance: int = 2
var _stored_brightness: float = 50.0
var _stored_vsync: bool = false
var _stored_mode: String = "survival"
var _stored_block_breaking: bool = true
var _profile: Dictionary = {"skin_tone":"d3af92","body_type_index":0}

const SKIN_SWATCHES: PackedStringArray = ["f3d2b5","ddb18f","c99273","aa7658","8f5c45","6b4537"]

func _ready() -> void:
    layer = 4
    visible = false
    _load_settings()
    _build_ui()

func set_targets(player: SSDFlyPlayer, camera: Camera3D, world: SSDWorld, game_mode: SSDGameMode, day_night: SSDDayNightCycle = null) -> void:
    _player = player
    _camera = camera
    _world = world
    _game_mode = game_mode
    _day_night = day_night
    if _game_mode != null:
        _game_mode.mode_changed.connect(func(_mode: int, mode_name: String) -> void:
            _stored_mode = mode_name
            _sync_from_targets()
            _save_settings()
        )
        _game_mode.set_mode_by_name(_stored_mode)
    _apply_settings_to_targets()
    _profile = SSDCore.get_current_world_profile()
    _sync_from_targets()
    _load_profile_controls()

func is_open() -> bool:
    return visible

func toggle_open() -> void:
    visible = not visible
    if visible:
        _sync_from_targets()
        _profile = SSDCore.get_current_world_profile()
        _load_profile_controls()
        _show_page(_page_options)

func close() -> void:
    visible = false
    menu_closed.emit()

func _build_ui() -> void:
    _dimmer = ColorRect.new()
    _dimmer.anchor_right = 1.0
    _dimmer.anchor_bottom = 1.0
    _dimmer.color = Color(0.0, 0.0, 0.0, 0.30)
    add_child(_dimmer)

    _panel = Panel.new()
    _panel.anchor_left = 0.5
    _panel.anchor_top = 0.5
    _panel.anchor_right = 0.5
    _panel.anchor_bottom = 0.5
    _panel.position = Vector2(-260.0, -220.0)
    _panel.size = Vector2(520.0, 440.0)
    _panel.add_theme_stylebox_override("panel", _make_panel_style())
    add_child(_panel)

    var title: Label = Label.new()
    title.text = "Game Menu"
    title.position = Vector2(16.0, 12.0)
    title.size = Vector2(180.0, 24.0)
    title.add_theme_font_size_override("font_size", 18)
    _panel.add_child(title)

    var resume_button := _make_menu_button("Resume", Vector2(16.0, 48.0), func() -> void: close())
    _panel.add_child(resume_button)
    var save_button := _make_menu_button("Save World", Vector2(16.0, 88.0), _save_world)
    _panel.add_child(save_button)
    var char_button := _make_menu_button("Character", Vector2(16.0, 128.0), func() -> void: _show_page(_page_character))
    _panel.add_child(char_button)
    var options_button := _make_menu_button("Options", Vector2(16.0, 168.0), func() -> void: _show_page(_page_options))
    _panel.add_child(options_button)
    var controls_button := _make_menu_button("Controls", Vector2(16.0, 208.0), func() -> void: _show_page(_page_controls))
    _panel.add_child(controls_button)
    var save_quit_button := _make_menu_button("Save & Quit to Title", Vector2(16.0, 248.0), _save_and_quit)
    _panel.add_child(save_quit_button)

    _page_options = Control.new()
    _page_options.position = Vector2(164.0, 44.0)
    _page_options.size = Vector2(336.0, 380.0)
    _panel.add_child(_page_options)
    _build_options_page()

    _page_character = Control.new()
    _page_character.position = Vector2(164.0, 44.0)
    _page_character.size = Vector2(336.0, 380.0)
    _panel.add_child(_page_character)
    _build_character_page()

    _page_controls = Control.new()
    _page_controls.position = Vector2(164.0, 44.0)
    _page_controls.size = Vector2(336.0, 380.0)
    _panel.add_child(_page_controls)
    _build_controls_page()

func _build_options_page() -> void:
    var y: float = 6.0
    _add_slider_row(_page_options, "FOV", y, 50.0, 110.0, 1.0, func(value: float) -> void:
        _stored_fov = value
        if _camera != null:
            _camera.fov = value
        _fov_value.text = str(int(round(value)))
        _save_settings()
    )
    _fov_slider = _page_options.get_node("FOVSlider") as HSlider
    _fov_value = _page_options.get_node("FOVValue") as Label

    y += 56.0
    _add_slider_row(_page_options, "Mouse Sensitivity", y, 5.0, 80.0, 1.0, func(value: float) -> void:
        _stored_sensitivity = value
        if _player != null:
            _player.set_mouse_sensitivity(value / 10000.0)
        _sense_value.text = "%.2f" % value
        _save_settings()
    )
    _sense_slider = _page_options.get_node("MouseSensitivitySlider") as HSlider
    _sense_value = _page_options.get_node("MouseSensitivityValue") as Label

    y += 56.0
    _add_slider_row(_page_options, "Render Distance", y, 2.0, 32.0, 1.0, func(value: float) -> void:
        _stored_render_distance = int(round(value))
        if _world != null:
            if _world.has_method("apply_render_distance"):
                _world.apply_render_distance(_stored_render_distance)
            else:
                _world.load_radius = _stored_render_distance
                _world.collision_radius = max(1, _world.load_radius - 1)
            _world.set_target(_player)
        _render_value.text = str(_stored_render_distance)
        _save_settings()
    )
    _render_slider = _page_options.get_node("RenderDistanceSlider") as HSlider
    _render_value = _page_options.get_node("RenderDistanceValue") as Label

    y += 56.0
    _add_slider_row(_page_options, "Brightness", y, 0.0, 100.0, 1.0, func(value: float) -> void:
        _stored_brightness = value
        if _day_night != null:
            _day_night.set_brightness_percent(value)
        _brightness_value.text = str(int(round(value)))
        _save_settings()
    )
    _brightness_slider = _page_options.get_node("BrightnessSlider") as HSlider
    _brightness_value = _page_options.get_node("BrightnessValue") as Label

    var mode_label: Label = Label.new()
    mode_label.text = "Gamemode"
    mode_label.position = Vector2(0.0, 235.0)
    mode_label.size = Vector2(120.0, 18.0)
    _page_options.add_child(mode_label)

    _mode_option = OptionButton.new()
    _mode_option.position = Vector2(0.0, 255.0)
    _mode_option.size = Vector2(186.0, 26.0)
    _mode_option.add_item("Survival", SSDGameMode.Mode.SURVIVAL)
    _mode_option.add_item("Creative", SSDGameMode.Mode.CREATIVE)
    _mode_option.item_selected.connect(func(index: int) -> void:
        if _game_mode != null:
            _game_mode.set_mode(_mode_option.get_item_id(index))
            _stored_mode = _game_mode.get_mode_name()
            _save_settings()
    )
    _page_options.add_child(_mode_option)

    _vsync_check = CheckBox.new()
    _vsync_check.text = "Enable VSync"
    _vsync_check.position = Vector2(0.0, 292.0)
    _vsync_check.toggled.connect(func(enabled: bool) -> void:
        _stored_vsync = enabled
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)
        _save_settings()
    )
    _page_options.add_child(_vsync_check)

    _block_break_check = CheckBox.new()
    _block_break_check.text = "Enable Block Breaking"
    _block_break_check.position = Vector2(0.0, 322.0)
    _block_break_check.toggled.connect(func(enabled: bool) -> void:
        _stored_block_breaking = enabled
        _save_settings()
    )
    _page_options.add_child(_block_break_check)

func _build_character_page() -> void:
    var title: Label = Label.new()
    title.text = "World Character"
    title.position = Vector2(0.0, 0.0)
    title.size = Vector2(180.0, 24.0)
    _page_character.add_child(title)

    _preview = SSDPlayerPreview.new()
    _preview.position = Vector2(0.0, 32.0)
    _preview.size = Vector2(150.0, 220.0)
    _page_character.add_child(_preview)

    var body_label: Label = Label.new()
    body_label.text = "Body Type"
    body_label.position = Vector2(168.0, 34.0)
    body_label.size = Vector2(100.0, 18.0)
    _page_character.add_child(body_label)

    _body_option = OptionButton.new()
    _body_option.position = Vector2(168.0, 56.0)
    _body_option.size = Vector2(150.0, 26.0)
    _body_option.add_item("Body 1", 0)
    _body_option.add_item("Body 2", 1)
    _body_option.add_item("Body 3", 2)
    _body_option.add_item("Body 4", 3)
    _body_option.item_selected.connect(func(index: int) -> void:
        var body_id: int = _body_option.get_item_id(index)
        _profile["body_type_index"] = body_id
        if _preview != null:
            _preview.set_body_type(body_id)
        if _player != null:
            _player.set_body_type(body_id)
    )
    _page_character.add_child(_body_option)

    var skin_title: Label = Label.new()
    skin_title.text = "Skin Tone"
    skin_title.position = Vector2(168.0, 98.0)
    skin_title.size = Vector2(100.0, 18.0)
    _page_character.add_child(skin_title)

    _skin_label = Label.new()
    _skin_label.position = Vector2(168.0, 194.0)
    _skin_label.size = Vector2(150.0, 18.0)
    _page_character.add_child(_skin_label)

    for i: int in range(SKIN_SWATCHES.size()):
        var swatch: Button = Button.new()
        swatch.position = Vector2(168.0 + float(i % 3) * 48.0, 122.0 + floorf(float(i) / 3.0) * 48.0)
        swatch.size = Vector2(36.0, 36.0)
        swatch.text = ""
        swatch.set_meta("skin_hex", SKIN_SWATCHES[i])
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#" + SKIN_SWATCHES[i])
        style.border_color = Color(0.20,0.20,0.20,1.0)
        style.border_width_left = 2
        style.border_width_top = 2
        style.border_width_right = 2
        style.border_width_bottom = 2
        swatch.add_theme_stylebox_override("normal", style)
        swatch.add_theme_stylebox_override("hover", style.duplicate())
        swatch.pressed.connect(_on_skin_swatch_pressed.bind(swatch))
        _page_character.add_child(swatch)

    var save_label: Label = Label.new()
    save_label.text = "Saved per world"
    save_label.position = Vector2(168.0, 226.0)
    save_label.size = Vector2(120.0, 18.0)
    _page_character.add_child(save_label)

    var apply_button := Button.new()
    apply_button.text = "Save Character"
    apply_button.position = Vector2(168.0, 254.0)
    apply_button.size = Vector2(150.0, 30.0)
    apply_button.pressed.connect(_save_world)
    _page_character.add_child(apply_button)


func _build_controls_page() -> void:
    var title: Label = Label.new()
    title.text = "Controls"
    title.position = Vector2(0.0, 0.0)
    title.size = Vector2(180.0, 24.0)
    _page_controls.add_child(title)

    var actions: Array = [
        ["move_forward", "Move Forward"],
        ["move_backward", "Move Backward"],
        ["move_left", "Move Left"],
        ["move_right", "Move Right"],
        ["jump", "Jump"],
        ["sprint", "Sprint"],
        ["toggle_inventory", "Inventory"],
        ["toggle_chat", "Chat"],
        ["toggle_menu", "Pause Menu"],
        ["toggle_camera_mode", "Camera Toggle"],
    ]
    var y: float = 10.0
    for entry in actions:
        var action_name: String = entry[0]
        var display_name: String = entry[1]
        var label: Label = Label.new()
        label.text = display_name
        label.position = Vector2(0.0, y + 4.0)
        label.size = Vector2(140.0, 22.0)
        _page_controls.add_child(label)

        var button: Button = Button.new()
        button.text = SSDCore.get_action_binding_text(action_name)
        button.position = Vector2(154.0, y)
        button.size = Vector2(150.0, 26.0)
        button.pressed.connect(func() -> void:
            _waiting_rebind_action = action_name
            button.text = "Press key..."
        )
        _page_controls.add_child(button)
        _control_buttons[action_name] = button
        y += 32.0

func _refresh_control_buttons() -> void:
    for action_name in _control_buttons.keys():
        var button: Button = _control_buttons[action_name]
        if button != null:
            button.text = SSDCore.get_action_binding_text(action_name)

func _on_skin_swatch_pressed(button: Button) -> void:
    var skin_hex: String = str(button.get_meta("skin_hex", "d3af92"))
    _profile["skin_tone"] = skin_hex
    if _preview != null:
        _preview.set_skin_tone(Color("#" + skin_hex))
    if _player != null:
        _player.set_skin_tone(Color("#" + skin_hex))
    if _skin_label != null:
        _skin_label.text = "#%s" % skin_hex.to_upper()

func _load_profile_controls() -> void:
    if _body_option == null:
        return
    var body_index: int = clampi(int(_profile.get("body_type_index", 0)), 0, 3)
    _body_option.select(body_index)
    if _preview != null:
        _preview.set_body_type(body_index)
        _preview.set_skin_tone(Color("#" + str(_profile.get("skin_tone", "d3af92"))))
    if _skin_label != null:
        _skin_label.text = "#%s" % str(_profile.get("skin_tone", "d3af92")).to_upper()

func _show_page(page: Control) -> void:
    _page_options.visible = page == _page_options
    _page_character.visible = page == _page_character
    _page_controls.visible = page == _page_controls
    if page == _page_controls:
        _refresh_control_buttons()

func _make_menu_button(text_value: String, pos: Vector2, cb: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = pos
    button.size = Vector2(132.0, 30.0)
    button.pressed.connect(cb)
    return button

func _add_slider_row(parent_node: Control, label_text: String, row_y: float, min_value: float, max_value: float, step: float, changed_callable: Callable) -> void:
    var safe_name: String = label_text.replace(" ", "")
    var label: Label = Label.new()
    label.text = label_text
    label.position = Vector2(0.0, row_y)
    label.size = Vector2(136.0, 16.0)
    label.add_theme_font_size_override("font_size", 11)
    parent_node.add_child(label)

    var slider: HSlider = HSlider.new()
    slider.name = "%sSlider" % safe_name
    slider.position = Vector2(0.0, row_y + 18.0)
    slider.size = Vector2(230.0, 18.0)
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value_changed.connect(changed_callable)
    parent_node.add_child(slider)

    var value_label: Label = Label.new()
    value_label.name = "%sValue" % safe_name
    value_label.position = Vector2(244.0, row_y + 14.0)
    value_label.size = Vector2(72.0, 18.0)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    parent_node.add_child(value_label)

func _sync_from_targets() -> void:
    if _camera != null:
        _stored_fov = _camera.fov
    if _player != null:
        _stored_sensitivity = _player.mouse_sensitivity * 10000.0
    if _world != null:
        _stored_render_distance = _world.load_radius
    if _day_night != null:
        _stored_brightness = _day_night.get_brightness_percent()
    if _game_mode != null:
        _stored_mode = _game_mode.get_mode_name()
    _stored_vsync = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

    if _fov_slider != null:
        _fov_slider.value = _stored_fov
        _fov_value.text = str(int(round(_stored_fov)))
    if _sense_slider != null:
        _sense_slider.value = _stored_sensitivity
        _sense_value.text = "%.2f" % _stored_sensitivity
    if _render_slider != null:
        _render_slider.value = _stored_render_distance
        _render_value.text = str(_stored_render_distance)
    if _brightness_slider != null:
        _brightness_slider.value = _stored_brightness
        _brightness_value.text = str(int(round(_stored_brightness)))
    if _vsync_check != null:
        _vsync_check.button_pressed = _stored_vsync
    if _mode_option != null:
        _mode_option.select(1 if _stored_mode == "creative" else 0)
    if _block_break_check != null:
        _block_break_check.button_pressed = _stored_block_breaking

func _load_settings() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        return
    _stored_fov = float(cfg.get_value("video", "fov", _stored_fov))
    _stored_sensitivity = float(cfg.get_value("input", "mouse_sensitivity", _stored_sensitivity))
    _stored_render_distance = int(cfg.get_value("world", "render_distance", _stored_render_distance))
    _stored_brightness = float(cfg.get_value("video", "brightness", _stored_brightness))
    _stored_vsync = bool(cfg.get_value("video", "vsync", _stored_vsync))
    _stored_mode = str(cfg.get_value("gameplay", "gamemode", _stored_mode))
    _stored_block_breaking = bool(cfg.get_value("gameplay", "block_breaking_enabled", _stored_block_breaking))
    if cfg.has_section("bindings"):
        for action_name in cfg.get_section_keys("bindings"):
            SSDCore.rebind_action_to_key(action_name, int(cfg.get_value("bindings", action_name, 0)))

func _save_settings() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    cfg.set_value("video", "fov", _stored_fov)
    cfg.set_value("input", "mouse_sensitivity", _stored_sensitivity)
    cfg.set_value("world", "render_distance", _stored_render_distance)
    cfg.set_value("video", "brightness", _stored_brightness)
    cfg.set_value("video", "vsync", _stored_vsync)
    cfg.set_value("gameplay", "gamemode", _stored_mode)
    cfg.set_value("gameplay", "block_breaking_enabled", _stored_block_breaking)
    for action_name in _control_buttons.keys():
        var events: Array[InputEvent] = InputMap.action_get_events(str(action_name))
        for event in events:
            if event is InputEventKey:
                var key_event: InputEventKey = event as InputEventKey
                var keycode: int = int(key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode)
                cfg.set_value("bindings", str(action_name), keycode)
                break
    cfg.save(SETTINGS_PATH)

func _apply_settings_to_targets() -> void:
    if _camera != null:
        _camera.fov = _stored_fov
    if _player != null:
        _player.set_mouse_sensitivity(_stored_sensitivity / 10000.0)
    if _world != null:
        if _world.has_method("apply_render_distance"):
            _world.apply_render_distance(_stored_render_distance)
        else:
            _world.load_radius = _stored_render_distance
            _world.collision_radius = max(1, _stored_render_distance - 1)
        _world.set_target(_player)
    if _day_night != null:
        _day_night.set_brightness_percent(_stored_brightness)
    if _game_mode != null:
        _game_mode.set_mode_by_name(_stored_mode)
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _stored_vsync else DisplayServer.VSYNC_DISABLED)

static func is_block_breaking_enabled() -> bool:
    var cfg: ConfigFile = ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        return true
    return bool(cfg.get_value("gameplay", "block_breaking_enabled", true))

func _save_world() -> void:
    SSDCore.set_current_world_profile(_profile)
    if _player != null:
        _player.refresh_profile_from_core()
    _save_settings()

func _save_and_quit() -> void:
    _save_world()
    SSDCore.go_to_main_menu()


func _input(event: InputEvent) -> void:
    if not visible or _waiting_rebind_action.is_empty():
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.keycode == KEY_ESCAPE:
            _waiting_rebind_action = ""
            _refresh_control_buttons()
            get_viewport().set_input_as_handled()
            return
        var code: int = int(key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode)
        SSDCore.rebind_action_to_key(_waiting_rebind_action, code)
        _waiting_rebind_action = ""
        _refresh_control_buttons()
        _save_settings()
        get_viewport().set_input_as_handled()

func _make_panel_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.08, 0.12, 0.97)
    style.border_color = Color(0.18, 0.18, 0.18, 1.0)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
    style.shadow_size = 3
    return style
