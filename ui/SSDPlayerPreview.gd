extends Control
class_name SSDPlayerPreview

const SSD_PLAYER_MODEL_SCRIPT = preload("res://client/player/SSDPlayerModel.gd")

var _viewport_container: SubViewportContainer
var _viewport: SubViewport
var _preview_root: Node3D
var _camera: Camera3D
var _light: DirectionalLight3D
var _model: SSDPlayerModel
var _inventory: SSDInventory
var _rotate_model: bool = false
var _yaw_degrees: float = -16.0
var _upper_body_only: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build_preview_if_needed()
    _model.apply_profile(SSDCore.get_player_profile())
    _sync_from_inventory()
    _apply_preview_pose()

func set_skin_tone(color_value: Color) -> void:
    if _model != null:
        _model.set_skin_tone(color_value)

func set_body_type(index: int) -> void:
    if _model != null:
        _model.set_body_type(index)

func set_shirt_item(item_id: int) -> void:
    if _model != null:
        _model.set_shirt_item(item_id)

func set_jacket_item(item_id: int) -> void:
    if _model != null:
        _model.set_jacket_item(item_id)

func set_inventory(inventory: SSDInventory) -> void:
    if _inventory != null and _inventory.inventory_changed.is_connected(Callable(self, "_sync_from_inventory")):
        _inventory.inventory_changed.disconnect(Callable(self, "_sync_from_inventory"))
    _inventory = inventory
    if _inventory != null:
        _inventory.inventory_changed.connect(Callable(self, "_sync_from_inventory"))
    _sync_from_inventory()

func set_rotate_model(enabled: bool) -> void:
    _rotate_model = enabled

func set_upper_body_only(enabled: bool) -> void:
    _upper_body_only = enabled
    if enabled:
        _yaw_degrees = 0.0
    _apply_preview_pose()

func set_yaw_degrees(value: float) -> void:
    _yaw_degrees = value
    _apply_preview_pose()

func _sync_from_inventory() -> void:
    if _model == null:
        return
    var shirt_id: int = SSDItemDefs.ITEM_AIR
    var jacket_id: int = SSDItemDefs.ITEM_AIR
    if _inventory != null:
        shirt_id = _inventory.get_equipped_item_id("Shirt")
        jacket_id = _inventory.get_equipped_item_id("Jacket")
    _model.set_shirt_item(shirt_id)
    _model.set_jacket_item(jacket_id)

func _process(delta: float) -> void:
    if _model != null and _rotate_model:
        _model.rotation.y += delta * 0.35

func _build_preview_if_needed() -> void:
    if _viewport_container != null:
        return

    _viewport_container = SubViewportContainer.new()
    _viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    _viewport_container.stretch = true
    add_child(_viewport_container)

    _viewport = SubViewport.new()
    _viewport.size = Vector2i(256, 256)
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport.transparent_bg = true
    _viewport_container.add_child(_viewport)

    _preview_root = Node3D.new()
    _viewport.add_child(_preview_root)

    var environment: WorldEnvironment = WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
    environment.environment.ambient_light_color = Color(1.0, 1.0, 1.0, 1.0)
    environment.environment.ambient_light_energy = 0.8
    _preview_root.add_child(environment)

    _light = DirectionalLight3D.new()
    _light.rotation_degrees = Vector3(-28.0, 28.0, 0.0)
    _light.light_energy = 1.25
    _preview_root.add_child(_light)

    _camera = Camera3D.new()
    _camera.current = true
    _camera.cull_mask = 2
    _preview_root.add_child(_camera)

    _model = SSD_PLAYER_MODEL_SCRIPT.new() as SSDPlayerModel
    _model.render_layer_mask = 2
    _preview_root.add_child(_model)

func _apply_preview_pose() -> void:
    if _model == null or _camera == null:
        return
    _model.rotation_degrees = Vector3(0.0, 180.0, 0.0) if _upper_body_only else Vector3(0.0, _yaw_degrees, 0.0)
    if _upper_body_only:
        _model.position = Vector3(0.0, 0.12, 0.0)
        _camera.look_at_from_position(Vector3(0.0, 1.24, 1.62), Vector3(0.0, 1.06, 0.0), Vector3.UP)
    else:
        _model.position = Vector3(0.0, 0.88, 0.0)
        _camera.look_at_from_position(Vector3(0.0, 1.02, 2.75), Vector3(0.0, 1.0, 0.0), Vector3.UP)
