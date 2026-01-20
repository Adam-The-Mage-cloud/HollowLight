shader_type canvas_item;

uniform float speed1 = 0.02;
uniform float speed2 = 0.015;
uniform float intensity = 0.35;
uniform float scale = 2.5;

uniform sampler2D noise_tex1;
uniform sampler2D noise_tex2;

void fragment() {
    vec2 uv = UV * scale;

    float t = TIME * 0.1;

    float n1 = texture(noise_tex1, uv + vec2(t * speed1, 0.0)).r;
    float n2 = texture(noise_tex2, uv + vec2(0.0, t * speed2)).r;

    float fog = (n1 + n2) * 0.5;

    fog = pow(fog, 1.8);

    COLOR = vec4(vec3(1.0), fog * intensity);
}