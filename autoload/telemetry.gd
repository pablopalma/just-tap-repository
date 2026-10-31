extends Node
## Beta play data (docs/beta-datos.md): anonymous events, sent in batches to a Google Apps Script
## that writes one row per event in a sheet, so the balance can be checked against real players.
## No personal data: a random player id, the build, the platform and what happens in the game.
## The player can turn it off on the title screen. Nothing is sent when BuildFlags.TELEMETRY_URL is
## empty, when the save is disabled (tests, trailer) or once the dev menu has been used.

const PATH := "user://telemetry.cfg"
const FLUSH_EVERY := 30.0
## While playing, a snapshot every minute: shows where people are stuck and when they leave.
const TICK_EVERY := 60.0
const MAX_QUEUE := 300

## The player's choice, saved.
var enabled := true
var uid := ""
## Where batches go: BuildFlags.TELEMETRY_URL, or `-- --telemetry-url=<url>` for local tests.
var url := BuildFlags.TELEMETRY_URL
## tools/telemetry_test: records even though the save is off (so the test never touches it).
var testing := false

var _sid := ""
var _queue: Array[Dictionary] = []
var _inflight: Array[Dictionary] = []
var _flush_t := 0.0
var _tick_t := 0.0
var _opened := false
var _started := false
var _dev := false
var _tree_opens := 0       # times the tree was opened at the current barrier
var _tree_since := -1.0    # when the tree was opened, in session seconds
var _http: HTTPRequest


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--telemetry-url="):
			url = a.trim_prefix("--telemetry-url=")
	_load()
	_sid = _rand_id(8)
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_sent)
	GameState.gate_broken.connect(_on_gate)
	GameState.upgrade_bought.connect(_on_buy)
	GameState.star_completed.connect(func(n: int) -> void: event("star", {}, n))
	GameState.demo_finished.connect(_on_demo_end)
	GameState.game_finished.connect(func() -> void: event("game_end", {"taps": GameState.total_taps}))
	GameState.progress_reset.connect(func() -> void: event("new_game", {}, 1))
	GameState.jumped.connect(func(_n: int) -> void: _dev = true)
	if OS.has_feature("web"):
		_install_web_hook()


func active() -> bool:
	return enabled and not _dev and (SaveSystem.enabled or testing) and url != ""


func set_enabled(on: bool) -> void:
	if not on:
		event("opt_out")
		flush()
	enabled = on
	_save()
	if on:
		event("opt_in")


## Records one event. d: small dictionary of numbers and short strings. n: barrier (default: current).
func event(e: String, d := {}, n := -1) -> void:
	if not active():
		return
	var ev := {"e": e, "t": snappedf(_now(), 0.1), "n": GameState.stage if n < 0 else n, "d": d}
	if OS.has_feature("web"):
		# The page holds web events and sends them itself (see _install_web_hook).
		JavaScriptBridge.eval("window.__jtMeta = %s; window.__jtPush(%s);" % [_meta(), JSON.stringify(ev)])
		return
	if _queue.size() >= MAX_QUEUE:
		_queue.pop_front()
	_queue.append(ev)


## The tree panel was shown or hidden (Main connects it).
func tree_visible(on: bool) -> void:
	if on:
		_tree_opens += 1
		_tree_since = _now()
	elif _tree_since >= 0.0:
		event("tree", {"s": snappedf(_now() - _tree_since, 0.1), "light": roundf(GameState.light)})
		_tree_since = -1.0


func _process(delta: float) -> void:
	if not _opened:
		# First frame: the save is loaded and tests have had their chance to disable saving.
		_opened = true
		event("open", {"returning": SaveSystem.had_progress, "w": DisplayServer.window_get_size().x})
	if GameState.running and not _started:
		_started = true
		event("start", {"light": roundf(GameState.light)})
	if GameState.running and not GameState.finished:
		_tick_t += delta
		if _tick_t >= TICK_EVERY:
			_tick_t = 0.0
			event("tick", {"p": snappedf(GameState.progress(), 0.01), "s": roundf(GameState.time_at_gate),
				"light": roundf(GameState.light), "taps": GameState.total_taps})
	_flush_t += delta
	if _flush_t >= FLUSH_EVERY:
		_flush_t = 0.0
		flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		event("leave", {"p": snappedf(GameState.progress(), 0.01), "s": roundf(GameState.time_at_gate)})
		flush()


