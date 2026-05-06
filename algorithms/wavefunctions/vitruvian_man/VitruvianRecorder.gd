extends Node3D

@export var recording_node_path: NodePath
@export var sample_rate: float = 0.05 # Seconds between samples
@export var max_harmonics: int = 10 # Number of epicycles

var _recording_node: Node3D
var _points: Array[Vector3] = []
var _is_recording: bool = false
var _timer: float = 0.0
var _fourier_body_scene = preload("res://algorithms/wavefunctions/vitruvian_man/FourierBody.tscn")
var _current_body: Node3D

func _ready() -> void:
	if recording_node_path:
		_recording_node = get_node(recording_node_path)
	else:
		_recording_node = self
	
	if continuous_mode:
		start_recording()


func start_recording() -> void:
	_points.clear()
	_is_recording = true
	_timer = 0.0
	if _current_body:
		_current_body.queue_free()
		_current_body = null

func stop_recording() -> void:
	_is_recording = false
	if _points.size() > 2:
		var descriptors = calculate_dft(_points, max_harmonics)
		spawn_body(descriptors)

func _process(delta: float) -> void:
	if _is_recording:
		_timer += delta
		if _timer >= sample_rate:
			_timer = 0.0
			# Record local position relative to this node (the center of the vitruvian man)
			var pos = _recording_node.global_position
			var local_pos = to_local(pos)
			_points.append(local_pos)
			
			# Continuous mode: Keep buffer size limited
			if continuous_mode:
				# Estimate points needed for buffer_duration
				var max_points = int(buffer_duration / sample_rate)
				if _points.size() > max_points:
					_points.pop_front()
				
				_update_timer += sample_rate
				if _update_timer >= update_interval:
					_update_timer = 0.0
					if _points.size() > 10:
						var descriptors = calculate_dft(_points, max_harmonics)
						spawn_body(descriptors)

@export var continuous_mode: bool = true
@export var buffer_duration: float = 3.0 # Seconds of history to keep
@export var update_interval: float = 0.5 # How often to update the Fourier body

var _update_timer: float = 0.0



func calculate_dft(path_points: Array[Vector3], num_harmonics: int) -> Array:
	var N = path_points.size()
	var descriptors = []
	
	# We want frequencies from -M to +M, sorted by magnitude (radius) usually, 
	# but for reconstruction we just need the list.
	# 0 is the center offset.
	
	var freqs = []
	freqs.append(0)
	for i in range(1, num_harmonics + 1):
		freqs.append(i)
		freqs.append(-i)
		
	for k in freqs:
		var sum_real = 0.0
		var sum_imag = 0.0
		
		for n in range(N):
			var p = path_points[n]
			# Treat x as real, y as imag (ignore z for 2D projection)
			var x = p.x
			var y = p.y
			
			var angle = -2.0 * PI * k * n / N
			var c = cos(angle)
			var s = sin(angle)
			
			# (x + iy) * (c + is) = (xc - ys) + i(xs + yc)
			sum_real += x * c - y * s
			sum_imag += x * s + y * c
			
		var avg_real = sum_real / N
		var avg_imag = sum_imag / N
		
		var radius = sqrt(avg_real * avg_real + avg_imag * avg_imag)
		var phase = atan2(avg_imag, avg_real)
		
		# Filter out very small wheels
		if radius > 0.001:
			descriptors.append({
				"freq": float(k),
				"radius": radius,
				"phase": phase
			})
			
	# Sort by radius descending (optional, but looks better if big wheels are first)
	descriptors.sort_custom(func(a, b): return a.radius > b.radius)
	
	return descriptors

func spawn_body(descriptors) -> void:
	if _current_body and is_instance_valid(_current_body):
		_current_body.configure(descriptors)
	elif _fourier_body_scene:
		_current_body = _fourier_body_scene.instantiate()
		add_child(_current_body)
		_current_body.configure(descriptors)

func apply_grid_config(config: Dictionary) -> void:
	pass
