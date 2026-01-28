shader_type canvas_item;

// -----------------------------
// TUNING
// -----------------------------
uniform float time_scale      : hint_range(0.0, 4.0)  = 1.0;
uniform float ripple_strength : hint_range(0.0, 0.1)  = 0.02;
uniform float ripple_density  : hint_range(1.0, 20.0) = 6.0;
uniform float ripple_speed    : hint_range(0.1, 5.0)  = 1.0;

// Match this to your *screen* pixel size / zoom.
// e.g. 16 for 16x16 tiles at 1x, 32 for 2x zoom, etc.
uniform float pixel_size      : hint_range(1.0, 64.0) = 16.0;

// Colors
uniform vec3 shallow_color : source_color = vec3(0.16, 0.22, 0.20);
uniform vec3 deep_color    : source_color = vec3(0.05, 0.10, 0.12);

// Foam band along the island edge
// foam_start = where the band begins in UV.y (0 = top, 1 = bottom)
// foam_height = thickness of the band
uniform float foam_start  : hint_range(0.0, 1.0) = 0.0;
uniform float foam_height : hint_range(0.0, 0.5) = 0.08;
uniform float foam_intensity : hint_range(0.0, 0.5) = 0.08;

// Optional subtle shimmer
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.2;

// -----------------------------
// HELPERS
// -----------------------------
float ordered_dither_4x4(ivec2 icoord) {
	int d = (icoord.x % 4) + (icoord.y % 4) * 2;
	return float(d) / 8.0;
}

// -----------------------------
// MAIN
// -----------------------------
void fragment() {
	// Pixel snapping for crisp, non‑shimmery motion
	vec2 uv = floor(UV * pixel_size) / pixel_size;
	float t = TIME * time_scale;

	// Depth fade (top = shallow, bottom = deep)
	float depth = smoothstep(0.0, 1.0, uv.y);
	vec3 base = mix(shallow_color, deep_color, depth);

	// Radial ripples (calm, pond‑like)
	vec2 center = vec2(0.5, 0.5); // center of the TextureRect
	float dist = distance(uv, center);
	float ripple = sin(dist * ripple_density - t * ripple_speed) * ripple_strength;
	base += ripple;

	// Foam band near the island edge (assumed at top of rect)
	// Adjust foam_start / foam_height in the inspector to line up with your shoreline tiles.
	float foam = smoothstep(foam_start, foam_start + foam_height, uv.y);
	base += foam * foam_intensity;

	// Subtle shimmer using ordered dithering so it stays pixel‑art friendly
	ivec2 icoord = ivec2(FRAGCOORD.xy);
	float dither = ordered_dither_4x4(icoord);
	float shimmer = sin((uv.x + uv.y) * 10.0 + t * 2.0);
	shimmer = step(0.95, shimmer) * shimmer_strength;
	shimmer *= step(dither, 0.5); // breaks it into chunky pixels
	base += shimmer;

	COLOR = vec4(base, 1.0);
}