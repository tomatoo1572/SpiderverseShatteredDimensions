extends Node3D
class_name SSDBlockSelector

@export var max_distance: float = 8.0

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D as MeshInstance3D

var _world: SSDWorld
var _camera: Camera3D
var _has_selection: bool = false
var _selected_block: Vector3i = Vector3i.ZERO
var _has_place_target: bool = false
var _place_block: Vector3i = Vector3i.ZERO

func _ready() -> void:
    _build_outline_mesh()
    visible = false

func set_targets(world: SSDWorld, camera: Camera3D) -> void:
    _world = world
    _camera = camera

func _physics_process(_delta: float) -> void:
    if _world == null or _camera == null:
        visible = false
        _has_selection = false
        _has_place_target = false
        return

    _update_selection()

func has_selection() -> bool:
    return _has_selection

func get_selected_block() -> Vector3i:
    return _selected_block

func has_place_target() -> bool:
    return _has_place_target

func get_place_block() -> Vector3i:
    return _place_block

func _update_selection() -> void:
    var origin: Vector3 = _camera.global_position
    var direction: Vector3 = (-_camera.global_basis.z).normalized()
    var hit_result: Dictionary = _raycast_voxels(origin, direction, max_distance)

    if hit_result.is_empty():
        _has_selection = false
        _has_place_target = false
        visible = false
        return

    _selected_block = hit_result.get("hit", Vector3i.ZERO)
    _place_block = hit_result.get("place", Vector3i.ZERO)
    _has_selection = true
    _has_place_target = hit_result.get("has_place", false)
    visible = true
    global_position = Vector3(
        float(_selected_block.x) * SSDChunkConfig.VOXEL_SIZE,
        float(_selected_block.y) * SSDChunkConfig.VOXEL_SIZE,
        float(_selected_block.z) * SSDChunkConfig.VOXEL_SIZE
    )

func _raycast_voxels(origin: Vector3, direction: Vector3, max_dist: float) -> Dictionary:
    var voxel_size: float = SSDChunkConfig.VOXEL_SIZE
    var pos: Vector3 = origin / voxel_size
    var current: Vector3i = Vector3i(floori(pos.x), floori(pos.y), floori(pos.z))
    var previous_empty: Vector3i = current

    if _is_solid(current):
        return {
            "hit": current,
            "place": current,
            "has_place": false,
        }

    var step_x: int = 1 if direction.x > 0.0 else -1 if direction.x < 0.0 else 0
    var step_y: int = 1 if direction.y > 0.0 else -1 if direction.y < 0.0 else 0
    var step_z: int = 1 if direction.z > 0.0 else -1 if direction.z < 0.0 else 0

    var t_delta_x: float = INF if is_zero_approx(direction.x) else abs(1.0 / direction.x)
    var t_delta_y: float = INF if is_zero_approx(direction.y) else abs(1.0 / direction.y)
    var t_delta_z: float = INF if is_zero_approx(direction.z) else abs(1.0 / direction.z)

    var t_max_x: float = _initial_t_max(pos.x, direction.x, current.x)
    var t_max_y: float = _initial_t_max(pos.y, direction.y, current.y)
    var t_max_z: float = _initial_t_max(pos.z, direction.z, current.z)

    var traveled: float = 0.0
    while traveled <= max_dist:
        previous_empty = current

        if t_max_x < t_max_y and t_max_x < t_max_z:
            current.x += step_x
            traveled = t_max_x
            t_max_x += t_delta_x
        elif t_max_y < t_max_z:
            current.y += step_y
            traveled = t_max_y
            t_max_y += t_delta_y
        else:
            current.z += step_z
            traveled = t_max_z
            t_max_z += t_delta_z

        if _is_solid(current):
            return {
                "hit": current,
                "place": previous_empty,
                "has_place": true,
            }

    return {}

func _initial_t_max(position_axis: float, direction_axis: float, current_axis: int) -> float:
    if is_zero_approx(direction_axis):
        return INF

    if direction_axis > 0.0:
        return (float(current_axis + 1) - position_axis) / direction_axis

    return (position_axis - float(current_axis)) / -direction_axis

