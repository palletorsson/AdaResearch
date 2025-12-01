extends Node3D

@onready var generator = $EuclideanRhythmGenerator
@onready var visualizer_root = $VisualizerRoot
@onready var info_label = $InfoLabel

var indicators: Array[MeshInstance3D] = []
var step_indicators: Array[MeshInstance3D] = []
var audio_player: AudioStreamPlayer

# Auto-DJ State
var _bar_counter: int = 0
var _beat_counter: int = 0

# Synthesis Parameters
@export_group("Kick Synthesis")
@export var kick_attack: float = 0.005:
	set(v): kick_attack = v; _schedule_regen()
@export var kick_decay: float = 0.35:
	set(v): kick_decay = v; _schedule_regen()
@export var kick_start_freq: float = 120.0:
	set(v): kick_start_freq = v; _schedule_regen()
@export var kick_end_freq: float = 35.0:
	set(v): kick_end_freq = v; _schedule_regen()
@export var kick_distortion: float = 3.0:
	set(v): kick_distortion = v; _schedule_regen()
@export var kick_noise: float = 0.2:
	set(v): kick_noise = v; _schedule_regen()
	
var _regen_timer: Timer

func _ready() -> void:
	# Setup Regen Timer (Debounce)
	_regen_timer = Timer.new()
	_regen_timer.one_shot = true
	_regen_timer.wait_time = 0.1
	_regen_timer.timeout.connect(_regenerate_sound)
	add_child(_regen_timer)

	# Setup Audio
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	_regenerate_sound()
	
	# Setup initial visualization
	_rebuild_visualizer(generator.steps)
	
	# Connect signals
	generator.pattern_changed.connect(_on_pattern_changed)
	generator.pulse.connect(_on_pulse)
	
	# Force initial update
	_on_pattern_changed(generator._current_pattern)
	
	_setup_ui()

func _schedule_regen() -> void:
	if _regen_timer:
		_regen_timer.start()

func _regenerate_sound() -> void:
	if audio_player:
		audio_player.stream = _generate_kick_wav()

func _setup_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Kick Synthesizer"
	vbox.add_child(title)
	
	_add_slider(vbox, "BPM", 60, 200, generator.bpm, func(v): generator.bpm = v; _update_label())
	_add_slider(vbox, "Attack", 0.0, 0.1, kick_attack, func(v): kick_attack = v)
	_add_slider(vbox, "Decay", 0.1, 1.0, kick_decay, func(v): kick_decay = v)
	_add_slider(vbox, "Start Freq", 50, 300, kick_start_freq, func(v): kick_start_freq = v)
	_add_slider(vbox, "End Freq", 10, 100, kick_end_freq, func(v): kick_end_freq = v)
	_add_slider(vbox, "Distortion", 1.0, 10.0, kick_distortion, func(v): kick_distortion = v)
	_add_slider(vbox, "Noise", 0.0, 1.0, kick_noise, func(v): kick_noise = v)

func _add_slider(parent, label_text, min_v, max_v, current, callback: Callable) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.01 if max_v < 10 else 1.0
	slider.value = current
	slider.custom_minimum_size.x = 200
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	var val_label = Label.new()
	val_label.text = "%.2f" % current
	val_label.custom_minimum_size.x = 50
	hbox.add_child(val_label)
	
	slider.value_changed.connect(func(v): val_label.text = "%.2f" % v)

func _on_pulse(step_index: int, is_active: bool) -> void:
	# Highlight current step
	for i in range(step_indicators.size()):
		var mat = step_indicators[i].material_override as StandardMaterial3D
		if i == step_index:
			mat.emission = Color.WHITE
			if is_active:
				_flash_pulse(i)
		else:
			mat.emission = Color.BLACK
			
	# Play sound
	if is_active and audio_player:
		audio_player.play()
		
	# Auto-DJ Logic
	# Assuming 16 steps = 1 bar (4/4 time, 16th notes)
	if step_index == 0:
		_bar_counter += 1
		_apply_humanization()

func _apply_humanization() -> void:
	# BERGHAIN MODE
	# The foundation is the relentess 4-on-the-floor: 1, 5, 9, 13
	
	var pattern = generator._current_pattern
	for i in range(pattern.size()):
		pattern[i] = false
		
	# Base Industrial Kick
	var kicks = [0, 4, 8, 12]
	
	# Variation Cycles (Hypnotic, minimal changes)
	var cycle = _bar_counter % 16
	
	if cycle < 12:
		# Standard Driving Loop
		# Occasionally add an off-beat "ghost" (the reverb catch)
		if cycle % 4 == 3:
			kicks.append(14) # The "skip" at the end
	else:
		# Tension Building (remove a kick)
		if cycle == 14:
			kicks.erase(12) # Drop the 4
		elif cycle == 15:
			kicks = [0, 2, 4, 6, 8, 10, 12, 14] # The Roll / Strobe
			
	# Apply
	for idx in kicks:
		if idx < pattern.size():
			pattern[idx] = true
			
	generator.pattern_changed.emit(pattern)

