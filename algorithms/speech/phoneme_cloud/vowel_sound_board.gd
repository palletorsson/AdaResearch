extends Node3D

# Vowel Sound Board
# Modeled after NailColorController.
# Maps 3D Space (ValueMapper) to Vowel Field (F1, Delta, Intensity).
# Supports "Automatic" pattern playback (Tweening the cursor).

@onready var mapper = $ValueMapper3D
@onready var synth = $VowelSynth3D
@onready var label_mode = $LabelMode
@onready var label_word = $LabelWord

# Field Constraints (Matches Vowels.json / Theory)
const F1_MIN = 200.0
const F1_MAX = 900.0
const DELTA_MIN = 200.0
const DELTA_MAX = 2200.0

# Anchors for Patterns (F1, Delta)
const ANCHORS = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345),
	"r": Vector2(450, 750), # Approx
	"d_locus": Vector2(200, 1600) # Locus
}

const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const TEST_PHONEMES = {
	"Vowels": ["i", "e", "a", "o", "u"],
	"Fricatives": ["s", "z", "f", "v", "sh", "th", "h"],
	"Plosives": ["p", "b", "t", "d", "k", "g"],
	"Nasals": ["m", "n", "ng"],
	"Liquids": ["l", "r", "w", "y"],
	"Affricates": ["ch", "j"]
}

# Playback State
var is_playing_sequence: bool = false

# --- Trail / Trace Logic ---
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _trail_times: Array[float] = []
var _time_elapsed: float = 0.0
const TRAIL_FADE_DURATION: float = 1.0
const TRAIL_COLOR: Color = Color(1.0, 0.4, 0.9, 1.0) # Pink/Magenta trace

func _ready():
	# Configure Mapper Range
	mapper.output_x_min = DELTA_MIN
	mapper.output_x_max = DELTA_MAX
	mapper.label_x = "Delta (Identity)"
	
	mapper.output_y_min = F1_MIN
	mapper.output_y_max = F1_MAX
	mapper.label_y = "F1 (Openness)"
	
	mapper.output_z_min = 0.0
	mapper.output_z_max = 1.0
	mapper.label_z = "Intensity"
	
	mapper.values_changed.connect(_on_mapper_changed)
	
	# Initial State
	label_mode.text = "Mode: Manual (Grab Point)"
	label_word.text = ""
	
	# Style LabelWord
	var font = load("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")
	label_word.font = font
	label_word.font_size = 18 # Even Smaller
	label_word.position.x += 0.15
	label_word.position.y -= 0.15
	
	# Add Frame to LabelWord
	var word_bg_mesh = QuadMesh.new()
	word_bg_mesh.size = Vector2(0.4, 0.12) # Smaller Frame
	var word_bg = MeshInstance3D.new()
	word_bg.mesh = word_bg_mesh
	var mat_w = StandardMaterial3D.new()
	mat_w.albedo_color = Color(0.0, 0.0, 0.0, 0.5)
	mat_w.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_w.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_w.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	word_bg.material_override = mat_w
	word_bg.position = Vector3(0, 0, -0.01)
	label_word.add_child(word_bg)
	
	# Visuals
	_spawn_visual_anchors()
	_setup_trail()
	_create_test_panel()
	
	# Auto-Play Loop ("Now and then")
	_start_ambient_loop()

func _start_ambient_loop():
	await get_tree().create_timer(1.0).timeout
	while true:
		if not is_inside_tree(): return
		
		play_word("ada")
		await get_tree().create_timer(1.5).timeout
		
		play_word("research")
		await get_tree().create_timer(2.0).timeout
		
		# New Request
		play_word("iloveyou")
		await get_tree().create_timer(2.0).timeout
		
		# "Now and then" -> Pause
		await get_tree().create_timer(4.0).timeout

