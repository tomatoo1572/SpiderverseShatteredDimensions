extends CharacterBody3D
class_name SSDFlyPlayer

const SSD_PLAYER_MODEL_SCRIPT = preload("res://client/player/SSDPlayerModel.gd")

const PLAYER_HEIGHT: float = 1.8
const PLAYER_RADIUS: float = 0.295
const EYE_HEIGHT: float = 1.62

enum CameraMode {
    FIRST_PERSON,
    THIRD_PERSON,
}

@export var walk_speed: float = 6.2
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 7.55
@export var gravity_accel: float = 24.0
@export var mouse_sensitivity: float = 0.00195
@export var fly_speed: float = 16.0
@export var fly_sprint_speed: float = 24.0
@export var third_person_distance: float = 3.10
@export var third_person_shoulder_offset: Vector3 = Vector3(0.62, -0.02, 0.0)
@export var world_model_offset: Vector3 = Vector3(0.0, 0.24, 0.0)
@export var first_person_model_offset: Vector3 = Vector3(0.0, -1.66, 0.02)
@export var first_person_camera_offset: Vector3 = Vector3(0.0, 0.04, -0.12)
@export var jump_stamina_cost: float = 4.0

@onready var _pivot: Node3D = $Pivot as Node3D
@onready var _camera: Camera3D = $Pivot/Camera3D as Camera3D

var _pitch: float = 0.0
var _flying: bool = false
var _flight_allowed: bool = false
var _controls_enabled: bool = true
var _vitals: SSDVitals
var _world_model: SSDPlayerModel
var _first_person_model: SSDPlayerModel
var _inventory: SSDInventory
var _world: SSDWorld
var _camera_mode: int = CameraMode.FIRST_PERSON
var _held_item_root: Node3D
var _held_item_mesh: MeshInstance3D
var _third_person_held_root: Node3D
var _third_person_held_mesh: MeshInstance3D
var _freelook_yaw: float = 0.0
var _freelook_pitch: float = 0.0
var _icon_mesh_cache: Dictionary = {}

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    floor_snap_length = 0.42
    safe_margin = 0.02
    max_slides = 6
    floor_stop_on_slope = true
    _pivot.position.y = EYE_HEIGHT
    _camera.near = 0.01
    _ensure_visual_models()
    _ensure_held_item_root()
    _apply_camera_mode(true)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_flight"):
        if not _flight_allowed:
            return
        _flying = not _flying
        if not _flying:
            velocity.y = 0.0
        return

    if event.is_action_pressed("toggle_camera_mode"):
        _camera_mode = CameraMode.THIRD_PERSON if _camera_mode == CameraMode.FIRST_PERSON else CameraMode.FIRST_PERSON
        _apply_camera_mode(false)
        return

    if not _controls_enabled:
        return
    if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
        return

    if event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        if _camera_mode == CameraMode.THIRD_PERSON and Input.is_action_pressed("camera_freelook"):
            _freelook_yaw = wrapf(_freelook_yaw - (motion.relative.x * mouse_sensitivity * 0.85), -PI, PI)
            _freelook_pitch = clampf(_freelook_pitch - (motion.relative.y * mouse_sensitivity * 0.85), deg_to_rad(-75.0), deg_to_rad(75.0))
        else:
            rotate_y(-motion.relative.x * mouse_sensitivity)
            _pitch = clampf(_pitch - (motion.relative.y * mouse_sensitivity), deg_to_rad(-89.0), deg_to_rad(89.0))

func _physics_process(delta: float) -> void:
    if not _controls_enabled:
        velocity = Vector3.ZERO
        return

    var input_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var input_z: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

    var horizontal_basis: Basis = global_transform.basis
    var forward: Vector3 = -horizontal_basis.z
    var right: Vector3 = horizontal_basis.x
    var move_direction: Vector3 = (right * input_x) + (forward * input_z)
    if move_direction.length_squared() > 0.0:
        move_direction = move_direction.normalized()

    var wants_sprint: bool = Input.is_action_pressed("sprint") and move_direction.length_squared() > 0.0

    var in_water: bool = _is_in_water()
    if _flying:
        _process_flying(delta, move_direction, wants_sprint)
    elif in_water:
        _process_swimming(delta, move_direction, wants_sprint)
    else:
        _process_grounded(delta, move_direction, wants_sprint)

    _update_visual_models()
    _update_camera_transform()

