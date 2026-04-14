extends CanvasLayer
class_name SSDDebugHUD

const SSD_STATUS_WIDGET_SCRIPT = preload("res://ui/SSDStatusWidget.gd")
const SSD_PLAYER_PREVIEW_SCRIPT = preload("res://ui/SSDPlayerPreview.gd")

@onready var _legacy_panel: PanelContainer = $PanelContainer as PanelContainer
@onready var _legacy_label: Label = $PanelContainer/MarginContainer/Label as Label

var _world: SSDWorld
var _player: Node3D
var _selector: SSDBlockSelector
var _hotbar: SSDHotbar
var _vitals: SSDVitals
var _day_night: SSDDayNightCycle
var _inventory: SSDInventory
var _status_widget: SSDStatusWidget
var _info_label: Label
var _portrait_preview: SSDPlayerPreview

func _ready() -> void:
	if _legacy_panel != null:
		_legacy_panel.visible = false
	if _legacy_label != null:
		_legacy_label.visible = false
	_build_status_widget_if_needed()
	_build_info_label_if_needed()
	_build_portrait_preview_if_needed()

func set_targets(world: SSDWorld, player: Node3D, selector: SSDBlockSelector, hotbar: SSDHotbar = null, vitals: SSDVitals = null, day_night: SSDDayNightCycle = null) -> void:
	_world = world
	_player = player
	_selector = selector
	_hotbar = hotbar
	_vitals = vitals
	_day_night = day_night

func set_inventory(inventory: SSDInventory) -> void:
	_inventory = inventory
	if _portrait_preview != null:
		_portrait_preview.set_inventory(inventory)

func _process(_delta: float) -> void:
	if _info_label == null:
		return

	if _world == null or _player == null:
		_info_label.text = "FPS: %d\nTime: --:--\nPos: loading..." % Engine.get_frames_per_second()
		_refresh_status_widget()
		return

	var position_text: String = "%.1f, %.1f, %.1f" % [
		_player.global_position.x,
		_player.global_position.y,
		_player.global_position.z
	]

	var time_text: String = "--:--"
	var day_text: String = "1"
	if _day_night != null:
		time_text = _day_night.get_formatted_time()
		day_text = str(_day_night.get_day_count())

	_info_label.text = "FPS: %d\nTime: Day %s  %s\nPos: %s" % [
		Engine.get_frames_per_second(),
		day_text,
		time_text,
		position_text
	]

	_refresh_status_widget()

func _build_status_widget_if_needed() -> void:
	if has_node("StatusWidget"):
		_status_widget = get_node("StatusWidget") as SSDStatusWidget
		return

	_status_widget = SSD_STATUS_WIDGET_SCRIPT.new() as SSDStatusWidget
	_status_widget.name = "StatusWidget"
	_status_widget.position = Vector2(12.0, 12.0)
	_status_widget.size = Vector2(520.0, 132.0)
	add_child(_status_widget)

func _build_portrait_preview_if_needed() -> void:
	if _portrait_preview != null:
		return
	_portrait_preview = SSD_PLAYER_PREVIEW_SCRIPT.new() as SSDPlayerPreview
	_portrait_preview.name = "PortraitPreview"
	_portrait_preview.position = Vector2(12.0, 10.0)
	_portrait_preview.size = Vector2(96.0, 96.0)
	_portrait_preview.set_rotate_model(false)
	_portrait_preview.set_upper_body_only(true)
	_portrait_preview.set_yaw_degrees(-18.0)
	add_child(_portrait_preview)
	if _inventory != null:
		_portrait_preview.set_inventory(_inventory)

func _build_info_label_if_needed() -> void:
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.anchor_left = 1.0
	_info_label.anchor_top = 0.0
	_info_label.anchor_right = 1.0
	_info_label.anchor_bottom = 0.0
	_info_label.offset_left = -280.0
	_info_label.offset_top = 10.0
	_info_label.offset_right = -12.0
	_info_label.offset_bottom = 74.0
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_info_label.add_theme_font_size_override("font_size", 15)
	add_child(_info_label)

func _refresh_status_widget() -> void:
	if _status_widget == null:
		return

	var hp_ratio: float = 1.0
	var st_ratio: float = 1.0
	var hp_text: String = "100 / 100"
	var st_text: String = "100 / 100"

	if _vitals != null:
		hp_ratio = 0.0 if _vitals.max_health <= 0.0 else (_vitals.health / _vitals.max_health)
		st_ratio = 0.0 if _vitals.max_stamina <= 0.0 else (_vitals.current_stamina / _vitals.max_stamina)
		hp_text = "%d / %d" % [roundi(_vitals.health), roundi(_vitals.max_health)]
		st_text = "%d / %d" % [roundi(_vitals.current_stamina), roundi(_vitals.max_stamina)]

	_status_widget.set_values(hp_ratio, st_ratio, hp_text, st_text)
