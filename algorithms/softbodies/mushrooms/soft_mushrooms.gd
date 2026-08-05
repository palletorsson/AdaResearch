extends Node3D

# @identity
# essence: N StaticBody3D stems topped with SoftBody3D sphere caps pinned at the bottom — each cap's pressure_coefficient and linear_stiffness create a wobbly mushroom that jiggles when touched
# desire: to grow a field of soft mushrooms you can push through, each one bobbing and recovering differently because of randomized cap size and stiffness
# critical_parameter: cap_radius_range — larger caps wobble more dramatically under the same force, smaller caps feel springy and taut
# triggers: player or rigid body collision with the SoftBody3D cap causes vertex displacement; the pin constraint at the stem-cap junction prevents the cap from flying off
# emerges: randomized hue and dot patterns on the mushroom_dots shader make each specimen visually unique despite identical physics, creating a garden that feels grown rather than copied
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: extends jelly_cube's single-object deformation to a population; appears in SoftBodies_Carusell alongside cloth_straps and revolving_joy_ride
# truth: a mushroom cap does not decide its shape — the pin constraint, gravity, and whatever bumps into it negotiate the form in real time

## --- DNA (stage 2, promoted 2026-08-05) ---
##
## STAGE-2 DNA PROMOTION. The sweep refused this artifact: five exports, and every one
## of them a size or a count. The two constants that carry an argument were buried in
## create_mushroom and spawn_mushrooms —
##
##   flesh       what the cap is made of, which is what decides its shape
##   occurrence  how the fruiting bodies come up together
##
## flesh is the artifact's own truth statement, made turnable. linear_stiffness 0.2,
## pressure_coefficient 0.5 and damping 0.05 were three numbers with no name; together
## they are ONE claim about tissue. A turgid cap holds the sphere it was built as and
## gravity barely reads on it; a slack one collapses over its stem into a parasol. Same
## mesh, same pin, same gravity — a different negotiation.
##
## occurrence was not a decision at all: randf_range over a 20 m square, because that is
## what a for-loop does when nobody asks. But scatter is a CLAIM about fungal ecology,
## and it is not the only one. A fairy ring is a single organism's mycelium advancing
## outward from where it germinated; a caespitose clump is many fruiting bodies from one
## base. Naming the default turns an accident into one option among four, and makes the
## invisible mycelium legible in the arrangement of the visible parts.
##
## flesh=soft + occurrence=scattered reproduces the shipped garden exactly: the same
## three SoftBody3D numbers, and the same two randf_range draws in the same order (see
## _site). rng_seed and spawn_span are BENCH knobs, not axes — both default to 0, which
## means "behave as before"; the registry's dna.fixture uses them to pin the garden so a
## sweep compares four fleshes and not four different gardens.
##
## Usage in map_data.json:
##   "soft_mushroom#flesh:turgid"
##   "soft_mushroom#occurrence:ring#flesh:slack"

## What the cap is made of. Each value is one claim about tissue, spelled as the three
## SoftBody3D numbers that carry it. "soft" is the shipped flesh, value for value.
const FLESH = {
	"soft": {"stiffness": 0.2, "pressure": 0.5, "damping": 0.05},
	# Inflated and taut — the cap holds the ball it was built as, a young button.
	"turgid": {"stiffness": 0.5, "pressure": 4.0, "damping": 0.05},
	# No inflation, almost no skin — the cap gives up and drapes over its stem.
	"slack": {"stiffness": 0.05, "pressure": 0.0, "damping": 0.05},
	# A skin that resists and does not ring — the specimen holds its authored shape.
	"firm": {"stiffness": 0.95, "pressure": 0.5, "damping": 0.4},
}

const OCCURRENCES = ["scattered", "troop", "ring", "clustered"]

@export var mushroom_count: int = 15
@export var spawn_area_size: Vector2 = Vector2(20, 20)
@export var stem_height_range: Vector2 = Vector2(0.5, 1.5)
@export var stem_radius: float = 0.2
@export var cap_radius_range: Vector2 = Vector2(0.6, 1.2)
## DNA gene: the cap's tissue. See FLESH above.
@export_enum("soft", "turgid", "slack", "firm") var flesh: String = "soft"
## DNA gene: how the fruiting bodies come up together. "scattered" is the shipped
## randf_range field; troop follows a wandering line, ring is a fairy ring advancing
## from one germination point, clustered is caespitose — many caps from one base.
@export_enum("scattered", "troop", "ring", "clustered") var occurrence: String = "scattered"
## BENCH KNOB, not an axis. 0 keeps the shipped global unseeded randomness, so an
## existing placement grows the same kind of garden it always did. Any other value
## pins every draw, which is the only way a sweep compares one variable at a time.
@export var rng_seed: int = 0
## BENCH KNOB, not an axis. 0 uses spawn_area_size. A 20 m field puts a 2 m cap at
## about 26 px in a 760 px sweep frame, which is not a picture of anything.
@export var spawn_span: float = 0.0

