extends Node
## Estimates play time with the game's own formulas, for two kinds of player:
##   human  — 3.5 taps/s, opens the tree every 25 s and buys the cheapest upgrades it can.
##   casual — 2.5 taps/s, opens the tree every 45 s and buys one affordable upgrade at random,
##            and stops for longer now and then. Nobody should ever get stuck: "worst" is the
##            longest time spent on a single barrier.
## godot --headless --path . res://tools/sim_time.tscn
## CANDIDATES lists chapter HP multipliers to compare; each is averaged over RUNS runs.

const DT := 0.05
const LIMIT := 4.0 * 3600.0
const RUNS := 3
const CANDIDATES := [[8.0, 10.0]]
const PROFILES := {
	"human": {"rate": 3.5, "tree_every": 25.0, "tree_time": 6.0, "pause_every": 60.0, "pause_time": 4.0, "greedy": true},
	"casual": {"rate": 2.5, "tree_every": 45.0, "tree_time": 10.0, "pause_every": 50.0, "pause_time": 10.0, "greedy": false},
}


func _ready() -> void:
	SaveSystem.enabled = false
	var dark_hp: float = GameState.chapter_hp[2]  # 41–45, the demo's dark: the game's own value
	for cand in CANDIDATES:
		for profile in PROFILES:
			var zones := [0.0, 0.0, 0.0, 0.0, 0.0]
			var total := 0.0
			var worst := 0.0
			var worst_at := 0
			for run in RUNS:
				GameState.chapter_hp = [cand[0], cand[1], dark_hp, 1.0, 1.0]
				var res := _play(PROFILES[profile])
				total += res[0]
				for z in 5:
					zones[z] += res[1][z]
				if res[2] > worst:
					worst = res[2]
					worst_at = res[3]
			var line := "SIM %-6s hp=%s  total=%.1f min  worst=%.1f min (b%d)  zones:" % [profile, str(cand),
				total / RUNS / 60.0, worst / 60.0, worst_at]
			for z in 5:
				line += " %.1f" % (zones[z] / RUNS / 60.0)
			print(line)
	get_tree().quit()


## Returns [total s, [s in zones 1..5], longest s on one barrier, that barrier].
func _play(p: Dictionary) -> Array:
	var g := GameState
	g.new_game()
	g.running = true
	var t := 0.0
	var tap_acc := 0.0
	var auto_acc := 0.0
	var next_tree: float = p.tree_every
	var next_pause: float = p.pause_every
	var busy_until := 0.0
	var zone_start := [0.0, -1.0, -1.0, -1.0, -1.0]
	var gate_since := 0.0
	var gate := g.stage
	var worst := 0.0
	var worst_at := 0
	while not g.finished and t < LIMIT:
		t += DT
		g.time_at_gate += DT
		g.hp = minf(g.max_hp(g.stage), g.hp + g.regen(g.stage) * DT)
		g._regen_special(DT)
		auto_acc += 0.6 * g.lv("pulso") * DT
		while auto_acc >= 1.0 and not g.finished:
			auto_acc -= 1.0
			g.tap("auto")
		if t >= next_tree:
			next_tree = t + p.tree_every
			busy_until = t + p.tree_time
			if p.greedy:
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
			else:
				var options := []
				for id in Upgrades.ORDER:
					if g.can_buy(id):
						options.append(id)
				if not options.is_empty():
					g.buy(options[randi() % options.size()])
		if t >= next_pause:
			next_pause = t + p.pause_every
			busy_until = maxf(busy_until, t + p.pause_time)
		if t >= busy_until:
			tap_acc += p.rate * DT
			while tap_acc >= 1.0 and not g.finished:
				tap_acc -= 1.0
				g.tap("tap")
		if g.stage != gate:
			if t - gate_since > worst:
				worst = t - gate_since
				worst_at = gate
			gate = g.stage
			gate_since = t
		var z := clampi(int((g.stage - 1) / 10), 0, 4)
		if zone_start[z] < 0.0:
			zone_start[z] = t
	var spent := []
	for z in 5:
		var end: float = zone_start[z + 1] if z < 4 else t
		spent.append(end - zone_start[z])
	return [t, spent, worst, worst_at]