func _process_grounded(delta: float, move_direction: Vector3, wants_sprint: bool) -> void:
    var sprinting: bool = wants_sprint and _can_sprint()
    var current_speed: float = sprint_speed if sprinting else walk_speed
    velocity.x = move_toward(velocity.x, move_direction.x * current_speed, 42.0 * delta)
    velocity.z = move_toward(velocity.z, move_direction.z * current_speed, 42.0 * delta)

    var jumped_this_frame: bool = false
    if is_on_floor():
        if Input.is_action_just_pressed("jump"):
            if _vitals == null or (_vitals.can_jump(jump_stamina_cost) and _vitals.spend_stamina(jump_stamina_cost)):
                velocity.y = jump_velocity
                jumped_this_frame = true
            else:
                velocity.y = -0.01
        else:
            velocity.y = 0.0
    else:
        velocity.y -= gravity_accel * delta

    floor_snap_length = 0.0 if jumped_this_frame else 0.42
    move_and_slide()

    if not jumped_this_frame and is_on_floor():
        apply_floor_snap()
        if move_direction.length_squared() == 0.0:
            velocity.x = move_toward(velocity.x, 0.0, 56.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 56.0 * delta)

    _update_vitals(delta, sprinting and is_on_floor() and move_direction.length_squared() > 0.0)

func _process_swimming(delta: float, move_direction: Vector3, wants_sprint: bool) -> void:
    var sprinting: bool = wants_sprint and _can_sprint()
    var current_speed: float = walk_speed * (0.86 if sprinting else 0.62)
    velocity.x = move_toward(velocity.x, move_direction.x * current_speed, 18.0 * delta)
    velocity.z = move_toward(velocity.z, move_direction.z * current_speed, 18.0 * delta)

    var vertical_target: float = -1.35
    if Input.is_action_pressed("jump"):
        vertical_target = 4.4
    elif Input.is_action_pressed("crouch"):
        vertical_target = -3.8
    velocity.y = move_toward(velocity.y, vertical_target, 16.0 * delta)
    floor_snap_length = 0.0
    move_and_slide()
    _update_vitals(delta, sprinting and move_direction.length_squared() > 0.0)

func _is_in_water() -> bool:
    if _world == null:
        return false
    var samples: Array[Vector3] = [
        global_position + Vector3(0.0, 0.25, 0.0),
        global_position + Vector3(0.0, 0.95, 0.0),
        global_position + Vector3(0.0, 1.45, 0.0),
    ]
    for sample: Vector3 in samples:
        var bx: int = floori(sample.x / SSDChunkConfig.VOXEL_SIZE)
        var by: int = floori(sample.y / SSDChunkConfig.VOXEL_SIZE)
        var bz: int = floori(sample.z / SSDChunkConfig.VOXEL_SIZE)
        if SSDVoxelDefs.is_fluid(_world.get_block_global(bx, by, bz)):
            return true
    return false

func _process_flying(delta: float, move_direction: Vector3, wants_sprint: bool) -> void:
    var current_speed: float = fly_sprint_speed if wants_sprint else fly_speed
    var fly_direction: Vector3 = move_direction
    if Input.is_action_pressed("jump"):
        fly_direction.y += 1.0
    if Input.is_action_pressed("crouch"):
        fly_direction.y -= 1.0
    if fly_direction.length_squared() > 0.0:
        fly_direction = fly_direction.normalized()
    velocity = fly_direction * current_speed
    move_and_slide()
    _update_vitals(delta, false)

func _update_visual_models() -> void:
    _pivot.rotation.x = _pitch
    if _world_model != null:
        _world_model.visible = _camera_mode == CameraMode.THIRD_PERSON
    if _first_person_model != null:
        _first_person_model.visible = _camera_mode == CameraMode.FIRST_PERSON
    if _held_item_root != null:
        _held_item_root.visible = _camera_mode == CameraMode.FIRST_PERSON
    if _third_person_held_root != null:
        _third_person_held_root.visible = _camera_mode == CameraMode.THIRD_PERSON

