extends Node
class_name MusicGraphSystem

@export var synth_path: NodePath
var synth: GraphSynth

var nodes: Dictionary = {} # ID -> MusicGraphNode
var active_cursors: Array[Dictionary] = [] # { "current_node": ID, "timer": 0.0 }

func _ready():
	if synth_path: synth = get_node(synth_path)
	_build_test_graph()
	# Start
	active_cursors.append({"current_node": "root", "timer": 0.0})

func _build_test_graph():
	# A simple looping graph with branching
	_add_node("root", "C4", 1.0, Vector3(0,0,0))
	_add_edge("root", "mid", "next")
	
	_add_node("mid", "E4", 0.5, Vector3(2,0,0))
	_add_edge("mid", "high", "fork", 0.5) # Branch 1 (50%)
	_add_edge("mid", "low", "next")  # Branch 2
	
	_add_node("high", "G4", 0.5, Vector3(4,2,0))
	_add_edge("high", "end", "next")
	
	_add_node("low", "C3", 1.0, Vector3(4,-2,0))
	_add_edge("low", "end", "next")
	
	_add_node("end", "C5", 2.0, Vector3(6,0,0))
	_add_edge("end", "root", "loop") # Loop back

func _add_node(id, note, dur, pos):
	var n = MusicGraphNode.new()
	n.id = id
	n.note = note
	n.duration = dur
	n.position = pos
	nodes[id] = n

func _add_edge(from, to, type, chance=1.0):
	if nodes.has(from):
		nodes[from].add_edge(to, type, chance)

func _process(delta):
	if not synth: return
	
	for i in range(active_cursors.size() - 1, -1, -1):
		var cursor = active_cursors[i]
		
		# Safety check for invalid nodes
		if not nodes.has(cursor.current_node):
			active_cursors.remove_at(i)
			continue
			
		var node = nodes[cursor.current_node]
		
		# Scale timer by intensity (higher intensity = faster)
		var speed_scale = lerp(0.8, 1.5, intensity)
		cursor.timer += delta * speed_scale
		
		if cursor.timer >= node.duration:
			# Time to move - Trigger logic was here, but moving it to entry makes more sense for rhythm
			_move_cursor(i)

var intensity: float = 0.5 # 0.0 to 1.0

func set_intensity(val: float):
	intensity = clamp(val, 0.0, 1.0)

func _move_cursor(idx):
	var cursor = active_cursors[idx]
	var node = nodes[cursor.current_node]
	
	if node.edges.is_empty():
		active_cursors.remove_at(idx) # Dead end
		return
		
	# Check max polyphony based on intensity
	# Low intensity: 1-2 cursors. High intensity: up to 8.
	var max_cursors = int(lerp(1.0, 8.0, intensity))
	
	# Logic: Always try to move the current cursor along one "main" path (next/loop).
	# Forks are optional additions.
	
	var moved = false
	var edges_shuffled = node.edges.duplicate()
	edges_shuffled.shuffle() # Randomize order so we don't bias the first definition
	
	for edge in edges_shuffled:
		var roll = randf()
		
		# Modulate chance with intensity for forks
		var chance = edge.chance
		if edge.type == "fork":
			chance *= lerp(0.5, 2.0, intensity) # More forks at high intensity
			
		if roll > chance: continue
		
		if edge.type == "fork":
			# Spawn new cursor if room
			if active_cursors.size() < max_cursors:
				var new_cursor = {"current_node": edge.target_id, "timer": 0.0}
				active_cursors.append(new_cursor)
				# Play note immediately
				if nodes.has(edge.target_id):
					synth.play_note(nodes[edge.target_id].note)
			
		else: # "next" or "loop"
			if not moved:
				# Move current cursor
				cursor.current_node = edge.target_id
				cursor.timer = 0.0
				moved = true
				if nodes.has(edge.target_id):
					synth.play_note(nodes[edge.target_id].note)

	
	# If we didn't find a valid move (bad luck with probabilities), force first edge
	if not moved and not node.edges.is_empty():
		var fallback = node.edges[0]
		cursor.current_node = fallback.target_id
		cursor.timer = 0.0
		if nodes.has(fallback.target_id):
			synth.play_note(nodes[fallback.target_id].note)

