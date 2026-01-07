shader_type canvas_item;

// Chromatic aberration controls
uniform bool apply = true;
uniform float amount = 1.0;
uniform sampler2D offset_texture : hint_default_white;

// Wave controls
uniform float wave_frequency = 30.0;   // how many waves across the sprite
uniform float wave_amplitude = 0.01;   // how strong the distortion is
uniform float wave_longitude = 0.01;
uniform float wave_speed = 2.0;        // how fast the wave animates

void fragment() {
    // Base UV
    vec2 new_uv = UV;

		// Apply wavy distortion (horizontal sine wave based on Y)
    		new_uv.x += sin(new_uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude * 0.25;
		new_uv.y += sin(new_uv.y * wave_frequency + TIME * wave_speed) * wave_longitude * 0.25 ;

    // Sample base texture
    vec4 texture_color = texture(TEXTURE, new_uv);
    vec4 color = texture_color;

    if (apply) {


        float adjusted_amount = amount * texture(offset_texture, new_uv).r / 100.0;

        // Apply chromatic aberration with wavy UVs
        color.r = texture(TEXTURE, vec2(new_uv.x + adjusted_amount, new_uv.y)).r;
        color.g = texture(TEXTURE, new_uv).g;
        color.b = texture(TEXTURE, vec2(new_uv.x - adjusted_amount, new_uv.y)).b;
    }

    COLOR = color;
}
