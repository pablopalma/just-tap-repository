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
// The way through (tools/spacetime.gd's cinematic): inside the hole, the light of every star it
// swallowed streams past, outwards from the centre ahead, twisting; a white light grows there at the end.
// Gravitational lensing: light from behind the hole bends round it. A point of the sky seen at
// distance r (shadow radii) from the centre comes from r - te*te/r: stars and the galaxy's band stretch
// into arcs round the hole, and an Einstein ring of te gathers their light. It grows as you come near.
uniform float te = 1.2;                 // the Einstein ring's radius, in shadow radii
// The hole spins and drags space round with it: the view swirls, more near it (radians at the ring).
uniform float twist = 0.0;
// Falling in, the shadow is no longer empty: the matter inside shows through it, more and more.
uniform float reveal = 0.0;
// Close in (13/11/2026): you are down on the disk. Below the horizon the floor is the disk itself, a
// sea of burning gas out to the horizon, white-hot far off, amber and streaked near; it passes in
// front of the shadow, which stands up over it, huge, to one side; the disk's far side, bent over the
// hole, arcs overhead; the light is blinding. 0 the far view, 1 down on the disk.
uniform float immerse = 0.0;
uniform float horizon = 0.44;           // the eye line on the screen (UV)
uniform float cam_h = 3.6;              // the camera's height over the floor (world)
uniform float focal_k = 0.861;          // the camera's focal length / 720
uniform vec2 cam_pos;                   // where the camera is over the floor (world x, z)
uniform float flow = 0.0;               // how far the gas has turned
uniform float fall = 0.0;               // the fall into it (0..1): the disk sweeps past and is gone
uniform float inside = 0.0;             // 0 the sky as above, 1 the way through
uniform float travel = 0.0;             // seconds inside
uniform float white = 0.0;              // the white light ahead, filling everything

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

// Inside (12/11/2026, after the player's references): dark and quiet, deep teal. Walls of smeared,
// dim light turn round the way through; a few thin star trails rush out; now and then a small nebula
// drifts past in colour; and ahead a sphere of bent space, like a glass ball, holds a whole starfield
// turned round inside it, with a bright rim.
float stars(vec2 p, float density) {
	vec2 c = floor(p);
	float h = hash(c);
	vec2 f = fract(p) - 0.5 - (vec2(hash(c + 3.1), hash(c + 7.7)) - 0.5) * 0.6;
	return step(1.0 - density, h) * smoothstep(0.12, 0.0, length(f)) * (0.4 + 0.6 * hash(c + 1.3));
}

float wall(float wa, float z) {
	return noise(vec2(wa * 9.0, z * 0.35)) * noise(vec2(wa * 23.0 + 4.0, z * 0.9));
}

// The sphere of bent space at the heart of it, a starfield turned round inside it (rgb, and how much
// of it covers this point). It shows in the shadow from the very start, small and still, so going in
// is going towards it.
float sphere_r() {
	return 0.1 + 0.06 * smoothstep(0.0, 14.0, travel);
}

vec4 sphere_view(vec2 d) {
	float r = length(d);
	float R = sphere_r();
	if (r >= R) {
		return vec4(0.0);
	}
	vec2 in_p = d / R;
	float k = sqrt(max(1.0 - dot(in_p, in_p), 0.0));
	vec2 bent = -in_p / (k + 0.35) * 2.2 + travel * 0.05 + vec2(spin * 0.03, 0.0);   // seen through it, upside down
	vec3 c = vec3(0.03, 0.06, 0.07) + vec3(0.95, 0.92, 0.85) * stars(bent * 14.0, 0.2) * 1.4;
	c += vec3(0.55, 0.45, 0.4) * noise(bent * 2.0 + 3.0) * 0.18;             // a nebula far inside
	c += vec3(0.5, 0.6, 0.62) * smoothstep(0.55, 1.0, 1.0 - k) * 0.3;
	return vec4(c, smoothstep(R, R * 0.96, r));
}

