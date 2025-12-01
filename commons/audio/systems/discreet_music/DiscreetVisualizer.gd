extends Node3D

@export var looper_path: NodePath
var looper: DiscreetMusicLooper

# Visuals
var left_tape: MeshInstance3D
var right_tape: MeshInstance3D
var left_markers = []
var right_markers = []

const TAPE_SPEED = 2.0 # Units per second
const MARKER_COLOR = Color(0.2, 0.8, 0.8, 0.8)

func _ready():
	if looper_path:
		looper = get_node(looper_path)
		
	_create_tapes()

func _create_tapes():
	# Left Tape Line
	var mesh = BoxMesh.new()
	mesh.size = Vector3(20.0, 0.05, 0.1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mesh.material = mat
	
	left_tape = MeshInstance3D.new()
	left_tape.mesh = mesh
	left_tape.position = Vector3(0, 1.0, 0)
	add_child(left_tape)
	
	# Right Tape Line
	right_tape = MeshInstance3D.new()
	right_tape.mesh = mesh
	right_tape.position = Vector3(0, -1.0, 0)
	add_child(right_tape)

func _process(delta):
	if not looper: return
	
	# Manage markers (simple approach: clear and redraw or pool? 
	# Let's just spawn markers when notes trigger and move them)
	
	# Actually, visualizing the LOOP structure is better.
	# We can map the entire loop to the tape length.
	pass
	
	# Update marker positions based on loop time
	_update_tape_visuals(looper.left_loop_events, looper.left_timer, looper.left_loop_duration, left_markers, 1.0)
	_update_tape_visuals(looper.right_loop_events, looper.right_timer, looper.right_loop_duration, right_markers, -1.0)

func _update_tape_visuals(events, timer, duration, markers_array, y_pos):
	# This is a bit tricky to do efficiently in _process without reconstructing.
	# Let's just draw the playhead moving over the static loop map?
	# Or the loop map moving past the playhead?
	# "Eno's tape loops" -> The tape moves past the head.
	
	# If markers_array is empty, populate it
	if markers_array.is_empty():
		for evt in events:
			if evt.type == "trigger":
				var m = MeshInstance3D.new()
				m.mesh = BoxMesh.new()
				m.mesh.size = Vector3(evt.dur * TAPE_SPEED, 0.4, 0.1)
				m.material_override = StandardMaterial3D.new()
				m.material_override.albedo_color = MARKER_COLOR
				add_child(m)
				markers_array.append({"mesh": m, "time": evt.time})
	
	# Move markers
	# Tape moves LEFT. Playhead is at X=0.
	# Marker X = (EventTime - Timer) * Speed
	# If Marker X < -10, wrap around? No, loop is circular.
	# Relative time = (EventTime - Timer)
	# If Relative time < 0, add Duration (wrap)
	
	for item in markers_array:
		var rel_time = item.time - timer
		# Handle wrapping for visual continuity
		if rel_time < -5.0: # Just passed
			rel_time += duration
		if rel_time > duration - 5.0:
			rel_time -= duration
			
		var x = rel_time * TAPE_SPEED
		
		# Only show if within view range
		item.mesh.visible = abs(x) < 10.0
		item.mesh.position = Vector3(x, y_pos, 0)

