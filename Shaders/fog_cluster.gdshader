shader_type canvas_item;

uniform float noise_scale = 2.0;
uniform float distortion_amount = 0.25;
uniform float softness = 1.8;
uniform float intensity = 0.6;
uniform float time_scale = 0.15;

uniform sampler2D noise_tex;

void fragment() {
    vec2 uv = UV * noise_scale;

    float t = TIME * time_scale;

    // Distort UVs for organic wobble
    float d1 = texture(noise_tex, uv + vec2(t * 0.2, t * 0.1)).r;
    float d2 = texture(noise_tex, uv - vec2(t * 0.15, t * 0.25)).r;
    float distortion = (d1 - d2) * distortion_amount;

    uv += distortion;

    // Sample noise for fog density
    float n = texture(noise_tex, uv).r;

    // Soft radial fade so the blob has a natural edge
    float dist = distance(UV, vec2(0.5));
    float radial = pow(1.0 - dist, softness);

    float fog = n * radial * intensity;

    COLOR = vec4(vec3(1.0), fog);
}