extends Node3D


# @identity
# essence: tube_y(x, t) = A * sin(omega * x + phi * t) — sine-displaced cylinders in a tunnel
# desire: Walk through a hallway where glowing tubes undulate with sine wave displacement
# critical_parameter: tube_count — determines visual density of the oscillating environment
# triggers: time drives phase animation; color_variants assign distinct hues per tube
# emerges: an immersive sine wave environment — architecture that breathes with oscillation
# needs: VR walkthrough [has], frequency control [missing]
# relationships: depends on MultiMesh cylinder instancing; contrasts with coloredlines (sine tubes vs parametric curves); unlocks environmental wave experience
# truth: A hallway of sine tubes is a frozen moment of wave interference made architectural.

@export var hallway_length: float = 60.0
@export var hallway_width: float = 12.0
@export var hallway_height: float = 12.0
@export var tube_count: int = 8
@export var tube_length: float = 80.0
@export var wave_amplitude: float = 2.5
@export var wave_frequency: float = 0.3
@export var tube_radius: float = 0.4
@export var segment_spacing: float = 1.0
@export var animate_tubes: bool = true
@export var rotation_speed: float = 0.35

@export var color_variants: Array = [
	Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
	Color.PURPLE, Color.AQUA, Color.DARK_ORANGE, Color.CYAN
]

## AXIS — WHICH PART OF THE ROOM the wave has been made into.
##
## The scene calls itself a hallway and builds no hallway. hallway_length and hallway_width
## are exported and never read; only hallway_height is, and only to lift the tubes to head
## height. So the default is eight tubes sharing one centre-line, phase-shifted 0.6 rad
## apart, weaving into a rope suspended down the middle of a room that does not exist. That
## is a wave you look at, not a wave you are inside.
##
##   braid   the legacy lineage, byte for byte — one centre-line, eight interleaved tubes
##   walls   the family splits into two ranks at ±hallway_width/2 and stacks four ribbons up
##           each long face; the wave's own ±2.5 m displacement then makes the corridor's
##           clear width breathe between about 7 m and 17 m as the body walks it
##   vault   the tubes fan across a semicircle of radius hallway_width/2 centred at head
##           height — an arched rib ceiling, the wave overhead and the body under it
##   deck    the tubes lie across the floor as parallel rails, one every ~1.7 m — the wave
##           underfoot, a rippled deck the body has no choice but to accept
##
## The claim: letting a formula generate architecture is a decision about what a body is
## asked to accommodate. `braid` refuses the job and stays an exhibit. The other three take
## it, and each asks for something different — to be flanked, to be roofed, to be carried.
##
## The wave function is untouched in all four. Only the placement of the family changes.
@export_enum("braid", "walls", "vault", "deck") var element: String = "braid"
const ELEMENTS: PackedStringArray = ["braid", "walls", "vault", "deck"]

var tube_segments: Array[MultiMeshInstance3D] = []
var elapsed: float = 0.0

func _ready() -> void:
	_read_dna_meta()
	_setup_environment()
	_create_sine_tubes()


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build and
## an unknown word keeps the default. No metadata, no change: the legacy path is untouched.
func _read_dna_meta() -> void:
	if has_meta("config_element"):
		var e: String = str(get_meta("config_element")).strip_edges().to_lower()
		element = e if ELEMENTS.has(e) else element

func _process(delta: float) -> void:
	if not animate_tubes:
		return
	elapsed += delta
	_update_tubes(elapsed)

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 0.6
	$WorldEnvironment.environment = env


func _create_sine_tubes() -> void:
	var half_len := int(tube_length * 0.5)
	var segments_per_tube := half_len * 2  # -half_len to half_len-1

	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = tube_radius
	cyl_mesh.bottom_radius = tube_radius
	cyl_mesh.height = segment_spacing
	cyl_mesh.rings = 8
	cyl_mesh.radial_segments = 24

	for i in range(tube_count):
		var color = color_variants[i % color_variants.size()]
		var material := _make_metallic(color)

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = segments_per_tube
		mm.mesh = cyl_mesh

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = material
		add_child(mmi)
		tube_segments.append(mmi)

	_update_tubes(0.0)

func _update_tubes(time_val: float) -> void:
	var half_len := int(tube_length * 0.5)
	var rot_basis := Basis.IDENTITY.rotated(Vector3(1, 0, 0), PI * 0.5)

	for i in range(tube_segments.size()):
		var mm: MultiMesh = tube_segments[i].multimesh
		var off: Vector3 = _element_offset(i, tube_segments.size())
		var idx := 0
		for z in range(-half_len, half_len):
			var phase := float(i) * 0.6 + (time_val * rotation_speed)
			var x := sin(float(z) * wave_frequency + phase) * wave_amplitude
			var y := sin(float(z) * wave_frequency * 0.7 + phase) * 0.5 * wave_amplitude + hallway_height * 0.5
			var pos := Vector3(x, y, float(z)) + off
			mm.set_instance_transform(idx, Transform3D(rot_basis, pos))
			idx += 1

func _make_metallic(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.85
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = col * 0.25
	mat.emission_energy_multiplier = 1.0
	return mat

func _make_reflective(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 1.0
	mat.roughness = 0.06
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the DNA axis is read here. Every other key is ignored exactly as before, so a map
	# that does not name `element` still reaches the legacy lineage untouched. The grid calls
	# this deferred (after _ready), by which time _read_dna_meta has usually already applied
	# the same value from metadata; re-placing the family is cheap, so do it either way.
	if config.has("element"):
		var e: String = str(config["element"]).strip_edges().to_lower()
		element = e if ELEMENTS.has(e) else element
		_update_tubes(elapsed)


# ── ELEMENT ──────────────────────────────────────────────────────────────────────────────
# Appended LAST so every line above keeps its meaning on the legacy path. `braid` returns
# Vector3.ZERO and the offset added in _update_tubes is then exact — the default build is
# the same braid down the same centre-line it has always been.

func _element_offset(i: int, n: int) -> Vector3:
	match element:
		"walls":
			return _element_walls(i, n)
		"vault":
			return _element_vault(i, n)
		"deck":
			return _element_deck(i, n)
		_:
			return Vector3.ZERO


## WALLS — the family splits left/right and stacks up the two long faces of the corridor,
## so the tubes stop being an object in the room and become the room's sides. The wave's own
## lateral displacement now reads as the wall bulging in and out around the body.
func _element_walls(i: int, n: int) -> Vector3:
	var per_side: int = maxi((n + 1) / 2, 1)
	var side: float = -1.0 if i < per_side else 1.0
	var k: int = i % per_side
	var t: float = 0.0
	if per_side > 1:
		t = float(k) / float(per_side - 1)
	return Vector3(side * hallway_width * 0.5, (t - 0.5) * hallway_height * 0.55, 0.0)


## VAULT — the tubes fan across a semicircle over the walkway: a rib ceiling. The wave is
## overhead, and the body passes underneath something it cannot reach.
func _element_vault(i: int, n: int) -> Vector3:
	var t: float = 0.0
	if n > 1:
		t = float(i) / float(n - 1)
	var a: float = PI * t
	var radius: float = maxf(hallway_width * 0.5, 1.0)
	return Vector3(-cos(a) * radius, sin(a) * radius, 0.0)


## DECK — the tubes lie side by side across the floor as parallel rails. The wave is
## underfoot: the only one of the four the body has to negotiate with its feet.
func _element_deck(i: int, n: int) -> Vector3:
	var t: float = 0.0
	if n > 1:
		t = float(i) / float(n - 1)
	return Vector3((t - 0.5) * hallway_width, -hallway_height * 0.5 + 1.35, 0.0)
