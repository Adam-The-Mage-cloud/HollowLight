shader_type canvas_item;

// -------------------------
// Theme Tint Colour
// -------------------------
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;

// -------------------------
// Fire Flash (ignition burst)
// -------------------------
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color = vec3(1.0, 0.75, 0.3);

// -------------------------
// White Susceptible Flash
// -------------------------
uniform float susceptible_flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 susceptible_flash_color = vec3(1.0, 0.75, 0.3);

// -------------------------
// Burn-Away
// -------------------------
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D burn_noise;
uniform float burn_edge_width = 0.15;
uniform vec3 burn_edge_color = vec3(0.95, 0.40, 0.09);

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

// -------------------------
// Ultra-Light Cloud Distortion + Dissolve
// -------------------------
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_speed = 1.0;
uniform float cloud_scale = 3.0;
uniform float cloud_dissolve = 0.0;

// Single cheap noise texture
uniform sampler2D cloud_noise;

void fragment() {
    vec2 uv = UV;
    vec2 distorted_uv = uv;

    // -------------------------
    // ALIVE SHADOW CLOUD DISTORTION (Mobile-Safe)
    // -------------------------
    if (cloud_amount > 0.0) {
        float t = TIME * cloud_speed;

        // Two scrolling noise layers
        float n1 = texture(cloud_noise, uv * cloud_scale + vec2(t * 0.4, t * 0.1)).r;
        float n2 = texture(cloud_noise, uv * (cloud_scale * 0.7) + vec2(-t * 0.2, t * 0.5)).r;

        // Convert to signed noise
        float s1 = n1 * 2.0 - 1.0;
        float s2 = n2 * 2.0 - 1.0;

        // Alive wobble (very cheap)
        float wobble = sin(t * 0.8 + uv.x * 6.0) * 0.02;

        // Stronger, shadow-like distortion
        vec2 warp = vec2(s1 * 0.06, s2 * 0.06);

        distorted_uv += (warp + wobble) * cloud_amount;
    }

    vec4 tex = texture(TEXTURE, distorted_uv);
    vec4 out_color = tex;

    // -------------------------
    // ULTRA-LIGHT CLOUD DISSOLVE
    // -------------------------
    if (cloud_dissolve > 0.0) {
        float t = TIME * cloud_speed * 0.4;

        float d = texture(cloud_noise,
            uv * (cloud_scale * 1.1) + vec2(t, -t * 0.5)
        ).r;

        float dissolve = smoothstep(0.25, 0.75, d);
        out_color.a *= mix(1.0, dissolve, cloud_dissolve);
    }

    // -------------------------
    // ORIGINAL BURN / CRUMBLE / FLASH LOGIC
    // -------------------------
    if (tex.a >= 0.1) {

        float noise_val = texture(burn_noise, uv).r;
        noise_val *= tex.a;

        float threshold = burn_amount * 3.0;

        if (noise_val < threshold - burn_edge_width) {

            float crumble = texture(burn_noise,
                uv * 1.5 + vec2(0.0, TIME * 0.1)).r;

            float shift = floor(crumble * crumble_strength) / 64.0;
            vec2 crumble_uv = uv + vec2(0.0, shift);

            vec4 ash = texture(TEXTURE, crumble_uv);
            ash.rgb *= 0.15;

            float crumble_progress = clamp(noise_val / threshold, 0.0, 1.0);
            float fade = smoothstep(0.0, 1.0, crumble_progress);
            fade = 1.0 - fade;
            fade *= crumble_fade;

            fade *= (1.0 - burn_amount);

            out_color = vec4(ash.rgb, ash.a * fade);

        } else if (noise_val < threshold) {

            float edge = smoothstep(threshold - burn_edge_width, threshold, noise_val);

            vec3 glow = burn_edge_color * (edge * 2.0);
            float glow_alpha = edge * 1.5;

            out_color = vec4(glow, glow_alpha);

        } else if (noise_val < threshold + char_width) {

            float char_progress = (noise_val - threshold) / char_width;
            char_progress = clamp(char_progress, 0.0, 1.0);

            float char_fade = 1.0 - smoothstep(0.0, 1.0, char_progress);
            char_fade *= (1.0 - burn_amount);

            out_color = vec4(char_color, tex.a * char_fade);

        } else {

            float flash_mask = texture(burn_noise, uv).r;

            if (flash_mask > 0.5) {

                float flash_curve = flash_amount * flash_amount;

                vec3 dark_flash = flash_color * 0.5;
                vec3 flash_mix = mix(dark_flash, flash_color, flash_curve);

                vec4 fire_flash = vec4(flash_mix, tex.a);
                out_color = mix(tex, fire_flash, flash_curve);

            } else {
                out_color = tex;
            }
        }
    }

    if (susceptible_flash_amount > 0.0) {
        float s_curve = susceptible_flash_amount * susceptible_flash_amount;
        vec3 s_mix = mix(tex.rgb, susceptible_flash_color, s_curve);
        out_color.rgb = mix(out_color.rgb, s_mix, s_curve);
    }

    if (tint_amount > 0.0) {
        out_color.rgb = mix(out_color.rgb, tint_color, tint_amount);
    }

    COLOR = out_color;
}