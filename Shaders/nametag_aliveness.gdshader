shader_type canvas_item;

uniform float amplitude = 0.425;
uniform float speed = 1.2;

void fragment() {
    float offset = sin(TIME * speed) * amplitude / 100.0;
    COLOR = texture(TEXTURE, UV + vec2(0.0, offset));
}