func _update_camera_transform() -> void:
    if _camera == null:
        return
    if _camera_mode == CameraMode.FIRST_PERSON:
        _camera.position = first_person_camera_offset
        _camera.rotation = Vector3.ZERO
        _camera.cull_mask = 1 | 2 | 4
        return

    _camera.cull_mask = 1 | 2
    var look_origin: Vector3 = global_position + Vector3(0.0, EYE_HEIGHT - 0.04, 0.0)
    var base_yaw: float = rotation.y + _freelook_yaw
    var base_pitch: float = clampf(_pitch + _freelook_pitch, deg_to_rad(-75.0), deg_to_rad(75.0))
    var yaw_basis: Basis = Basis(Vector3.UP, base_yaw)
    var pitch_basis: Basis = Basis(Vector3.RIGHT, base_pitch)
    var look_basis: Basis = yaw_basis * pitch_basis
    var shoulder_origin: Vector3 = look_origin + (yaw_basis * Vector3(third_person_shoulder_offset.x, third_person_shoulder_offset.y, 0.0))
    var desired_world: Vector3 = shoulder_origin + (look_basis * Vector3(0.0, 0.0, third_person_distance))

    var final_world: Vector3 = desired_world
    var state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(shoulder_origin, desired_world)
    query.exclude = [self]
    var hit: Dictionary = state.intersect_ray(query)
    if not hit.is_empty():
        var hit_pos: Vector3 = hit.get("position", desired_world)
        final_world = hit_pos + (shoulder_origin - desired_world).normalized() * 0.16

    _camera.global_position = final_world
    _camera.look_at(shoulder_origin + (look_basis * Vector3(0.0, 0.0, -4.0)), Vector3.UP)

func _can_sprint() -> bool:
    return _vitals == null or _vitals.can_sprint()

func _update_vitals(delta: float, sprinting: bool) -> void:
    if _vitals == null:
        return
    _vitals.tick(delta, sprinting)

func set_controls_enabled(enabled: bool) -> void:
    _controls_enabled = enabled
    if not enabled:
        velocity = Vector3.ZERO

func reset_motion() -> void:
    velocity = Vector3.ZERO

func set_vitals(vitals: SSDVitals) -> void:
    _vitals = vitals

func get_vitals() -> SSDVitals:
    return _vitals

func is_flying() -> bool:
    return _flying

func set_mouse_sensitivity(value: float) -> void:
    mouse_sensitivity = clampf(value, 0.0005, 0.0080)

func set_flight_allowed(enabled: bool) -> void:
    _flight_allowed = enabled
    if not _flight_allowed and _flying:
        _flying = false
        velocity.y = 0.0

func is_flight_allowed() -> bool:
    return _flight_allowed

func set_inventory(inventory: SSDInventory) -> void:
    if _inventory != null and _inventory.inventory_changed.is_connected(Callable(self, "_sync_equipment_from_inventory")):
        _inventory.inventory_changed.disconnect(Callable(self, "_sync_equipment_from_inventory"))
    if _inventory != null and _inventory.inventory_changed.is_connected(Callable(self, "_refresh_held_item_visual")):
        _inventory.inventory_changed.disconnect(Callable(self, "_refresh_held_item_visual"))
    _inventory = inventory
    if _inventory != null:
        _inventory.inventory_changed.connect(Callable(self, "_sync_equipment_from_inventory"))
        _inventory.inventory_changed.connect(Callable(self, "_refresh_held_item_visual"))
    _sync_equipment_from_inventory()
    _refresh_held_item_visual()

func set_skin_tone(color_value: Color) -> void:
    for model: SSDPlayerModel in [_world_model, _first_person_model]:
        if model != null:
            model.set_skin_tone(color_value)

func set_body_type(index: int) -> void:
    for model: SSDPlayerModel in [_world_model, _first_person_model]:
        if model != null:
            model.set_body_type(index)

func refresh_profile_from_core() -> void:
    var profile: Dictionary = SSDCore.get_current_world_profile()
    for model: SSDPlayerModel in [_world_model, _first_person_model]:
        if model != null:
            model.apply_profile(profile)

func _sync_equipment_from_inventory() -> void:
    var shirt_id: int = SSDItemDefs.ITEM_AIR
    var jacket_id: int = SSDItemDefs.ITEM_AIR
    if _inventory != null:
        shirt_id = _inventory.get_equipped_item_id("Shirt")
        jacket_id = _inventory.get_equipped_item_id("Jacket")
    for model: SSDPlayerModel in [_world_model, _first_person_model]:
        if model != null:
            model.set_shirt_item(shirt_id)
            model.set_jacket_item(jacket_id)

