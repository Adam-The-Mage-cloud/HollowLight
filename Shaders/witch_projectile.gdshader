shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_tex;

void fragment() {
    vec4 albedo = texture(TEXTURE, UV);
    if (albedo.a <= 0.0) {
        discard;
    }

    // Sample noise (scaled UV for more detail)
    float n = texture(noise_tex, UV * 1.0).r;

    // Dissolve based on reveal
    if (n > reveal) {
        discard;
    }

    COLOR = albedo;
}
