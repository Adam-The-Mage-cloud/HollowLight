shader_type canvas_item;

uniform vec2 flow_speed = vec2(0.03, 0.0);
uniform vec2 flow_speed_2 = vec2(0.01, 0.0);
uniform float pixel_snap = 64.0;
uniform float mix_strength = 0.35;
uniform float brightness = 1.0;

uniform vec2 alt_uv_offset = vec2(0.0, 0.0);

// Colour controls
uniform vec3 water_color = vec3(0.55, 0.75, 1.0);
uniform float color_strength = 0.85;

uniform vec3 sunset_tint = vec3(1.0, 0.75, 0.45);
uniform float sunset_strength = 0.25;

void fragment() {
    vec2 uv = UV;

    // Pixel snapping
    uv = floor(uv * pixel_snap) / pixel_snap;

    // Base scrolling layer
    vec2 uv1 = fract(uv + TIME * flow_speed);

    // Fake second layer using UV distortion instead of a second texture sample
    vec2 uv2 = uv1 + (sin((uv + TIME * flow_speed_2) * 6.283) * 0.01) + alt_uv_offset;

    // Sample only once
    vec4 c1 = texture(TEXTURE, uv1);

    // Fake the second layer by reusing the same sample with offset UVs
    vec4 c2 = texture(TEXTURE, fract(uv2));

    // Blend
    vec4 col = mix(c1, c2, mix_strength);

    // Brightness
    col.rgb *= brightness;

    // Water tint
    col.rgb = mix(col.rgb, water_color, color_strength);

    // Sunset tint on bright areas (cheap version)
    float highlight = max(max(col.r, col.g), col.b);
    highlight = smoothstep(0.6, 1.0, highlight);
    col.rgb = mix(col.rgb, sunset_tint, highlight * sunset_strength);

    COLOR = col;
}