shader_type canvas_item;

// White flash control
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

// Wave controls
uniform float wave_frequency = 30.0;   // how many waves across the sprite
uniform float wave_amplitude = 0.01;   // horizontal distortion
uniform float wave_longitude = 0.01;   // vertical distortion
uniform float wave_speed = 2.0;        // breathing speed

void fragment() {
    // Base UV
    vec2 new_uv = UV;

    // Breathing / wavy distortion
    float wave = sin(new_uv.y * wave_frequency + TIME * wave_speed);
    new_uv.x += wave * wave_amplitude * 0.25;
    new_uv.y += wave * wave_longitude * 0.25;

    // Sample base texture
    vec4 tex = texture(TEXTURE, new_uv);

    // White flash blend
    vec4 flash_color = vec4(1.0, 1.0, 1.0, tex.a);
    vec4 final_color = mix(tex, flash_color, flash_amount);

    COLOR = final_color;
}