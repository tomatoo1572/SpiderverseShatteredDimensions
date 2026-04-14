extends Node3D
class_name SSDSchematicPreview

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D

func _ready() -> void:
    _mesh_instance = MeshInstance3D.new()
    _mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_mesh_instance)
    _material = StandardMaterial3D.new()
    _material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _material.albedo_color = Color(0.35, 0.95, 1.0, 0.24)
    _material.emission_enabled = true
    _material.emission = Color(0.20, 0.85, 1.0, 1.0)
    _material.emission_energy_multiplier = 0.5
    _mesh_instance.material_override = _material
    visible = false

func build_from_schematic(data: Dictionary, origin: Vector3i) -> void:
    if data.is_empty():
        clear_preview()
        return
    var palette: Array = data.get("palette", [])
    var blocks: Array = data.get("blocks", [])
    if blocks.is_empty():
        clear_preview()
        return
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for entry_variant in blocks:
        if typeof(entry_variant) != TYPE_DICTIONARY:
            continue
        var entry: Dictionary = entry_variant
        var palette_index: int = int(entry.get("p", 0))
        if palette_index < 0 or palette_index >= palette.size():
            continue
        var block_id: int = int(palette[palette_index])
        if block_id == SSDVoxelDefs.BlockId.AIR:
            continue
        var pos := origin + Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
        _append_box(st, Vector3(pos), Vector3(pos) + Vector3.ONE)
    _mesh_instance.mesh = st.commit()
    visible = _mesh_instance.mesh != null

func clear_preview() -> void:
    visible = false
    if _mesh_instance != null:
        _mesh_instance.mesh = null

func _append_box(st: SurfaceTool, min_v: Vector3, max_v: Vector3) -> void:
    var p000 := Vector3(min_v.x, min_v.y, min_v.z)
    var p100 := Vector3(max_v.x, min_v.y, min_v.z)
    var p110 := Vector3(max_v.x, max_v.y, min_v.z)
    var p010 := Vector3(min_v.x, max_v.y, min_v.z)
    var p001 := Vector3(min_v.x, min_v.y, max_v.z)
    var p101 := Vector3(max_v.x, min_v.y, max_v.z)
    var p111 := Vector3(max_v.x, max_v.y, max_v.z)
    var p011 := Vector3(min_v.x, max_v.y, max_v.z)
    _add_quad(st, p000, p100, p110, p010)
    _add_quad(st, p101, p001, p011, p111)
    _add_quad(st, p001, p000, p010, p011)
    _add_quad(st, p100, p101, p111, p110)
    _add_quad(st, p010, p110, p111, p011)
    _add_quad(st, p001, p101, p100, p000)

func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
    var normal := Plane(a, b, c).normal
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(d)
