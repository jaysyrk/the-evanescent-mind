shader_type canvas_item;
/// mental_state.gdshader
/// Full-screen post-processing shader driven by WorldVisualManager.
/// Handles: desaturation, oversaturation, chromatic aberration, vignette, screen jitter.

uniform float desaturate    : hint_range(0.0, 1.0) = 0.0;
uniform float oversaturate  : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic     : hint_range(0.0, 1.0) = 0.0;
uniform float vignette      : hint_range(0.0, 1.0) = 0.0;
uniform float jitter        : hint_range(0.0, 0.4) = 0.0;
uniform float time          : hint_range(0.0, 1e6)  = 0.0;

// Simple pseudo-random for jitter
float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// --- Screen jitter (high anxiety) ---
	if (jitter > 0.001) {
		float jitter_y = floor(uv.y * 60.0) / 60.0;
		float offset = (rand(vec2(jitter_y, floor(time * 20.0))) - 0.5) * jitter * 0.02;
		uv.x += offset;
	}

	// --- Chromatic aberration (anxiety) ---
	float ca = chromatic * 0.012;
	vec2 dir = uv - vec2(0.5);
	float ca_strength = length(dir);
	vec4 col;
	col.r = texture(TEXTURE, uv + dir * ca_strength * ca).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - dir * ca_strength * ca).b;
	col.a = texture(TEXTURE, uv).a;

	// --- Desaturation (depressive) ---
	if (desaturate > 0.001) {
		float lum = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
		col.rgb = mix(col.rgb, vec3(lum), desaturate);
		// Slight blue-grey tint at full desaturation
		col.rgb = mix(col.rgb, vec3(lum * 0.85, lum * 0.87, lum * 0.95), desaturate * 0.4);
	}

	// --- Oversaturation (manic) ---
	if (oversaturate > 0.001) {
		float lum = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
		col.rgb = mix(col.rgb, col.rgb + (col.rgb - vec3(lum)) * 1.5, oversaturate * 0.6);
		// Slight warm push when manic
		col.r = mix(col.r, col.r * 1.05, oversaturate * 0.3);
	}

	// --- Vignette (anxiety / depressive) ---
	if (vignette > 0.001) {
		float dist = length(uv - vec2(0.5)) * 1.6;
		float vig = smoothstep(0.4, 1.1, dist) * vignette;
		col.rgb *= 1.0 - vig;
	}

	COLOR = col;
}
