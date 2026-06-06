extends Node3D
class_name DopplerEffectDemo

## Doppler Effect — moving source emits wave rings that compress ahead and stretch behind.
## Each ring expands from its emission position, not the current source position,
## naturally showing wavelength compression (blue shift) and stretching (red shift).

# @identity
# essence: a moving source that drops an expanding ring at every tick, each ring
#   growing from WHERE it was born, not where the source is now. Because the
#   source keeps moving, the rings pile up ahead and spread out behind — and the
#   geometry alone, no extra physics, produces the Doppler shift. The DOPPLER
#   EFFECT shown as pure kinematics: frequency change is just emission positions
#   left behind by motion.
# desire: to dissolve the mystery of pitch-shift into something you can see. The
#   demo wants to prove that the rising siren and the falling one are the SAME
#   sound — that the shift lives not in the source but in the relationship
#   between motion and the listener's place. It wants the observer marker to read
#   blue ahead and red behind from one unchanged emitter.
# critical_parameter: source_speed relative to wave_expand_speed — their ratio is
#   the Mach number. Below 1 the rings nest and shift; approaching 1 they bunch
#   into a wall ahead (the shock cone); the ratio IS how much compression the
#   observer hears.
# triggers: _process advances the source, emits a ring every emit_interval, and
#   expands every live ring; rings store their birth position so expansion is
#   anchored to emission, not to the source
# emerges: ahead of the source reads BLUE-SHIFT / COMPRESSED; behind reads
#   RED-SHIFT / STRETCHED; ratio near 1 reads SHOCK / PILE-UP. Same emitter, the
#   observer's POSITION relative to motion IS the pitch
# relationships: cousin to wave and oscillation artifacts (all propagate from a
#   source, but the Doppler demo adds a MOVING origin); peer to coupled_pendulums
#   only loosely (both are about relation, here between source and observer);
#   sibling to any artifact where the same signal reads differently by vantage
# truth: the Doppler effect is the rule that observed frequency depends on the
#   relative motion of source and observer — and this demo shows the deeper fact
#   that it is not a property of the wave but of GEOMETRY: rings centered on past
#   positions, seen from a place the source is moving toward or away from. Pitch
#   is parallax for sound.

# --- Configuration ---
@export var arena_size: float = 0.8
@export var source_speed: float = 0.15
@export var emit_interval: float = 0.18
@export var wave_expand_speed: float = 0.25
@export var max_rings: int = 30
@export var circle_segments: int = 48
@export var ring_max_radius: float = 0.6

# --- Colors ---
@export var color_blue_shift: Color = Color(0.3, 0.5, 1.0)
@export var color_neutral: Color = Color(0.8, 0.8, 0.8)
@export var color_red_shift: Color = Color(1.0, 0.3, 0.2)
@export var color_source: Color = Color(1.0, 0.8, 0.2)

# --- Internal ---
var _time: float = 0.0
var _emit_timer: float = 0.0
var _source_mesh: MeshInstance3D
var _ring_mesh: MeshInstance3D
var _ring_material: StandardMaterial3D
var _title_label: Label3D
var _freq_label: Label3D
var _observer_marker: MeshInstance3D
var _base_mesh: MeshInstance3D

# Ring data: each ring stores [emit_x, emit_z, birth_time]
var _rings: Array[Vector3] = []

# Observer position (stationary, ahead of source path)
var _observer_pos: Vector3 = Vector3(0.3, 0.0, 0.0)


func _ready() -> void:
	_build_base()
	_build_source()
	_build_observer()
	_build_ring_display()
	_build_labels()


func _build_base() -> void:
	_base_mesh = MeshInstance3D.new()
	_base_mesh.name = "ArenaBase"
	var box := BoxMesh.new()
	box.size = Vector3(arena_size, 0.01, arena_size)
	_base_mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.06)
	mat.roughness = 0.9
	_base_mesh.material_override = mat
	_base_mesh.position.y = -0.005
	add_child(_base_mesh)


func _build_source() -> void:
	_source_mesh = MeshInstance3D.new()
	_source_mesh.name = "WaveSource"
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	_source_mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_source
	mat.emission_enabled = true
	mat.emission = color_source
	mat.emission_energy_multiplier = 1.0
	_source_mesh.material_override = mat
	_source_mesh.position.y = 0.025
	add_child(_source_mesh)


func _build_observer() -> void:
	_observer_marker = MeshInstance3D.new()
	_observer_marker.name = "Observer"
	var sphere := SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	_observer_marker.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.4)
	mat.emission_energy_multiplier = 0.5
	_observer_marker.material_override = mat
	_observer_marker.position = Vector3(_observer_pos.x, 0.015, _observer_pos.z)
	add_child(_observer_marker)


func _build_ring_display() -> void:
	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.name = "WaveRings"
	add_child(_ring_mesh)

	_ring_material = StandardMaterial3D.new()
	_ring_material.vertex_color_use_as_albedo = true
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _build_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "DOPPLER EFFECT"
	_title_label.pixel_size = 0.002
	_title_label.font_size = 16
	_title_label.modulate = Color.WHITE
	_title_label.position = Vector3(0, 0.35, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)

	_freq_label = Label3D.new()
	_freq_label.name = "FreqLabel"
	_freq_label.pixel_size = 0.0015
	_freq_label.font_size = 14
	_freq_label.modulate = Color(0.2, 1.0, 0.4)
	_freq_label.position = Vector3(_observer_pos.x, 0.06, _observer_pos.z + 0.05)
	_freq_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_freq_label)

	# Source label
	var src_label := Label3D.new()
	src_label.name = "SourceLabel"
	src_label.text = "SOURCE"
	src_label.pixel_size = 0.001
	src_label.font_size = 12
	src_label.modulate = color_source
	src_label.position = Vector3(0, 0.08, 0)
	src_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_source_mesh.add_child(src_label)

	# Observer label
	var obs_label := Label3D.new()
	obs_label.name = "ObserverLabel"
	obs_label.text = "OBSERVER"
	obs_label.pixel_size = 0.001
	obs_label.font_size = 12
	obs_label.modulate = Color(0.2, 1.0, 0.4)
	obs_label.position = Vector3(0, 0.04, 0.03)
	obs_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_observer_marker.add_child(obs_label)


