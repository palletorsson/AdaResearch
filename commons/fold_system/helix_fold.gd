# @identity
# essence: a triangle strip coils from flat ribbon into a helix via sin/cos — DNA, springs, spiral shells
# desire: a living coil that winds tight when folded and unfurls into a flat banner when open
# critical_parameter: fold_amount — 0.0 is flat zigzag strip, 1.0 is tight helix coil
# triggers: fold_amount interpolates every vertex between flat position and helical position
# emerges: the helix pitch, radius, and sine modulation create organic coiling motion
# needs: PrimitiveMeshBuilder [reuse]; triangle strip generation [built here]
# truth: sin(t) and cos(t) are enough to fold a flat ribbon into a living spiral.

class_name HelixFold
extends Node3D
## A triangle strip that folds from a flat zigzag ribbon into a helix.
## Uses sin/cos to compute helical vertex positions.
## Shows 5 stages side by side like DeltahedronStages.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

const STAGE_COUNT := 5
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.5

@export var segment_count: int = 24       ## Number of triangle pairs in the strip
@export var strip_width: float = 0.03     ## Width of the flat ribbon
@export var strip_length: float = 0.6     ## Total length of the flat strip
@export var helix_radius: float = 0.06    ## Radius of the coil
@export var helix_turns: float = 3.0      ## Number of full rotations
@export var helix_height: float = 0.25    ## Total vertical rise
@export var sine_modulation: float = 0.3  ## Sine wave on radius (0=perfect helix, 1=wavy)

var _verts_flat: Array[Vector3] = []
var _verts_helix: Array[Vector3] = []
var _faces: Array = []


func _ready() -> void:
	_generate_strip()
	_build_stages()


func _generate_strip() -> void:
	_verts_flat.clear()
	_verts_helix.clear()
	_faces.clear()

	var seg_length: float = strip_length / float(segment_count)

	for i in (segment_count + 1):
		var t: float = float(i) / float(segment_count)  # 0 to 1 along strip

		# ── Flat positions: zigzag ribbon along Z axis ──
		var flat_z: float = t * strip_length - strip_length * 0.5
		var flat_left := Vector3(-strip_width * 0.5, 0.0, flat_z)
		var flat_right := Vector3(strip_width * 0.5, 0.0, flat_z)

		# ── Helix positions: coiled around Y axis ──
		var angle: float = t * helix_turns * TAU
		var y: float = t * helix_height - helix_height * 0.5

		# Sine modulation on radius — organic breathing
		var r: float = helix_radius * (1.0 + sin(t * TAU * 2.0) * sine_modulation)

		# Inner and outer edge of the ribbon on the helix
		var r_inner: float = r - strip_width * 0.5
		var r_outer: float = r + strip_width * 0.5

		var helix_inner := Vector3(cos(angle) * r_inner, y, sin(angle) * r_inner)
		var helix_outer := Vector3(cos(angle) * r_outer, y, sin(angle) * r_outer)

		_verts_flat.append(flat_left)   # Even index = left/inner
		_verts_flat.append(flat_right)  # Odd index = right/outer
		_verts_helix.append(helix_inner)
		_verts_helix.append(helix_outer)

	# Build triangle faces from the strip (two triangles per segment)
	for i in segment_count:
		var base: int = i * 2
		# Quad split into two triangles
		_faces.append([base, base + 1, base + 2])
		_faces.append([base + 1, base + 3, base + 2])


func _build_stages() -> void:
	var total_width: float = (STAGE_COUNT - 1) * SPACING
	var start_x: float = -total_width * 0.5

	for stage in STAGE_COUNT:
		var fold_t: float = STAGE_FOLDS[stage]
		var x_offset: float = start_x + stage * SPACING

		# Interpolate vertices
		var verts: Array = []
		for i in _verts_flat.size():
			verts.append(_verts_flat[i].lerp(_verts_helix[i], fold_t))

		# Color: cyan (flat) → white (mid) → warm orange (coiled)
		var color: Color
		if fold_t < 0.5:
			color = Color(0.4 + fold_t * 0.8, 0.7 + fold_t * 0.4, 0.9 - fold_t * 0.2)
		else:
			var ft: float = (fold_t - 0.5) * 2.0
			color = Color(0.8 + ft * 0.2, 0.7 - ft * 0.3, 0.5 - ft * 0.3)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.7
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.25
		mat.emission_energy_multiplier = 0.6

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_offset, helix_height * 0.5, 0)
		mi.name = "Stage_%d" % stage
		add_child(mi)

		# Label
		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [fold_t * 100.0, verts.size(), _faces.size()]
		label.font_size = 48
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_offset, -0.08, 0)
		add_child(label)


func apply_grid_config(_config: Dictionary) -> void:
	pass
