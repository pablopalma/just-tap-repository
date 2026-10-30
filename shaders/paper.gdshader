shader_type canvas_item;
// Paper background (design doc §8): grain, large soft tonal blotches, faint fibres and a warm vignette.
// Fixed to the screen, so it never needs redrawing.

uniform vec4 paper : source_color = vec4(0.922, 0.902, 0.871, 1.0);
uniform vec4 vignette : source_color = vec4(0.431, 0.392, 0.353, 0.3);

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

void fragment() {
	vec2 px = FRAGCOORD.xy;
	vec3 col = paper.rgb;
	col += (hash(floor(px)) - 0.5) * (12.0 / 255.0);
	float blot = noise(px / 380.0) * 0.6 + noise(px / 170.0) * 0.4;
	col -= (blot - 0.5) * 0.035;
	vec2 fp = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * px;
	float fibre = noise(vec2(fp.x / 2.5, fp.y / 22.0));
	col -= smoothstep(0.9, 1.0, fibre) * 0.012;
	float d = distance(UV, vec2(0.5));
	col = mix(col, vignette.rgb, smoothstep(0.38, 0.85, d) * vignette.a);
	COLOR = vec4(col, 1.0);
}
