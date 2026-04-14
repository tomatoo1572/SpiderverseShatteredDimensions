extends Node3D
class_name SSDPlayerModel

const MODEL_SCENE: PackedScene = preload("res://assets/models/player/SSDMALE.glb")
const SKIN_TEXTURE: Texture2D = preload("res://assets/textures/player/skin_base.png")
const BOXERS_TEXTURE: Texture2D = preload("res://assets/textures/player/boxers.png")
const BODY_TYPE_TEXTURES: Array[Texture2D] = [
    preload("res://assets/textures/player/body_type_1.png"),
    preload("res://assets/textures/player/body_type_2.png"),
    preload("res://assets/textures/player/body_type_3.png"),
    preload("res://assets/textures/player/body_type_4.png"),
]
const SHIRT_TEXTURE: Texture2D = preload("res://assets/textures/player/shirt_under.png")
const HOODIE_TEXTURE: Texture2D = preload("res://assets/textures/player/hoodie_outer.png")

@export var render_layer_mask: int = 2
@export var skin_tone: Color = Color(0.86, 0.72, 0.62, 1.0)
@export_range(0, 3, 1) var body_type_index: int = 0
@export var model_scale: float = 0.82
@export var hide_head: bool = false
@export var head_cutoff_y: float = 0.70

var _model_instance: Node3D
var _shader: Shader
var _shirt_item_id: int = SSDItemDefs.ITEM_SHIRT_RED
var _jacket_item_id: int = SSDItemDefs.ITEM_HOODIE_RED

func _ready() -> void:
    _build_model_if_needed()

func set_skin_tone(color_value: Color) -> void:
    skin_tone = color_value
    _apply_materials_recursive(_model_instance)

func set_body_type(index: int) -> void:
    body_type_index = clampi(index, 0, BODY_TYPE_TEXTURES.size() - 1)
    _apply_materials_recursive(_model_instance)

func set_shirt_enabled(enabled: bool) -> void:
    _shirt_item_id = SSDItemDefs.ITEM_SHIRT_RED if enabled else SSDItemDefs.ITEM_AIR
    _apply_materials_recursive(_model_instance)

func set_hoodie_enabled(enabled: bool) -> void:
    _jacket_item_id = SSDItemDefs.ITEM_HOODIE_RED if enabled else SSDItemDefs.ITEM_AIR
    _apply_materials_recursive(_model_instance)

func set_shirt_item(item_id: int) -> void:
    _shirt_item_id = item_id
    _apply_materials_recursive(_model_instance)

func set_jacket_item(item_id: int) -> void:
    _jacket_item_id = item_id
    _apply_materials_recursive(_model_instance)

func apply_profile(profile: Dictionary) -> void:
    set_skin_tone(_profile_color(profile))
    set_body_type(int(profile.get("body_type_index", 0)))

func _build_model_if_needed() -> void:
    if _model_instance != null:
        return
    if MODEL_SCENE == null:
        return

    _model_instance = MODEL_SCENE.instantiate() as Node3D
    if _model_instance == null:
        return

    _model_instance.name = "Model"
    _model_instance.scale = Vector3.ONE * model_scale
    add_child(_model_instance)
    _apply_materials_recursive(_model_instance)

func _apply_materials_recursive(node: Node) -> void:
    if node == null:
        return

    if node is MeshInstance3D:
        var mesh_node: MeshInstance3D = node as MeshInstance3D
        mesh_node.layers = render_layer_mask
        mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if render_layer_mask == 4 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        mesh_node.material_override = _make_material()

    for child: Node in node.get_children():
        _apply_materials_recursive(child)

func _make_material() -> ShaderMaterial:
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = _get_shader()
    material.set_shader_parameter("skin_tex", SKIN_TEXTURE)
    material.set_shader_parameter("shirt_tex", SHIRT_TEXTURE)
    material.set_shader_parameter("boxers_tex", BOXERS_TEXTURE)
    material.set_shader_parameter("body_tex", BODY_TYPE_TEXTURES[clampi(body_type_index, 0, BODY_TYPE_TEXTURES.size() - 1)])
    material.set_shader_parameter("hoodie_tex", HOODIE_TEXTURE)
    material.set_shader_parameter("skin_tone", skin_tone)
    material.set_shader_parameter("shirt_enabled", _shirt_item_id == SSDItemDefs.ITEM_SHIRT_RED)
    material.set_shader_parameter("hoodie_enabled", _jacket_item_id == SSDItemDefs.ITEM_HOODIE_RED)
    material.set_shader_parameter("hide_head", hide_head)
    material.set_shader_parameter("head_cutoff_y", head_cutoff_y)
    return material

func _get_shader() -> Shader:
    if _shader != null:
        return _shader

    _shader = Shader.new()
    _shader.code = """
shader_type spatial;
render_mode cull_back, blend_mix, depth_draw_opaque;

uniform sampler2D skin_tex;
uniform sampler2D shirt_tex;
uniform sampler2D boxers_tex;
uniform sampler2D body_tex;
uniform sampler2D hoodie_tex;
uniform vec4 skin_tone : source_color = vec4(0.86, 0.72, 0.62, 1.0);
uniform bool shirt_enabled = true;
uniform bool hoodie_enabled = true;
uniform bool hide_head = false;
uniform float head_cutoff_y = 0.70;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    if (hide_head && local_pos.y > head_cutoff_y) {
        discard;
    }

    vec4 skin_sample = texture(skin_tex, UV);
    vec4 shirt_sample = texture(shirt_tex, UV);
    vec4 boxers_sample = texture(boxers_tex, UV);
    vec4 body_sample = texture(body_tex, UV);
    vec4 hoodie_sample = texture(hoodie_tex, UV);

    vec3 color_value = skin_sample.rgb * skin_tone.rgb;
    color_value = mix(color_value, shirt_sample.rgb, shirt_enabled ? shirt_sample.a : 0.0);
    color_value = mix(color_value, boxers_sample.rgb, boxers_sample.a);
    color_value = mix(color_value, body_sample.rgb, body_sample.a);
    color_value = mix(color_value, hoodie_sample.rgb, hoodie_enabled ? hoodie_sample.a : 0.0);

    float alpha_value = skin_sample.a;
    if (shirt_enabled) {
        alpha_value = max(alpha_value, shirt_sample.a);
    }
    alpha_value = max(alpha_value, boxers_sample.a);
    alpha_value = max(alpha_value, body_sample.a);
    if (hoodie_enabled) {
        alpha_value = max(alpha_value, hoodie_sample.a);
    }

    ALBEDO = color_value;
    ALPHA = alpha_value;
    ROUGHNESS = 1.0;
    SPECULAR = 0.04;
}
"""
    return _shader

func _profile_color(profile: Dictionary) -> Color:
    var color_text: String = str(profile.get("skin_tone", "d3af92"))
    if color_text.begins_with("#"):
        color_text = color_text.substr(1)
    if color_text.length() != 6:
        color_text = "d3af92"
    return Color("#" + color_text)
