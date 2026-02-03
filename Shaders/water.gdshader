shader_type canvas_item;

uniform vec2 flow_speed = vec2(0.03, 0.0);
uniform vec2 flow_speed_2 = vec2(0.01, 0.0);
uniform float pixel_snap = 64.0;
uniform float mix_strength = 0.35;
uniform float brightness = 1.0;

// Offset to sample your alternate water tile in the atlas
uniform vec2 alt_uv_offset = vec2(0.0, 0.0);

// --- Colour controls ---
uniform vec3 water_color = vec3(0.55, 0.75, 1.0); // bright sky blue
uniform float color_strength = 0.85;

uniform vec3 sunset_tint = vec3(1.0, 0.75, 0.45); // warm golden-orange
uniform float sunset_strength = 0.25;

void fragment() {
    vec2 uv = UV;

    // Pixel snapping for crisp pixel-art
    uv = floor(uv * pixel_snap) / pixel_snap;

    // Two scrolling UV layers
    vec2 uv1 = uv + TIME * flow_speed;
    vec2 uv2 = uv + TIME * flow_speed_2 + alt_uv_offset;

    // Wrap UVs so they never leave 0–1
    uv1 = fract(uv1);
    uv2 = fract(uv2);

    // Prevent sampling tile edges (fixes grey seams)
    uv1 = clamp(uv1, 0.001, 0.999);
    uv2 = clamp(uv2, 0.001, 0.999);

    // Sample atlas
    vec4 c1 = texture(TEXTURE, uv1);
    vec4 c2 = texture(TEXTURE, uv2);

    // Blend the two layers
    vec4 col = mix(c1, c2, mix_strength);

    // Global brightness
    col.rgb *= brightness;

    // --- 1. Light sky-blue base ---
    col.rgb = mix(col.rgb, water_color, color_strength);

    // --- 2. Subtle sunset highlight on bright areas only ---
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    float highlight = smoothstep(0.6, 1.0, luma);
    col.rgb = mix(col.rgb, sunset_tint, highlight * sunset_strength);

    COLOR = col;
}