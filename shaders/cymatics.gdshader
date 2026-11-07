shader_type canvas_item;
// Cymatics in paint (tools/cymatics.gd): the figures a vibrating plate draws in sand (Chladni's), as
// pigment settling on wet paper. f = cos(n·πx)cos(m·πy) − cos(m·πx)cos(n·πy): the pigment gathers where
// f is still (its nodal lines). A note sets a new (n, m): the plate shivers, the pigment runs, and the
// new figure sharpens as it settles. The figures before stay as faint layers underneath.

uniform vec4 paper : source_color = vec4(0.92, 0.9, 0.87, 1.0);
uniform vec4 pigment : source_color = vec4(0.79, 0.35, 0.31, 1.0);
uniform vec4 ghost_pigment : source_color = vec4(0.30, 0.52, 0.70, 1.0);
uniform vec2 mode_now = vec2(1.0, 2.0);      // the figure forming
uniform vec2 mode_before = vec2(1.0, 2.0);   // the one it comes from
uniform vec2 mode_ghost = vec2(2.0, 3.0);    // an older one, a faint layer below
uniform float change = 1.0;                  // 0 the note just sounded, 1 settled
uniform float shiver = 0.0;                  // the plate trembling (the note's strike)
uniform float ghost = 0.35;                  // how much of the old layer shows
uniform float aspect = 1.7778;
uniform float radius = 0.42;                 // the plate, a fraction of the height
uniform float seed = 0.0;
// glow: luminous pigment over whatever is behind (the dark), the plate itself transparent
uniform bool glow = false;
uniform float alpha = 1.0;

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
	for (int k = 0; k < 5; k++) {
		v += a * noise(p);
		p = p * 2.07 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return v;
}

float chladni(vec2 p, vec2 nm) {
	float pi = 3.14159265;
	return cos(nm.x * pi * p.x) * cos(nm.y * pi * p.y) - cos(nm.y * pi * p.x) * cos(nm.x * pi * p.y);
}

void fragment() {
	// the plate's space: -1..1 across the plate, a circle on the screen
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0) / radius;
	float r = length(p);
	// paint wobbles the lines: wet edges, a hand's tremble, and the plate shivering on the note
	vec2 wob = vec2(fbm(p * 3.0 + TIME * 0.05), fbm(p * 3.0 + 7.3 - TIME * 0.04)) - 0.5;
	vec2 q = p * 0.75 + wob * 0.06 + shiver * 0.03 * vec2(sin(TIME * 53.0 + p.y * 9.0), cos(TIME * 47.0 + p.x * 9.0));
	float s = smoothstep(0.0, 1.0, change);
	float f = mix(chladni(q, mode_before), chladni(q, mode_now), s);
	// how sharply the pigment has gathered: loose and spread as it runs, fine lines as it settles
	float sharp = mix(4.0, 12.0, s) * (1.0 - 0.5 * shiver);
	float line = exp(-abs(f) * sharp);
	// granulation: pigment pools in the paper's tooth, darker at the edges of a stroke
	float grain = fbm(p * 18.0) * 0.6 + fbm(p * 55.0) * 0.4;
	float body = smoothstep(0.25, 0.85, line + (grain - 0.5) * 0.45);
	float edge = smoothstep(0.35, 0.55, line) - smoothstep(0.55, 0.9, line);
	// a wash bleeding out from the lines, as wet pigment spreads into the paper
	float wash = exp(-abs(f) * 2.5) * (0.55 + 0.45 * fbm(p * 6.0 + 2.0));
	float paint = clamp(body * 0.85 + edge * 0.4 + wash * 0.22, 0.0, 1.0);
	// the older layer, faint, in its own colour
	float g = exp(-abs(chladni(q, mode_ghost)) * 10.0);
	float gpaint = smoothstep(0.3, 0.9, g + (grain - 0.5) * 0.5) * ghost;
	// inside the plate only, its rim soft like a wash
	float plate = 1.0 - smoothstep(0.92, 1.02, r + (fbm(p * 4.0) - 0.5) * 0.06);
	if (glow) {
		vec3 lit = mix(pigment.rgb, vec3(1.0, 0.97, 0.88), 0.4);
		vec3 old = mix(ghost_pigment.rgb, vec3(1.0, 0.97, 0.88), 0.3);
		float a = paint * 0.95;
		float ga = gpaint * 0.45 * (1.0 - a);
		float rim_g = exp(-pow((r - 0.98) * 26.0, 2.0)) * 0.18;
		vec3 c = (lit * a + old * ga + vec3(1.0, 0.95, 0.8) * rim_g) / max(a + ga + rim_g, 0.001);
		COLOR = vec4(c, clamp(a + ga + rim_g, 0.0, 1.0) * plate * alpha);
	} else {
	vec3 col = paper.rgb;
	col = mix(col, col * ghost_pigment.rgb * 1.15, gpaint * plate * 0.8);
	col = mix(col, col * pigment.rgb, paint * plate * 0.92);
	// a soft wash where the plate is, and its rim in diluted ink
	col *= 1.0 - 0.05 * plate;
	float rim = exp(-pow((r - 0.98) * 30.0, 2.0));
	col = mix(col, col * vec3(0.55, 0.52, 0.5), rim * 0.35);
	// paper grain over all
	col += (hash(floor(FRAGCOORD.xy)) - 0.5) * 0.03;
	COLOR = vec4(col, 1.0);
	}
}
