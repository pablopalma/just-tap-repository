class_name Upgrades
extends RefCounted
## Upgrade tree data (design doc §5). Positions are % of the tree panel, y grows downward.

const ORDER := ["fuerza", "ganancia", "pulso", "resonancia", "corrosion", "eco", "destello"]

const DATA := {
	"fuerza": {"name": "Fuerza", "desc": "Cuánto empuja cada tap", "req": "", "req_lv": 0,
		"base": 10.0, "growth": 1.33, "max": 400, "pos": Vector2(50, 88)},
	"ganancia": {"name": "Ganancia", "desc": "Más luz por barrera y por tap", "req": "fuerza", "req_lv": 2,
		"base": 30.0, "growth": 1.9, "max": 40, "pos": Vector2(18, 60)},
	"pulso": {"name": "Pulso", "desc": "La línea late sola", "req": "fuerza", "req_lv": 3,
		"base": 50.0, "growth": 1.65, "max": 40, "pos": Vector2(50, 56)},
	"resonancia": {"name": "Resonancia", "desc": "Taps seguidos cargan combo", "req": "fuerza", "req_lv": 5,
		"base": 80.0, "growth": 1.8, "max": 20, "pos": Vector2(82, 60)},
	"corrosion": {"name": "Corrosión", "desc": "Las barreras se regeneran más lento", "req": "ganancia", "req_lv": 3,
		"base": 200.0, "growth": 1.9, "max": 20, "pos": Vector2(18, 24)},
	"eco": {"name": "Eco", "desc": "Cada tap puede repetirse", "req": "pulso", "req_lv": 3,
		"base": 300.0, "growth": 2.0, "max": 10, "pos": Vector2(50, 18)},
	"destello": {"name": "Destello", "desc": "Crítico ×4", "req": "resonancia", "req_lv": 2,
		"base": 250.0, "growth": 1.9, "max": 12, "pos": Vector2(82, 24)},
}


## What level l does, in words.
static func effect_text(id: String, l: int) -> String:
	match id:
		"fuerza": return Loc.effect(id, Fmt.num((1 + l) * pow(1.075, l)))
		"ganancia": return Loc.effect(id, Fmt.num(pow(1.15, l)))
		"pulso": return Loc.effect(id, Fmt.num(0.6 * l))
		"resonancia": return Loc.effect(id, Fmt.num(1.5 * l))
		"corrosion": return Loc.effect(id, Fmt.num(pow(0.9, l)))
		"eco": return Loc.effect(id, str(6 * l))
		"destello": return Loc.effect(id, str(3 * l))
	return ""
