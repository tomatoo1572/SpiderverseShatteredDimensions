extends CharacterBody3D
class_name SSDItemDrop

@export var gravity_accel: float = 18.0
@export var despawn_seconds: float = 60.0

var block_id: int = SSDItemDefs.ITEM_AIR
var item_count: int = 1
var pickup_delay: float = 0.85
var _lifetime: float = 0.0
var _player: Node3D
var _inventory: SSDInventory
var _mesh_instance: MeshInstance3D

func _ready() -> void:
    _ensure_nodes()
    safe_margin = 0.02

func setup(new_block_id: int, new_count: int, player: Node3D, inventory: SSDInventory, launch_velocity: Vector3) -> void:
    block_id = new_block_id
    item_count = max(1, new_count)
    _player = player
    _inventory = inventory
    velocity = launch_velocity
    _ensure_nodes()
    _refresh_visuals()

func _physics_process(delta: float) -> void:
    _lifetime += delta
    pickup_delay = maxf(0.0, pickup_delay - delta)
    if _lifetime >= despawn_seconds:
        queue_free()
        return

    velocity.y -= gravity_accel * delta
    if is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
    move_and_slide()

    if _mesh_instance != null:
        _mesh_instance.rotate_y(1.9 * delta)

    if pickup_delay > 0.0 or _player == null or _inventory == null:
        return

    if global_position.distance_squared_to(_player.global_position + Vector3(0.0, 0.9, 0.0)) <= 1.15 * 1.15:
        var remaining: int = _inventory.add_items(block_id, item_count)
        if remaining <= 0:
            queue_free()
        else:
            item_count = remaining

func _ensure_nodes() -> void:
    if _mesh_instance == null:
        _mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
        if _mesh_instance == null:
            _mesh_instance = MeshInstance3D.new()
            _mesh_instance.name = "MeshInstance3D"
            add_child(_mesh_instance)

    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision == null:
        collision = CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        var shape: SphereShape3D = SphereShape3D.new()
        shape.radius = 0.16
        collision.shape = shape
        add_child(collision)

func _refresh_visuals() -> void:
    if _mesh_instance == null:
        return
    var custom_icon: Texture2D = SSDItemDefs.get_inventory_icon_texture(block_id)
    if custom_icon != null:
        var quad: QuadMesh = QuadMesh.new()
        quad.size = Vector2(0.34, 0.34)
        _mesh_instance.mesh = quad
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.albedo_texture = custom_icon
        mat.roughness = 1.0
        _mesh_instance.material_override = mat
        return

    var cube: BoxMesh = BoxMesh.new()
    cube.size = Vector3(0.24, 0.24, 0.24)
    _mesh_instance.mesh = cube

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = SSDVoxelDefs.get_color(block_id)
    material.roughness = 1.0
    material.metallic = 0.0
    _mesh_instance.material_override = material
