extends CharacterBody3D
class_name SSDPassiveMob

signal drop_requested(item_id: int, count: int, world_position: Vector3, impulse: Vector3)

@export var mob_type: String = "sheep"
@export var move_speed: float = 1.45
@export var gravity_accel: float = 22.0

var _wander_timer: float = 0.0
var _wander_dir: Vector3 = Vector3.ZERO
var _body: MeshInstance3D
var _head: MeshInstance3D

func _ready() -> void:
    _ensure_visuals()
    safe_margin = 0.02
    max_slides = 4
    floor_stop_on_slope = true
    add_to_group("passive_mob")

func _physics_process(delta: float) -> void:
    _wander_timer -= delta
    if _wander_timer <= 0.0:
        _wander_timer = randf_range(1.5, 4.0)
        var angle: float = randf_range(-PI, PI)
        _wander_dir = Vector3(cos(angle), 0.0, sin(angle))
        if randf() < 0.25:
            _wander_dir = Vector3.ZERO

    velocity.x = _wander_dir.x * move_speed
    velocity.z = _wander_dir.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity_accel * delta
    else:
        velocity.y = -0.01
    move_and_slide()

func interact_kill() -> void:
    var drops: Array = _get_drops()
    for entry_variant in drops:
        var entry: Dictionary = entry_variant
        var item_id: int = int(entry.get("item_id", SSDItemDefs.ITEM_AIR))
        var count: int = int(entry.get("count", 0))
        if item_id == SSDItemDefs.ITEM_AIR or count <= 0:
            continue
        var impulse: Vector3 = Vector3(randf_range(-1.2, 1.2), randf_range(1.8, 2.4), randf_range(-1.2, 1.2))
        drop_requested.emit(item_id, count, global_position + Vector3(0.0, 0.45, 0.0), impulse)
    queue_free()

func _get_drops() -> Array:
    match mob_type:
        "sheep":
            return [
                {"item_id": SSDItemDefs.ITEM_WOOL, "count": 1},
                {"item_id": SSDItemDefs.ITEM_RAW_MUTTON, "count": 1 + (1 if randf() < 0.45 else 0)},
            ]
        "cow":
            return [
                {"item_id": SSDItemDefs.ITEM_LEATHER, "count": 1},
                {"item_id": SSDItemDefs.ITEM_RAW_BEEF, "count": 1 + (1 if randf() < 0.55 else 0)},
            ]
        "chicken":
            return [
                {"item_id": SSDItemDefs.ITEM_FEATHER, "count": 1},
                {"item_id": SSDItemDefs.ITEM_RAW_CHICKEN, "count": 1},
            ]
        _:
            return []

func _ensure_visuals() -> void:
    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision == null:
        collision = CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        var shape: CapsuleShape3D = CapsuleShape3D.new()
        shape.radius = 0.35
        shape.height = 0.9
        collision.shape = shape
        collision.position = Vector3(0.0, 0.55, 0.0)
        add_child(collision)

    if _body == null:
        _body = MeshInstance3D.new()
        _body.name = "Body"
        add_child(_body)
    if _head == null:
        _head = MeshInstance3D.new()
        _head.name = "Head"
        add_child(_head)

    var body_mesh: BoxMesh = BoxMesh.new()
    var head_mesh: BoxMesh = BoxMesh.new()
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.roughness = 1.0

    match mob_type:
        "sheep":
            body_mesh.size = Vector3(0.95, 0.75, 0.58)
            head_mesh.size = Vector3(0.34, 0.32, 0.28)
            _body.position = Vector3(0.0, 0.72, 0.0)
            _head.position = Vector3(0.0, 0.83, 0.52)
            mat.albedo_color = Color(0.94, 0.94, 0.91, 1.0)
        "cow":
            body_mesh.size = Vector3(1.10, 0.82, 0.62)
            head_mesh.size = Vector3(0.42, 0.34, 0.32)
            _body.position = Vector3(0.0, 0.78, 0.0)
            _head.position = Vector3(0.0, 0.82, 0.58)
            mat.albedo_color = Color(0.47, 0.29, 0.16, 1.0)
        "chicken":
            body_mesh.size = Vector3(0.42, 0.46, 0.34)
            head_mesh.size = Vector3(0.22, 0.22, 0.18)
            _body.position = Vector3(0.0, 0.48, 0.0)
            _head.position = Vector3(0.0, 0.76, 0.18)
            mat.albedo_color = Color(0.95, 0.92, 0.84, 1.0)
        _:
            body_mesh.size = Vector3(0.8, 0.6, 0.4)
            head_mesh.size = Vector3(0.3, 0.3, 0.2)
            _body.position = Vector3(0.0, 0.6, 0.0)
            _head.position = Vector3(0.0, 0.8, 0.4)
            mat.albedo_color = Color(0.8, 0.8, 0.8, 1.0)

    _body.mesh = body_mesh
    _head.mesh = head_mesh
    _body.material_override = mat
    _head.material_override = mat
