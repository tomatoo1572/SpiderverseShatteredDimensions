shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha, shadows_disabled;

uniform vec4 line_color : source_color = vec4(0.02, 0.02, 0.02, 0.95);
uniform float line_width : hint_range(0.005, 0.2, 0.001) = 0.035;
uniform float fill_alpha : hint_range(0.0, 0.35, 0.001) = 0.0;

void fragment() {
    vec2 edge_distance = min(UV, vec2(1.0) - UV);
    float edge = 1.0 - step(line_width, min(edge_distance.x, edge_distance.y));
    float alpha = max(fill_alpha, edge * line_color.a);

    if (alpha <= 0.001) {
        discard;
    }

    ALBEDO = line_color.rgb;
    ALPHA = alpha;
}
