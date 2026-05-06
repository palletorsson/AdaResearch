extends MusicGraphSystem
class_name GitTimelineSystem

## GitTimelineSystem
## Generates a musical graph representing a "Git Timeline".
## - "Master" branch (v1): The initial stable melody (Blue).
## - "Feature" branches: Experimental forks.
## - "Release" branch (v2): An extended timeline that opens up "after a while" (Purple).

var active_cursors: Array = []

func _ready():
	if synth_path: synth = get_node(synth_path)
	_build_git_graph()
	
	# Start cursor on Master branch
	active_cursors.append({"current_node": "commit_0", "timer": 0.0})

func _build_git_graph():
	var master_scale = ["C3", "D3", "E3", "F3", "G3", "A3", "B3", "C4", "D4", "E4", "F4", "G4"]
	var feature_scale = ["C#4", "D#4", "F#4", "G#4", "A#4"] # Pentatonic-ish / Accidentals
	
	var spacing_x = 2.0
	var master_commits = 16
	
	# --- 1. Master Branch v1 (The Trunk) ---
	for i in range(master_commits):
		var id = "commit_%d" % i
		var note = master_scale[i % master_scale.size()]
		var pos = Vector3(i * spacing_x, 0, 0)
		
		var col = Color(0.2, 0.5, 1.0) # Master Blue
		if i == 0: col = Color(0.8, 0.8, 0.8) # Init
		
		# Add Node
		var dur = 0.6
		if i % 4 == 0: dur = 1.2 # Downbeat
		
		_add_colored_node(id, note, dur, pos, col)
		
		# Link to previous
		if i > 0:
			var prev = "commit_%d" % (i-1)
			_add_edge(prev, id, "next")
			
	# --- 2. v2.0 Release Branch (The Extended Timeline) ---
	# Starts after master_commits
	var v2_commits = 24
	var v2_scale = ["G3", "A3", "B3", "C4", "D4", "E4", "F#4", "G4", "A4", "B4", "C5", "D5"] # Modulate to G Major
	var v2_start_x = master_commits * spacing_x + 2.0
	
	for i in range(v2_commits):
		var id = "v2_commit_%d" % i
		var note = v2_scale[i % v2_scale.size()]
		var pos = Vector3(v2_start_x + (i * spacing_x), 0, 0)
		
		# v2 Color (Purple/Pink) to distinguish "Next Version"
		var col = Color(0.6, 0.2, 0.8) 
		if i == 0: col = Color(0.9, 0.8, 1.0) # v2 Launch
		
		var dur = 0.5 # Slightly faster tempo for v2
		if i % 8 == 0: dur = 1.5 # Big downbeats
		
		_add_colored_node(id, note, dur, pos, col)
		
		if i > 0:
			var prev = "v2_commit_%d" % (i-1)
			_add_edge(prev, id, "next")
			
	# Loop v2 back to itself (v2.0 -> v2.0)
	_add_edge("v2_commit_%d" % (v2_commits-1), "v2_commit_0", "loop")
	
	# --- Links: v1 -> v2 ---
	# At the end of v1, we can either loop back to v1 (Maintenance) or upgrade to v2 (Release)
	var end_v1 = "commit_%d" % (master_commits-1)
	
	# 80% chance to stay in v1 loop
	_add_edge(end_v1, "commit_0", "loop", 0.8)
	
	# 20% chance to upgrade to v2
	# This creates the "traverse to after a while" behavior
	_add_edge(end_v1, "v2_commit_0", "next", 0.2)
	
	
	# --- 3. Feature Branch A (v1 Fork) ---
	# Forks at commit_2, Merges at commit_10
	var fork_start = 2
	var merge_target = 10
	var branch_len = 6
	
	for i in range(branch_len):
		var id = "featureA_%d" % i
		var note = feature_scale[i % feature_scale.size()]
		var pos = Vector3((fork_start + 1 + i) * spacing_x, 2.0, 0) 
		
		_add_colored_node(id, note, 0.4, pos, Color(0.2, 0.8, 0.4)) # Feature Green
		
		if i == 0:
			_add_edge("commit_%d" % fork_start, id, "fork", 0.6)
		else:
			_add_edge("featureA_%d" % (i-1), id, "next")
			
	_add_edge("featureA_%d" % (branch_len-1), "commit_%d" % merge_target, "next")
	
	# --- 4. Feature Branch B (v1 Bass Fork) ---
	# Forks at commit_6, Dead ends or Loops
	fork_start = 6
	branch_len = 5
	
	for i in range(branch_len):
		var id = "featureB_%d" % i
		var note = master_scale[(i * 2) % master_scale.size()].replace("3", "2") 
		var pos = Vector3((fork_start + 1 + i) * spacing_x, -2.0, 0)
		
		_add_colored_node(id, note, 0.8, pos, Color(0.9, 0.5, 0.1)) # Feature Orange
		
		if i == 0:
			_add_edge("commit_%d" % fork_start, id, "fork", 0.4)
		else:
			_add_edge("featureB_%d" % (i-1), id, "next")
			
	_add_edge("featureB_%d" % (branch_len-1), "featureB_0", "loop")

	# --- 5. Feature Branch C (v2 Refactor) ---
	# A complex branch in the v2 timeline
	# Loops around v2_commit_8 to v2_commit_16
	fork_start = 8
	branch_len = 8
	
	for i in range(branch_len):
		var id = "refactor_%d" % i
		var note = v2_scale[(i * 3) % v2_scale.size()].replace("4", "5") # High octave arpeggios
		var pos = Vector3(v2_start_x + (fork_start + 1 + i) * spacing_x, 3.0, 0)
		
		_add_colored_node(id, note, 0.3, pos, Color(1.0, 0.2, 0.4)) # Refactor Red/Pink
		
		if i == 0:
			_add_edge("v2_commit_%d" % fork_start, id, "fork", 0.5)
		else:
			_add_edge("refactor_%d" % (i-1), id, "next")
			
	# Merge back into v2
	_add_edge("refactor_%d" % (branch_len-1), "v2_commit_%d" % (fork_start + branch_len + 2), "next")

func _add_colored_node(id, note, dur, pos, col):
	var n = MusicGraphNode.new()
	n.id = id
	n.note = note
	n.duration = dur
	n.position = pos
	n.color = col
	nodes[id] = n
