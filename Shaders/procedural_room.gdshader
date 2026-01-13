shader_type canvas_item;

uniform vec2 spotlight_pos = vec2(0.5, 0.5);

uniform float spotlight_width_px = 37000.0;
uniform float falloff_px = 9000.0;

uniform float darkness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 darkness_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const float TARGET_ASPECT = 16.0 / 9.0;

void fragment() {
    vec2 screen_size = vec2(float(SCREEN_PIXEL_SIZE.x), float(SCREEN_PIXEL_SIZE.y));
    vec2 center_px = spotlight_pos * screen_size;
    vec2 pos_px = SCREEN_UV * screen_size;

    vec2 rel = pos_px - center_px;

    float screen_aspect = screen_size.x / screen_size.y;
    if (screen_aspect > TARGET_ASPECT) {
        rel.x *= screen_aspect / TARGET_ASPECT;
    } else {
        rel.y *= TARGET_ASPECT / screen_aspect;
    }

    float dist = max(abs(rel.x), abs(rel.y));
    float mask = smoothstep(spotlight_width_px, spotlight_width_px - falloff_px, dist);

    COLOR = vec4(darkness_color.rgb, mask * darkness_color.a * darkness);
}
