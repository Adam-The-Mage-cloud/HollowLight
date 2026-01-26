shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // The actual color of the text (Label.modulate or Theme font color)
    vec4 base = tex * COLOR;

    // Add brightness on top of the base color
    vec3 flashed = base.rgb + flash_amount;

    COLOR = vec4(flashed, base.a);
}