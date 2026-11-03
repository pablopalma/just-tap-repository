shader_type canvas_item;
render_mode blend_add, unshaded;
// God rays: soft shafts of light fanning out from a light (the sun, the moon), broken by slow noise
// into beams of different widths and strengths, fading with distance and at the frame's edges.
// Drawn on a rect over the view, added onto what is behind it.

uniform vec2 origin = vec2(0.5, -0.2);   // where the light is, in the rect's UV (may be outside it)
uniform float aspect = 1.7778;            // the rect's width / height, so the beams are not stretched
uniform vec4 color : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float intensity = 0.5;
uniform float density = 7.0;              // how many beams around the light
uniform float speed = 0.04;               // how fast they drift
uniform float sharpness = 2.2;            // higher: thinner, clearer beams
uniform float falloff = 0.8;              // how quickly they fade away from the light
uniform float edge_fade = 0.12;           // softening at the rect's edges
uniform float seed = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

// smooth 1D value noise that wraps around the circle (period p)
float noise(float x, float p) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(mod(i, p) + seed), hash(mod(i + 1.0, p) + seed), u);
}

void fragment() {
	vec2 d = UV - origin;
	d.x *= aspect;
	float r = length(d);
	float a = atan(d.y, d.x) / 6.2831853 + 0.5;   // 0..1 around the light
	float t = TIME * speed;
	// two layers of beams: broad ones and thin ones, drifting apart
	float n1 = noise(a * density + t * 7.0, density);
	float n2 = noise(a * density * 2.7 - t * 5.0 + 13.0, floor(density * 2.7));
	float n3 = noise(a * density * 0.6 + t * 3.0 + 31.0, floor(density * 0.6) + 1.0);
	float beams = pow(n1, sharpness) * 0.7 + pow(n2, sharpness + 1.5) * 0.5;
	beams *= 0.55 + 0.45 * n3;                     // some groups of beams brighter than others
	// light along a beam: strongest near the light, fading out; a soft core close to it
	float along = exp(-r * falloff) * smoothstep(0.0, 0.12, r);
	float glow = exp(-r * 6.0) * 0.35;
	// dust in the air: a fine shimmer moving through the beams
	float dust = 0.85 + 0.15 * noise(r * 40.0 - TIME * 0.6 + a * 90.0, 1000.0);
	float edges = smoothstep(0.0, edge_fade, UV.x) * smoothstep(0.0, edge_fade, 1.0 - UV.x)
		* smoothstep(0.0, edge_fade, UV.y) * smoothstep(0.0, edge_fade, 1.0 - UV.y);
	float v = (beams * along * dust + glow) * intensity * edges;
	COLOR = vec4(color.rgb * v, v);
}
