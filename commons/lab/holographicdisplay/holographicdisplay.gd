# holographicdisplay.gd
# Holographic display with sine-based scan lines and flicker
# Demonstrates interference patterns and wave visualization
extends Node3D

class_name LabHolographicDisplay


# @identity
# essence: hologram(t) = content * (1 + scale_pulse * sin(2*TAU*t)) + bob * sin(1.5*TAU*t)
# desire: Observe a floating holographic projection that bobs and pulses with subtle oscillation
# critical_parameter: record — whether the projection is a live view or a long exposure
# triggers: time drives vertical bob, scale pulse, scan line sweep, and flicker effects; record decides how much of the turn is drawn at once
# emerges: the illusion of a sci-fi hologram from layered sine-driven animation
# needs: VR observation [has], content swap [missing], glitch trigger [has]
# relationships: shares the `record` axis word for word with [[seismograph]], [[multimeter]] and [[atmosphericmonitoring]]; contrasts with microscope (hologram vs optical instrument)
# truth: A hologram is light structured by interference — oscillation made visible as projection. A display that keeps nothing is a window; one that keeps its own past is an instrument.

# ── RECORD ───────────────────────────────────────────────────────────────────
# THE AXIS, shared word for word with [[seismograph]], [[multimeter]] and
# [[atmosphericmonitoring]]: what this instrument KEEPS. The other three grow paper; this
# one has no paper, so it keeps its record in the same medium it displays in — light. That
# is the interesting case in the family, because it is the one where the record and the
# reading are made of the same stuff and you have to be told which is which.
#
#   instant   one cube, the pose it is in now. a window.                     ← legacy
#   window    a short wake — three dimmer copies trailing the live pose
#   archive   the whole turn drawn at once: twelve poses, a shell of edges
#   margin    the archive, READ: graticule rings, a tick bezel, two caliper marks
#
# It is a long exposure, not a motion blur: every pose in the shell is a pose the cube
# genuinely holds, drawn from the same twelve edges and eight corners as the live one. The
# wake rotates WITH the content (so `window` reads as trailing it); the graticule does not,
# because the reader's marks belong to the room and not to the thing being measured.
#
# NOT TOUCHED: the projection. The rotation, bob, scale pulse, scan line, flicker, emitter
# glow and projector phases all run identically at every rung, and every added node lives
# outside HologramContent so _set_hologram_opacity cannot reach it and it cannot reach the
# flicker.
@export_enum("instant", "window", "archive", "margin") var record: String = "instant"

@export_group("Hologram")
@export var scan_frequency: float = 2.0  # Hz
@export var flicker_frequency: float = 15.0  # Hz (subtle)
@export var flicker_intensity: float = 0.1
@export var hologram_color: Color = Color(0.2, 0.8, 1.0)
@export var hologram_height: float = 0.2

@export_group("Effects")
@export var rotation_speed: float = 0.3  # Rotations per second
@export var vertical_oscillation: float = 0.01
@export var scale_pulse: float = 0.05

## Internal
var time: float = 0.0
var hologram_content: Node3D
var scan_line: MeshInstance3D
var base_emitter: MeshInstance3D
var projector_lights: Array[SpotLight3D] = []

func _ready() -> void:
	_build_display()
	_build_record()

func _process(delta: float) -> void:
	time += delta

	# Hologram rotation
	if hologram_content:
		hologram_content.rotation.y += rotation_speed * delta * TAU
		# The wake follows the pose it is a wake OF. Null at record:instant, so the legacy
		# lineage never reaches this. The graticule lives on a separate, unturned node.
		if _rec_wake != null:
			_rec_wake.rotation.y = hologram_content.rotation.y
		
		# Vertical bob
		var bob = vertical_oscillation * sin(time * 1.5 * TAU)
		hologram_content.position.y = 0.15 + bob
		
		# Scale pulse
		var pulse = 1.0 + scale_pulse * sin(time * 2.0 * TAU)
		hologram_content.scale = Vector3(pulse, pulse, pulse)
	
	# Scan line sweeps up and down
	if scan_line:
		var scan_pos = sin(time * scan_frequency * TAU) * hologram_height * 0.4
		scan_line.position.y = 0.15 + scan_pos
		
		# Scan line intensity
		if scan_line.material_override:
			var intensity = 0.5 + 0.5 * abs(cos(time * scan_frequency * TAU))
			scan_line.material_override.emission_energy_multiplier = intensity * 2.0
	
	# Flicker effect on hologram
	if hologram_content:
		var flicker = 1.0 - flicker_intensity * (0.5 + 0.5 * sin(time * flicker_frequency * TAU))
		_set_hologram_opacity(flicker)
	
	# Base emitter glow
	if base_emitter and base_emitter.material_override:
		var glow = 0.8 + 0.4 * sin(time * 3.0)
		base_emitter.material_override.emission_energy_multiplier = glow
	
	# Projector lights
	for i in range(projector_lights.size()):
		var light = projector_lights[i]
		var phase = float(i) * TAU / float(projector_lights.size())
		var intensity = 0.3 + 0.2 * sin(time * 4.0 + phase)
		light.light_energy = intensity

