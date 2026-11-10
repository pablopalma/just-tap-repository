shader_type canvas_item;
// The mesh of tools/spacetime.gd: a grid of lines on the floor (x across, z ahead, in the mesh's
// VERTEX), sunk by the light's well and the ripples of taps, then projected in perspective. The same
// height as spacetime.gd's _height(), which the light and its line use.

uniform vec2 origin;          // the grid's world offset (snapped, so it scrolls)
uniform vec2 well;
uniform float depth = 2.8;
uniform float width2 = 6.76;  // the well's width, squared
uniform vec4 ripples[8];      // at.x, at.y, front (world units), strength
uniform int ripple_count = 0;
uniform vec2 cam;             // camera x, z
uniform float cam_h = 8.0;
uniform float focal = 620.0;
uniform vec2 screen;
uniform float horizon = 0.16;
uniform float far_span = 52.0;
uniform float pull = 7.0;    // the black hole's pull: far off, the floor sinks away towards it
// The hole's lens on the screen: a vertex seen through it moves out from the hole's centre to the
// outer image of a point lens, (b + sqrt(b*b + 4 te*te)) / 2. te 0: no bending.
uniform vec2 hole_px;
uniform float hole_r_px = 100.0;
uniform float mesh_te = 0.0;
uniform vec4 ink : source_color;
uniform vec4 blue : source_color;

varying float sink;
varying float far_k;

float height(vec2 p) {
	float h = -depth * exp(-dot(p - well, p - well) / width2);
	for (int i = 0; i < 8; i++) {
		if (i >= ripple_count) {
			break;
		}
		vec4 r = ripples[i];
		float x = distance(p, r.xy) - r.z;
		h += 0.55 * r.w * sin(x * 1.6) * exp(-x * x * 0.35);
	}
	float far = clamp((p.y - cam.y) / far_span, 0.0, 1.0);
	float dx = p.x - cam.x;
	float sp = 5.0 + 12.0 * far;
	return h - pull * pow(far, 2.2) * exp(-dx * dx / (2.0 * sp * sp));
}

void vertex() {
	vec2 p = VERTEX + origin;
	float h = height(p);
	float dz = max(p.y - cam.y, 0.5);
	float s = focal * (screen.y / 720.0) / dz;
	VERTEX = vec2(screen.x * 0.5 + (p.x - cam.x) * s, screen.y * horizon + (cam_h - h) * s);
	if (mesh_te > 0.0) {
		vec2 d = (VERTEX - hole_px) / hole_r_px;
		float b = length(d) + 0.0001;
		// only what is far off, behind the hole's plane, is seen through it
		float behind = smoothstep(0.2, 0.7, clamp((p.y - cam.y) / far_span, 0.0, 1.0));
		float th = (b + sqrt(b * b + 4.0 * mesh_te * mesh_te)) * 0.5;
		VERTEX = hole_px + d / b * mix(b, th, behind) * hole_r_px;
	}
	sink = clamp(-h / depth, 0.0, 1.0);
	far_k = clamp((p.y - cam.y) / far_span, 0.0, 1.0);
}

void fragment() {
	vec3 col = mix(ink.rgb, blue.rgb, 0.55 + 0.3 * sink);
	float a = (0.22 + 0.3 * sink) * (1.0 - far_k * far_k);
	COLOR = vec4(col, a);
}
