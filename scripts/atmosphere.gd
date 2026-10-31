class_name Atmosphere
extends RefCounted
## Sounds that are not notes, made once at start (they are not in the sample pack): air, a reversed
## swell, a tonal bird cry and a deep resonance. Mono 16-bit at 22 050 Hz. They are played through
## reverb-heavy buses so they sit far away, the way Gris uses air and voices rather than effects.
## The cry is rendered on A4 (MIDI 69) and tuned to the chord with pitch_scale.

const RATE := 22050


## A soft rush of air: band-limited noise with a quick rise and a long fall (a wing beat).
static func whoosh(length := 0.75) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lo := 0.0
	var lo2 := 0.0
	for i in n:
		var t := float(i) / n
		var white := rng.randf_range(-1.0, 1.0)
		lo += (white - lo) * 0.11
		lo2 += (lo - lo2) * 0.02
		var band := lo - lo2
		var env := pow(sin(PI * pow(t, 0.55)), 2.0)
		out[i] = band * env
	return _wav(out)


## Air swelling up and cut short, like a reversed cymbal: what comes before something appears.
static func swell(length := 1.6) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var lo := 0.0
	for i in n:
		var t := float(i) / n
		var white := rng.randf_range(-1.0, 1.0)
		lo += (white - lo) * lerpf(0.01, 0.35, t * t)
		var env := pow(t, 2.6) * (1.0 - smoothstep(0.93, 1.0, t))
		out[i] = lo * env
	return _wav(out)


## A distant bird: a tone that rises a little and falls further, with vibrato and a breathy edge.
static func cry(length := 1.5) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	var phase := 0.0
	var air := 0.0
	for i in n:
		var t := float(i) / n
		var semis := 3.0 * sin(PI * minf(t * 1.6, 1.0)) - 5.0 * smoothstep(0.45, 1.0, t)
		semis += 0.3 * sin(TAU * 5.5 * t * length)
		var f := 440.0 * pow(2.0, semis / 12.0)
		phase += TAU * f / RATE
		air += (rng.randf_range(-1.0, 1.0) - air) * 0.3
		var tone := sin(phase) + 0.28 * sin(2.0 * phase) + 0.08 * sin(3.0 * phase)
		var env := smoothstep(0.0, 0.12, t) * pow(1.0 - t, 1.4)
		out[i] = (tone * 0.8 + air * 0.12) * env
	return _wav(out)


## A deep, slow resonance: a low sine that sinks a little, with a soft thump at the start.
static func boom(length := 2.4) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var phase := 0.0
	var lo := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(62.0, 46.0, sqrt(t))
		phase += TAU * f / RATE
		lo += (rng.randf_range(-1.0, 1.0) - lo) * 0.05
		var env := smoothstep(0.0, 0.03, t) * exp(-3.2 * t)
		out[i] = (sin(phase) + 0.25 * sin(2.0 * phase)) * env + lo * exp(-40.0 * t) * 0.6
	return _wav(out)


## The ground giving way far below: low, rolling noise that swells and dies (a tremor).
static func rumble(length := 3.0) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	var lo := 0.0
	var lo2 := 0.0
	for i in n:
		var t := float(i) / n
		lo += (rng.randf_range(-1.0, 1.0) - lo) * 0.012
		lo2 += (lo - lo2) * 0.05
		# slow beating, like something heavy shifting
		var roll := 0.7 + 0.3 * sin(TAU * 3.2 * t * length) * sin(TAU * 0.9 * t * length)
		var env := smoothstep(0.0, 0.18, t) * pow(1.0 - t, 1.8)
		out[i] = lo2 * roll * env
	return _wav(out)


## Bits of ink and stone falling apart: sparse little clicks and grains over a short hiss.
static func crumble(length := 1.4) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var hiss := 0.0
	var grain := 0.0
	var grain_v := 0.0
	for i in n:
		var t := float(i) / n
		hiss += (rng.randf_range(-1.0, 1.0) - hiss) * 0.4
		# a new grain now and then, denser at the start
		if rng.randf() < lerpf(0.004, 0.0006, t):
			grain_v = rng.randf_range(0.5, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		grain_v *= 0.93
		grain += (grain_v - grain) * 0.6
		var env := pow(1.0 - t, 2.2)
		out[i] = (grain * 0.9 + hiss * 0.08) * env
	return _wav(out)


## A whale far up in the sky: a long, low call that rises, holds and falls, with slow vibrato,
## soft overtones and air. Rendered around A3 (MIDI 57) and tuned with pitch_scale.
static func whale(length := 5.0) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var phase := 0.0
	var air := 0.0
	for i in n:
		var t := float(i) / n
		# rise a fifth, hold, sink below where it started
		var semis := 7.0 * smoothstep(0.0, 0.35, t) - 9.0 * smoothstep(0.6, 1.0, t)
		semis += 0.25 * sin(TAU * 4.2 * t * length) * smoothstep(0.2, 0.5, t)
		var f := 220.0 * pow(2.0, semis / 12.0)
		phase += TAU * f / RATE
		air += (rng.randf_range(-1.0, 1.0) - air) * 0.08
		# the voice brightens in the middle, like a mouth opening
		var open := sin(PI * t)
		var tone := sin(phase) + 0.45 * open * sin(2.0 * phase) + 0.22 * open * sin(3.0 * phase) \
			+ 0.08 * sin(5.0 * phase)
		var env := smoothstep(0.0, 0.2, t) * smoothstep(1.0, 0.75, t)
		out[i] = (tone * 0.75 + air * 0.25) * env
	return _wav(out)


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] / peak * 0.85, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
