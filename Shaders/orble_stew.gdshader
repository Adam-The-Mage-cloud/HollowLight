shader_type canvas_item;

uniform float wobble_strength = 0.015;
uniform float wobble_speed = 0.8;
uniform float heat_distort = 0.01;

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    float t = TIME * wobble_speed;

    float n = noise(uv * 3.0 + t);
    uv += (n - 0.5) * wobble_strength;

    COLOR = texture(TEXTURE, uv);

    float heat = noise(vec2(uv.x * 10.0, t * 2.0));
    uv.y += (heat - 0.5) * heat_distort;
}