extends Node

@export var synth_path: NodePath
@export var listener_path: NodePath

var synth: FMPianoSynth
var listener: AirPointListener

var last_proximity: float = 0.0
var trigger_threshold: float = 0.5
var trigger_cooldown: float = 0.0

func _ready():
	if synth_path: synth = get_node(synth_path)
	if listener_path: listener = get_node(listener_path)

func _process(delta):
	if not synth or not listener: return
	
	if trigger_cooldown > 0:
		trigger_cooldown -= delta
		return
		
	# Simple logic: Trigger a note when proximity crosses threshold
	# Or when speed spikes?
	
	# Let's trigger on velocity spikes (acceleration)
	if listener.acceleration.length() > 2.0:
		_trigger_random_note()
		trigger_cooldown = 0.2
		
	# Or just periodic based on proximity?
	# The closer you are, the faster it plays
	elif listener.proximity > 0.1:
		# Map proximity 0.1-1.0 to rate 0.5s - 0.05s
		var rate = lerp(0.5, 0.05, listener.proximity)
		if trigger_cooldown <= -rate:
			_trigger_random_note()
			trigger_cooldown = 0.0 # reset relative

func _trigger_random_note():
	var notes = [261.63, 311.13, 349.23, 392.00, 415.30, 523.25] # Fm7 chord tones
	var note = notes[randi() % notes.size()]
	var vel = 0.5 + listener.proximity * 0.5
	synth.play_note(note, vel)