func _ensure_visual_models() -> void:
    if has_node("VisualModel"):
        _world_model = get_node("VisualModel") as SSDPlayerModel
    else:
        _world_model = SSD_PLAYER_MODEL_SCRIPT.new() as SSDPlayerModel
        _world_model.name = "VisualModel"
        _world_model.render_layer_mask = 2
        _world_model.position = world_model_offset
        add_child(_world_model)

    if has_node("Pivot/FirstPersonModel"):
        _first_person_model = get_node("Pivot/FirstPersonModel") as SSDPlayerModel
    else:
        _first_person_model = SSD_PLAYER_MODEL_SCRIPT.new() as SSDPlayerModel
        _first_person_model.name = "FirstPersonModel"
        _first_person_model.render_layer_mask = 4
        _first_person_model.position = first_person_model_offset
        _first_person_model.rotation_degrees = Vector3(0.0, 0.0, 0.0)
        _pivot.add_child(_first_person_model)

    if _world_model != null:
        _world_model.position = world_model_offset
    if _first_person_model != null:
        _first_person_model.position = first_person_model_offset
        _first_person_model.hide_head = true
        _first_person_model.head_cutoff_y = 0.70
    if _world_model != null:
        _world_model.hide_head = false

    for model: SSDPlayerModel in [_world_model, _first_person_model]:
        if model != null:
            model.model_scale = 0.82
            model.apply_profile(SSDCore.get_current_world_profile())
    _sync_equipment_from_inventory()
    _refresh_held_item_visual()

func _ensure_held_item_root() -> void:
    if _camera == null:
        return
    if _held_item_root == null:
        _held_item_root = Node3D.new()
        _held_item_root.name = "HeldItemRoot"
        _camera.add_child(_held_item_root)
    if _held_item_mesh == null:
        _held_item_mesh = MeshInstance3D.new()
        _held_item_mesh.name = "HeldItemMesh"
        _held_item_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        _held_item_mesh.layers = 4
        _held_item_root.add_child(_held_item_mesh)
    if _third_person_held_root == null:
        _third_person_held_root = Node3D.new()
        _third_person_held_root.name = "ThirdPersonHeldRoot"
        add_child(_third_person_held_root)
    if _third_person_held_mesh == null:
        _third_person_held_mesh = MeshInstance3D.new()
        _third_person_held_mesh.name = "ThirdPersonHeldMesh"
        _third_person_held_mesh.layers = 2
        _third_person_held_root.add_child(_third_person_held_mesh)
    _refresh_held_item_visual()

func _refresh_held_item_visual() -> void:
    if _held_item_mesh == null or _third_person_held_mesh == null:
        return
    var item_id: int = SSDItemDefs.ITEM_AIR
    if _inventory != null:
        item_id = _inventory.get_selected_block_id()
    if item_id == SSDItemDefs.ITEM_AIR:
        _held_item_mesh.visible = false
        _third_person_held_mesh.visible = false
        return

    var render_data: Dictionary = _build_held_render_data(item_id)
    var mesh: Mesh = render_data.get("mesh", null) as Mesh
    var material: Material = render_data.get("material", null) as Material
    var is_block: bool = bool(render_data.get("is_block", false))
    if mesh == null or material == null:
        _held_item_mesh.visible = false
        _third_person_held_mesh.visible = false
        return

    _held_item_mesh.mesh = mesh
    _held_item_mesh.material_override = material
    _third_person_held_mesh.mesh = mesh
    _third_person_held_mesh.material_override = material

    if is_block:
        _held_item_root.position = Vector3(0.30, -0.42, -0.52)
        _held_item_root.rotation_degrees = Vector3(-12.0, -18.0, 0.0)
        _held_item_mesh.position = Vector3.ZERO
        _held_item_mesh.rotation_degrees = Vector3(18.0, 42.0, -10.0)
        _held_item_mesh.scale = Vector3.ONE * 0.24

        _third_person_held_root.position = Vector3(0.31, 0.98, -0.12)
        _third_person_held_root.rotation_degrees = Vector3(-76.0, 10.0, 86.0)
        _third_person_held_mesh.position = Vector3.ZERO
        _third_person_held_mesh.rotation_degrees = Vector3.ZERO
        _third_person_held_mesh.scale = Vector3.ONE * 0.22
    else:
        _held_item_root.position = Vector3(0.30, -0.40, -0.44)
        _held_item_root.rotation_degrees = Vector3(-8.0, -18.0, 0.0)
        _held_item_mesh.position = Vector3.ZERO
        _held_item_mesh.rotation_degrees = Vector3(8.0, 36.0, -10.0)
        _held_item_mesh.scale = Vector3.ONE

        _third_person_held_root.position = Vector3(0.31, 0.98, -0.08)
        _third_person_held_root.rotation_degrees = Vector3(-84.0, 8.0, 82.0)
        _third_person_held_mesh.position = Vector3.ZERO
        _third_person_held_mesh.rotation_degrees = Vector3.ZERO
        _third_person_held_mesh.scale = Vector3.ONE

    _held_item_mesh.visible = true
    _third_person_held_mesh.visible = true

