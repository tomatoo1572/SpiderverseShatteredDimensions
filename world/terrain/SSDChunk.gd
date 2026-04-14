extends StaticBody3D
class_name SSDChunk

var chunk_coords: Vector2i = Vector2i.ZERO
var data: SSDChunkData

var _opaque_mesh_instance: MeshInstance3D
var _transparent_mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _cached_collision_shape: ConcavePolygonShape3D
var _collision_enabled: bool = false
var _last_surface_arrays: Dictionary = {}

func _ready() -> void:
    _ensure_nodes()

func setup(coords: Vector2i, chunk_data: SSDChunkData, opaque_material: Material, transparent_material: Material) -> void:
    chunk_coords = coords
    data = chunk_data
    position = Vector3(float(coords.x * SSDChunkConfig.SIZE_X) * SSDChunkConfig.VOXEL_SIZE, 0.0, float(coords.y * SSDChunkConfig.SIZE_Z) * SSDChunkConfig.VOXEL_SIZE)
    _ensure_nodes()
    _opaque_mesh_instance.material_override = opaque_material
    _transparent_mesh_instance.material_override = transparent_material

func apply_surface_arrays(surface_arrays: Dictionary) -> void:
    _ensure_nodes()
    _last_surface_arrays = surface_arrays.duplicate(true)
    _opaque_mesh_instance.mesh = SSDChunkMesher.create_mesh_from_arrays(surface_arrays.get("opaque", {}))
    _transparent_mesh_instance.mesh = SSDChunkMesher.create_mesh_from_arrays(surface_arrays.get("transparent", {}))
    var chunk_bounds: AABB = AABB(
        Vector3(-1.00, -1.00, -1.00),
        Vector3(
            (SSDChunkConfig.SIZE_X * SSDChunkConfig.VOXEL_SIZE) + 2.0,
            (SSDChunkConfig.SIZE_Y * SSDChunkConfig.VOXEL_SIZE) + 2.0,
            (SSDChunkConfig.SIZE_Z * SSDChunkConfig.VOXEL_SIZE) + 2.0
        )
    )
    _opaque_mesh_instance.custom_aabb = chunk_bounds
    _transparent_mesh_instance.custom_aabb = chunk_bounds
    _cached_collision_shape = null
    if _collision_enabled:
        _apply_collision_state(true)
    else:
        _collision_shape.shape = null

func set_collision_enabled(enabled: bool) -> void:
    _collision_enabled = enabled
    _apply_collision_state(enabled)

func has_collision_enabled() -> bool:
    return _collision_enabled

func _apply_collision_state(enabled: bool) -> void:
    _ensure_nodes()
    if not enabled:
        _collision_shape.shape = null
        return
    if _opaque_mesh_instance.mesh == null and _transparent_mesh_instance.mesh == null:
        _collision_shape.shape = null
        return
    if _cached_collision_shape == null:
        _cached_collision_shape = SSDChunkMesher.create_collision_shape_from_arrays(_last_surface_arrays)
    _collision_shape.shape = _cached_collision_shape

func _ensure_nodes() -> void:
    if _opaque_mesh_instance == null:
        _opaque_mesh_instance = get_node_or_null("OpaqueMesh") as MeshInstance3D
        if _opaque_mesh_instance == null:
            _opaque_mesh_instance = MeshInstance3D.new()
            _opaque_mesh_instance.name = "OpaqueMesh"
            _opaque_mesh_instance.extra_cull_margin = 96.0
            add_child(_opaque_mesh_instance)
    if _transparent_mesh_instance == null:
        _transparent_mesh_instance = get_node_or_null("TransparentMesh") as MeshInstance3D
        if _transparent_mesh_instance == null:
            _transparent_mesh_instance = MeshInstance3D.new()
            _transparent_mesh_instance.name = "TransparentMesh"
            _transparent_mesh_instance.extra_cull_margin = 96.0
            add_child(_transparent_mesh_instance)
    if _collision_shape == null:
        _collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
        if _collision_shape == null:
            _collision_shape = CollisionShape3D.new()
            _collision_shape.name = "CollisionShape3D"
            add_child(_collision_shape)
