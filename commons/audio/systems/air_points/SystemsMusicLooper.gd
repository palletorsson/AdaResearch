extends Node
class_name SystemsMusicLooper

## SystemsMusicLooper
## Implements the phasing loop logic from Brian Eno's "Music for Airports".
## Controls an FMPianoSynth.

@export var synth_path: NodePath
var synth: FMPianoSynth

# The 7 Loops from the JS reference
# {note: string, octave: int, duration: float, delay: float}
var loops = [
	{"note": "F",  "octave": 4, "duration": 19.7, "delay": 4.0},
	{"note": "G#", "octave": 4, "duration": 17.8, "delay": 8.1}, # Ab -> G#
	{"note": "C",  "octave": 5, "duration": 21.3, "delay": 5.6},
	{"note": "C#", "octave": 5, "duration": 18.5, "delay": 12.6}, # Db -> C#
	{"note": "D#", "octave": 5, "duration": 20.0, "delay": 9.2},  # Eb -> D#
	{"note": "F",  "octave": 5, "duration": 20.0, "delay": 14.1},
	{"note": "G#", "octave": 5, "duration": 17.7, "delay": 3.1}   # Ab -> G#
]

# Note frequencies
const NOTES = {
	"C": 261.63, "C#": 277.18, "D": 293.66, "D#": 311.13, 
	"E": 329.63, "F": 349.23, "F#": 369.99, "G": 392.00, 
	"G#": 415.30, "A": 440.00, "A#": 466.16, "B": 493.88
}

var loop_timers: Array[float] = []
var loop_states: Array[bool] = [] # true if waiting for delay, false if looping

var intensity: float = 0.5 # 0.0 to 1.0

func set_intensity(val: float):
	intensity = clamp(val, 0.0, 1.0)

func _ready():
	if synth_path:
		synth = get_node(synth_path)
	
	for i in range(loops.size()):
		loop_timers.append(0.0)
		loop_states.append(true) # Start in delay phase

func _process(delta):
	if not synth: return
	
	# Modulate Synth Parameters based on intensity
	# Gain: 0.2 to 0.6
	synth.gain = lerp(0.2, 0.6, intensity)
	
	for i in range(loops.size()):
		var loop = loops[i]
		loop_timers[i] += delta
		
		if loop_states[i]: # Delay Phase
			if loop_timers[i] >= loop.delay:
				# Delay finished, play first note and switch to Loop Phase
				_play_loop_note(i)
				loop_timers[i] = 0.0 # Reset relative to loop start
				loop_states[i] = false
		else: # Loop Phase
			if loop_timers[i] >= loop.duration:
				# Loop finished, play note and restart
				_play_loop_note(i)
				loop_timers[i] -= loop.duration

func _play_loop_note(index: int):
	# Density Control: Chance to skip note at low intensity
	# Intensity 0.0 -> 30% chance to play
	# Intensity 0.5 -> 100% chance to play
	if intensity < 0.5:
		if randf() > (0.3 + intensity * 1.4): return
	
	var loop = loops[index]
	var base_freq = NOTES[loop.note]
	# Calculate frequency for octave (base is octave 4)
	var freq = base_freq * pow(2.0, loop.octave - 4)
	
	# Velocity increases with intensity
	var vel = lerp(0.4, 0.9, intensity) + randf() * 0.1
	
	# Map note sustain to loop duration
	# Scale sustain with intensity (longer sustain at high intensity for wash)
	var sustain = lerp(4.0, 8.0, (loop.duration - 17.7) / (21.3 - 17.7))
	sustain *= lerp(0.8, 1.5, intensity)
	
	synth.play_note(freq, vel, sustain)
