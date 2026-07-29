@tool
extends Node3D

## Principal VR Audio Monitor
## Visualizes audio waves in 3D using a SubViewport and WaveformDisplay


# @identity
# essence: AudioServer.get_bus_peak_volume_left/right -> waveform display
# desire: See the audio bus activity rendered as a real-time waveform monitor in VR
# critical_parameter: audio_bus — selects which audio bus to monitor
# triggers: auto_connect finds and binds to the audio system on ready
# emerges: visual feedback loop between what you hear and what you see
# needs: VR viewport display [has], bus selection [missing]
# relationships: depends on WaveformDisplay 2D scene; contrasts with dual_display_test (monitoring vs spectrum analysis)
# truth: Sound is invisible force; the monitor makes the waveform a visible object.

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# feed: what the instrument is reporting. The truth line above claims the
#   monitor "makes the waveform a visible object" — but in every map where it
#   currently stands, nothing is playing, so the screen draws a flat line at the
#   2% amplitude floor. The instrument is a promise, not a reading. The screen's
#   own driver (SimpleWaveformDisplay) has had set_frequency/set_amplitude since
#   the day it was written and nothing has ever called them. This axis reaches
#   them: "live" (shipped) monitors the real bus and usually shows the silence
#   honestly; "test" drives it with a 440 Hz tone so the apparatus demonstrates
#   its own competence instead of the world's; "saturated" pins it at full scale
#   on a dense signal — the over-read, the instrument that always agrees.
#   Three positions on one question: does a measuring device show the world, or
#   show itself?
# chassis: how much apparatus the reading arrives inside. Shipped, the number is
#   wrapped in a bezelled box wearing a nameplate that says PRINCIPAL MONITOR —
#   the authority of equipment. "anonymous" keeps the box and drops the name.
#   "bare" hides the housing entirely and leaves only the glowing readout in the
#   air. Collision is on a separate StaticBody3D, so the artifact stays exactly
#   as grabbable and as placeable in all three.
const SIGNAL_FEEDS = ["live", "test", "saturated"]
const CHASSIS_MODES = ["cased", "anonymous", "bare"]
const TEST_HZ := 440.0
const TEST_AMP := 0.65
const SATURATED_HZ := 1600.0
const SATURATED_AMP := 1.0
# SimpleWaveformDisplay's shipped defaults, restored when a placement is
# switched back to "live" at runtime.
const LIVE_CYCLES := 4.0

@export var monitor_name: String = "PRINCIPAL MONITOR"
@export var audio_bus: String = "Master"
@export var auto_connect: bool = true

@export_enum("live", "test", "saturated") var feed: String = "live"
@export_enum("cased", "anonymous", "bare") var chassis: String = "cased"

@onready var viewport_2d = $ScreenOrigin/Viewport2Din3D
@onready var name_label = $Chassis/LabelName
var display: Node
var _built: bool = false

func _ready():
	if name_label: name_label.text = monitor_name

	display = _resolve_display()

	# If we are in the same scene as a UVAC, try to connect to it
	if auto_connect:
		_find_and_connect_to_uvac()

	_apply_feed()
	_apply_chassis()
	_built = true

func _resolve_display() -> Node:
	# Access the instantiated scene from Viewport2Din3D
	# It usually instantiates 'scene' as a child of its internal SubViewport
	if not viewport_2d:
		return null

	# Wait for the scene to likely be ready or access it if already there
	var found: Node = null
	var scene_instance = viewport_2d.get_scene_instance()
	if scene_instance:
		found = scene_instance.get_node_or_null("WaveformDisplay")

	# Fallback if get_scene_instance isn't immediate or available (depends on XR Tools version)
	if not found:
		# Try to find it manually in the viewport
		var vp = viewport_2d.get_node_or_null("Viewport")
		if vp:
			for child in vp.get_children():
				var wd = child.get_node_or_null("WaveformDisplay")
				if wd:
					found = wd
					break
				if child.name == "VRAudioMonitorUI": # The root of our scene
					found = child.get_node_or_null("WaveformDisplay")
					break
	return found

func _apply_feed() -> void:
	if display == null:
		display = _resolve_display()
	if display == null:
		return

	if feed == "live":
		# The shipped path: the display detects the bus on its own. Only undo an
		# override we ourselves installed — at _ready time (_built false) this
		# touches nothing at all.
		if _built:
			display.set("_direct_frequency", 0.0)
			display.set("_direct_amplitude", -1.0)
			display.set("num_cycles", LIVE_CYCLES)
		return

	var hz: float = TEST_HZ if feed == "test" else SATURATED_HZ
	var amp: float = TEST_AMP if feed == "test" else SATURATED_AMP
	if display.has_method("set_frequency"):
		display.call("set_frequency", hz)
	if display.has_method("set_amplitude"):
		display.call("set_amplitude", amp)

func _apply_chassis() -> void:
	var body: Node = get_node_or_null("Chassis")
	if body is Node3D:
		(body as Node3D).visible = (chassis != "bare")
	if name_label:
		name_label.visible = (chassis == "cased")

func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: nothing is re-applied unless a declared value actually changed,
	# and never before _ready has run once. A placement that passes no
	# feed/chassis token is left exactly as it shipped.
	var feed_changed: bool = false
	var chassis_changed: bool = false

	if config_data.has("feed"):
		var want_feed: String = str(config_data["feed"]).strip_edges().to_lower()
		if SIGNAL_FEEDS.has(want_feed) and want_feed != feed:
			feed = want_feed
			feed_changed = true

	if config_data.has("chassis"):
		var want_chassis: String = str(config_data["chassis"]).strip_edges().to_lower()
		if CHASSIS_MODES.has(want_chassis) and want_chassis != chassis:
			chassis = want_chassis
			chassis_changed = true

	if not _built:
		return
	if feed_changed:
		_apply_feed()
	if chassis_changed:
		_apply_chassis()

func _find_and_connect_to_uvac():
	# Look for UVAC in parent or siblings
	var parent = get_parent()
	if not parent: return

	for child in parent.get_children():
		if child.has_signal("sound_played"):
			child.connect("sound_played", _on_sound_played)
			print("VRAudioMonitor: Connected to UVAC")
			break

func _on_sound_played(_stream):
	# We could use the stream here, but waveform display currently monitors the bus
	# This is a hook for future granular monitoring
	pass

func set_mode(_is_spectrum: bool):
	if display:
		# Toggle between Oscilloscope and Spectrum if supported
		# For now, WaveformDisplay is primarily a spectral sine wave
		pass
