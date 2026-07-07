extends Node3D
class_name QuantumDice

# @identity
# essence: a six-sided die with pip patterns on every face — and a quantum mode that makes each face glow with its probability weight, so a fair die and a loaded die are visually distinct without rolling
# desire: turn dice from an opaque random source into a legible probability artifact — the player sees the distribution before the roll
# critical_parameter: face_weights — six floats that drive each face's emission energy in quantum_mode; uniform [1,1,1,1,1,1] = a fair die, [0,0,0,0,0,1] = a loaded die
# triggers: _ready() builds the cube body, the 21 pip dots (1+2+3+4+5+6 = 21 across all faces), and per-face emission materials wired to face_weights
# emerges: the abstract probability distribution becomes a literal pattern of glowing faces — a 6-face heat map of likelihood
# needs: standard 1..6 pip layout [present, 2026-05-19]; quantum_mode toggle [present, 2026-05-19]; per-face weight inspector [present, 2026-05-19]; roll animation [not present — future]
# relationships: lives in commons/primitives/dice/; complements interactive_point_origin (random point) and shannon_entropy_meter (measures the distribution this dice generates); the chain dice → entropy_meter → coin_flip makes the whole probability-as-quantity arc concrete
# truth: a die's randomness is normally hidden inside opaque physics. By exposing the per-face weight as light, the die stops being a black box and starts being a chart you can roll.

## Six-sided die with standard pip patterns and an optional quantum mode where
## each face glows with its probability weight. Built procedurally — no
## texture maps. Face/pip layout follows the standard convention where
## opposite faces sum to 7 (1↔6, 2↔5, 3↔4).
##
## When quantum_mode is on, face_weights drive each face's emission energy:
## a fair die [1,1,1,1,1,1] makes all six faces glow equally; a loaded die
## like [0,0,0,0,0,1] makes only the "6" face glow, encoding the distribution
## visually before any roll.

@export_group("Dimensions")
## Edge length of the cube body. Default 0.4 m = a comfortable VR-hand dice.
@export var edge: float = 0.4
## Pip dot radius. Default 0.025 m = ~6% of edge length, reads cleanly at arm's
## length without overcrowding the 6-pip face.
@export var pip_radius: float = 0.025
## How far each pip sphere sits proud of its face (positive) or recessed
## (negative). Small positive value keeps the pips from z-fighting with the face.
@export var pip_offset: float = 0.005

@export_group("Body")
## Color of the cube body. Default off-white = traditional bone dice. Bumped
## slightly emissive so quantum_mode glow reads against it.
@export var body_color: Color = Color(0.94, 0.92, 0.86, 1.0)
## Color of the pip dots. Default dark grey = traditional ink-filled pips.
@export var pip_color: Color = Color(0.08, 0.08, 0.1, 1.0)

@export_group("Quantum mode")
## When true, the dice body becomes translucent and each face glows with
## its weight from face_weights. When false, the dice renders as a normal
## solid die with dark pips.
@export var quantum_mode: bool = false
## Probability weight per face, in pip-count order [1, 2, 3, 4, 5, 6]. In
## quantum_mode, each weight drives its face's emission energy. The weights
## are not normalized — they're shown as raw intensities — so [1,1,1,1,1,1]
## means "fair", [0,0,0,0,0,1] means "loaded toward 6", and [2,1,1,1,1,1]
## means "biased twice toward 1".
@export var face_weights: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
## Color hue shift driver for the glow. Each face's emission uses
## glow_color × its weight. Defaults to a warm gold, visible against
## both the bone-white body and dark surroundings.
@export var glow_color: Color = Color(1.0, 0.85, 0.3, 1.0)

# Internal
var _body: MeshInstance3D
var _face_materials: Array[StandardMaterial3D] = []   # 6 materials, one per face glow overlay (quantum mode only)
var _face_overlays: Array[MeshInstance3D] = []
var _pips: Array[MeshInstance3D] = []


func _ready() -> void:
	_build()


func _build() -> void:
	# Clean any previous build (allows _build_reset() use)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_face_materials.clear()
	_face_overlays.clear()
	_pips.clear()

	_build_body()
	_build_face_glows()
	_build_pips()


