shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_disabled;

uniform sampler2D atlas_tex : source_color, filter_nearest, repeat_disable;
uniform vec3 sun_light_dir = vec3(0.3, 0.9, 0.25);
uniform float world_brightness = 1.0;
uniform float daylight = 1.0;
uniform float ambient_floor = 0.62;
uniform float toon_strength = 0.45;

void fragment() {
    vec4 tex = texture(atlas_tex, UV);
    if (tex.a < 0.5) {
        discard;
    }

    vec3 n = normalize(NORMAL);
    vec3 l = normalize(sun_light_dir);
    float ndl = max(dot(n, l), 0.0);
    float toon = floor(ndl * 3.0 + 0.001) / 3.0;
    float light_term = mix(ndl, toon, toon_strength);
    light_term = ambient_floor + light_term * 0.58;
    light_term *= mix(0.84, 1.08, daylight);

    vec3 base = tex.rgb * COLOR.rgb;
    ALBEDO = clamp(base * light_term * world_brightness, vec3(0.0), vec3(1.0));
    ALPHA = 1.0;
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
}
