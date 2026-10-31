shader_type canvas_item;
// The demo's dark. Two parts:
//   invert: the world turns to its negative, like a photograph — black paper, white ink — the dark
//           stretch of the demo (0 normal .. 1 white on black).
//   amount: ink darkness creeping in from the edges, with a ragged, slowly moving front
//           (0 nothing .. 1 only a small clearing left around the centre).

uniform float amount = 0.0;
uniform float invert = 0.0;
uniform vec4 ink : source_color = vec4(0.12, 0.11, 0.11, 1.0);
uniform vec2 centre = vec2(0.5, 0.56);
uniform sampler2D screen : hint_screen_texture, filter_linear;

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
		p = p * 2.07 + vec2(11.0, 5.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = UV - centre;
	p.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float d = length(p);
	float n = fbm(FRAGCOORD.xy / 180.0 + vec2(TIME * 0.04, -TIME * 0.03));
	float reach = mix(1.25, 0.16, amount);
	float x = d + (n - 0.5) * 0.28 - reach;
	float dark = smoothstep(-0.06, 0.12, x) * amount * 0.94;
	if (invert > 0.001) {
		// White on black: the paper's light becomes the dark, the ink becomes light. Colour drains.
		vec3 c = texture(screen, SCREEN_UV).rgb;
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		float neg = pow(clamp((1.0 - lum - 0.04) / 0.9, 0.0, 1.0), 0.8);
		vec3 night = vec3(neg) * vec3(0.93, 0.94, 0.97) + vec3(0.025, 0.025, 0.03);
		vec3 col = mix(c, night, invert);
		col = mix(col, ink.rgb * 0.4, dark);
		COLOR = vec4(col, 1.0);
	} else {
		COLOR = vec4(ink.rgb, dark);
	}
}
