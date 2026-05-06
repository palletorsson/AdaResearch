extends Node
class_name MusicGraphSystem

@export var synth_path: NodePath
var synth: GraphSynth

var nodes: Dictionary = {} # ID -> MusicGraphNode
var active_agents: Array[GraphAgent] = []

@export_enum("Ambient", "Chaos", "Melodic") var current_preset: String = "Ambient"

func _ready():
	if synth_path: synth = get_node(synth_path)
	_load_preset(current_preset)

func _input(event):
	if event.is_action_pressed("ui_accept"): # Spacebar
		_cycle_preset()

func _cycle_preset():
	if current_preset == "Ambient": current_preset = "Chaos"
	elif current_preset == "Chaos": current_preset = "Melodic"
	else: current_preset = "Ambient"
	
	print("Switching to: " + current_preset)
	_load_preset(current_preset)

func _load_preset(name: String):
	# Clear existing
	nodes.clear()
	active_agents.clear()
	intensity = 0.5
	
	match name:
		"Ambient":
			_build_ambient_graph()
			intensity = 0.3
			var start_agent = GraphAgent.new("center")
			start_agent.instrument_override = "piano"
			start_agent.speed = 0.4 
			active_agents.append(start_agent)
			_trigger_node_audio("center", "piano")
			
		"Chaos":
			_build_chaos_graph()
			intensity = 0.8
			for i in range(5): # Start with chaos
				var start_agent = GraphAgent.new("node_" + str(randi() % 10))
				start_agent.instrument_override = "synth"
				start_agent.speed = randf_range(1.0, 2.0)
				active_agents.append(start_agent)
		
		"Melodic":
			_build_melodic_graph()
			intensity = 0.6
			# Two synchronized agents
			var a1 = GraphAgent.new("root")
			a1.instrument_override = "piano"
			a1.speed = 1.0
			active_agents.append(a1)
			
			var a2 = GraphAgent.new("bass_root")
			a2.instrument_override = "synth"
			a2.speed = 1.0 # Bass moves slower usually but dist is same
			active_agents.append(a2)

func _build_ambient_graph():
	# ... (Existing Ambient Logic)
	# Center Cluster (Piano Anchor)
	_add_node("center", ["C3", "G3", "D4"], "piano", Vector3(0,0,0))
	_add_edge("center", "ring_1", "next")
	_add_edge("center", "ring_2", "next")
	_add_edge("center", "ring_3", "next")
	
	# Outer Rings (Sci-Fi Synths)
	var ring_radius = 6.0
	for i in range(5):
		var angle = (i / 5.0) * TAU
		var pos = Vector3(cos(angle), 0, sin(angle)) * ring_radius
		var id = "ring_" + str(i+1)
		
		var notes = ["C4"]
		if i == 0: notes = ["C4"]
		if i == 1: notes = ["D4"]
		if i == 2: notes = ["E4"]
		if i == 3: notes = ["G4"]
		if i == 4: notes = ["A4"]
		
		_add_node(id, notes, "synth", pos)
		var next_idx = (i + 1) % 5
		var next_id = "ring_" + str(next_idx + 1)
		_add_edge(id, next_id, "next", 0.7)
		_add_edge(id, "center", "loop", 0.3)
		
		var far_pos = pos * 2.0
		var far_id = "far_" + str(i+1)
		_add_node(far_id, ["C2"], "synth", far_pos)
		_add_edge(id, far_id, "fork", 0.2) 
		_add_edge(far_id, id, "loop") 

func _build_chaos_graph():
	# Random connected web
	for i in range(20):
		var pos = Vector3(randf_range(-8, 8), randf_range(-5, 5), randf_range(-5, 5))
		var id = "node_" + str(i)
		# Random chromatic notes
		var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
		var note = notes.pick_random() + str(randi_range(3, 6))
		
		_add_node(id, [note], "synth", pos)
	
	# Connect randomly
	for i in range(20):
		var id = "node_" + str(i)
		for j in range(3): # 3 connections per node
			var target = "node_" + str(randi() % 20)
			if target != id:
				# High chance of fork for chaos
				var type = "fork" if randf() > 0.5 else "next"
				_add_edge(id, target, type)

