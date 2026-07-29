extends Node3D

## Frame Counter Display — the panel that reports the machine's own tick.
##
## STAGE-2 DNA PROMOTION (2026-07-29). Before this the whole artifact was three
## lines: `label.text = "%d" % Engine.get_process_frames()`. Zero exports, so the
## auto-research runner refused it — nothing to turn.
##
## The hard-coded parameter space was hiding in that one format string. A cumulative
## frame count is only ONE of the things a frame counter can say, and it is the least
## honest one: a five-digit number ticking up too fast to read is exactly how time
## looks when you pretend it is continuous. The artifact's own truth line says the
## opposite — "there is no continuous time in real-time 3D, only discrete frame
## steps" — and its @identity has been asking for a rate readout since it was written.
##
## Two axes:
##
##   reading   WHAT the panel reports    count · rate · delta · budget
##   epoch     the WINDOW it summarises  boot · arrival
##
## reading=count, epoch=boot is the old behaviour to the character, and it is the
## default, so all 11 existing placements are untouched.
##
## The axes argue against each other on purpose. `count` says time is an odometer.
## `delta` says a frame is 11 milliseconds wide and you are living inside one.
## `budget` refuses to report a fact at all and reports a verdict against the 90 Hz
## contract the headset signed. And `epoch` asks whose clock this is: the machine has
## been running since before you arrived (boot), or the count started when you walked
## into this room (arrival). Same panel, four different claims about what a frame is.
##
## Usage in map_data.json:
##   "frame_counter_display"                                  (legacy: raw frame count)
##   "frame_counter_display#reading:delta"                    (ms per frame, session mean)
##   "frame_counter_display#reading:budget#epoch:arrival"     (live % of the VR budget)
##   "frame_counter_display#reading:count#epoch:arrival"      (frames since you got here)

# @identity
# essence: label.text = Engine.get_process_frames() — a live counter of rendered frames since startup
# desire: learner understands that VR runs as a discrete sequence of frames, not a continuous flow
# critical_parameter: reading — whether the panel reports the running total, the rate, the width of one frame, or the overrun against the VR budget
# triggers: every rendered frame — the number ticks up continuously; pausing the game stops the counter
# emerges: the frame as the fundamental unit of VR time — everything the player experiences is discretised into frames
# needs: [has Label3D [has], has frame-rate and per-frame duration readouts [has]]
# relationships: utility display used alongside interactive scenes; reminds learner of the discrete substrate of 3D
# truth: there is no continuous time in real-time 3D — only discrete frame steps, typically 72 or 90 per second in VR

## What quantity the panel reports.
## count = frames accumulated (the legacy default); rate = frames per second;
## delta = the width of one frame in milliseconds; budget = that width as a
## percentage of the headset's frame budget, so 100% means exactly on time.
@export_enum("count", "rate", "delta", "budget") var reading: String = "count"
## The window the number summarises. boot = the whole session (a running total for
## count, a lifetime mean for the others); arrival = since this panel entered the
## map, which for the rate readings means the present moment rather than the average.
@export_enum("boot", "arrival") var epoch: String = "boot"
## The frame budget the `budget` reading judges against. 90 Hz is the Quest's contract.
@export var target_hz: float = 90.0

## Caption printed on the small side label, per reading and epoch. The panel is
## labelled "Frames"; if it starts reporting milliseconds and the caption still says
## Frames, the artifact is lying about its own units.
const CAPTIONS := {
	"count": {"boot": "Frames", "arrival": "Frames here"},
	"rate": {"boot": "FPS mean", "arrival": "FPS now"},
	"delta": {"boot": "ms mean", "arrival": "ms now"},
	"budget": {"boot": "budget mean", "arrival": "budget now"},
}
const SMOOTHING: float = 0.12
const REFRESH_S: float = 0.2

@onready var label: Label3D = $StartButton/Label3D
@onready var caption: Label3D = $Label3D

var _arrival_frame: int = 0
var _avg_delta: float = 0.0
var _since_refresh: float = 999.0
var _built: bool = false


func _ready() -> void:
	_arrival_frame = int(Engine.get_process_frames())
	_built = true
	_refresh_caption()


func _process(delta: float) -> void:
	if reading == "count":
		# LEGACY LINEAGE — untouched. Rewritten every frame, no smoothing, no refresh
		# gate, because the point of the running total is that it never stops moving.
		label.text = "%d" % _count()
		return

	if _avg_delta <= 0.0:
		_avg_delta = delta
	else:
		_avg_delta = _avg_delta + (delta - _avg_delta) * SMOOTHING

	# A number redrawn 90 times a second is unreadable, so the rate readings settle
	# five times a second. The count reading above deliberately does not.
	_since_refresh += delta
	if _since_refresh < REFRESH_S:
		return
	_since_refresh = 0.0
	label.text = _readout()


func _count() -> int:
	var frames: int = int(Engine.get_process_frames())
	if epoch == "arrival":
		var since: int = frames - _arrival_frame
		return since if since > 0 else 0
	return frames


## The span one frame occupies, in seconds — averaged over the whole session under
## epoch=boot, or as it is right now under epoch=arrival.
func _frame_seconds() -> float:
	if epoch == "boot":
		var uptime: float = float(Time.get_ticks_msec()) / 1000.0
		var frames: int = int(Engine.get_process_frames())
		if frames > 0 and uptime > 0.0:
			return uptime / float(frames)
	return _avg_delta


func _readout() -> String:
	var span: float = _frame_seconds()
	if span <= 0.0:
		return "--"
	match reading:
		"rate":
			return "%d fps" % int(round(1.0 / span))
		"delta":
			return "%.1f ms" % (span * 1000.0)
		"budget":
			var hz: float = target_hz if target_hz > 1.0 else 90.0
			return "%d%%" % int(round(span * hz * 100.0))
	return "%d" % _count()


func _refresh_caption() -> void:
	if caption == null:
		return
	var row: Dictionary = CAPTIONS.get(reading, CAPTIONS["count"])
	caption.text = str(row.get(epoch, row.get("boot", "Frames")))


func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: only touch the caption when a value actually changed and _ready has
	# already run once. An unconditional refresh here would repaint every shipped
	# placement for nothing.
	var changed: bool = false
	if config_data.has("reading"):
		var r: String = str(config_data["reading"])
		if CAPTIONS.has(r) and r != reading:
			reading = r
			changed = true
	if config_data.has("epoch"):
		var e: String = str(config_data["epoch"])
		if (e == "boot" or e == "arrival") and e != epoch:
			epoch = e
			changed = true
	if config_data.has("target_hz"):
		var hz: float = float(config_data["target_hz"])
		if hz > 1.0 and not is_equal_approx(hz, target_hz):
			target_hz = hz
			changed = true
	if changed and _built:
		_since_refresh = REFRESH_S
		_refresh_caption()
