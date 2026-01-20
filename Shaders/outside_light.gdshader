shader_type canvas_item;

uniform float softness = 0.25; // how much the edges fade

void fragment() {
    vec2 uv = UV;

    // Distance to nearest edge of the square
    float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

    // Normalize edge distance (0 at edge, 1 at center)
    float fade = smoothstep(0.0, softness, edge_dist);

    // Use original texture color but override alpha with fade
    vec4 tex = texture(TEXTURE, uv);
    tex.a *= fade;

    COLOR = tex;
}