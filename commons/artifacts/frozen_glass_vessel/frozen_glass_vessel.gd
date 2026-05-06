# frozen_glass_vessel.gd — Walkable vessel whose shape came from physics.
#
# Build a sphere mesh, pin the top ring (the blowpipe attachment), optionally
# pre-inflate (pressure pulse), then run gravity + spring tension for N steps.
# The simulation runs once at _ready(); the FROZEN POSE is the vessel.
#
# Walkable twin of gl01_classic_bulb in the soft-body gallery. Where that
# image is the research artifact, this is the thesis artifact — a 2-meter
# physics-grown vessel standing next to the player, labeled with its DNA.
#
# @identity
# essence: A glass vessel that no one designed — its shape is the record of gravity × pressure × duration × top pin
# desire: To stand next to a form that was not drawn but grown, and see on a label that the DNA is 3 forces and a clock
# critical_parameter: steps — the clock. Longer simulation = longer neck. Duration is the design parameter.
# triggers: Change stiffness → from rigid orb to collapsing teardrop. Change gravity direction → lopsided handcraft. Change pin width → bottle neck vs bowl mouth.
# emerges: An amphora, a bottle, a bowl, an urn — depending on force balance. Vessel type from force DNA.
# needs: VR scale (1.5m tall), Label3D for pedagogy, double-sided material so interior is visible
# relationships: Walkable twin of soft-body gallery gl01. Same DNA as trajectory-gallery tr01_unit_circle_spiral in spirit — both are "frozen processed form", but this one is 2D-surface instead of 1D-trajectory.
# truth: Duration is DNA. The clock is part of the genome.

extends Node3D

class_name FrozenGlassVessel

const SoftBodySimScript = preload("res://commons/soft_body/soft_body_sim.gd")

## Sphere topology
@export var radius: float = 0.55
@export var rings: int = 14
@export var segments: int = 22

## Vessel physics DNA
@export var pin_top_fraction: float = 0.12   # fraction of top vertices pinned
@export var preinflate: float = 0.2           # pressure pulse before sim
@export var stiffness: float = 0.6
@export var damping: float = 0.995
@export var gravity_y: float = -9.8
@export var gravity_x: float = 0.0           # non-zero = lopsided vessel
@export var gravity_z: float = 0.0
@export var sim_steps: int = 200             # duration — THE design parameter

## Material
@export var vessel_color: Color = Color(0.6, 0.78, 0.82, 0.85)
@export var emission_boost: float = 0.3
@export var roughness: float = 0.35

## Label
@export var show_label: bool = true
@export var label_height: float = 1.85

var _mi: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	_build_vessel()
	if show_label:
		_build_label()


func _build_vessel() -> void:
	# ─── Build sphere verts + triangle topology ───────────────
	var initial_verts: PackedVector3Array = PackedVector3Array()
	for i in rings + 1:
		var phi: float = PI * float(i) / float(rings)
		var y: float = cos(phi) * radius
		var r_ring: float = sin(phi) * radius
		for j in segments:
			var theta: float = TAU * float(j) / float(segments)
			initial_verts.append(Vector3(r_ring * cos(theta), y, r_ring * sin(theta)))

	# ─── Seed soft-body simulation ────────────────────────────
	var sim = SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = stiffness
	sim.damping = damping
	sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
	sim.floor_y = -10.0  # effectively disabled; the vessel hangs free
	sim.constraint_passes = 5

	var pin_y: float = radius * (1.0 - pin_top_fraction * 2.0)
	for i in initial_verts.size():
		var v: Vector3 = initial_verts[i]
		var pinned: bool = v.y > pin_y
		if not pinned and preinflate > 0.0:
			if v.length() > 1e-6:
				v = v * (1.0 + preinflate)
		sim.add_particle(v, pinned)

	# Springs: each quad-cell of the sphere grid
	var stride: int = segments
	for i in rings:
		for j in segments:
			var jn: int = (j + 1) % segments
			var a: int = i * stride + j
			var b: int = i * stride + jn
			var c: int = (i + 1) * stride + j
			var d: int = (i + 1) * stride + jn
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)

	# ─── Run the simulation — THE FROZEN MOMENT ──────────────
	sim.simulate(sim_steps)

	# ─── Build ArrayMesh from the deformed positions ─────────
	var final_verts: PackedVector3Array = sim.positions
	var indices: PackedInt32Array = PackedInt32Array()
	for i in rings:
		for j in segments:
			var jn: int = (j + 1) % segments
			var a: int = i * stride + j
			var b: int = i * stride + jn
			var c: int = (i + 1) * stride + j
			var d: int = (i + 1) * stride + jn
			# Two triangles per quad, CCW outward
			indices.append_array([a, c, d])
			indices.append_array([a, d, b])

	# Compute vertex normals from face cross products
	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(final_verts.size())
	for i in normals.size():
		normals[i] = Vector3.ZERO
	for tri in range(indices.size() / 3):
		var ia: int = indices[tri * 3]
		var ib: int = indices[tri * 3 + 1]
		var ic: int = indices[tri * 3 + 2]
		var n: Vector3 = (final_verts[ib] - final_verts[ia]).cross(
			final_verts[ic] - final_verts[ia])
		if n.length_squared() > 1e-12:
			n = n.normalized()
		normals[ia] += n
		normals[ib] += n
		normals[ic] += n
	for i in normals.size():
		var nn: Vector3 = normals[i]
		normals[i] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.UP

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = final_verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	_mi = MeshInstance3D.new()
	_mi.name = "Vessel"
	_mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.albedo_color = vessel_color
	mat.roughness = roughness
	mat.metallic = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # double-sided so interior reads
	if vessel_color.a < 0.98:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_boost > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(vessel_color.r, vessel_color.g, vessel_color.b)
		mat.emission_energy_multiplier = emission_boost
	_mi.material_override = mat
	add_child(_mi)

	print("FrozenGlassVessel: %d verts × %d steps → frozen vessel (g=(%.1f, %.1f, %.1f), stiff=%.2f, pin=%.2f)" % [
		final_verts.size(), sim_steps,
		gravity_x, gravity_y, gravity_z, stiffness, pin_top_fraction
	])


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "Label"
	_label.text = "Frozen Glass Vessel\ngravity × pressure × %d steps\nno designer placed any vertex" % sim_steps
	_label.pixel_size = 0.003
	_label.font_size = 26
	_label.modulate = Color(0.88, 0.86, 0.82)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, label_height, 0)
	add_child(_label)


## Grid-system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("radius"):             radius = float(config_data["radius"])
	if config_data.has("rings"):              rings = clampi(int(config_data["rings"]), 6, 24)
	if config_data.has("segments"):           segments = clampi(int(config_data["segments"]), 8, 32)
	if config_data.has("pin_top_fraction"):   pin_top_fraction = float(config_data["pin_top_fraction"])
	if config_data.has("preinflate"):         preinflate = float(config_data["preinflate"])
	if config_data.has("stiffness"):          stiffness = float(config_data["stiffness"])
	if config_data.has("gravity_y"):          gravity_y = float(config_data["gravity_y"])
	if config_data.has("gravity_x"):          gravity_x = float(config_data["gravity_x"])
	if config_data.has("sim_steps"):          sim_steps = clampi(int(config_data["sim_steps"]), 40, 800)
	# Rebuild
	for child in get_children(): child.queue_free()
	_build_vessel()
	if show_label: _build_label()