func flush() -> void:
	if OS.has_feature("web"):
		if url != "":
			JavaScriptBridge.eval("window.__jtFlush && window.__jtFlush();")
		return
	if _queue.is_empty() or url == "":
		return
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED or not _inflight.is_empty():
		return
	_inflight = _queue.duplicate()
	_queue.clear()
	var err := _http.request(url, ["Content-Type: text/plain"], HTTPClient.METHOD_POST,
		_body(_inflight))
	if err != OK:
		_requeue()


func _on_sent(result: int, code: int, _headers: PackedStringArray, _body_bytes: PackedByteArray) -> void:
	# Apps Script answers a POST with a redirect to the result; either means it was written.
	if result != HTTPRequest.RESULT_SUCCESS or code >= 400:
		_requeue()
	_inflight.clear()


func _requeue() -> void:
	var merged: Array[Dictionary] = []
	merged.append_array(_inflight)
	merged.append_array(_queue)
	_queue = merged
	while _queue.size() > MAX_QUEUE:
		_queue.pop_front()
	_inflight.clear()


func _body(events: Array) -> String:
	var b := _meta_dict()
	b["ev"] = events
	return JSON.stringify(b)


func _meta_dict() -> Dictionary:
	return {"uid": uid, "sid": _sid, "v": BuildFlags.VERSION, "plat": _platform(), "lang": SaveSystem.lang}


func _meta() -> String:
	return JSON.stringify(_meta_dict())


# --- Game events ------------------------------------------------------------

func _on_gate(n: int) -> void:
	var levels := 0
	for id in GameState.up:
		levels += int(GameState.up[id])
	# Emitted before the barrier's counters reset, so they still describe this barrier.
	event("gate", {"s": snappedf(GameState.time_at_gate, 0.1), "taps": GameState.taps_at_gate,
		"light": roundf(GameState.light), "lv": levels, "tree": _tree_opens,
		"cine": GameState.cinematic}, n)
	_tree_opens = 0


func _on_buy(id: String, level: int) -> void:
	var d: Dictionary = Upgrades.DATA[id]
	# what this level cost (GameState.cost already gives the next one)
	event("buy", {"id": id, "lv": level, "cost": ceilf(d.base * pow(d.growth, level - 1)),
		"light": roundf(GameState.light)})


func _on_demo_end() -> void:
	event("demo_end", {"taps": GameState.total_taps, "clock": roundf(GameState.clock)})
	flush()


# --- Web --------------------------------------------------------------------

## On the web the page itself holds the events and sends them with navigator.sendBeacon (no CORS,
## and it survives the tab closing): every FLUSH_EVERY seconds on its own timer, when Godot asks,
## and when the tab is hidden or closed, which Godot may not live to see.
func _install_web_hook() -> void:
	JavaScriptBridge.eval("""
(function () {
  if (window.__jtFlush) return;
  var url = %s, max = %d;
  window.__jtEv = [];
  window.__jtMeta = null;
  window.__jtPush = function (e) {
    window.__jtEv.push(e);
    if (window.__jtEv.length > max) window.__jtEv.shift();
  };
  window.__jtFlush = function () {
    if (!window.__jtEv.length || !window.__jtMeta) return;
    var b = Object.assign({}, window.__jtMeta, {ev: window.__jtEv});
    window.__jtEv = [];
    try { navigator.sendBeacon(url, JSON.stringify(b)); } catch (e) {}
  };
  setInterval(window.__jtFlush, %d);
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'hidden') window.__jtFlush();
  });
  window.addEventListener('pagehide', window.__jtFlush);
})();
""" % [JSON.stringify(url), MAX_QUEUE, int(FLUSH_EVERY * 1000.0)])

# --- Helpers ----------------------------------------------------------------

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func _platform() -> String:
	if OS.has_feature("web"):
		if OS.has_feature("web_android") or OS.has_feature("web_ios"):
			return "web-mobile"
		return "web"
	return OS.get_name().to_lower()


static func _rand_id(n: int) -> String:
	const CHARS := "abcdefghijkmnpqrstuvwxyz23456789"
	var s := ""
	for i in n:
		s += CHARS[randi() % CHARS.length()]
	return s


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		uid = str(cfg.get_value("t", "uid", ""))
		enabled = bool(cfg.get_value("t", "on", true))
	if uid == "":
		uid = _rand_id(12)
		_save()


func _save() -> void:
	if not SaveSystem.enabled:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("t", "uid", uid)
	cfg.set_value("t", "on", enabled)
	cfg.save(PATH)