func _build_held_render_data(item_id: int) -> Dictionary:
    if SSDItemDefs.is_placeable_block(item_id):
        return _build_block_render_data(item_id)
    return _build_item_render_data(item_id)

func _build_item_render_data(item_id: int) -> Dictionary:
    var icon_texture: Texture2D = SSDItemDefs.get_inventory_icon_texture(item_id)
    if icon_texture == null:
        return {}
    var cache_key: String = str(item_id)
    if _icon_mesh_cache.has(cache_key):
        return _icon_mesh_cache[cache_key]

    var image: Image = icon_texture.get_image()
    if image == null:
        return {}

    var mesh: ArrayMesh = _build_extruded_icon_mesh(image, 0.38, 0.055, 0.10)
    if mesh == null or mesh.get_surface_count() == 0:
        return {}

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    material.roughness = 1.0
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    material.alpha_scissor_threshold = 0.5

    var result: Dictionary = {
        "mesh": mesh,
        "material": material,
        "is_block": false,
    }
    _icon_mesh_cache[cache_key] = result
    return result

func _build_extruded_icon_mesh(image: Image, total_size: float, depth: float, alpha_threshold: float) -> ArrayMesh:
    var width: int = image.get_width()
    var height: int = image.get_height()
    if width <= 0 or height <= 0:
        return null

    var max_dim: float = float(max(width, height))
    var pixel_size: float = total_size / max_dim
    var half_depth: float = depth * 0.5

    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var colors: PackedColorArray = PackedColorArray()
    var indices: PackedInt32Array = PackedInt32Array()

    var read_image: Image = image

    for y: int in range(height):
        for x: int in range(width):
            var px: Color = read_image.get_pixel(x, y)
            if px.a <= alpha_threshold:
                continue

            var left: float = ((float(x) / max_dim) - (float(width) / max_dim) * 0.5) * total_size
            var right: float = left + pixel_size
            var top: float = (((float(height - y - 1)) / max_dim) - (float(height) / max_dim) * 0.5) * total_size
            var bottom: float = top + pixel_size

            var front_color: Color = Color(px.r, px.g, px.b, px.a)
            var side_color: Color = Color(px.r * 0.72, px.g * 0.72, px.b * 0.72, px.a)

            _append_colored_quad(vertices, normals, colors, indices,
                Vector3(left, bottom, half_depth),
                Vector3(right, bottom, half_depth),
                Vector3(right, top, half_depth),
                Vector3(left, top, half_depth),
                Vector3.FORWARD,
                front_color
            )
            _append_colored_quad(vertices, normals, colors, indices,
                Vector3(right, bottom, -half_depth),
                Vector3(left, bottom, -half_depth),
                Vector3(left, top, -half_depth),
                Vector3(right, top, -half_depth),
                Vector3.BACK,
                Color(front_color.r * 0.90, front_color.g * 0.90, front_color.b * 0.90, front_color.a)
            )

            if x == 0 or read_image.get_pixel(x - 1, y).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(left, bottom, -half_depth),
                    Vector3(left, bottom, half_depth),
                    Vector3(left, top, half_depth),
                    Vector3(left, top, -half_depth),
                    Vector3.LEFT,
                    side_color
                )
            if x == width - 1 or read_image.get_pixel(x + 1, y).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(right, bottom, half_depth),
                    Vector3(right, bottom, -half_depth),
                    Vector3(right, top, -half_depth),
                    Vector3(right, top, half_depth),
                    Vector3.RIGHT,
                    side_color
                )
            if y == 0 or read_image.get_pixel(x, y - 1).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(left, top, half_depth),
                    Vector3(right, top, half_depth),
                    Vector3(right, top, -half_depth),
                    Vector3(left, top, -half_depth),
                    Vector3.UP,
                    Color(px.r * 0.94, px.g * 0.94, px.b * 0.94, px.a)
                )
            if y == height - 1 or read_image.get_pixel(x, y + 1).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(left, bottom, -half_depth),
                    Vector3(right, bottom, -half_depth),
                    Vector3(right, bottom, half_depth),
                    Vector3(left, bottom, half_depth),
                    Vector3.DOWN,
                    Color(px.r * 0.58, px.g * 0.58, px.b * 0.58, px.a)
                )

    var mesh: ArrayMesh = ArrayMesh.new()
    if vertices.is_empty():
        return mesh
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func _append_colored_quad(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color_value: Color) -> void:
    var start_index: int = vertices.size()
    vertices.push_back(a)
    vertices.push_back(b)
    vertices.push_back(c)
    vertices.push_back(d)
    for _i: int in range(4):
        normals.push_back(normal)
        colors.push_back(color_value)
    indices.push_back(start_index + 0)
    indices.push_back(start_index + 1)
    indices.push_back(start_index + 2)
    indices.push_back(start_index + 0)
    indices.push_back(start_index + 2)
    indices.push_back(start_index + 3)