// its rim: a thin glint, catching the light only here and there
vec3 sphere_rim(vec2 d) {
	float r = length(d);
	float a = atan(d.y, d.x) / 6.28318 + 0.5;
	float glint = smoothstep(0.45, 0.9, noise(vec2(a * 14.0 + travel * 0.2 + spin * 0.05, 2.0)));
	return vec3(0.75, 0.88, 0.88) * exp(-pow((r - sphere_r()) * 320.0, 2.0)) * (0.12 + 0.6 * glint);
}

vec3 tunnel(vec2 d) {
	float r = length(d) + 0.0001;
	float a = atan(d.y, d.x) / 6.28318 + 0.5;
	float z = 0.3 / r + travel * (1.1 + travel * 0.05);    // depth: what is at the edges rushes past
	vec3 deep = vec3(0.012, 0.03, 0.035);
	vec3 col = deep;
	// the walls: long smears of dim light along the way, turning slowly
	float wa = fract(a + travel * 0.015 + 0.04 / (r + 0.2));
	// blended across the wrap of the angle, so there is no seam where it comes round
	float smear = mix(wall(wa, z), wall(wa - 1.0, z), smoothstep(0.85, 1.0, wa));
	smear = smoothstep(0.25, 0.75, smear) * smoothstep(0.15, 0.55, r);
	col += mix(vec3(0.16, 0.26, 0.27), vec3(0.75, 0.68, 0.55), smoothstep(0.55, 0.95, smear)) * smear * 0.55;
	// thin star trails, few, rushing outwards
	for (int layer = 0; layer < 2; layer++) {
		float cells = 220.0 + 160.0 * float(layer);
		float cell = mod(floor(a * cells), cells);
		float h = hash(vec2(cell, 11.0 + float(layer)));
		float lane = abs(fract(a * cells) - 0.5);
		float along = fract(z * (0.6 + 0.5 * h) + h * 17.0);
		float dash = smoothstep(0.0, 0.02, along) * smoothstep(0.12, 0.02, along);
		float on = step(0.82, h);
		vec3 c = mix(vec3(0.6, 0.85, 0.85), vec3(1.0, 0.9, 0.75), step(0.5, hash(vec2(cell, 2.0))));
		col += c * dash * smoothstep(0.35, 0.0, lane) * on * smoothstep(0.08, 0.4, r) * 0.9;
	}
	// still, far stars between them
	col += vec3(0.75, 0.82, 0.85) * stars(vec2(a * 260.0, z * 3.0), 0.04) * 0.6 * smoothstep(0.1, 0.3, r);
	// a nebula drifting past now and then: a soft cloud of colour on its way out
	for (int k = 0; k < 3; k++) {
		float fk = float(k);
		float life = fract(travel * 0.09 + fk * 0.37);
		float ang = 6.28318 * hash(vec2(floor(travel * 0.09 + fk * 0.37), fk));
		vec2 at = vec2(cos(ang), sin(ang)) * mix(0.05, 1.1, life * life);
		float size = mix(0.02, 0.22, life);
		vec2 e = (d - at) / size;
		float cloud = exp(-dot(e, e) * 1.5) * (0.5 + 0.5 * noise(e * 3.0 + fk));
		vec3 tint = mix(vec3(0.85, 0.42, 0.3), vec3(0.35, 0.5, 0.85), hash(vec2(fk, 5.0)));
		col += tint * cloud * 0.5 * smoothstep(0.0, 0.2, life) * (1.0 - smoothstep(0.75, 1.0, life));
	}
	// ahead: the sphere of bent space (sphere_view), the same one the shadow shows from the start
	vec4 sp = sphere_view(d);
	col = mix(col, sp.rgb, sp.a) + sphere_rim(d);
	// the white light ahead, at the very end
	col += hot.rgb * exp(-r * 7.0) * 2.5 * white;
	return col;
}

