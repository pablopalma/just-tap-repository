extends Node
## Estimates play time with a "human" player model using the game's own formulas.
## godot --headless --path . res://tools/sim_time.tscn
## Model: taps at TAP_RATE while playing; every TREE_EVERY s opens the tree for TREE_TIME s
## (no taps) and buys the cheapest affordable upgrade until none is left; a short pause every
## minute. Echoes are ignored (slightly pessimistic). Cinematics never block input.
## CANDIDATES lists chapter HP multipliers to compare; each is averaged over RUNS runs.

const DT := 0.05
const TAP_RATE := 3.5
const TREE_EVERY := 25.0
const TREE_TIME := 6.0
const PAUSE_EVERY := 60.0
const PAUSE_TIME := 4.0
const LIMIT := 4.0 * 3600.0
const RUNS := 3
const CANDIDATES := [[5.0, 6.0]]


func _ready() -> void:
	for cand in CANDIDATES:
		var zones := [0.0, 0.0, 0.0, 0.0]
		var total := 0.0
		for run in RUNS:
			GameState.chapter_hp = [cand[0], cand[1], 1.0, 1.0, 1.0]
			var res := _play()
			total += res[0]
			for z in 4:
				zones[z] += res[1][z]
		var line := "SIM hp=%s  total=%.1f min  zones:" % [str(cand), total / RUNS / 60.0]
		for z in 4:
			line += " %.1f" % (zones[z] / RUNS / 60.0)
		print(line)
	get_tree().quit()


## Returns [total seconds, [seconds spent in each of zones 1..4]].
func _play() -> Array:
	var g := GameState
	g.new_game()
	g.running = true
	var t := 0.0
	var tap_acc := 0.0
	var auto_acc := 0.0
	var next_tree := TREE_EVERY
	var next_pause := PAUSE_EVERY
	var busy_until := 0.0
	var zone_start := [0.0, -1.0, -1.0, -1.0]
	while not g.finished and t < LIMIT:
		t += DT
		g.hp = minf(g.max_hp(g.stage), g.hp + g.regen(g.stage) * DT)
		auto_acc += 0.6 * g.lv("pulso") * DT
		while auto_acc >= 1.0 and not g.finished:
			auto_acc -= 1.0
			g.tap("auto")
		if t >= next_tree:
			next_tree = t + TREE_EVERY
			busy_until = t + TREE_TIME
			var bought := true
			while bought:
				bought = false
				var best := ""
				for id in Upgrades.ORDER:
					if g.can_buy(id) and (best == "" or g.cost(id) < g.cost(best)):
						best = id
				if best != "":
					g.buy(best)
					bought = true
		if t >= next_pause:
			next_pause = t + PAUSE_EVERY
			busy_until = maxf(busy_until, t + PAUSE_TIME)
		if t >= busy_until:
			tap_acc += TAP_RATE * DT
			while tap_acc >= 1.0 and not g.finished:
				tap_acc -= 1.0
				g.tap("tap")
		var z := clampi(int((g.stage - 1) / 10), 0, 3)
		if zone_start[z] < 0.0:
			zone_start[z] = t
	var spent := []
	for z in 4:
		var end: float = zone_start[z + 1] if z < 3 else t
		spent.append(end - zone_start[z])
	return [t, spent]