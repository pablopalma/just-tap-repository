shader_type canvas_item;
render_mode unshaded;
// Volumetric fog for a plane of depth: drifting banks of mist, thick near the ground and thinning
// upward, lit from the light behind (brighter towards it). One rect per plane, between the planes, so
// what is further away sinks into more haze. Its noise moves with the camera by the plane's depth.

uniform vec4 color : source_color = vec4(0.6, 0.7, 0.85, 1.0);
uniform vec4 lit : source_color = vec4(1.0, 0.95, 0.85, 1.0);   // the fog where the light shines through
uniform float density = 0.6;
uniform float ground = 0.8;       // where the ground is, in the rect's UV
uniform float thickness = 0.35;   // how high above the ground it reaches (UV)
uniform float base = 0.08;        // a thin haze everywhere
uniform vec2 light = vec2(0.5, 0.2);    // the light, in the rect's UV
uniform float aspect = 1.7778;
uniform vec2 drift = vec2(0.02, 0.0);
uniform vec2 scroll = vec2(0.0);  // the camera, scaled by this plane's depth
uniform float scale = 2.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
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
	for (int k = 0; k < 5; k++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = vec2(UV.x * aspect, UV.y);
	vec2 p = uv * scale + scroll + drift * TIME;
	// banks of mist: warped noise, stretched sideways like layers of air
	vec2 warp = vec2(fbm(p * vec2(0.6, 1.4) + TIME * 0.015), fbm(p + 5.2));
	float mist = fbm(p * vec2(0.5, 1.6) + warp * 1.5);
	mist = smoothstep(0.3, 0.85, mist);
	// thick by the ground, thinning upward; nothing below the ground's edge is lost either
	float h = clamp((ground - UV.y) / thickness, -1.0, 1.0);
	float layer = 1.0 - smoothstep(0.0, 1.0, h);
	float a = (mist * layer + base * (0.6 + 0.4 * mist)) * density;
	// the light behind shines through it
	vec2 d = (UV - light) * vec2(aspect, 1.0);
	float shine = exp(-length(d) * 2.2);
	vec3 c = mix(color.rgb, lit.rgb, clamp(shine * 0.8 + mist * 0.15, 0.0, 1.0));
	COLOR = vec4(c, clamp(a, 0.0, 0.95));
}