# ── Body ─────────────────────────────────────────────────────────────

func _build_body() -> void:
	_body = MeshInstance3D.new()
	_body.name = "Body"
	var cube := BoxMesh.new()
	cube.size = Vector3(edge, edge, edge)
	_body.mesh = cube

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.6
	mat.metallic = 0.05
	if quantum_mode:
		# Translucent body so the glow overlays read through. Slight emission
		# keeps the cube from going invisible.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.35
		mat.emission_enabled = true
		mat.emission = body_color.darkened(0.5)
		mat.emission_energy_multiplier = 0.4
	_body.material_override = mat
	add_child(_body)


# ── Face glow overlays (quantum mode) ────────────────────────────────

func _build_face_glows() -> void:
	if not quantum_mode:
		return
	# One thin emissive quad per face, riding 0.001 m proud of the face so it
	# doesn't z-fight. The quad's emission energy = face_weights[face_index].
	var half := edge * 0.5
	var faces = _face_layout()
	for i in range(faces.size()):
		var f = faces[i]
		var center: Vector3 = f["center"] as Vector3
		var normal: Vector3 = f["normal"] as Vector3
		var u: Vector3 = f["u"] as Vector3
		var v: Vector3 = f["v"] as Vector3

		var quad := MeshInstance3D.new()
		quad.name = "FaceGlow_%d" % (i + 1)
		var qm := QuadMesh.new()
		qm.size = Vector2(edge * 0.96, edge * 0.96)
		quad.mesh = qm

		# Build an orthonormal basis where the quad's +Z points along `normal`.
		# QuadMesh lies in its local XY plane (so its normal is +Z).
		var basis := Basis(u.normalized(), v.normalized(), normal.normalized())
		quad.transform = Transform3D(basis, center + normal * 0.001)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = glow_color
		mat.albedo_color.a = 0.6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = glow_color
		var w := face_weights[i] if i < face_weights.size() else 1.0
		mat.emission_energy_multiplier = max(0.0, w) * 2.0
		quad.material_override = mat
		add_child(quad)
		_face_overlays.append(quad)
		_face_materials.append(mat)


# ── Pips ─────────────────────────────────────────────────────────────

func _build_pips() -> void:
	var faces = _face_layout()
	var pip_mat := StandardMaterial3D.new()
	pip_mat.albedo_color = pip_color
	pip_mat.roughness = 0.4
	pip_mat.metallic = 0.1

	for i in range(faces.size()):
		var f = faces[i]
		var center: Vector3 = f["center"] as Vector3
		var normal: Vector3 = f["normal"] as Vector3
		var u: Vector3 = f["u"] as Vector3
		var v: Vector3 = f["v"] as Vector3
		var pip_count := i + 1
		var positions: Array = _pip_layout_2d(pip_count)
		for p_entry in positions:
			var p: Vector2 = p_entry as Vector2
			var pip := MeshInstance3D.new()
			pip.name = "Pip_%d_%d" % [pip_count, _pips.size()]
			var s := SphereMesh.new()
			s.radius = pip_radius
			s.height = pip_radius * 2.0
			s.radial_segments = 12
			s.rings = 6
			pip.mesh = s
			# 2D pip position (u, v) → 3D world position relative to face center,
			# pushed slightly proud of the face along normal.
			var pos: Vector3 = center + normal * pip_offset + u * p.x + v * p.y
			pip.position = pos
			pip.material_override = pip_mat
			add_child(pip)
			_pips.append(pip)


# ── Face & pip layouts ───────────────────────────────────────────────