func _is_solid(cell: Vector3i) -> bool:
    var block_id: int = _world.get_block_global(cell.x, cell.y, cell.z)
    return SSDVoxelDefs.is_solid(block_id)

func _build_outline_mesh() -> void:
    var epsilon: float = 0.004
    var thickness: float = 0.022
    var min_pos: Vector3 = Vector3(-epsilon, -epsilon, -epsilon)
    var max_pos: Vector3 = Vector3(1.0 + epsilon, 1.0 + epsilon, 1.0 + epsilon)

    var surface_tool: SurfaceTool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    var corners: Array[Vector3] = [
        Vector3(min_pos.x, min_pos.y, min_pos.z),
        Vector3(max_pos.x, min_pos.y, min_pos.z),
        Vector3(max_pos.x, max_pos.y, min_pos.z),
        Vector3(min_pos.x, max_pos.y, min_pos.z),
        Vector3(min_pos.x, min_pos.y, max_pos.z),
        Vector3(max_pos.x, min_pos.y, max_pos.z),
        Vector3(max_pos.x, max_pos.y, max_pos.z),
        Vector3(min_pos.x, max_pos.y, max_pos.z),
    ]

    var edges: Array[Array] = [
        [corners[0], corners[1]], [corners[1], corners[2]], [corners[2], corners[3]], [corners[3], corners[0]],
        [corners[4], corners[5]], [corners[5], corners[6]], [corners[6], corners[7]], [corners[7], corners[4]],
        [corners[0], corners[4]], [corners[1], corners[5]], [corners[2], corners[6]], [corners[3], corners[7]],
    ]

    for edge: Array in edges:
        _append_edge_prism(surface_tool, edge[0] as Vector3, edge[1] as Vector3, thickness)

    _mesh_instance.mesh = surface_tool.commit()

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(0.03, 0.03, 0.03, 1.0)
    material.no_depth_test = false
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _mesh_instance.material_override = material
    _mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _append_edge_prism(surface_tool: SurfaceTool, start: Vector3, end: Vector3, thickness: float) -> void:
    var half: float = thickness * 0.5
    var min_v: Vector3 = Vector3(minf(start.x, end.x), minf(start.y, end.y), minf(start.z, end.z))
    var max_v: Vector3 = Vector3(maxf(start.x, end.x), maxf(start.y, end.y), maxf(start.z, end.z))

    if not is_equal_approx(start.x, end.x):
        min_v.y -= half
        max_v.y += half
        min_v.z -= half
        max_v.z += half
    elif not is_equal_approx(start.y, end.y):
        min_v.x -= half
        max_v.x += half
        min_v.z -= half
        max_v.z += half
    else:
        min_v.x -= half
        max_v.x += half
        min_v.y -= half
        max_v.y += half

    _append_box(surface_tool, min_v, max_v)

func _append_box(surface_tool: SurfaceTool, min_v: Vector3, max_v: Vector3) -> void:
    var p000: Vector3 = Vector3(min_v.x, min_v.y, min_v.z)
    var p100: Vector3 = Vector3(max_v.x, min_v.y, min_v.z)
    var p110: Vector3 = Vector3(max_v.x, max_v.y, min_v.z)
    var p010: Vector3 = Vector3(min_v.x, max_v.y, min_v.z)
    var p001: Vector3 = Vector3(min_v.x, min_v.y, max_v.z)
    var p101: Vector3 = Vector3(max_v.x, min_v.y, max_v.z)
    var p111: Vector3 = Vector3(max_v.x, max_v.y, max_v.z)
    var p011: Vector3 = Vector3(min_v.x, max_v.y, max_v.z)

    _add_quad(surface_tool, p000, p100, p110, p010)
    _add_quad(surface_tool, p101, p001, p011, p111)
    _add_quad(surface_tool, p001, p000, p010, p011)
    _add_quad(surface_tool, p100, p101, p111, p110)
    _add_quad(surface_tool, p010, p110, p111, p011)
    _add_quad(surface_tool, p001, p101, p100, p000)

func _add_quad(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    surface_tool.add_vertex(a)
    surface_tool.add_vertex(b)
    surface_tool.add_vertex(c)
    surface_tool.add_vertex(a)
    surface_tool.add_vertex(c)
    surface_tool.add_vertex(d)
