extends Node3D

@export var looper_path: NodePath
var looper: SystemsMusicLooper

# Visuals
var background_rings: Array[MeshInstance3D] = []
var arc_rings: Array[MeshInstance3D] = []
var play_head_line: MeshInstance3D

# Shader Resource
const ARC_SHADER_SOURCE = "res://commons/audio/systems/air_points/ArcRing.gdshader"

# Colors (Matching User Reference)
const BG_RING_COLOR = Color(0.92, 0.92, 0.92, 1.0) # Very light grey background
const ARC_COLOR = Color(0.85, 0.1, 0.38, 1.0) # Deep Pink
const LINE_COLOR = Color(0.6, 0.6, 0.6, 1.0) # Dark Grey Playhead

func _ready():
	if looper_path:
		looper = get_node(looper_path)
		await get_tree().process_frame
		_setup_visuals()

func _setup_visuals():
	if not looper: return
	
	# Clear existing
	for c in get_children():
		c.queue_free()
	background_rings.clear()
	arc_rings.clear()
	
	# 1. Calculate radii
	var min_dur = 1000.0
	var max_dur = 0.0
	for loop in looper.loops:
		if loop.duration < min_dur: min_dur = loop.duration
		if loop.duration > max_dur: max_dur = loop.duration
	
	# 2. Create Play Head Line
	_create_play_head_line()
	
	# 3. Load Shader
	var shader = load(ARC_SHADER_SOURCE)
	if not shader:
		push_error("ArcRing.gdshader not found!")
		return
		
	for i in range(looper.loops.size()):
		var loop = looper.loops[i]
		
		# Radius mapping
		var norm_dur = (loop.duration - min_dur) / (max_dur - min_dur + 0.001)
		var radius = 1.0 + norm_dur * 1.5
		radius += i * 0.05 
		var thickness = 0.1 # Thicker bands as per image
		
		# --- Background Ring (Static) ---
		var bg_mesh = TorusMesh.new()
		bg_mesh.inner_radius = radius
		bg_mesh.outer_radius = radius + thickness
		bg_mesh.rings = 64
		bg_mesh.ring_segments = 16 # Changed from radial_segments
		
		var bg_mat = StandardMaterial3D.new()
		bg_mat.albedo_color = BG_RING_COLOR
		bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bg_mesh.material = bg_mat
		
		var bg_ring = MeshInstance3D.new()
		bg_ring.mesh = bg_mesh
		bg_ring.rotation_degrees.x = 90 
		add_child(bg_ring)
		background_rings.append(bg_ring)
		
		# --- Arc Ring (Dynamic) ---
		var arc_mesh = TorusMesh.new()
		arc_mesh.inner_radius = radius
		arc_mesh.outer_radius = radius + thickness
		arc_mesh.rings = 64
		arc_mesh.ring_segments = 16 # Changed from radial_segments
		
		var arc_mat = ShaderMaterial.new()
		arc_mat.shader = shader
		arc_mat.set_shader_parameter("albedo", ARC_COLOR)
		
		# Calculate Arc Fraction
		var total_len = loop.duration + loop.delay
		var arc_frac = loop.duration / total_len
		arc_mat.set_shader_parameter("arc_end", arc_frac)
		
		var arc_ring = MeshInstance3D.new()
		arc_ring.mesh = arc_mesh
		arc_ring.rotation_degrees.x = 90
		
		# Important: Align UVs. Usually TorusMesh UV.x starts at -X or something.
		# We will calibrate rotation in _process.
		
		add_child(arc_ring)
		arc_rings.append(arc_ring)
		
		# Store metadata for update
		arc_ring.set_meta("total_len", total_len)
		arc_ring.set_meta("duration", loop.duration)

func _create_play_head_line():
	var line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(5.0, 0.02, 0.02)
	
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = LINE_COLOR
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mesh.material = line_mat
	
	play_head_line = MeshInstance3D.new()
	play_head_line.mesh = line_mesh
	play_head_line.position = Vector3(2.5, 0, 0) # Extends from 0 to 5 on X axis
	
	add_child(play_head_line)

func _process(_delta):
	if not looper: return
	if arc_rings.size() == 0: return
	
	for i in range(looper.loops.size()):
		var arc_ring = arc_rings[i]
		var total_len = arc_ring.get_meta("total_len")
		var duration = arc_ring.get_meta("duration")
		
		# Determine Phase (0.0 to 1.0)
		# 0.0 = Start of Note (Switch from Delay to Loop)
		# 1.0 = End of Delay
		
		var current_time_in_cycle = 0.0
		if looper.loop_states[i]: # Delay Phase
			current_time_in_cycle = duration + looper.loop_timers[i]
		else: # Loop Phase
			current_time_in_cycle = looper.loop_timers[i]
			
		var phase = current_time_in_cycle / total_len
		
		# Rotation Logic:
		# At phase 0.0, the START of the arc should be at the Playhead (Angle 0)
		# As phase increases, the ring should rotate CLOCKWISE (-Z rotation in 2D, or Y in 3D XZ plane)
		# so that the arc passes UNDER the playhead.
		
		# Angle = -Phase * 360
		var angle_rad = -phase * TAU
		
		# NOTE: We need to calibrate the TorusMesh UV offset.
		# Experimentally, if UV.x=0 is at angle X, we need to subtract X.
		# Usually UV starts at -PI (Left/West).
		# We want UV.x=0 (Start of Arc) to align with Playhead (East/0) when angle_rad is 0.
		# If UV start is West (-180), and Playhead is East (0), we need 180 deg offset.
		# Let's try adding PI (180 deg).
		
		arc_ring.rotation.y = angle_rad + PI
		
		# Pulse effect when note starts
		if not looper.loop_states[i] and looper.loop_timers[i] < 0.2:
			arc_ring.scale = Vector3.ONE * 1.05
		else:
			arc_ring.scale = arc_ring.scale.lerp(Vector3.ONE, 0.1)