func _process(delta: float) -> void:
	_time += delta

	# Move source back and forth along X axis
	var half_travel := arena_size * 0.35
	var source_x := sin(_time * source_speed * TAU / (2.0 * half_travel)) * half_travel
	_source_mesh.position.x = source_x

	# Emit new ring periodically
	_emit_timer += delta
	if _emit_timer >= emit_interval:
		_emit_timer -= emit_interval
		_emit_ring(source_x)

	# Remove old rings that have expanded past max radius
	_cull_old_rings()

	# Rebuild ring visuals
	_rebuild_rings()

	# Update frequency label
	_update_freq_label(source_x)


func _emit_ring(source_x: float) -> void:
	# Store: (emit_x, emit_z, birth_time)
	_rings.append(Vector3(source_x, 0.0, _time))

	# Cap ring count
	if _rings.size() > max_rings:
		_rings.remove_at(0)


func _cull_old_rings() -> void:
	var i := 0
	while i < _rings.size():
		var age := _time - _rings[i].z
		var radius := age * wave_expand_speed
		if radius > ring_max_radius:
			_rings.remove_at(i)
		else:
			i += 1


func _rebuild_rings() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	for ring_data in _rings:
		var emit_x: float = ring_data.x
		var emit_z: float = ring_data.y
		var birth_time: float = ring_data.z
		var age := _time - birth_time
		var radius := age * wave_expand_speed

		if radius < 0.001:
			continue

		# Fade out as ring expands
		var alpha := clampf(1.0 - radius / ring_max_radius, 0.1, 1.0)

		_draw_circle(im, Vector3(emit_x, 0.005, emit_z), radius, alpha)

	im.surface_end()
	_ring_mesh.mesh = im
	_ring_mesh.material_override = _ring_material


func _draw_circle(im: ImmediateMesh, center: Vector3, radius: float, alpha: float) -> void:
	for i in range(circle_segments):
		var angle_a := float(i) / float(circle_segments) * TAU
		var angle_b := float(i + 1) / float(circle_segments) * TAU

		var pa := center + Vector3(cos(angle_a) * radius, 0, sin(angle_a) * radius)
		var pb := center + Vector3(cos(angle_b) * radius, 0, sin(angle_b) * radius)

		# Color based on direction from source center to this segment
		# Points ahead of source motion get blue-shifted, behind get red-shifted
		var seg_mid_angle := (angle_a + angle_b) * 0.5
		var seg_dir_x := cos(seg_mid_angle)

		# Source moves in +X direction when sin is increasing (first half of cycle)
		# Use the source velocity direction at emission time to determine shift
		# Simplification: color by segment's X-direction relative to center
		# Positive X = ahead (blue shift), Negative X = behind (red shift)
		var shift := clampf(seg_dir_x, -1.0, 1.0)
		var ring_color: Color
		if shift > 0.0:
			ring_color = color_neutral.lerp(color_blue_shift, shift)
		else:
			ring_color = color_neutral.lerp(color_red_shift, -shift)
		ring_color.a = alpha

		im.surface_set_color(ring_color)
		im.surface_add_vertex(pa)
		im.surface_set_color(ring_color)
		im.surface_add_vertex(pb)


func _update_freq_label(source_x: float) -> void:
	# Calculate apparent frequency at observer based on Doppler formula
	# f_observed = f_source * v_wave / (v_wave + v_source_away)
	# v_source_away = component of source velocity toward/away from observer

	var source_vel_x := source_speed * TAU / (2.0 * arena_size * 0.35) * cos(_time * source_speed * TAU / (2.0 * arena_size * 0.35)) * arena_size * 0.35
	var dir_to_observer := (_observer_pos.x - source_x)
	var dist_to_observer := absf(dir_to_observer)

	if dist_to_observer < 0.01:
		_freq_label.text = "f = 1.00x"
		return

	# Velocity component along direction from source to observer
	# Positive = approaching, negative = receding
	var v_along := source_vel_x * signf(dir_to_observer)

	# Doppler ratio: f_obs / f_source = v_wave / (v_wave - v_source_toward)
	var denominator := wave_expand_speed - v_along
	if absf(denominator) < 0.001:
		denominator = 0.001

	var ratio := wave_expand_speed / denominator
	ratio = clampf(ratio, 0.3, 3.0)

	# Color the label based on shift
	if ratio > 1.05:
		_freq_label.modulate = color_blue_shift.lerp(Color.WHITE, 0.3)
	elif ratio < 0.95:
		_freq_label.modulate = color_red_shift.lerp(Color.WHITE, 0.3)
	else:
		_freq_label.modulate = Color(0.8, 0.8, 0.8)

	_freq_label.text = "f = %.2fx" % ratio


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("source_speed"):
		source_speed = float(config_data["source_speed"])
	if config_data.has("emit_interval"):
		emit_interval = float(config_data["emit_interval"])
	if config_data.has("wave_expand_speed"):
		wave_expand_speed = float(config_data["wave_expand_speed"])