var _rng: RandomNumberGenerator = null
var _grown: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	# The grid stamps `config_<key>` metadata before _ready; apply_grid_config only
	# arrives deferred, after the garden has already grown.
	if has_meta("config_flesh"):
		flesh = str(get_meta("config_flesh")).to_lower()
	if has_meta("config_occurrence"):
		occurrence = str(get_meta("config_occurrence")).to_lower()
	if has_meta("config_rng_seed"):
		rng_seed = int(get_meta("config_rng_seed"))
	_seed_rng()
	setup_scene()
	spawn_mushrooms()
	_built = true

## rng_seed 0 leaves _rng null and every draw goes to the global generator exactly as
## it always has — the shipped behaviour, not a reimplementation of it.
func _seed_rng() -> void:
	if rng_seed == 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = rng_seed

func _rand(a: float, b: float) -> float:
	if _rng != null:
		return _rng.randf_range(a, b)
	return randf_range(a, b)

func _rand01() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()

func setup_scene() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 5, 15)
	cam.look_at(Vector3(0, 0, 0))
	add_child(cam)
	
	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 20, 10)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	# Ground removed as per request

func spawn_mushrooms() -> void:
	for i in range(mushroom_count):
		create_mushroom(_site(i))

## The field the stand comes up in. spawn_span is the bench override; 0 means the
## shipped spawn_area_size.
func _span() -> Vector2:
	if spawn_span > 0.0:
		return Vector2(spawn_span, spawn_span)
	return spawn_area_size

## Where the i-th fruiting body comes up.
##
## "scattered" is the shipped code: the same two draws, in the same order, off the same
## generator — so an unseeded default garden is the one this artifact has always grown.
## The other three are the arrangements mycology actually names, and each says something
## the scatter cannot: a troop follows buried wood, a ring is ONE organism's mycelium
## advancing outward from where it germinated, a clump is many caps off a single base.
func _site(index: int) -> Vector3:
	var span := _span()
	match occurrence:
		"troop":
			var t: float = (float(index) + 0.5) / float(maxi(1, mushroom_count))
			var along: float = (t - 0.5) * span.x
			var drift: float = sin(t * 5.6) * span.y * 0.12 + _rand(-span.y * 0.03, span.y * 0.03)
			return Vector3(along, 0.0, drift)
		"ring":
			var a: float = TAU * float(index) / float(maxi(1, mushroom_count))
			var r: float = minf(span.x, span.y) * 0.38 * (1.0 + _rand(-0.05, 0.05))
			return Vector3(cos(a) * r, 0.0, sin(a) * r)
		"clustered":
			var ca: float = TAU * _rand01()
			var cr: float = minf(span.x, span.y) * 0.07 * sqrt(_rand01())
			return Vector3(cos(ca) * cr, 0.0, sin(ca) * cr)
	return Vector3(
		_rand(-span.x / 2, span.x / 2),
		0,
		_rand(-span.y / 2, span.y / 2)
	)

