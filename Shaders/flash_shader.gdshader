shader_type canvas_item;

// Theme Tint Colour :
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Flash effect
    vec4 out_color = mix(tex, vec4(1.0, 1.0, 1.0, tex.a), flash_amount);

    // Tint applied AFTER flash
    if (tint_amount > 0.0) {
        out_color.rgb = mix(out_color.rgb, tint_color, tint_amount);
    }

    COLOR = out_color;
}