func _build_block_render_data(block_id: int) -> Dictionary:
    var mesh: ArrayMesh = ArrayMesh.new()
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var colors: PackedColorArray = PackedColorArray()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    var face_dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
    var face_vertices: Array = [
        [Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)],
        [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],
        [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
        [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)],
        [Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
        [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)],
    ]

    for face_index: int in range(6):
        var start_index: int = vertices.size()
        var uv_rect: Rect2 = SSDVoxelDefs.get_face_uv_rect(block_id, face_index)
        var uv_left: float = uv_rect.position.x
        var uv_top: float = uv_rect.position.y
        var uv_right: float = uv_rect.position.x + uv_rect.size.x
        var uv_bottom: float = uv_rect.position.y + uv_rect.size.y
        var face_uvs: Array[Vector2] = [
            Vector2(uv_right, uv_bottom),
            Vector2(uv_right, uv_top),
            Vector2(uv_left, uv_top),
            Vector2(uv_left, uv_bottom),
        ]
        var shade: float = 1.0
        match face_index:
            2:
                shade = 0.84
            3:
                shade = 0.52
            0, 1:
                shade = 0.72
            4, 5:
                shade = 0.66
        for vertex_index: int in range(4):
            vertices.push_back((face_vertices[face_index][vertex_index] as Vector3) - Vector3(0.5, 0.5, 0.5))
            normals.push_back(face_dirs[face_index])
            colors.push_back(Color(shade, shade, shade, 1.0))
            uvs.push_back(face_uvs[vertex_index])
        indices.push_back(start_index + 0)
        indices.push_back(start_index + 1)
        indices.push_back(start_index + 2)
        indices.push_back(start_index + 0)
        indices.push_back(start_index + 2)
        indices.push_back(start_index + 3)

    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_texture = load("res://assets/textures/blocks/terrain_atlas.png") as Texture2D
    material.vertex_color_use_as_albedo = true
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_BACK
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    if block_id == SSDVoxelDefs.BlockId.GLASS or SSDVoxelDefs.is_fluid(block_id):
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.albedo_color = Color(0.78, 0.78, 0.78, 0.72)
    else:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        material.alpha_scissor_threshold = 0.5
        material.albedo_color = Color(0.72, 0.72, 0.72, 1.0)
    return {
        "mesh": mesh,
        "material": material,
        "is_block": true,
    }

func _apply_camera_mode(force_update: bool) -> void:
    if force_update:
        _freelook_yaw = 0.0
        _freelook_pitch = 0.0
    _update_visual_models()
    _update_camera_transform()

func get_pitch_radians() -> float:
    return _pitch

func get_body_yaw_radians() -> float:
    return rotation.y

func set_world(world: SSDWorld) -> void:
    _world = world
