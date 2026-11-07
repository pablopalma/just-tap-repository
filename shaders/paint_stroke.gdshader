shader_type canvas_item;
// A watercolour stroke along a Line2D (scripts/world/paint_trail.gd): pigment pooled darker at the
// stroke's edges, granulated in the paper's tooth, its edges ragged where the water ran, thinner and
// paler in places like a brush running dry. UV.y goes across the stroke; the world position (taken
// in vertex()) drives the noise, so the texture stays put on the paper as the stroke grows.

uniform float strength = 0.55;   // how much pigment
uniform float seed = 0.0;

varying vec2 world;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(4.1, 1.3);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world = VERTEX;
}

void fragment() {
	float across = abs(UV.y * 2.0 - 1.0);
	// ragged edges: where the water ran, the stroke is wider or narrower
	float ragged = (fbm(world * 0.045) - 0.5) * 0.55 + (fbm(world * 0.21) - 0.5) * 0.2;
	float inside = 1.0 - smoothstep(0.72, 0.98, across + ragged);
	// pigment pools at the edges of a wash, lighter in the middle
	float pool = 0.55 + 0.45 * smoothstep(0.45, 0.85, across + ragged * 0.5);
	// granulation and the brush running dry in places
	float grain = 0.75 + 0.25 * fbm(world * 0.6);
	float dry = 0.65 + 0.35 * smoothstep(0.25, 0.7, fbm(world * 0.012 + 3.0));
	float a = inside * pool * grain * dry * strength;
	COLOR = vec4(COLOR.rgb, a * COLOR.a);
}
