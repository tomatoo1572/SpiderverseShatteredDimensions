extends MeshInstance3D
class_name SSDSkyDome

const SUN_TEXTURE_PATH: String = "res://assets/textures/sky/sun_disc.png"
const MOON_TEXTURE_PATH: String = "res://assets/textures/sky/moon_disc.png"

var _material: ShaderMaterial

func _ready() -> void:
    if mesh == null:
        var sphere: SphereMesh = SphereMesh.new()
        sphere.radius = 2400.0
        sphere.height = 4800.0
        sphere.radial_segments = 48
        sphere.rings = 24
        mesh = sphere

    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    layers = 1
    _material = ShaderMaterial.new()
    _material.shader = Shader.new()
    _material.shader.code = """
shader_type spatial;
render_mode unshaded, cull_front, fog_disabled, depth_draw_never;

uniform vec4 day_top : source_color = vec4(0.14, 0.22, 0.34, 1.0);
uniform vec4 day_horizon : source_color = vec4(0.40, 0.50, 0.64, 1.0);
uniform vec4 night_top : source_color = vec4(0.010, 0.016, 0.034, 1.0);
uniform vec4 night_horizon : source_color = vec4(0.03, 0.05, 0.09, 1.0);
uniform vec4 dawn_tint : source_color = vec4(0.80, 0.48, 0.28, 1.0);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float daylight = 1.0;
uniform float horizon_tint = 0.0;
uniform float time_hours = 12.0;
uniform float brightness = 1.0;
uniform float cloud_opacity = 0.20;
uniform float sun_size = 0.030;
uniform float moon_size = 0.028;
uniform sampler2D sun_tex;
uniform sampler2D moon_tex;

varying vec3 world_dir;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += noise2(p) * amplitude;
        p = p * 2.03 + vec2(7.13, 3.71);
        amplitude *= 0.5;
    }
    return value;
}

vec4 sample_celestial(sampler2D tex, vec3 dir, vec3 center_dir, float size_value) {
    vec3 forward = normalize(center_dir);
    vec3 ref_up = abs(forward.y) > 0.98 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(ref_up, forward));
    vec3 up = normalize(cross(forward, right));

    float forward_dot = dot(dir, forward);
    if (forward_dot <= 0.0) {
        return vec4(0.0);
    }

    vec2 plane = vec2(dot(dir, right), dot(dir, up)) / max(0.0001, forward_dot);
    vec2 uv = plane / size_value * 0.5 + 0.5;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0);
    }
    return texture(tex, uv);
}

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 center_pos = MODEL_MATRIX[3].xyz;
    world_dir = normalize(world_pos - center_pos);
}

void fragment() {
    vec3 dir = normalize(world_dir);
    float h = clamp(pow(max(dir.y * 0.5 + 0.5, 0.0), 0.92), 0.0, 1.0);

    vec3 day_col = mix(day_horizon.rgb, day_top.rgb, h);
    vec3 night_col = mix(night_horizon.rgb, night_top.rgb, h);
    vec3 sky_col = mix(night_col, day_col, daylight);

    float horizon_glow = pow(1.0 - abs(dir.y), 3.0) * horizon_tint;
    sky_col = mix(sky_col, dawn_tint.rgb, horizon_glow * 0.62);

    vec2 cloud_uv = dir.xz / max(0.22, dir.y + 0.38);
    cloud_uv += vec2(time_hours * 0.010, 0.0);
    float cloud_noise = fbm(cloud_uv * 0.78) * 0.70 + fbm(cloud_uv * 1.65 + vec2(13.2, 7.4)) * 0.30;
    float cloud_mask = smoothstep(0.58, 0.76, cloud_noise) * smoothstep(-0.02, 0.20, dir.y);
    vec3 cloud_day = vec3(0.66, 0.70, 0.76);
    vec3 cloud_night = vec3(0.08, 0.09, 0.12);
    vec3 cloud_col = mix(cloud_night, cloud_day, daylight);
    sky_col = mix(sky_col, cloud_col, cloud_mask * cloud_opacity * mix(0.20, 1.0, daylight));

    vec3 n_sun_dir = normalize(sun_dir);
    float sun_dot = dot(dir, n_sun_dir);
    float sun_glow = smoothstep(0.989, 0.9995, sun_dot) * (0.03 + daylight * 0.14);
    sky_col += vec3(0.90, 0.76, 0.52) * sun_glow;

    float moon_dot = dot(dir, -n_sun_dir);
    float moon_glow = smoothstep(0.993, 0.99965, moon_dot) * (1.0 - daylight);
    sky_col += vec3(0.56, 0.62, 0.72) * moon_glow * 0.10;

    vec4 sun_sample = sample_celestial(sun_tex, dir, n_sun_dir, sun_size);
    vec4 moon_sample = sample_celestial(moon_tex, dir, -n_sun_dir, moon_size);
    sky_col = mix(sky_col, sun_sample.rgb, sun_sample.a * clamp(daylight * 1.15, 0.0, 1.0));
    sky_col = mix(sky_col, moon_sample.rgb, moon_sample.a * (1.0 - daylight));

    vec2 star_uv = dir.xz / max(0.08, dir.y + 0.52) * 60.0;
    float star_pick = hash21(floor(star_uv));
    float star_twinkle = 0.78 + 0.22 * sin(time_hours * 1.7 + star_pick * 80.0);
    float stars = step(0.9982, star_pick) * pow(max(dir.y, 0.0), 1.4) * (1.0 - daylight) * star_twinkle;
    sky_col += vec3(stars);

    ALBEDO = clamp(sky_col * brightness, vec3(0.0), vec3(1.0));
}
"""
    material_override = _material

    var sun_texture: Texture2D = load(SUN_TEXTURE_PATH) as Texture2D
    var moon_texture: Texture2D = load(MOON_TEXTURE_PATH) as Texture2D
    if sun_texture != null:
        _material.set_shader_parameter("sun_tex", sun_texture)
    if moon_texture != null:
        _material.set_shader_parameter("moon_tex", moon_texture)

func set_sky_values(daylight: float, horizon_tint: float, sun_direction: Vector3, time_hours: float, brightness: float) -> void:
    if _material == null:
        return
    _material.set_shader_parameter("daylight", clampf(daylight, 0.0, 1.0))
    _material.set_shader_parameter("horizon_tint", clampf(horizon_tint, 0.0, 1.0))
    _material.set_shader_parameter("sun_dir", sun_direction.normalized())
    _material.set_shader_parameter("time_hours", time_hours)
    _material.set_shader_parameter("brightness", clampf(brightness, 0.22, 0.68))