func _play_iloveyou():
	# 1. I (/a/ -> /i/)
	_set_mapper_pos(ANCHORS["a"], 0.0)
	label_word.text = "I"
	_tween_mapper(ANCHORS["a"], 1.0, 0.1) # Fade In /a/
	await get_tree().create_timer(0.3).timeout
	
	_tween_mapper(ANCHORS["i"], 1.0, 0.2) # Glide /i/
	await get_tree().create_timer(0.3).timeout
	
	# Gap
	_tween_mapper(ANCHORS["i"], 0.0, 0.2)
	await get_tree().create_timer(0.25).timeout
	
	# 2. Love (/l/ -> /uh/ -> /v/)
	label_word.text = "Love"
	# /l/ approx
	var pos_l = Vector2(800, 400) # F1=400, Delta=800
	_set_mapper_pos(pos_l, 0.0)
	_tween_mapper(pos_l, 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	
	# /uh/ (Central)
	_tween_mapper(ANCHORS["a"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	
	# /v/ (Fade out)
	_tween_mapper(ANCHORS["i"], 0.0, 0.2) 
	await get_tree().create_timer(0.2).timeout
	
	# 3. You (/y/ -> /u/)
	label_word.text = "You"
	# /y/ (semivowel /j/ is like /i/)
	_set_mapper_pos(ANCHORS["i"], 0.0)
	_tween_mapper(ANCHORS["i"], 1.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	
	# /u/
	_tween_mapper(ANCHORS["u"], 1.0, 0.3)
	await get_tree().create_timer(0.8).timeout # Hold
	
	# Fade
	_tween_mapper(ANCHORS["u"], 0.0, 0.5)


func _process(delta):
	if not mapper.point: return
	
	_time_elapsed += delta
	var current_pos = mapper.point.global_position
	
	# Add point
	# Only add if moving?
	if _trail_points.is_empty() or current_pos.distance_squared_to(_trail_points[-1]) > 0.0001:
		_trail_points.append(current_pos)
		_trail_times.append(_time_elapsed)
	
	# Fade / Cleanup
	var cutoff = _time_elapsed - TRAIL_FADE_DURATION
	while _trail_times.size() > 0 and _trail_times[0] < cutoff:
		_trail_times.pop_front()
		_trail_points.pop_front()
	
	_rebuild_trail()

func _setup_trail():
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "Trace"
	_trail_instance.mesh = _trail_mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = TRAIL_COLOR
	mat.emission_enabled = true
	mat.emission = TRAIL_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	
	_trail_instance.material_override = mat
	_trail_instance.set_as_top_level(true) # Draw in global space
	add_child(_trail_instance)

func _rebuild_trail():
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2: return
	
	# Using LINE_STRIP for continuous line
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(_trail_points.size()):
		# Fade calculation
		var age = _time_elapsed - _trail_times[i]
		var alpha = 1.0 - clamp(age / TRAIL_FADE_DURATION, 0.0, 1.0)
		var col = TRAIL_COLOR
		col.a = alpha
		_trail_mesh.surface_set_color(col)
		_trail_mesh.surface_add_vertex(_trail_points[i])
	
	_trail_mesh.surface_end()


func _spawn_visual_anchors():
	# Load Font
	var font = load("res://commons/font/Roboto-VariableFont_wdth,wght.ttf")
	
	# Create labels in the 3D graph space at the correct coordinates
	for vowel in ANCHORS:
		var coords = ANCHORS[vowel] # Vector2(F1, Delta)
		
		# Values to Normalized (0-1)
		# X = Delta
		var norm_x = (coords.y - DELTA_MIN) / (DELTA_MAX - DELTA_MIN)
		# Y = F1
		var norm_y = (coords.x - F1_MIN) / (F1_MAX - F1_MIN)
		
		# Map to Space Size
		var pos = Vector3(
			norm_x * mapper.space_size.x,
			norm_y * mapper.space_size.y,
			mapper.space_size.z * 0.5 # Center Z plane
		)
		
		# Offset per user request (Down Y, Right X)
		pos.x += 0.05
		pos.y -= 0.05
		
		var viz = Label3D.new()
		viz.text = "/" + vowel + "/"
		viz.font = font
		viz.font_size = 24 # Smaller
		viz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		viz.modulate = Color(1, 1, 1, 0.8) # More opaque
		viz.position = pos
		viz.scale = Vector3.ONE * 0.08 # Smaller scale
		
		# Frame Background
		var bg_mesh = QuadMesh.new()
		bg_mesh.size = Vector2(0.8, 0.8) # Relative to label scale
		var bg = MeshInstance3D.new()
		bg.mesh = bg_mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1, 0.6) # Dark transparent frame
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bg.material_override = mat
		
		# Parent BG to Label and push back
		bg.position = Vector3(0, 0, -0.01)
		viz.add_child(bg)
		
		# Add as child of mapper so it stays local to graph
		mapper.add_child(viz)

func _on_mapper_changed(delta_val: float, f1_val: float, intensity_val: float):
	# Update Synth Realtime
	# Note: Mapper Y is Up, so high Y = High F1 (Open Mouth)
	# Mapper X is Right, so high X = High Delta (Front Vowels like i)
	
	synth.f1 = f1_val
	synth.delta = delta_val
	synth.target_intensity = intensity_val
	
	if intensity_val > 0.01:
		synth.is_speaking = true
	else:
		synth.is_speaking = false

# --- Automatic Pattern Playback ---

func play_word(word: String):
	if is_playing_sequence: return
	is_playing_sequence = true
	label_mode.text = "Mode: Automatic"
	label_word.text = word
	
	match word.to_lower():
		"ada":
			await _play_ada()
		"research":
			await _play_research()
		"iloveyou":
			await _play_iloveyou()
		"alphabet":
			await _play_alphabet()
	
	is_playing_sequence = false
	label_mode.text = "Mode: Manual (Grab Point)"

func _play_ada():
	# A -> D -> A
	# 1. Move to A, Volume 0
	_set_mapper_pos(ANCHORS["a"], 0.0)
	await get_tree().create_timer(0.1).timeout
	
	# 2. Fade In A
	_tween_mapper(ANCHORS["a"], 1.0, 0.1)
	await get_tree().create_timer(0.4).timeout
	
	# 3. D (Close, Front, Silence)
	_tween_mapper(ANCHORS["d_locus"], 0.0, 0.08)
	await get_tree().create_timer(0.08).timeout
	
	# 4. Burst A
	_tween_mapper(ANCHORS["a"], 1.0, 0.05)
	await get_tree().create_timer(0.4).timeout
	
	# 5. Fade out
	_tween_mapper(ANCHORS["a"], 0.0, 0.2)

func _play_research():
	# R -> i -> S -> er -> ch
	# 1. R
	_set_mapper_pos(ANCHORS["r"], 0.0)
	_tween_mapper(ANCHORS["r"], 0.9, 0.1) # Fade In
	await get_tree().create_timer(0.2).timeout
	
	# 2. Glide i
	_tween_mapper(ANCHORS["i"], 1.0, 0.2)
	await get_tree().create_timer(0.3).timeout
	
	# 3. Silence (S implied)
	_tween_mapper(ANCHORS["i"], 0.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	
	# 4. er (using 'e' anchor approx or custom)
	# er is central. Let's use 'e' but lowered intensity slightly
	_set_mapper_pos(ANCHORS["e"], 0.0) # Snap
	_tween_mapper(ANCHORS["e"], 1.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	
	# 5. Glide back to R
	_tween_mapper(ANCHORS["r"], 1.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	
	# 6. Cut (ch)
	_tween_mapper(ANCHORS["r"], 0.0, 0.05)


func _play_alphabet():
	var cycle = ["i", "e", "a", "o", "u"]
	for v in cycle:
		_set_mapper_pos(ANCHORS[v], 0.0)
		label_word.text = "/ " + v + " /"
		_tween_mapper(ANCHORS[v], 1.0, 0.1)
		await get_tree().create_timer(0.4).timeout
		_tween_mapper(ANCHORS[v], 0.0, 0.1)
		await get_tree().create_timer(0.1).timeout

# Utils to drive the Mapper (which drives the synth)
func _create_test_panel():
	var panel = Node3D.new()
	panel.name = "PhonemeTestPanel"
	add_child(panel)
	panel.position = Vector3(0.4, 0.4, 0.0) # Positioned to the right of mapper
	
	var row_y = 0.0
	for category in TEST_PHONEMES:
		# Category Label
		var cat_label = Label3D.new()
		cat_label.text = category
		cat_label.font_size = 18
		cat_label.position = Vector3(0.0, row_y + 0.08, 0.0)
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(cat_label)
		
		var col_x = 0.0
		for phoneme in TEST_PHONEMES[category]:
			var btn = BUTTON_SCENE.instantiate()
			panel.add_child(btn)
			btn.position = Vector3(col_x, row_y, 0.0)
			btn.scale = Vector3(0.5, 0.5, 0.5) # Half size for grid
			btn.rotation_degrees = Vector3(-90, 0, 0) # Face user
			
			# Label on button
			var lbl = Label3D.new()
			lbl.text = phoneme
			lbl.font_size = 32
			lbl.position = Vector3(0, 0.06, 0) # Slightly above surface
			lbl.rotation_degrees = Vector3(90, 0, 0) # Correct orientation relative to button
			btn.add_child(lbl)
			
			# Connect signal (using category to route)
			var callback = func(): _on_test_button_pressed(category, phoneme)
			btn.pressed.connect(callback)
			
			col_x += 0.08
		
		row_y -= 0.15

func _on_test_button_pressed(category: String, phoneme: String):
	label_word.text = phoneme
	match category:
		"Vowels":
			play_word(phoneme) # This handles vowels
		"Fricatives":
			synth.trigger_fricative(phoneme)
		"Plosives":
			synth.trigger_plosive(phoneme)
		"Nasals":
			synth.trigger_nasal(phoneme)
		"Liquids":
			synth.trigger_approximant(phoneme)
		"Affricates":
			synth.trigger_affricate(phoneme)

func _set_mapper_pos(target_field: Vector2, target_intensity: float):
	mapper.set_values(target_field.y, target_field.x, target_intensity)

func _tween_mapper(target_field: Vector2, target_intensity: float, duration: float):
	var tween = create_tween()
	var start_val = mapper.get_values() # Vector3(delta, f1, int)
	
	# Tween ValueMapper's set_values logic manually or just tween helper
	# Since set_values updates position, we can tween the 'point.position' directly if we knew it,
	# but mapper relies on internal state.
	# Better to just use a proxy generic tween that calls set_values each frame? 
	# Or tween a dummy value and update? 
	# Actually, simpler: Tween independent floats and call set_values in _process?
	# For now, let's just use a method tween.
	
	tween.tween_method(
		func(val: float): 
			# We need to interpolate X, Y, Z together.
			# Method tweening a single float 0->1 is easiest.
			var cur_delta = lerp(start_val.x, target_field.y, val)
			var cur_f1 = lerp(start_val.y, target_field.x, val)
			var cur_int = lerp(start_val.z, target_intensity, val)
			mapper.set_values(cur_delta, cur_f1, cur_int),
		0.0, 1.0, duration
	)
	await tween.finished
