extends Node3D
class_name SSDRemotePlayer

const SSD_PLAYER_MODEL_SCRIPT = preload("res://client/player/SSDPlayerModel.gd")
const TERRAIN_ATLAS: Texture2D = preload("res://assets/textures/blocks/terrain_atlas.png")
const REMOTE_EYE_HEIGHT: float = 1.62

@export var world_model_offset: Vector3 = Vector3(0.0, 0.24, 0.0)

var _model: SSDPlayerModel
var _pivot: Node3D
var _held_root: Node3D
var _held_mesh: MeshInstance3D
var _target_position: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _icon_mesh_cache: Dictionary = {}

func _ready() -> void:
    _target_position = global_position
    _target_yaw = rotation.y
    _ensure_visuals()

func _process(delta: float) -> void:
    global_position = global_position.lerp(_target_position, clampf(delta * 14.0, 0.0, 1.0))
    rotation.y = lerp_angle(rotation.y, _target_yaw, clampf(delta * 14.0, 0.0, 1.0))
    if _pivot != null:
        _pivot.rotation.x = lerp_angle(_pivot.rotation.x, _target_pitch, clampf(delta * 16.0, 0.0, 1.0))

func apply_profile(profile: Dictionary) -> void:
    if _model == null:
        _ensure_visuals()
    if _model != null:
        _model.apply_profile(profile)

func apply_state(world_position: Vector3, yaw: float, pitch: float, held_item_id: int) -> void:
    _target_position = world_position
    _target_yaw = yaw
    _target_pitch = pitch
    _refresh_held_item_visual(held_item_id)

func _ensure_visuals() -> void:
    if _pivot == null:
        _pivot = Node3D.new()
        _pivot.name = "RemotePivot"
        _pivot.position = Vector3(0.0, REMOTE_EYE_HEIGHT, 0.0)
        add_child(_pivot)
    if _model == null:
        _model = SSD_PLAYER_MODEL_SCRIPT.new() as SSDPlayerModel
        _model.name = "RemoteModel"
        _model.render_layer_mask = 2
        _model.position = world_model_offset
        _model.hide_head = false
        add_child(_model)
    if _held_root == null:
        _held_root = Node3D.new()
        _held_root.name = "HeldRoot"
        add_child(_held_root)
    if _held_mesh == null:
        _held_mesh = MeshInstance3D.new()
        _held_mesh.name = "HeldMesh"
        _held_mesh.layers = 2
        _held_root.add_child(_held_mesh)

func _refresh_held_item_visual(item_id: int) -> void:
    if _held_mesh == null:
        return
    if item_id == SSDItemDefs.ITEM_AIR:
        _held_mesh.visible = false
        return

    var render_data: Dictionary = _build_held_render_data(item_id)
    var mesh: Mesh = render_data.get("mesh", null) as Mesh
    var material: Material = render_data.get("material", null) as Material
    var is_block: bool = bool(render_data.get("is_block", false))
    if mesh == null or material == null:
        _held_mesh.visible = false
        return

    _held_mesh.mesh = mesh
    _held_mesh.material_override = material
    if is_block:
        _held_root.position = Vector3(0.31, 0.98, -0.12)
        _held_root.rotation_degrees = Vector3(-76.0, 10.0, 86.0)
        _held_mesh.position = Vector3.ZERO
        _held_mesh.rotation_degrees = Vector3.ZERO
        _held_mesh.scale = Vector3.ONE * 0.22
    else:
        _held_root.position = Vector3(0.31, 0.98, -0.08)
        _held_root.rotation_degrees = Vector3(-84.0, 8.0, 82.0)
        _held_mesh.position = Vector3.ZERO
        _held_mesh.rotation_degrees = Vector3.ZERO
        _held_mesh.scale = Vector3.ONE
    _held_mesh.visible = true

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

    for y: int in range(height):
        for x: int in range(width):
            var px: Color = image.get_pixel(x, y)
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

            if x == 0 or image.get_pixel(x - 1, y).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(left, bottom, -half_depth),
                    Vector3(left, bottom, half_depth),
                    Vector3(left, top, half_depth),
                    Vector3(left, top, -half_depth),
                    Vector3.LEFT,
                    side_color
                )
            if x == width - 1 or image.get_pixel(x + 1, y).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(right, bottom, half_depth),
                    Vector3(right, bottom, -half_depth),
                    Vector3(right, top, -half_depth),
                    Vector3(right, top, half_depth),
                    Vector3.RIGHT,
                    side_color
                )
            if y == 0 or image.get_pixel(x, y - 1).a <= alpha_threshold:
                _append_colored_quad(vertices, normals, colors, indices,
                    Vector3(left, top, half_depth),
                    Vector3(right, top, half_depth),
                    Vector3(right, top, -half_depth),
                    Vector3(left, top, -half_depth),
                    Vector3.UP,
                    Color(px.r * 0.94, px.g * 0.94, px.b * 0.94, px.a)
                )
            if y == height - 1 or image.get_pixel(x, y + 1).a <= alpha_threshold:
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
    material.albedo_texture = TERRAIN_ATLAS
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
