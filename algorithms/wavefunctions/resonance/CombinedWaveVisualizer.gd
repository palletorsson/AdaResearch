extends Node3D

## Combined Wave Visualizer
## Shows the additive combination of all resonating bars
## Based on exercise_3_12_additive_wave_vr.gd

const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_points: int = 100
@export var wave_width: float = 1.0
@export var wave_height_scale: float = 0.5
@export var display_height: float = 1.5

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
	# Look in parent for bars
	if get_parent():
		for child in get_parent().get_children():
			if child is ResonatingBar:
				_resonating_bars.append(child)
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
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var active_count = 0

	for i in num_points:
		var x := remap(i, 0, num_points - 1, -wave_width * 0.5, wave_width * 0.5)
		var y := 0.0

		# Add contribution from each resonating bar
		for bar in _resonating_bars:
			if bar.is_resonating:
				# Get wave contribution at current time
				y += bar.get_current_wave_contribution(_time + x * 0.5)
				if i == 0:  # Count active bars once
					active_count += 1

		# Apply height scaling
		y *= wave_height_scale

		# Create vertex
		var pos := Vector3(x, y, 0)

		# Color intensity based on amplitude
		var intensity = clamp(abs(y) / (wave_height_scale * 0.5), 0.0, 1.0)
		var color = Color(1.0, 0.75 + intensity * 0.25, 0.95, 0.8 + intensity * 0.2)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	_wave_mesh.mesh = mesh

	if MAT_WAVE:
		_wave_mesh.material_override = MAT_WAVE

func _update_status() -> void:
	"""Update status label"""
	var active_count = 0
	for bar in _resonating_bars:
		if bar.is_resonating:
			active_count += 1

	if active_count > 0:
		_status_label.text = "Resonating: %d bars" % active_count
	else:
		_status_label.text = "Hit bars with stick!"

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