func _build_melodic_graph():
	# Linear Melody Loops
	# Loop 1: Chords
	_add_node("root", ["C3", "E3", "G3"], "piano", Vector3(-4, 0, 0))
	_add_node("step1", ["F3", "A3", "C4"], "piano", Vector3(-2, 2, 0))
	_add_node("step2", ["G3", "B3", "D4"], "piano", Vector3(2, 2, 0))
	_add_node("resolve", ["C4", "E4", "G4"], "piano", Vector3(4, 0, 0))
	
	_add_edge("root", "step1", "next")
	_add_edge("step1", "step2", "next")
	_add_edge("step2", "resolve", "next")
	_add_edge("resolve", "root", "loop")
	
	# Loop 2: Bass
	_add_node("bass_root", ["C2"], "synth", Vector3(-4, -2, 0))
	_add_node("bass_sub", ["F2"], "synth", Vector3(0, -4, 0))
	_add_node("bass_dom", ["G2"], "synth", Vector3(4, -2, 0))
	
	_add_edge("bass_root", "bass_sub", "next")
	_add_edge("bass_sub", "bass_dom", "next")
	_add_edge("bass_dom", "bass_root", "loop")

# ... (Rest of file: add_node, process, etc)

func _add_node(id, notes_array, instr, pos):
	# Use dynamic load to avoid class_name cache issues during dev
	var script = load("res://commons/audio/systems/graph_music/MusicGraphNode.gd")
	var n = script.new()
	n.id = id
	n.chord_notes = notes_array
	n.instrument = instr
	n.position = pos
	# Duration logic could be dynamic, but fixed for now
	n.duration = 1.0 
	nodes[id] = n

func _add_edge(from, to, type, chance=1.0):
	if nodes.has(from):
		nodes[from].add_edge(to, type, chance)

func _process(delta):
	if not synth: return
	
	for i in range(active_agents.size() - 1, -1, -1):
		var agent = active_agents[i]
		_process_agent(agent, delta, i)

		
		
func _pick_next_node(agent: GraphAgent):
	var node = nodes[agent.current_node_id]
	if node.edges.is_empty(): return
	
	var edges = node.edges.duplicate()
	edges.shuffle()
	
	var selected_id = ""
	
	for edge in edges:
		var roll = randf()
		# Fork logic
		if edge.type == "fork":
			if roll < edge.chance:
				# Limit max agents based on preset
				var max_agents = 3 # Default low (Ambient)
				if current_preset == "Chaos": max_agents = 20
				if current_preset == "Melodic": max_agents = 4
				
				if active_agents.size() < max_agents:
					var new_agent = GraphAgent.new(agent.current_node_id)
					new_agent.target_node_id = edge.target_id
					new_agent.instrument_override = agent.instrument_override
					
					# Variation in speed
					if current_preset == "Chaos":
						new_agent.speed = agent.speed * randf_range(0.8, 1.5)
					else:
						new_agent.speed = agent.speed 
						
					active_agents.append(new_agent)
		else:
			# Main path (next/loop)
			if selected_id == "":
				selected_id = edge.target_id
	
	# If no main path found but edges exist (and we didn't take any forks?)
	# Fallback to first edge if logic failed
	if selected_id == "" and not edges.is_empty():
		selected_id = edges[0].target_id
		
	agent.target_node_id = selected_id

func _trigger_node_audio(node_id: String, instr_override: String):
	if not nodes.has(node_id): return
	var n = nodes[node_id]
	
	var instr = n.instrument
	if instr_override != "": instr = instr_override
	
	synth.play_notes(n.chord_notes, instr)

var intensity: float = 0.3 # Start lower

func set_intensity(val: float):
	intensity = clamp(val, 0.0, 1.0)

func _process_agent(agent: GraphAgent, delta: float, idx: int):
	# ... (logic same as before but use intensity)
	# If no target, find one
	if agent.target_node_id == "":
		_pick_next_node(agent)
		if agent.target_node_id == "":
			# Dead end, kill agent
			active_agents.remove_at(idx)
			return
			
	# Move agent
	# Scale speed by intensity (0.5 = normal, 1.0 = 2x, 0.0 = 0.5x)
	var speed_mod = lerp(0.5, 2.0, intensity)
	agent.progress += delta * agent.speed * speed_mod
	
	if agent.progress >= 1.0:
		# Arrived!
		agent.current_node_id = agent.target_node_id
		agent.target_node_id = ""
		agent.progress = 0.0
		
		# Trigger Node Logic
		_trigger_node_audio(agent.current_node_id, agent.instrument_override)
