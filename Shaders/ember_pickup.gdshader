shader_type canvas_item;

uniform float flicker_speed = 6.0;
uniform float flicker_strength = 0.15;
uniform float jitter_strength = 0.2;

void fragment() {
    vec2 uv = UV;

    // Pixel jitter (quantized)
    float jitter = (sin(TIME * flicker_speed + UV.y * 10.0) * jitter_strength);
    uv.x += floor(jitter * 2.0) / 2.0;

    // Base texture
    vec4 col = texture(TEXTURE, uv);

    // Brightness flicker
    float flicker = sin(TIME * flicker_speed) * flicker_strength;
    col.rgb *= 1.0 + flicker;

    COLOR = col;
}
