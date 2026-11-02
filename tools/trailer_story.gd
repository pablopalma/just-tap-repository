extends "res://tools/trailer.gd"
## The story's opening for the montage over the title theme (Builds/trailer/just_tap_historia.mp4),
## cut like a film: the page alone, the voice asks; a breath of silence; the theme comes in and the
## memory draws itself, its first line on a downbeat, the sun on the second. Video only: the montage
## lays the audio back from the files at these same times (THEME_AT and the line times).
## Recorded like trailer v3 (tools/make_trailer_v3.ps1), with res://tools/trailer_story.tscn.

## Where the question starts, and where the theme comes in (seconds).
const ASK_AT := 0.5
const THEME_AT := 6.4
## The theme's first downbeat is 0.424 s in; a bar is 3 s (80 BPM). The lines land on its beats.
const LINE_1 := 3.424   # bar 2
const LINE_2 := 10.924  # bar 4, third beat
## Shown until the montage's cut into the spiral (theme time 21.224) and a little over.
const LENGTH := THEME_AT + 21.8

var _story_node: Control
var _paper: ColorRect
var _timed := false


func _ready() -> void:
	super._ready()
	Music.layers = 0
	_veil.color.a = 0.0


func _plan() -> void:
	_at(0.0, 0.0, "page", 0)
	_at(0.0, ASK_AT, "ask", 0)
	_at(0.0, THEME_AT, "tell", 0)
	length_bars = LENGTH / BAR


func _process(delta: float) -> void:
	super._process(delta)
	if _main.intro != null:
		_main.intro.visible = false  # no title: only the page
	if is_instance_valid(_story_node) and _story_node._telling:
		# The second line on the beat, not just after the first.
		if _story_node._line_i == 1 and not _timed:
			_story_node._next = LINE_2
			_timed = true


## The page: the story's paper over the world, under the subtitles.
func _page(_arg) -> void:
	var parent: Node = _main.subtitle.get_parent()
	_paper = ColorRect.new()
	_paper.color = load("res://scripts/ui/story.gd").PAPER
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_paper)
	parent.move_child(_paper, _main.subtitle.get_index())


## The story asks (its own _ready says it); no buttons in a trailer.
func _ask(_arg) -> void:
	_story_node = load("res://scripts/ui/story.gd").new()
	var parent: Node = _main.subtitle.get_parent()
	parent.add_child(_story_node)
	parent.move_child(_story_node, _main.subtitle.get_index())
	_story_node._yes.get_parent().visible = false


func _tell(_arg) -> void:
	_story_node._tell()
	_story_node._next = LINE_1
