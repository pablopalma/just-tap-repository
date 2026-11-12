shader_type canvas_item;
// White mist for tools/rings.gd, a flight into the depth. Two uses of the same pass:
// - behind the rings: a haze that whitens what is far off, thickest at the vanishing point, so the
//   stains and the rings come out of the mist as they near;
// - in front of everything: wisps streaming out from the vanishing point past the camera as you fly,
//   only towards the edges, so the middle stays clear.
// The wisps live in the tunnel's own coordinates (the angle round the vanishing point, and the depth,
// 1 / distance from it), so as `travel` grows they come out of the middle and rush past the edges.

uniform vec2 centre = vec2(0.5, 0.5);   // the vanishing point (UV)
uniform float aspect = 1.7778;
uniform float travel = 0.0;
uniform float haze = 0.5;               // how white the far middle goes
uniform float haze_reach = 0.5;         // how far out from the middle the haze reaches
uniform float wisps = 0.4;
uniform float wisp_from = 0.1;          // the wisps only from this far out (UV) from the middle
uniform vec4 mist : source_color = vec4(0.975, 0.968, 0.955, 1.0);

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

// The wisps at angle u (0..1 round) and depth w: tiling round the circle, so there is no seam.
float cloud(float u, float w) {
	float n = 7.0;
	float a = fbm(vec2(u * n, w));
	float b = fbm(vec2((u - 1.0) * n, w));
	return mix(a, b, smoothstep(0.75, 1.0, u));
}

void fragment() {
	vec2 d = (UV - centre) * vec2(aspect, 1.0);
	float r = length(d) + 0.0001;
	float u = atan(d.y, d.x) / 6.2831853 + 0.5;
	float deep = haze * (1.0 - smoothstep(0.0, haze_reach, r));
	float w = 0.3 / (r + 0.04) + travel;
	float c = cloud(u, w * 0.9);
	float c2 = cloud(fract(u + 0.37), w * 0.55 + 4.0);
	float wisp = smoothstep(0.42, 0.78, c * 0.65 + c2 * 0.35) * smoothstep(wisp_from, wisp_from + 0.25, r);
	float a = clamp(deep + wisp * wisps * (1.0 - deep), 0.0, 0.95);
	COLOR = vec4(mist.rgb, a);
}