func _face_layout() -> Array:
	# Standard die where opposite faces sum to 7. Each face entry gives:
	#   - center: face's world position (relative to dice origin)
	#   - normal: outward face normal
	#   - u, v:   orthonormal axes lying IN the face plane, used to position
	#             pips. Their orientation determines how the pip pattern reads.
	# Order: faces[i] is the face with (i+1) pips.
	var half := edge * 0.5
	return [
		# Face 1 (one pip), on +X. u = +Z, v = +Y.
		{"center": Vector3( half, 0, 0), "normal": Vector3.RIGHT,    "u": Vector3.BACK,    "v": Vector3.UP},
		# Face 2 (two pips), on +Y. u = +X, v = -Z (so reading order points away from +X).
		{"center": Vector3(0,  half, 0), "normal": Vector3.UP,       "u": Vector3.RIGHT,   "v": Vector3.FORWARD},
		# Face 3 (three pips), on +Z. u = +X, v = +Y.
		{"center": Vector3(0, 0,  half), "normal": Vector3.BACK,     "u": Vector3.RIGHT,   "v": Vector3.UP},
		# Face 4 (four pips), on -Z. u = -X, v = +Y.
		{"center": Vector3(0, 0, -half), "normal": Vector3.FORWARD,  "u": Vector3.LEFT,    "v": Vector3.UP},
		# Face 5 (five pips), on -Y. u = +X, v = +Z.
		{"center": Vector3(0, -half, 0), "normal": Vector3.DOWN,     "u": Vector3.RIGHT,   "v": Vector3.BACK},
		# Face 6 (six pips), on -X. u = -Z, v = +Y.
		{"center": Vector3(-half, 0, 0), "normal": Vector3.LEFT,     "u": Vector3.FORWARD, "v": Vector3.UP},
	]


func _pip_layout_2d(count: int) -> Array:
	# Pip positions in the face's local (u, v) plane. Coordinates are scaled
	# to ~0.2 × edge so they sit ¼ of the way from center to edge — the
	# classic spacing where 6 pips fit two columns of 3 without crowding.
	var d := edge * 0.2
	match count:
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(-d,  d), Vector2( d, -d)]
		3:
			return [Vector2(-d,  d), Vector2.ZERO, Vector2( d, -d)]
		4:
			return [Vector2(-d,  d), Vector2( d,  d),
					Vector2(-d, -d), Vector2( d, -d)]
		5:
			return [Vector2(-d,  d), Vector2( d,  d),
					Vector2.ZERO,
					Vector2(-d, -d), Vector2( d, -d)]
		6:
			return [Vector2(-d,  d), Vector2( d,  d),
					Vector2(-d,  0), Vector2( d,  0),
					Vector2(-d, -d), Vector2( d, -d)]
	return []


# ── Public API ──────────────────────────────────────────────────────

## Set the probability weight for a single face. face_index is 0..5 (= pip count 1..6).
## In quantum_mode, this immediately updates that face's emission energy.
func set_face_weight(face_index: int, weight: float) -> void:
	if face_index < 0 or face_index >= 6:
		return
	if face_index < face_weights.size():
		face_weights[face_index] = weight
	if quantum_mode and face_index < _face_materials.size():
		_face_materials[face_index].emission_energy_multiplier = max(0.0, weight) * 2.0


## Toggle quantum mode at runtime. Rebuilds geometry.
func set_quantum_mode(b: bool) -> void:
	quantum_mode = b
	_build()


## Pick a face randomly weighted by face_weights. Returns face index 0..5.
## Returns -1 if all weights are zero.
func roll() -> int:
	var total: float = 0.0
	for w in face_weights:
		total += max(0.0, w)
	if total <= 0.0:
		return -1
	var pick := randf() * total
	var accum: float = 0.0
	for i in range(face_weights.size()):
		accum += max(0.0, face_weights[i])
		if pick <= accum:
			return i
	return face_weights.size() - 1


## Apply grid-system configuration. Honoured keys:
##   "edge"          — float, cube edge length
##   "quantum_mode"  — bool, switch to quantum visualisation
##   "face_weights"  — 6-float array, weighted distribution
##   "body_color"    — Color
func apply_grid_config(config: Dictionary) -> void:
	var dirty := false
	if config.has("edge"):
		edge = float(config["edge"]); dirty = true
	if config.has("quantum_mode"):
		quantum_mode = bool(config["quantum_mode"]); dirty = true
	if config.has("face_weights"):
		var fw = config["face_weights"]
		if fw is Array and fw.size() == 6:
			face_weights = PackedFloat32Array()
			for v in fw:
				face_weights.append(float(v))
			dirty = true
	if config.has("body_color"):
		var c = config["body_color"]
		if c is Color:
			body_color = c
			dirty = true
	if dirty:
		_build()
