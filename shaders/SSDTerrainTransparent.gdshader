shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_disabled;

uniform sampler2D atlas_tex : source_color, filter_nearest, repeat_disable;
uniform vec3 sun_light_dir = vec3(0.3, 0.9, 0.25);
uniform float world_brightness = 1.0;
uniform float daylight = 1.0;
uniform float ambient_floor = 0.68;
uniform float toon_strength = 0.35;
uniform vec4 water_uv_rect = vec4(0.0);

bool uv_in_rect(vec2 uv, vec4 rect) {
    return uv.x >= rect.x && uv.x <= rect.x + rect.z && uv.y >= rect.y && uv.y <= rect.y + rect.w;
}

void fragment() {
    vec2 sample_uv = UV;
    bool is_water = uv_in_rect(UV, water_uv_rect);
    if (is_water) {
        vec2 local_uv = (UV - water_uv_rect.xy) / max(water_uv_rect.zw, vec2(0.0001));
        local_uv.x = fract(local_uv.x + TIME * 0.07 + sin((local_uv.y * 10.0) + TIME * 1.6) * 0.03);
        local_uv.y = clamp(local_uv.y + sin((local_uv.x * 12.0) + TIME * 1.3) * 0.02, 0.0, 1.0);
        sample_uv = water_uv_rect.xy + local_uv * water_uv_rect.zw;
    }

    vec4 tex = texture(atlas_tex, sample_uv);
    if (tex.a < 0.01 && !is_water) {
        discard;
    }

    vec3 n = normalize(NORMAL);
    vec3 l = normalize(sun_light_dir);
    float ndl = max(dot(n, l), 0.0);
    float toon = floor(ndl * 3.0 + 0.001) / 3.0;
    float light_term = mix(ndl, toon, toon_strength);
    light_term = ambient_floor + light_term * 0.42;
    light_term *= mix(0.88, 1.04, daylight);

    vec3 base = tex.rgb * COLOR.rgb;
    float alpha = clamp(tex.a * COLOR.a, 0.0, 1.0);
    if (is_water) {
        float fresnel = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 2.0);
        base = mix(base, vec3(0.78, 0.92, 1.0), fresnel * 0.22);
        alpha = max(alpha, 0.70);
    }

    ALBEDO = clamp(base * light_term * world_brightness, vec3(0.0), vec3(1.0));
    ALPHA = alpha;
    ROUGHNESS = 0.92;
    SPECULAR = 0.0;
}
