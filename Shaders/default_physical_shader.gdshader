shader_type canvas_item;

// -------------------------
// Fire Flash (ignition burst)
// -------------------------
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color = vec3(1.0, 0.75, 0.3); // bright fire flash

// -------------------------
// White Susceptible Flash
// -------------------------
uniform float susceptible_flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 susceptible_flash_color = vec3(1.0, 0.75, 0.3); // bright fire flash

// -------------------------
// Burn-Away
// -------------------------
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D burn_noise;
uniform float burn_edge_width = 0.15;
uniform vec3 burn_edge_color = vec3(0.95, 0.40, 0.09); // slightly darker bright ember

// -------------------------
// Charred Outline
// -------------------------
uniform float char_width = 0.08;
uniform vec3 char_color = vec3(0.1, 0.05, 0.02);

// -------------------------                        
// Charcoal Crumble
// -------------------------
uniform float crumble_strength = 1.0;
uniform float crumble_fade = 0.6;

void fragment() {
    vec2 uv = clamp(UV, vec2(0.001), vec2(0.999));
    vec4 tex = texture(TEXTURE, uv);
    vec4 out_color = tex;

    if (tex.a >= 0.1) {

        float noise = texture(burn_noise, uv).r;
        noise *= tex.a;

        float threshold = burn_amount * 3.0 ;

        // -------------------------
        // CHARCOAL CRUMBLE (smooth fade)
        // -------------------------
        if (noise < threshold - burn_edge_width) {

            float crumble = texture(burn_noise, uv * 1.5 + vec2(0.0, TIME * 0.1)).r;

            float shift = floor(crumble * crumble_strength) / 64.0;
            vec2 crumble_uv = uv + vec2(0.0, shift);

            vec4 ash = texture(TEXTURE, crumble_uv);
            ash.rgb *= 0.15;

            float crumble_progress = clamp(noise / threshold, 0.0, 1.0);
            float fade = smoothstep(0.0, 1.0, crumble_progress);
            fade = 1.0 - fade;
            fade *= crumble_fade;

            // force fade to zero as burn completes
            fade *= (1.0 - burn_amount);

            out_color = vec4(ash.rgb, ash.a * fade);

        // -------------------------
        // GLOWING BURN EDGE
        // -------------------------
        } else if (noise < threshold) {

            float edge = smoothstep(threshold - burn_edge_width, threshold, noise);

            vec3 glow = burn_edge_color * (edge * 2.0);
            float glow_alpha = edge * 1.5;

            out_color = vec4(glow, glow_alpha);

        // -------------------------
        // CHARRED OUTLINE (fades out)
        // -------------------------
        } else if (noise < threshold + char_width) {

            float char_progress = (noise - threshold) / char_width;
            char_progress = clamp(char_progress, 0.0, 1.0);

            float char_fade = 1.0 - smoothstep(0.0, 1.0, char_progress);

            // fade out completely as burn finishes
            char_fade *= (1.0 - burn_amount);

            out_color = vec4(char_color, tex.a * char_fade);

        // -------------------------
        // PATCHY FIRE FLASH (dark → bright)
        // -------------------------
        } else {

            float flash_mask = texture(burn_noise, uv).r;

            if (flash_mask > 0.5) {

                // dark-to-bright flash curve
                float flash_curve = flash_amount * flash_amount;

                // darker initial flash
                vec3 dark_flash = flash_color * 0.5;

                // blend dark → bright
                vec3 flash_mix = mix(dark_flash, flash_color, flash_curve);

                vec4 fire_flash = vec4(flash_mix, tex.a);
                out_color = mix(tex, fire_flash, flash_curve);

            } else {
                out_color = tex;
            }
        }
    }
	// -------------------------
	// SECOND FLASH (susceptible flash)
	// -------------------------
	if (susceptible_flash_amount > 0.0) {
	    float s_curve = susceptible_flash_amount * susceptible_flash_amount;

	    // mix original tex with the susceptible flash color
	    vec3 s_mix = mix(tex.rgb, susceptible_flash_color, s_curve);

	    // overlay it on top of whatever out_color currently is
	    out_color.rgb = mix(out_color.rgb, s_mix, s_curve);
	}
    COLOR = out_color;
}