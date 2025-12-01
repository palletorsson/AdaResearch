extends MusicGraphSystem
class_name CircleOfFifthsSystem

func _ready():
	if synth_path: synth = get_node(synth_path)
	_build_circle_graph()
	
	# Start single cursor for cleaner polyphony (will fork over time)
	active_cursors.append({"current_node": "C4", "timer": 0.0})

func _build_circle_graph():
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octaves = [3, 4, 5]
	
	# 1. Create Nodes
	for oct in octaves:
		for i in range(12):
			var note_name = notes[i] + str(oct)
			var angle = i * (TAU / 12.0) # Chromatic angle
			# Circle of Fifths angle: i * 7 * (TAU / 12)
			var fifths_angle = (i * 7) % 12 * (TAU / 12.0)
			
			# Visual Position: Circle of Fifths
			var radius = 3.0 + (oct - 4) * 1.5 # Radius per octave
			var pos = Vector3(cos(fifths_angle) * radius, sin(fifths_angle) * radius, 0)
			
			# Slower duration (0.8s) for less chaos
			_add_node(note_name, note_name, 0.8, pos)
	
	# 2. Create Edges
	for id in nodes:
		var n = nodes[id]
		var pitch = _parse_note_index(n.note)
		var oct = int(n.note.substr(n.note.length()-1))
		
		# Edge 1: Perfect Fifth Up (Clockwise) - Main Path
		var next_pitch = (pitch + 7) % 12
		var next_id = notes[next_pitch] + str(oct)
		if nodes.has(next_id):
			_add_edge(id, next_id, "next", 0.8) # 80% chance to go forward
			
		# Edge 2: Perfect Fourth Up / Fifth Down (Counter-Clockwise)
		# Probability fork to modulate back
		var prev_pitch = (pitch + 5) % 12
		var prev_id = notes[prev_pitch] + str(oct)
		if nodes.has(prev_id):
			# Fork: Low chance (15%) to spawn a new voice going backwards
			nodes[id].add_edge(prev_id, "fork", 0.15)
			
		# Edge 3: Relative Minor (Down 3 semitones / Up 9)
		# C -> A
		var rel_pitch = (pitch + 9) % 12
		var rel_id = notes[rel_pitch] + str(oct)
		if nodes.has(rel_id):
			# Loop/Alternative: 10% chance to switch to relative minor instead of 5th
			nodes[id].add_edge(rel_id, "loop", 0.1)
			
		# Edge 4: Octave Jump (Up/Down)
		# Occurs "after a while" (low probability)
		var octave_up_id = notes[pitch] + str(oct + 1)
		var octave_down_id = notes[pitch] + str(oct - 1)
		
		if nodes.has(octave_up_id):
			# 5% chance to jump UP an octave
			nodes[id].add_edge(octave_up_id, "loop", 0.05)
			
		if nodes.has(octave_down_id):
			# 5% chance to jump DOWN an octave
			nodes[id].add_edge(octave_down_id, "loop", 0.05)

func _parse_note_index(note: String) -> int:
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var key = note.substr(0, note.length()-1)
	return notes.find(key)

