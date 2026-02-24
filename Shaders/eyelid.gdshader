shader_type canvas_item;

uniform float open_amount : hint_range(0.0, 1.0) = 0.0;
uniform float vertical_scale : hint_range(0.5, 2.0) = 1.4;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

// NEW: lets you choose grey, brown, skin tone, etc.
uniform vec3 lid_color : source_color = vec3(0.15, 0.15, 0.15);

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    uv.y *= vertical_scale;

    float dist = length(uv);

    float mask = smoothstep(open_amount, open_amount + 0.05, dist);

    float alpha = mask * fade;

    // Use your chosen color instead of pure black
    COLOR = vec4(lid_color, alpha);
}