// The disk under you, as a floor in perspective, its gas streaming sideways round the hole.
vec4 disk_floor(vec2 uv) {
	float y = uv.y - horizon;
	if (y <= 0.0) {
		return vec4(0.0);
	}
	float z = cam_h * focal_k / y;                              // how far ahead
	float x = (uv.x - 0.5) * aspect * z / focal_k;
	vec2 w = vec2(x + cam_pos.x, z + cam_pos.y);
	// streaks along the flow: stretched across, turning
	// clouds of gas, billowing, a little stretched along the flow
	vec2 f = vec2(w.x * 0.22 + flow, w.y * 0.55);
	float g = noise(f) * 0.45 + noise(f * 2.1 + 7.0) * 0.27 + noise(f * 4.3 + 3.0) * 0.17 + noise(f * 8.9 + 1.0) * 0.11;
	g = smoothstep(0.2, 0.85, g);
	float lanes = smoothstep(0.45, 0.8, noise(vec2(w.x * 0.12 + flow * 1.3, w.y * 0.9) + 11.0));
	float heat = 1.0 - smoothstep(0.0, 0.42, y);              // white-hot towards the horizon
	vec3 ember = vec3(0.62, 0.26, 0.07);
	vec3 col = mix(ember * 0.6, vec3(1.0, 0.7, 0.36), g);
	col *= 0.45 + 0.95 * g;
	col *= 1.0 - 0.55 * lanes * (1.0 - heat);                   // darker lanes in the near gas
	col = mix(col, hot.rgb * 1.1, pow(heat, 1.6));
	return vec4(col, smoothstep(0.0, 0.01, y));
}

// how bright the disk is at distance r (in shadow radii) from the centre: hot inside, fading out
float disk_glow(float r) {
	return smoothstep(1.35, 1.7, r) * exp(-(r - 1.7) * 0.42);
}

