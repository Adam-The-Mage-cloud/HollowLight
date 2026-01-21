shader_type canvas_item;

// Noise texture
uniform sampler2D noise_texture : repeat_enable, filter_nearest;

// Fog density
uniform float density : hint_range(0.0, 1.0) = 0.25;

// Fog speed
uniform vec2 speed = vec2(0.02, 0.01);

void fragment() {
    // --- PIXEL SNAP ---
    // Snap the base UV to texel boundaries to avoid subpixel sampling
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 snapped_uv = floor(UV * tex_size) / tex_size;

    // --- MIST UV ---
    // Move the fog independently (still snapped)
    vec2 fog_uv = snapped_uv + speed * TIME;

    // Sample noise (nearest filter avoids blur)
    float noise = texture(noise_texture, fog_uv).r;

    // Convert noise to fog alpha
    float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

    // Sample the base texture using snapped UV
    vec4 base = texture(TEXTURE, snapped_uv);

    // Apply fog
    base.a *= fog * density;
	
	float dither = fract(sin(dot(floor(UV * 256.0), vec2(12.9898,78.233))) * 43758.5453);
	base.rgb += (dither - 0.5) * 0.02;

    COLOR = base * COLOR;
}