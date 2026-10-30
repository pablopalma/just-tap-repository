class_name Fmt
extends RefCounted
## Number formatting: <1000 plain (1 decimal under 10), then K, M, B, T, Qa, Qi, Sx.

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx"]


static func num(v: float) -> String:
	var a := absf(v)
	if a < 10.0:
		if is_equal_approx(v, roundf(v)):
			return str(int(roundf(v)))
		return "%.1f" % v
	if a < 1000.0:
		return str(int(floorf(v)))
	var i := 0
	while a >= 1000.0 and i < SUFFIXES.size() - 1:
		a /= 1000.0
		v /= 1000.0
		i += 1
	var decimals := 2 if a < 10.0 else (1 if a < 100.0 else 0)
	return ("%." + str(decimals) + "f%s") % [v, SUFFIXES[i]]


## "021"
static func pad3(n: int) -> String:
	return "%03d" % n
