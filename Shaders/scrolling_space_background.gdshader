shader_type canvas_item;

uniform vec2 uv_offset;

void fragment() {
    vec2 uv = UV + uv_offset;
    COLOR = texture(TEXTURE, uv);
}