void fragment() {
	vec2 q = vec2((UV.x - center.x) * aspect, UV.y - center.y) / radius;   // in shadow radii, y down
	float r = length(q);
	vec3 col = space.rgb;
	// where this point's light really comes from (the lens), and how much brighter it is for it
	float drag = twist / (r * r + 0.3);
	vec2 qt = vec2(q.x * cos(drag) - q.y * sin(drag), q.x * sin(drag) + q.y * cos(drag));
	vec2 s = qt * (1.0 - te * te / max(r * r, 0.0001));
	vec2 src = center + vec2(s.x * radius / aspect, s.y * radius);
	float mag = clamp(1.0 / max(abs(1.0 - pow(te / max(r, 0.0001), 4.0)), 0.001), 1.0, 5.0);
	// stars, a few, twinkling faintly (drawn where their light comes from: near the ring, arcs)
	vec2 cell = floor(src * vec2(aspect, 1.0) * 140.0);
	float st = hash(cell);
	if (st > 0.985 && immerse < 0.98) {
		vec2 f = fract(src * vec2(aspect, 1.0) * 140.0) - 0.5;
		col += vec3(0.8, 0.85, 1.0) * smoothstep(0.25, 0.0, length(f)) * (st - 0.985) * 50.0 * mag;
	}
	// the galaxy's band, far behind: a faint dusty river of light across the sky, bent by the hole
	vec2 g = (src - vec2(0.5, 0.1)) * vec2(aspect, 1.0);   // it passes just above the hole: arcs, not a full ring
	float across = dot(g, normalize(vec2(-0.35, 1.0)));
	float dust = noise(src * vec2(aspect, 1.0) * 7.0) * 0.6 + noise(src * vec2(aspect, 1.0) * 23.0) * 0.4;
	float galaxy = exp(-across * across / 0.018) * (0.35 + 0.65 * dust);
	col += mix(vec3(0.35, 0.42, 0.65), vec3(0.8, 0.68, 0.58), dust) * galaxy * 0.09 * min(mag, 2.5) * (1.0 - immerse);
	// the Einstein ring itself: a thin gathering of all that light
	col += vec3(0.85, 0.88, 1.0) * exp(-pow((r - te) * 14.0, 2.0)) * 0.22 * smoothstep(1.05, 1.4, te) * (1.0 - immerse);
	// a wide soft glow of the hole's light on the space around it
	col += warm.rgb * 0.18 * exp(-max(r - 1.0, 0.0) * 0.55);
	// the far side of the disk, bent over the top of the shadow (and a thinner image under it)
	float side = clamp(0.5 - q.x / (r + 0.001) * 0.45, 0.2, 1.0);   // the side coming towards us, brighter
	float ang = atan(q.y, q.x);
	float up = smoothstep(0.0, -0.35, q.y);                          // over the shadow
	float arc_r = r - 1.0;
	// sharp at the shadow, fading outwards; it wraps all the way down to the disk on either side
	float arc = smoothstep(mix(0.5, 1.4, immerse), -0.1, q.y) * smoothstep(0.015, 0.05, arc_r)
		* (exp(-max(arc_r - 0.05, 0.0) * mix(9.0, 2.2, immerse)) + 0.35 * exp(-max(arc_r, 0.0) * mix(2.2, 0.9, immerse)));
	arc *= 1.0 + immerse * (1.6 * smoothstep(0.35, 0.8, noise(vec2(ang * 9.0 - spin * 2.0, r * 3.0))) - 0.4);
	float under = smoothstep(0.0, 0.35, q.y) * smoothstep(0.02, 0.06, arc_r) * exp(-max(arc_r - 0.06, 0.0) * 14.0);
	float bent = (arc + 0.55 * under) * gas(r, ang) * side * (1.0 - smoothstep(0.2, 0.5, fall));
	col += mix(warm.rgb, hot.rgb, smoothstep(0.3, 0.8, bent)) * bent * (2.0 + 1.5 * immerse);
	// close in, the whole sky glows with it: a haze over the horizon
	col += mix(warm.rgb, hot.rgb, 0.6) * immerse * (0.25 * exp(-max(r - 1.0, 0.0) * 0.6) + 0.55 * exp(-max(horizon - UV.y, 0.0) * 7.0));
	// the shadow
	float shadow = smoothstep(1.0, 0.985, r);
	// the shadow is dark, but the sphere at its heart shows from the start; falling in, all the rest
	vec4 sp0 = sphere_view(q * radius);
	vec3 within = mix(vec3(0.0), sp0.rgb, sp0.a) + sphere_rim(q * radius);
	if (reveal > 0.0) {
		within = mix(within, tunnel(q * radius), reveal);
	}
	col = mix(col, within, shadow);
	// the thin ring of light hugging it
	col += hot.rgb * exp(-pow((r - 1.015) * 60.0, 2.0)) * 0.9;
	// the near side of the disk, across in front of the shadow: a thin band, wider further out
	float x = abs(q.x);
	float half_h = tilt * (0.5 + 0.5 * smoothstep(0.0, 6.0, x)) + 0.03;
	float band = smoothstep(half_h, half_h * 0.25, abs(q.y - 0.04));
	float along = x < 1.7 ? 1.0 : disk_glow(x);   // in front of the shadow it runs straight across
	float dop = clamp(0.55 - q.x * 0.07, 0.25, 1.0);
	float front = band * along * gas(x, q.x * 0.35 + q.y * 3.0) * dop * 1.5 * (1.0 - smoothstep(0.15, 0.45, fall)) * (1.0 - immerse);
	col = mix(col, mix(warm.rgb, hot.rgb, smoothstep(0.3, 0.9, front)) * 1.25, clamp(front * 1.4, 0.0, 1.0));
	// the disk under you passes in front of the shadow; it goes as you fall in
	if (immerse > 0.0) {
		vec4 fl = disk_floor(UV);
		col = mix(col, fl.rgb, fl.a * immerse * (1.0 - smoothstep(0.35, 0.75, fall)));
	}
	if (inside > 0.0) {
		col = mix(col, tunnel(vec2((UV.x - center.x) * aspect, UV.y - center.y)), inside);
	}
	col = mix(col, hot.rgb * 1.05, white);
	COLOR = vec4(col, 1.0);
}