func _set_hologram_opacity(opacity: float) -> void:
	for child in hologram_content.get_children():
		if child is MeshInstance3D and child.material_override:
			child.material_override.albedo_color.a = opacity * 0.6

func _build_display() -> void:
	for child in get_children():
		child.queue_free()
	projector_lights.clear()
	
	# Base platform
	var base = MeshInstance3D.new()
	base.name = "Base"
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.12
	base_mesh.bottom_radius = 0.14
	base_mesh.height = 0.03
	base_mesh.radial_segments = 32
	base.mesh = base_mesh
	base.position = Vector3(0, 0.015, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.1, 0.12, 0.15)
	base_mat.metallic = 0.8
	base_mat.roughness = 0.2
	base.material_override = base_mat
	add_child(base)
	
	# Emitter ring
	base_emitter = MeshInstance3D.new()
	base_emitter.name = "EmitterRing"
	var emitter_mesh = TorusMesh.new()
	emitter_mesh.inner_radius = 0.08
	emitter_mesh.outer_radius = 0.1
	base_emitter.mesh = emitter_mesh
	base_emitter.position = Vector3(0, 0.035, 0)
	base_emitter.rotation.x = PI / 2
	var emitter_mat = StandardMaterial3D.new()
	emitter_mat.albedo_color = hologram_color
	emitter_mat.emission_enabled = true
	emitter_mat.emission = hologram_color
	emitter_mat.emission_energy_multiplier = 1.0
	base_emitter.material_override = emitter_mat
	add_child(base_emitter)
	
	# Projector points around the ring
	for i in range(4):
		var angle = float(i) * TAU / 4.0
		var x = cos(angle) * 0.09
		var z = sin(angle) * 0.09
		
		var proj_light = SpotLight3D.new()
		proj_light.name = "Projector_%d" % i
		proj_light.position = Vector3(x, 0.04, z)
		proj_light.rotation.x = -PI / 3
		proj_light.rotation.y = angle + PI
		proj_light.light_color = hologram_color
		proj_light.light_energy = 0.3
		proj_light.spot_range = 0.3
		proj_light.spot_angle = 30.0
		add_child(proj_light)
		projector_lights.append(proj_light)
	
	# Hologram content container
	hologram_content = Node3D.new()
	hologram_content.name = "HologramContent"
	hologram_content.position = Vector3(0, 0.15, 0)
	add_child(hologram_content)
	
	# Sample hologram - rotating wireframe cube
	_create_hologram_cube()
	
	# Scan line
	scan_line = MeshInstance3D.new()
	scan_line.name = "ScanLine"
	var scan_mesh = BoxMesh.new()
	scan_mesh.size = Vector3(0.2, 0.003, 0.2)
	scan_line.mesh = scan_mesh
	scan_line.position = Vector3(0, 0.15, 0)
	var scan_mat = StandardMaterial3D.new()
	scan_mat.albedo_color = Color(hologram_color.r, hologram_color.g, hologram_color.b, 0.3)
	scan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scan_mat.emission_enabled = true
	scan_mat.emission = hologram_color
	scan_mat.emission_energy_multiplier = 1.0
	scan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scan_line.material_override = scan_mat
	add_child(scan_line)

