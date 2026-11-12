shader_type canvas_item;
// One stain of watercolour for tools/rings.gd, opening like the colour coming back
// (colour_wave.gdshader): the pigment floods out from the centre, its front pushed in and out by
// cauliflower blooms, a darker wet edge where the pigment pools, granulation in the paper, pools of
// deeper colour inside and, as it dries, a lighter bloom back from the middle and a few drops
// spattered round it. Drawn on a quad facing the camera; multiplied over the paper, so stains that
// overlap darken each other like layers of watercolour.
render_mode blend_mul;

uniform vec4 tint : source_color = vec4(0.85, 0.55, 0.5, 1.0);
uniform float open = 0.0;     // 0 nothing yet .. 1 open all the way
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float beat = 0.0;     // the front surges a little on every beat, like the colour wave

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

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;                        // the stain's own bit of paper, -1..1
	vec2 q = p * 2.2 + vec2(seed, seed * 1.7);
	// the cauliflower front: the paper's own noise pushes it in and out
	float bloom = ((fbm(q) - 0.5) * 0.75 + (fbm(q * 3.1 + 5.0) - 0.5) * 0.22) * (0.45 + 0.3 * open);
	float r = 0.62 * open + 0.03 * beat * open;
	float d = length(p);
	float x = d + bloom - r;
	float inside = 1.0 - smoothstep(-0.015, 0.0, x);
	float rim_w = 0.04 + 0.02 * open;
	float rim = exp(-(x * x) / (rim_w * rim_w)) * smoothstep(0.0, 0.12, open);
	// pigment inside: deeper pools, granulation
	float pool = fbm(p * 3.0 + seed * 3.0);
	float gran = noise(p * 70.0 + seed) * 0.5 + noise(p * 160.0 - seed) * 0.5;
	float body = inside * (0.22 + 0.3 * pool) * (0.85 + 0.3 * gran);
	// drying: a lighter bloom back from the middle
	body *= 1.0 - 0.3 * smoothstep(0.65, 1.0, open) * (1.0 - smoothstep(0.0, r * 0.75, d + bloom * 0.5));
	float a = body + rim * 0.5 * (0.75 + 0.5 * gran);
	// a few drops spattered round it
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		vec2 dc = vec2(hash(vec2(seed, fi)), hash(vec2(fi + 3.0, seed))) - 0.5;
		dc = normalize(dc + vec2(0.001)) * (0.7 + 0.2 * hash(vec2(seed * 2.0, fi)));
		float dr = 0.02 + 0.035 * hash(vec2(seed + fi, 3.0));
		float when = 0.45 + 0.12 * fi;
		float appear = smoothstep(when, when + 0.15, open);
		float dd = length(p - dc) + (noise(p * 24.0 + fi * 7.0) - 0.5) * 0.02;
		a = max(a, (1.0 - smoothstep(dr * appear * 0.75, dr * appear, dd)) * 0.45 * appear);
	}
	a = clamp(a, 0.0, 1.0) * alpha;
	a *= 1.0 - smoothstep(0.9, 1.0, max(abs(p.x), abs(p.y)));   // never the quad's edge
	vec3 pigment = tint.rgb * (1.0 - 0.3 * rim);              // darker where it pools at the edge
	COLOR = vec4(mix(vec3(1.0), pigment, a), 1.0);
}
