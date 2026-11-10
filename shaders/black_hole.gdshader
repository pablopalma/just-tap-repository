shader_type canvas_item;
// The sky of tools/spacetime.gd: deep space and, sitting on the horizon, a black hole so big the
// light is a speck before it. Its disk of burning gas crosses in front of the shadow; the disk's far
// side, bent by the hole, shows as an arc over the shadow and a thin one under it; a fine ring of light
// hugs the shadow's edge. The gas turns (streaks moving round), brighter on the side coming towards us.

uniform float aspect = 1.777;
uniform vec2 center = vec2(0.5, 0.3);   // the hole's centre, in UV
uniform float radius = 0.2;            // the shadow's radius, as a fraction of the screen's height
uniform float tilt = 0.13;              // how open the disk is (0: edge on)
uniform vec4 space : source_color = vec4(0.035, 0.04, 0.07, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.93, 0.78, 1.0);
uniform vec4 warm : source_color = vec4(0.89, 0.71, 0.35, 1.0);
uniform float spin = 0.0;               // the gas's turn so far (time)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// streaks of gas going round: noise along the angle, turning with spin, finer further in
float gas(float r, float ang) {
	float a = ang + spin / max(r, 0.6);
	return 0.55 + 0.45 * noise(vec2(a * 6.0, r * 9.0)) * (0.6 + 0.4 * noise(vec2(a * 17.0, r * 31.0)));
}

// how bright the disk is at distance r (in shadow radii) from the centre: hot inside, fading out
float disk_glow(float r) {
	return smoothstep(1.35, 1.7, r) * exp(-(r - 1.7) * 0.42);
}

void fragment() {
	vec2 q = vec2((UV.x - center.x) * aspect, UV.y - center.y) / radius;   // in shadow radii, y down
	float r = length(q);
	vec3 col = space.rgb;
	// stars, a few, twinkling faintly
	vec2 cell = floor(UV * vec2(aspect, 1.0) * 140.0);
	float st = hash(cell);
	if (st > 0.985) {
		vec2 f = fract(UV * vec2(aspect, 1.0) * 140.0) - 0.5;
		col += vec3(0.8, 0.85, 1.0) * smoothstep(0.25, 0.0, length(f)) * (st - 0.985) * 50.0;
	}
	// a wide soft glow of the hole's light on the space around it
	col += warm.rgb * 0.18 * exp(-max(r - 1.0, 0.0) * 0.55);
	// the far side of the disk, bent over the top of the shadow (and a thinner image under it)
	float side = clamp(0.5 - q.x / (r + 0.001) * 0.45, 0.2, 1.0);   // the side coming towards us, brighter
	float ang = atan(q.y, q.x);
	float up = smoothstep(0.0, -0.35, q.y);                          // over the shadow
	float arc_r = r - 1.0;
	// sharp at the shadow, fading outwards; it wraps all the way down to the disk on either side
	float arc = smoothstep(0.5, -0.1, q.y) * smoothstep(0.015, 0.05, arc_r) * (exp(-max(arc_r - 0.05, 0.0) * 9.0) + 0.35 * exp(-max(arc_r, 0.0) * 2.2));
	float under = smoothstep(0.0, 0.35, q.y) * smoothstep(0.02, 0.06, arc_r) * exp(-max(arc_r - 0.06, 0.0) * 14.0);
	float bent = (arc + 0.55 * under) * gas(r, ang) * side;
	col += mix(warm.rgb, hot.rgb, smoothstep(0.3, 0.8, bent)) * bent * 2.0;
	// the shadow
	float shadow = smoothstep(1.0, 0.985, r);
	col = mix(col, vec3(0.0), shadow);
	// the thin ring of light hugging it
	col += hot.rgb * exp(-pow((r - 1.015) * 60.0, 2.0)) * 0.9;
	// the near side of the disk, across in front of the shadow: a thin band, wider further out
	float x = abs(q.x);
	float half_h = tilt * (0.5 + 0.5 * smoothstep(0.0, 6.0, x)) + 0.03;
	float band = smoothstep(half_h, half_h * 0.25, abs(q.y - 0.04));
	float along = x < 1.7 ? 1.0 : disk_glow(x);   // in front of the shadow it runs straight across
	float dop = clamp(0.55 - q.x * 0.07, 0.25, 1.0);
	float front = band * along * gas(x, sign(q.x) * 1.7 + q.y * 3.0) * dop * 1.5;
	col = mix(col, mix(warm.rgb, hot.rgb, smoothstep(0.3, 0.9, front)) * 1.25, clamp(front * 1.4, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
