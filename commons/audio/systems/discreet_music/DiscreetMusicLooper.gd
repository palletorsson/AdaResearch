extends Node
class_name DiscreetMusicLooper

@export var left_synth_path: NodePath
@export var right_synth_path: NodePath

var left_synth: DiscreetSynth
var right_synth: DiscreetSynth

# Time scaling: 1 measure = 2.0 seconds
const M_SCALE = 2.0

# Events: {time: float, type: string, note: string, duration: float}
# Types: "trigger", "set_note"
var left_loop_events = []
var right_loop_events = []

var left_loop_duration = 34.0 * M_SCALE
var right_loop_duration = 37.0 * M_SCALE

var left_timer = 0.0
var right_timer = 0.0

var left_event_idx = 0
var right_event_idx = 0

const NOTES = {
	"G3": 196.00, "B3": 246.94,
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00
}

func _ready():
	if left_synth_path: left_synth = get_node(left_synth_path)
	if right_synth_path: right_synth = get_node(right_synth_path)
	
	_setup_score()

func _setup_score():
	# Left Loop (34m)
	# 0:0 C5 (Dur 1.5m = 3s) -> D5 at +0:2 (1s)? 
	# JS: triggerAttackRelease('C5', '1:2', time); setNote('D5', '+0:2');
	# This implies C5 starts, then glides to D5 after 2 quarters (1s). Total dur 1:2 (3s).
	left_loop_events.append({"time": 0.0, "type": "trigger", "note": "C5", "dur": 3.0})
	left_loop_events.append({"time": 1.0, "type": "set", "note": "D5"})
	
	# +6:0 E4. (12s)
	left_loop_events.append({"time": 12.0, "type": "trigger", "note": "E4", "dur": 12.0}) # Play until next event roughly
	
	# +11:2 G4. (23s)
	left_loop_events.append({"time": 23.0, "type": "trigger", "note": "G4", "dur": 14.0}) # Until end
	
	# +19:0 E5... (38s)
	left_loop_events.append({"time": 38.0, "type": "trigger", "note": "E5", "dur": 15.0}) # Long sustain
	left_loop_events.append({"time": 38.0 + 3.0, "type": "set", "note": "G5"}) # +1:2
	left_loop_events.append({"time": 38.0 + 6.0, "type": "set", "note": "A5"}) # +3:0
	left_loop_events.append({"time": 38.0 + 9.0, "type": "set", "note": "G5"}) # +4:2
	
	# Right Loop (37m)
	# 0:0 D4 (1:2 = 3s) -> E4 at +6:0? No wait.
	# JS: trigger D4 '1:2', +5:0. Wait, start time is +5:0?
	# Ah, offset from loop start.
	# trigger D4 at 5:0 (10s).
	right_loop_events.append({"time": 10.0, "type": "trigger", "note": "D4", "dur": 12.0})
	right_loop_events.append({"time": 12.0, "type": "set", "note": "E4"}) # +6:0 (relative to loop start? or trigger?)
	# Assuming relative to loop start based on JS structure
	
	# +11:2:2 B3 (1m = 2s). (23.5s)
	right_loop_events.append({"time": 23.5, "type": "trigger", "note": "B3", "dur": 20.0})
	right_loop_events.append({"time": 24.5, "type": "set", "note": "G3"}) # +12:0:2
	
	# +23:2 G4 (0:2 = 1s). (47s)
	right_loop_events.append({"time": 47.0, "type": "trigger", "note": "G4", "dur": 15.0})
	
	# Sort events by time just in case
	left_loop_events.sort_custom(func(a, b): return a.time < b.time)
	right_loop_events.sort_custom(func(a, b): return a.time < b.time)

var intensity: float = 0.5 # 0.0 to 1.0

func set_intensity(val: float):
	intensity = clamp(val, 0.0, 1.0)

func _process(delta):
	if not left_synth or not right_synth: return
	
	# Modulate Synth Gain
	var target_gain = lerp(0.3, 0.6, intensity)
	left_synth.gain = target_gain
	right_synth.gain = target_gain
	
	# Left Loop
	left_timer += delta
	while left_event_idx < left_loop_events.size() and left_timer >= left_loop_events[left_event_idx].time:
		_execute_event(left_synth, left_loop_events[left_event_idx])
		left_event_idx += 1
		
	if left_timer >= left_loop_duration:
		left_timer -= left_loop_duration
		left_event_idx = 0
		
	# Right Loop
	right_timer += delta
	while right_event_idx < right_loop_events.size() and right_timer >= right_loop_events[right_event_idx].time:
		_execute_event(right_synth, right_loop_events[right_event_idx])
		right_event_idx += 1
		
	if right_timer >= right_loop_duration:
		right_timer -= right_loop_duration
		right_event_idx = 0

func _execute_event(synth: DiscreetSynth, evt):
	# Density Check
	if intensity < 0.3 and randf() > (0.2 + intensity * 2.0):
		return # Skip event at very low intensity
		
	var freq = NOTES[evt.note]
	if evt.type == "trigger":
		synth.trigger_note(freq, evt.dur)
	elif evt.type == "set":
		synth.set_note(freq)
