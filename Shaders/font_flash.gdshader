shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 base = tex * COLOR;

    // Undo premultiply
    vec3 straight = base.rgb / max(base.a, 0.0001);

    // Flash toward white
    straight = mix(straight, vec3(1.0), flash_amount);

    // Reapply alpha
    vec3 final_rgb = straight * base.a;

    COLOR = vec4(final_rgb, base.a);
}