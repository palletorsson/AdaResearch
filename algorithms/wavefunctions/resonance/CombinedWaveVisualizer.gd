extends Node3D

## Combined Wave Visualizer
## Shows the additive combination of all resonating bars
## Based on exercise_3_12_additive_wave_vr.gd

const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_points: int = 100
@export var wave_width: float = 1.0
@export var wave_height_scale: float = 0.5
@export var display_height: float = 1.5
## A line strip one pixel wide vanishes in a capture (this project's standing rule); the sum
## is drawn as a flat ribbon of this half-thickness instead (2026-09-11).
@export var ribbon_half_thickness: float = 0.004
## Opted into by the table stand. Other placements retain the schematic trace.
@export var sample_audio: bool = false
@export var window_seconds: float = 0.012
var _audio_windows: Array[Dictionary] = []
var _summed_samples := PackedFloat32Array()
var _display_limited: bool = false

var _wave_mesh: MeshInstance3D
var _status_label: Label3D
var _time: float = 0.0
var _resonating_bars: Array[ResonatingBar] = []

func _ready() -> void:
	_setup_visualization()
	_find_resonating_bars()

func _setup_visualization() -> void:
	# Create wave mesh
	_wave_mesh = MeshInstance3D.new()
	_wave_mesh.name = "WaveMesh"
	_wave_mesh.position.y = display_height
	add_child(_wave_mesh)

	# Create status label
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 20
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.outline_size = 3
	_status_label.outline_modulate = Color(0, 0, 0, 1)
	_status_label.position = Vector3(0, display_height + 0.3, 0)
	_status_label.scale = Vector3.ONE * 0.08
	add_child(_status_label)

func _find_resonating_bars() -> void:
	"""Find all ResonatingBar nodes in the scene"""
	# THE VISUALISER NEVER SAW THE BARS (2026-09-11): it looked only at the parent's direct
	# children, and ResonatingMetallophone keeps its bars under a "Bars" container, so every
	# placement drew a flat line and read "Hit bars with stick!" while bars rang. Recursive.
	_resonating_bars.clear()
	if get_parent():
		for child in get_parent().find_children("*", "ResonatingBar", true, false):
			if child is ResonatingBar and child not in _resonating_bars:
				_resonating_bars.append(child)
				if not child.hit.is_connected(_on_bar_hit):
					child.hit.connect(_on_bar_hit)

	print("CombinedWaveVisualizer: Found %d resonating bars" % _resonating_bars.size())

func _on_bar_hit(frequency: float, amplitude: float) -> void:
	print("CombinedWaveVisualizer: Bar hit - %.0f Hz @ %.2f amplitude" % [frequency, amplitude])

func _process(delta: float) -> void:
	_time += delta
	_update_wave()
	_update_status()

func _update_wave() -> void:
	"""Combine all active resonances into one visual wave"""
	var mesh := ImmediateMesh.new()
	var pts: Array[Vector3] = []
	var cols: Array[Color] = []

	var active_count = 0
	_audio_windows.clear()
	_summed_samples.resize(num_points)
	_summed_samples.fill(0.0)
	_display_limited = false
	if sample_audio:
		for bar in _resonating_bars:
			if is_instance_valid(bar) and bar.is_resonating:
				var window: Dictionary = bar.get_audio_window(window_seconds, num_points)
				_audio_windows.append(window)
				var values: PackedFloat32Array = window["samples"]
				for i in num_points:
					_summed_samples[i] += values[i]

	for i in num_points:
		var x := remap(i, 0, num_points - 1, -wave_width * 0.5, wave_width * 0.5)
		var y := 0.0

		# Add contribution from each resonating bar
		if sample_audio:
			y = _summed_samples[i]
			_display_limited = _display_limited or absf(y) > 1.0
			y = clampf(y, -1.0, 1.0) # fixed display range, never auto-normalised
		else:
			for bar in _resonating_bars:
				if bar.is_resonating:
					y += bar.get_current_wave_contribution(_time + x * 0.5)
					if i == 0:
						active_count += 1

		# Apply height scaling
		y *= wave_height_scale

		# Create vertex
		var pos := Vector3(x, y, 0)

		# Color intensity based on amplitude
		var intensity = clamp(abs(y) / (wave_height_scale * 0.5), 0.0, 1.0)
		var color = Color(1.0, 0.75 + intensity * 0.25, 0.95, 0.8 + intensity * 0.2)
		pts.append(pos)
		cols.append(color)

	# the polyline as a ribbon in the display plane
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d: Vector3 = b - a
		if d.length() < 0.000001:
			continue
		var n: Vector3 = Vector3(-d.y, d.x, 0.0).normalized() * ribbon_half_thickness
		for q in [a + n, b + n, b - n, a + n, b - n, a - n]:
			mesh.surface_set_color(cols[i])
			mesh.surface_add_vertex(q)
	mesh.surface_end()
	_wave_mesh.mesh = mesh

	if MAT_WAVE:
		_wave_mesh.material_override = MAT_WAVE

func _update_status() -> void:
	"""Update status label"""
	if sample_audio:
		var n: int = _audio_windows.size()
		var lines: Array[String] = []
		if n == 0:
			lines.append("silent · strike a bar")
		else:
			lines.append("%d voice%s · %.0f ms · source samples%s" % [n, "" if n == 1 else "s", window_seconds * 1000.0, " · display limit" if _display_limited else ""])
			for i in range(0, n, 2):
				var pair: Array[String] = []
				for j in range(i, mini(i + 2, n)):
					var w: Dictionary = _audio_windows[j]
					pair.append("%.0f Hz · %.1f s" % [w["frequency"], w["age"]])
				lines.append("    |    ".join(pair))
		_status_label.text = "\n".join(lines)
		return
	var active_count = 0
	for bar in _resonating_bars:
		if bar.is_resonating:
			active_count += 1

	if active_count > 0:
		# the voices, readable: which bar, how loud now, how long since its strike
		var parts: Array[String] = []
		for bar in _resonating_bars:
			if bar.is_resonating:
				parts.append("%.0f Hz %.2f (%.1f s)" % [bar.frequency, bar.current_amplitude, bar.resonance_time])
		_status_label.text = ("%d voice%s · " % [active_count, "" if active_count == 1 else "s"]) + " · ".join(parts)
	else:
		_status_label.text = "silent · strike a bar"

# Public API
func add_resonating_bar(bar: ResonatingBar) -> void:
	"""Manually add a resonating bar to track"""
	if bar not in _resonating_bars:
		_resonating_bars.append(bar)
		bar.hit.connect(_on_bar_hit)

func clear_bars() -> void:
	"""Clear all tracked bars"""
	_resonating_bars.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