func _mutate_rhythm() -> void:
	pass # Disabled in favor of _apply_humanization

func _generate_kick_wav() -> AudioStreamWAV:
	# PARAMETRIC KICK
	var sample_rate = 44100
	# Total duration includes decay tail
	var duration = kick_decay + 0.1 
	var frames = int(sample_rate * duration)
	var buffer = PackedByteArray()
	
	var phase = 0.0
	
	for i in range(frames):
		var t = float(i) / float(sample_rate) 
		var norm_t = float(i) / float(frames)
		
		# Pitch: Fast drop logic
		var pitch_env = pow(1.0 - norm_t, 6.0) 
		var current_freq = lerp(kick_end_freq, kick_start_freq, pitch_env)
		
		# Amp: Parametric Envelope
		var amp = 1.0
		if t < kick_attack:
			amp = t / kick_attack # Linear fade-in
		else:
			# Exponential decay based on kick_decay param
			var decay_t = (t - kick_attack) / kick_decay
			if decay_t > 1.0:
				amp = 0.0
			else:
				amp = pow(1.0 - decay_t, 4.0) # Hard curve
			
		phase += current_freq / float(sample_rate)
		
		var raw = sin(TAU * phase) * amp
		
		# Distortion
		raw = clamp(raw * kick_distortion, -0.95, 0.95)
		
		# Noise
		if t > kick_attack:
			var noise = (randf() * 2.0 - 1.0) * kick_noise * amp
			raw += noise
		
		var val = int((raw + 1.0) * 127.5)
		buffer.append(val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = buffer
	return stream

func _rebuild_visualizer(count: int) -> void:
	for child in visualizer_root.get_children():
		child.queue_free()
	indicators.clear()
	step_indicators.clear()
	
	var radius = 2.0
	for i in range(count):
		var angle = TAU * float(i) / float(count)
		# Rotate so index 0 is at top (negative Z) or right? Let's do top (-Z) and go clockwise
		# Godot -Z is forward. 
		var pos = Vector3(sin(angle), 0, -cos(angle)) * radius
		
		# Pulse Indicator (Inner)
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		mesh.mesh.radius = 0.1
		mesh.mesh.height = 0.2
		mesh.position = pos
		visualizer_root.add_child(mesh)
		indicators.append(mesh)
		
		# Create material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.DARK_GRAY
		mesh.material_override = mat
		
		# Active Step Indicator (Outer Ring)
		var step_mesh = MeshInstance3D.new()
		step_mesh.mesh = TorusMesh.new()
		step_mesh.mesh.inner_radius = 0.12
		step_mesh.mesh.outer_radius = 0.15
		step_mesh.position = pos
		# Orient torus flat
		# TorusMesh is usually flat on XZ?
		visualizer_root.add_child(step_mesh)
		step_indicators.append(step_mesh)
		
		var step_mat = StandardMaterial3D.new()
		step_mat.albedo_color = Color.BLACK
		step_mat.emission_enabled = true
		step_mat.emission = Color.BLACK
		step_mesh.material_override = step_mat

func _on_pattern_changed(pattern: Array[bool]) -> void:
	if pattern.size() != indicators.size():
		_rebuild_visualizer(pattern.size())
	
	for i in range(pattern.size()):
		var mat = indicators[i].material_override as StandardMaterial3D
		if pattern[i]:
			mat.albedo_color = Color.CYAN
			mat.emission_enabled = true
			mat.emission = Color.CYAN
			mat.emission_energy_multiplier = 1.0
		else:
			mat.albedo_color = Color.DARK_GRAY
			mat.emission_enabled = false
	
	_update_label()

func _flash_pulse(index: int) -> void:
	var mesh = indicators[index]
	var mat = mesh.material_override as StandardMaterial3D
	var tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3.ONE * 1.5, 0.05)
	tween.tween_property(mesh, "scale", Vector3.ONE, 0.1)

func _update_label() -> void:
	info_label.text = "E(%d, %d) Rotation: %d\nBPM: %.1f" % [
		generator.pulses,
		generator.steps,
		generator.rotation,
		generator.bpm
	]