func _create_hologram_cube() -> void:
	var cube_size = 0.08
	var holo_mat = StandardMaterial3D.new()
	holo_mat.albedo_color = Color(hologram_color.r, hologram_color.g, hologram_color.b, 0.5)
	holo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo_mat.emission_enabled = true
	holo_mat.emission = hologram_color
	holo_mat.emission_energy_multiplier = 1.5
	holo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Wireframe edges (12 edges of a cube)
	var edge_thickness = 0.003
	var edges = [
		# Bottom face
		{"start": Vector3(-1, -1, -1), "end": Vector3(1, -1, -1)},
		{"start": Vector3(1, -1, -1), "end": Vector3(1, -1, 1)},
		{"start": Vector3(1, -1, 1), "end": Vector3(-1, -1, 1)},
		{"start": Vector3(-1, -1, 1), "end": Vector3(-1, -1, -1)},
		# Top face
		{"start": Vector3(-1, 1, -1), "end": Vector3(1, 1, -1)},
		{"start": Vector3(1, 1, -1), "end": Vector3(1, 1, 1)},
		{"start": Vector3(1, 1, 1), "end": Vector3(-1, 1, 1)},
		{"start": Vector3(-1, 1, 1), "end": Vector3(-1, 1, -1)},
		# Verticals
		{"start": Vector3(-1, -1, -1), "end": Vector3(-1, 1, -1)},
		{"start": Vector3(1, -1, -1), "end": Vector3(1, 1, -1)},
		{"start": Vector3(1, -1, 1), "end": Vector3(1, 1, 1)},
		{"start": Vector3(-1, -1, 1), "end": Vector3(-1, 1, 1)},
	]
	
	for edge in edges:
		var start = edge.start * cube_size / 2.0
		var end = edge.end * cube_size / 2.0
		var midpoint = (start + end) / 2.0
		var length = start.distance_to(end)
		var direction = (end - start).normalized()
		
		var edge_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = edge_thickness
		cyl.bottom_radius = edge_thickness
		cyl.height = length
		edge_mesh.mesh = cyl
		edge_mesh.position = midpoint
		edge_mesh.material_override = holo_mat
		
		# Rotate to align with edge direction
		if direction != Vector3.UP and direction != Vector3.DOWN:
			edge_mesh.look_at_from_position(midpoint, midpoint + direction, Vector3.UP)
			edge_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		hologram_content.add_child(edge_mesh)
	
	# Corner spheres
	var corners = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1),
		Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1),
	]
	
	for corner in corners:
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = edge_thickness * 1.5
		sphere_mesh.height = edge_thickness * 3.0
		sphere.mesh = sphere_mesh
		sphere.position = corner * cube_size / 2.0
		sphere.material_override = holo_mat
		hologram_content.add_child(sphere)

## Public API
func set_hologram_color(color: Color) -> void:
	hologram_color = color
	# Would need to rebuild or update materials

func set_content_rotation_speed(speed: float) -> void:
	rotation_speed = speed

func trigger_glitch() -> void:
	# Temporary high flicker
	var original_flicker = flicker_intensity
	flicker_intensity = 0.8
	await get_tree().create_timer(0.3).timeout
	flicker_intensity = original_flicker


# ── RECORD, BUILT ────────────────────────────────────────────────────────────
# APPENDED. Every line below is gated behind `record != "instant"`, so the legacy lineage
# adds no node and allocates no material.

## The poses drawn behind the live one, per rung. `window` is a wake of three; `archive` is
## the whole turn, twelve poses at thirty degrees, which for a cube closes into a shell.
const REC_WAKE_STEP := 18.0
const REC_WAKE_POSES := 3
const REC_TURN_POSES := 12
const REC_CUBE := 0.08
const REC_EDGE := 0.003
const REC_MARK := Color(0.86, 0.45, 0.06)

var _rec_wake: Node3D = null
var _rec_marks: Node3D = null


## A map may set the rung with `#record:archive`. Only the record layer is rebuilt; the base,
## emitter ring, projectors, HologramContent and scan line are never touched.
func apply_grid_config(config_data: Dictionary) -> void:
	var raw: String = ""
	if config_data.has("record"):
		raw = str(config_data["record"])
	elif has_meta("config_record"):
		raw = str(get_meta("config_record"))
	if raw == "":
		return
	var want: String = raw.strip_edges().to_lower()
	if not (want in ["instant", "window", "archive", "margin"]):
		push_warning("holographicdisplay: unknown record rung '%s' — keeping '%s'" % [want, record])
		return
	if want == record:
		return
	record = want
	if _rec_wake != null:
		_rec_wake.queue_free()
		_rec_wake = null
	if _rec_marks != null:
		_rec_marks.queue_free()
		_rec_marks = null
	_build_record()


