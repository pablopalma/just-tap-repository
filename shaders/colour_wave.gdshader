shader_type canvas_item;
// The colour wave: a full-screen pass over the world (UI stays untouched). Colour spreads from a
// point like wet watercolour on paper: a darker, more saturated wet edge, cauliflower blooms
// along the front, pigment granulation and a slight wet distortion. Waves pulse with the beat.
// Positions are in world space, so the blooms stick to the world while the camera moves.
// "reveal" waves also paint colour back over a drained (grey) world; the others only pass by.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 cam_pos;
uniform float cam_zoom = 1.0;
uniform vec2 view_size = vec2(1280.0, 720.0);
uniform float now = 0.0;
uniform float beat_hz = 1.0;
uniform float drain = 0.0;          // 0 = world in colour, 1 = world grey outside reveal waves
uniform int wave_count = 0;
uniform vec4 waves[8];              // xy world centre, z start time, w 1 = reveal, 0 = pass
uniform vec4 tints[8];              // pigment colour of each wave
uniform float speed = 520.0;        // world units per second
uniform float rim_width = 46.0;
uniform vec4 paper : source_color = vec4(0.922, 0.902, 0.871, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 world = cam_pos + (SCREEN_UV * view_size - view_size * 0.5) / cam_zoom;

	float reveal = 0.0;
	float rim = 0.0;
	vec2 push = vec2(0.0);
	vec3 tint = vec3(0.0);
	float tint_w = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= wave_count) {
			break;
		}
		vec4 w = waves[i];
		float age = now - w.z;
		if (age < 0.0) {
			continue;
		}
		// The front grows in pulses: a little surge on every beat.
		float pulse = 0.5 - 0.5 * cos(age * beat_hz * 6.2831853);
		float r = speed * age + 70.0 * pulse * min(age, 1.0);
		vec2 d = world - w.xy;
		float dist = length(d);
		// Cauliflower edge: the front is pushed in and out by paper-fixed noise.
		float bloom = (fbm(world * 0.0035) - 0.5) * 340.0 + (fbm(world * 0.012) - 0.5) * 80.0;
		float x = dist + bloom - r;
		float inside = 1.0 - smoothstep(-rim_width, 0.0, x);
		if (w.w > 0.5) {
			reveal = max(reveal, inside);
		}
		float fade = clamp(1.0 - (age - 2.5) / 2.5, 0.0, 1.0);
		float ring = exp(-(x * x) / (rim_width * rim_width)) * fade;
		rim = max(rim, ring);
		push += normalize(d + vec2(0.001)) * ring;
		tint += tints[i].rgb * ring;
		tint_w += ring;
	}

	// Wet distortion along the front.
	vec2 uv = SCREEN_UV - push * 0.004;
	vec3 col = textureLod(screen_tex, uv, 0.0).rgb;

	// Drained world: warm grey, like the paper.
	float l = lum(col);
	vec3 grey = mix(vec3(l), paper.rgb * (l / lum(paper.rgb)), 0.35);
	float colour = max(1.0 - drain, reveal);
	vec3 outc = mix(grey, col, colour);

	// Wet edge: pigment pools at the front — darker and more saturated, with granulation.
	float g = noise(world * 0.09) * 0.6 + noise(world * 0.31) * 0.4;
	vec3 sat = mix(vec3(lum(outc)), outc, 1.0 + rim * 1.1);
	vec3 pigment = tint_w > 0.001 ? tint / tint_w : vec3(1.0);
	vec3 pooled = sat * mix(vec3(1.0), pigment, rim * 0.65) * mix(1.0, 0.82, rim) * (1.0 - rim * 0.16 * g);
	outc = mix(outc, pooled, clamp(rim * 1.2, 0.0, 1.0));

	COLOR = vec4(outc, 1.0);
}