func create_mushroom(pos: Vector3) -> void:
	var stem_h = _rand(stem_height_range.x, stem_height_range.y)
	var cap_r = _rand(cap_radius_range.x, cap_radius_range.y)
	
	# 1. Stem (StaticBody)
	var stem = StaticBody3D.new()
	stem.position = pos + Vector3(0, stem_h/2.0, 0)
	
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = stem_radius * 0.8 # Taper slightly
	stem_mesh.bottom_radius = stem_radius
	stem_mesh.height = stem_h
	
	var stem_vis = MeshInstance3D.new()
	stem_vis.mesh = stem_mesh
	stem.add_child(stem_vis)
	
	var stem_col = CollisionShape3D.new()
	stem_col.shape = CylinderShape3D.new()
	(stem_col.shape as CylinderShape3D).radius = stem_radius
	(stem_col.shape as CylinderShape3D).height = stem_h
	stem.add_child(stem_col)

	add_child(stem)
	_grown.append(stem)
	
	# 2. Cap (SoftBody)
	var cap = SoftBody3D.new()
	
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = cap_r
	cap_mesh.height = cap_r # Hemisphere-ish (flattened bottom?) No, SphereMesh height controls full height.
	# To make it look like a mushroom cap, maybe we use a full sphere but pin the bottom center?
	# Or a hemisphere. SphereMesh has is_hemisphere? No.
	# We can use a SphereMesh and squash it?
	cap_mesh.height = cap_r * 1.5
	cap_mesh.radial_segments = 16
	cap_mesh.rings = 8
	
	cap.mesh = cap_mesh
	
	# Position cap on top of stem
	# Stem top is at pos.y + stem_h
	# Cap center should be slightly above that?
	cap.position = pos + Vector3(0, stem_h + cap_r * 0.5, 0)
	
	# The flesh gene. Three numbers that were never named together are one claim about
	# tissue; "soft" returns the shipped 0.2 / 0.05 / 0.5 exactly.
	var tissue: Dictionary = FLESH.get(flesh, FLESH["soft"])
	cap.total_mass = 1.0
	cap.linear_stiffness = float(tissue["stiffness"])
	cap.damping_coefficient = float(tissue["damping"])
	cap.pressure_coefficient = float(tissue["pressure"])
	cap.simulation_precision = 5
	
	# Material
	var mat = ShaderMaterial.new()
	mat.shader = load("res://commons/resourses/shaders/mushroom_dots.gdshader")
	
	# Randomize colors
	var hue = _rand01()
	var base_col = Color.from_hsv(hue, 0.8, 0.8)
	var dot_col = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.2, 1.0) # Complementary-ish, pale

	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("dot_color", dot_col)
	mat.set_shader_parameter("dot_size", _rand(0.2, 0.4))
	mat.set_shader_parameter("dot_spacing", _rand(5.0, 15.0))

	cap.material_override = mat

	add_child(cap)
	_grown.append(cap)
	
	# Pin the bottom of the cap to the stem
	call_deferred("_pin_cap_to_stem", cap, stem, cap_mesh.height)

func _pin_cap_to_stem(cap: SoftBody3D, stem: StaticBody3D, height: float) -> void:
	if not is_instance_valid(cap) or not is_instance_valid(stem):
		return
		
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(cap.mesh, 0)
	
	var min_y = INF
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y < min_y:
			min_y = v.y
			
	# Pin vertices at the bottom
	var pinned_indices = []
	# Pin bottom 25% of the height
	var pin_height_threshold = min_y + (height * 0.25)
	# Pin within a wider radius to ensure we catch vertices
	var pin_radius_sq = (stem_radius * 2.0) ** 2
	
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y < pin_height_threshold:
			if Vector2(v.x, v.z).length_squared() < pin_radius_sq:
				pinned_indices.append(i)
	
	print("Mushroom at ", stem.position, ": Pinning ", pinned_indices.size(), " vertices.")
	
	if not pinned_indices.is_empty():
		var path = stem.get_path()
		for idx in pinned_indices:
			cap.set_point_pinned(idx, true, path)
		
		# Collision exception
		cap.add_collision_exception_with(stem)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## DNA / map config. GUARDED: the garden is regrown only when a value this artifact
## owns actually CHANGED, and only after _ready has grown it once. An unguarded regrow
## would free and respawn every stem and SoftBody3D cap on any call, including calls
## naming nothing here.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("flesh"):
		var f: String = str(config["flesh"]).to_lower()
		if FLESH.has(f) and f != flesh:
			flesh = f
			changed = true
	if config.has("occurrence"):
		var o: String = str(config["occurrence"]).to_lower()
		if o in OCCURRENCES and o != occurrence:
			occurrence = o
			changed = true
	if config.has("rng_seed"):
		var s: int = int(config["rng_seed"])
		if s != rng_seed:
			rng_seed = s
			changed = true
	if config.has("spawn_span"):
		var sp: float = float(config["spawn_span"])
		if not is_equal_approx(sp, spawn_span):
			spawn_span = sp
			changed = true
	if changed and _built:
		_regrow()

## Free only what spawn_mushrooms grew. The camera and light setup_scene built stay.
func _regrow() -> void:
	for n in _grown:
		if is_instance_valid(n):
			n.queue_free()
	_grown.clear()
	_seed_rng()
	spawn_mushrooms()