func _build_record() -> void:
	if record == "instant":
		return
	_rec_wake = Node3D.new()
	_rec_wake.name = "RecordWake"
	_rec_wake.position = Vector3(0, 0.15, 0)
	add_child(_rec_wake)

	if record == "window":
		# A wake: three poses the cube has just left, each dimmer than the one in front of it.
		for i in range(REC_WAKE_POSES):
			var fade: float = 1.0 - float(i) / float(REC_WAKE_POSES + 1)
			_rec_cube(deg_to_rad(-REC_WAKE_STEP * float(i + 1)),
				_rec_holo(0.30 * fade, 0.75 * fade))
	else:
		# The whole turn at once. Every pose is one the cube genuinely holds; drawn together
		# they close into a shell, which is what a long exposure of a turning object is.
		var mat: StandardMaterial3D = _rec_holo(0.22, 0.55)
		for i in range(REC_TURN_POSES):
			_rec_cube(TAU * float(i) / float(REC_TURN_POSES), mat)

	if record == "margin":
		_rec_graticule()


## One pose of the cube: the same twelve edges and eight corners as the live one, built with
## explicit axis rotations rather than look_at, so no node needs to be inside the tree first.
func _rec_cube(yaw: float, mat: StandardMaterial3D) -> void:
	var pose := Node3D.new()
	pose.rotation.y = yaw
	_rec_wake.add_child(pose)
	var h: float = REC_CUBE * 0.5
	for sa in [-1.0, 1.0]:
		for sb in [-1.0, 1.0]:
			# four edges along X, four along Y, four along Z
			_rec_bar(pose, Vector3(0.0, sa * h, sb * h), Vector3(0.0, 0.0, PI / 2.0), mat)
			_rec_bar(pose, Vector3(sa * h, 0.0, sb * h), Vector3.ZERO, mat)
			_rec_bar(pose, Vector3(sa * h, sb * h, 0.0), Vector3(PI / 2.0, 0.0, 0.0), mat)


func _rec_bar(parent: Node3D, pos: Vector3, rot: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = REC_EDGE
	cyl.bottom_radius = REC_EDGE
	cyl.height = REC_CUBE
	cyl.radial_segments = 6
	mi.mesh = cyl
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	parent.add_child(mi)


## MARGIN: the reader's marks. Three graticule rings the shell can be measured against, a
## tick bezel round the foot of it, and two caliper bars picking out one sector. These sit
## on their own node and do NOT turn with the content — the marks belong to the room.
func _rec_graticule() -> void:
	_rec_marks = Node3D.new()
	_rec_marks.name = "RecordMarks"
	add_child(_rec_marks)
	var mat: StandardMaterial3D = _rec_holo(0.55, 1.6, REC_MARK)
	for y in [0.112, 0.150, 0.188]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.0665
		torus.outer_radius = 0.0690
		ring.mesh = torus
		ring.position = Vector3(0, y, 0)
		ring.material_override = mat
		_rec_marks.add_child(ring)
	for k in range(24):
		var a: float = TAU * float(k) / 24.0
		var tick := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.011, 0.0018, 0.0018)
		tick.mesh = bm
		tick.position = Vector3(cos(a) * 0.077, 0.112, sin(a) * 0.077)
		tick.rotation.y = -a
		tick.material_override = mat
		_rec_marks.add_child(tick)
	for a2 in [0.0, PI * 0.5]:
		var cal := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.036, 0.0030, 0.0030)
		cal.mesh = cb
		cal.position = Vector3(cos(a2) * 0.088, 0.112, sin(a2) * 0.088)
		cal.rotation.y = -a2
		cal.material_override = mat
		_rec_marks.add_child(cal)


## The hologram's own look — unshaded, alpha, emissive — at a given opacity and energy. Same
## material family as _create_hologram_cube, so a recorded pose is made of the same light as
## a live one. A fresh material each call: these must never be reached by the flicker, which
## rewrites albedo alpha on HologramContent's children every frame.
func _rec_holo(alpha: float, energy: float, tint: Color = Color(-1, -1, -1)) -> StandardMaterial3D:
	var c: Color = hologram_color if tint.r < 0.0 else tint
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
