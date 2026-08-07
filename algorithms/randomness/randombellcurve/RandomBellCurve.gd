extends Node3D
## BellCurveTerrain.gd
## Builds a 20×20 quad grid (Y up) shaped into a 3D bell curve.
## Uses HeightMapShape3D for smooth player collisions.
##
## @identity
## essence: a Gaussian made walkable — the central limit theorem as terrain you climb
## desire: stand on the slope and feel that this exact shape is what randomness LOOKS like at scale
## critical_parameter: spread (sigma) — wider sigma means flatter terrain, tighter sigma means sharper peak; constitution — what the law's body is MADE of, continuum or count (skin | terrace | column | rib)
## triggers: _build_flat_grid() lays a 20x20 quad mesh; height_at(x,z) applies exp(-(r²)/(2σ²)) per vertex
## emerges: a 3D HeightMapShape3D that is the integral of countless independent random walks — the bell shape is inevitable
## needs: HeightMapShape3D for player collisions [has]; configurable sigma + height [has]; subtle Z-noise option [has]; a cast-and-painted finish that answers to light rather than a wireframe that ignores it [derived]; a grain sized for twenty metres, not for a bolt head [derived]; the hypsometric tint carried in vertex colour so it costs no draw call and no second material [derived]
## relationships: galton_board's analytical limit (infinite bins, infinite balls); kin to distribution_comparator; one cross-section of probability_distributions_3d; surfaces through [[pbr_kit]], the same move dome made off the same shader
## truth: The bell curve is not chosen — it is what every sum of independent randomness becomes.

const PBR := preload("res://commons/render/pbr_kit.gd")

@export var quads_x: int = 20
@export var quads_z: int = 20
@export var cell_size: float = 1.0
@export_range(0.1, 10.0, 0.1) var height_scale: float = 5.0   # overall height of the bell (Y-axis)
@export_range(0.1, 5.0, 0.1) var spread: float = 2.0          # width of the bell
@export var randomize_on_ready: bool = false                  # disabled - create once only
@export var update_interval: float = 2.0                      # seconds between new bell randomizations
@export var add_noise: bool = true                            # small random surface noise on Z-axis
@export var noise_strength: float = 0.05                      # subtle Z-axis noise variation

# ─────────────────────────────────────────────────────────────────────────────
# DNA — constitution
#
# This is the one artifact in the tier that shows the LAW WITH NO SAMPLES. The
# galton board earns its bell one ball at a time; this thing just states it —
# exp(-r²/s²) evaluated at 441 vertices, a shape you can stand on. Which raises
# the question the whole tier turns on and this artifact is best placed to ask:
# is the distribution the continuous law, or the counting that produced it?
#
#   constitution   what the law's body is made of
#
#     skin      one continuous surface, 800 triangles, no seam anywhere. The
#               claim at its purest: variation HAS a shape, the shape is smooth,
#               and nothing in the object admits that anything was ever counted.
#               THE LEGACY LINEAGE, vertex for vertex — 12 rooms have this.
#     rib       the same law cut into eleven standing sections, gaps between
#               them. Now it is a DRAWING: the 1-D curve repeated across depth,
#               a profile you could trace on paper, and you can see straight
#               through the object where the law is not being reported.
#     terrace   the law quantised into ten levels. Contours, a ziggurat, the
#               ordnance-survey read: still continuous underneath and no longer
#               continuous on its face. This is the moment binning happens.
#     column    400 separate standing boxes, one per cell, each as tall as the
#               law is there. A histogram in three dimensions. The surface is
#               gone; what is left is counts, side by side, with air between
#               them. The instances win.
#
# THE LADDER RUNS law → drawing → bin → count, and it is the same ladder the
# blur circle runs in its own material. Nothing in it changes the mathematics:
# every value evaluates the identical Gaussian at the identical 441 vertices
# from the identical RNG draws. What changes is what the body ADMITS about
# where the shape came from.
#
# THE COLLIDER DOES NOT MOVE. _update_collider() reads `verts`, the smooth
# field, at every value — so the terraces are a face, not a staircase, and a
# player walks the same slope in all four. Appearance only: this is walkable
# ground in 12 rooms and the ground is not up for redecoration.
#
# WHAT IS DELIBERATELY NOT THE AXIS. update_interval and randomize_on_ready are
# the artifact's two temptations and both are TIME — the second one re-rolls the
# whole bell every 2 s, which is not a variant, it is a slideshow. height_scale
# and spread are real knobs but they change the SIZE of the claim, not the
# claim; sweeping them would publish four photographs of the same argument.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what the law's body is made of. "skin" is the legacy default.
@export_enum("skin", "terrace", "column", "rib") var constitution: String = "skin"

## The allow-list, same four words in the same spelling as the @export_enum
## above. This is what a map token (#constitution:) is checked against.
const CONSTITUTIONS: PackedStringArray = ["skin", "terrace", "column", "rib"]

## RNG SEED. The build path rolls three times: height ×[0.8,1.2], spread
## ×[0.8,1.2], and a z-jitter per vertex — so until now every single run
## produced a DIFFERENT hill, and two renders of this artifact could differ by
## 20% in peak height with nothing changed. That variance is larger than most
## axes, and any sweep across an unseeded build measures it instead of the axis.
##
## -1 keeps the legacy line exactly: rng.randomize(), a new hill every run.
## Any value >= 0 pins the whole shape so one still can be compared with another.
@export var rng_seed: int = -1

const TERRACE_LEVELS := 10   # `terrace` — steps from base to peak
const RIB_STRIDE := 2        # `rib` — a standing section every N rows
const RIB_THICKNESS := 0.12  # `rib` — section thickness, in world units
const COLUMN_FILL := 0.78    # `column` — box footprint as a fraction of the cell
const FLOOR_HEIGHT := 0.02   # keeps the flat tail visible (and the AABB constant)

var verts: PackedVector3Array
var original_verts: PackedVector3Array  # Store original flat grid positions
var uvs: PackedVector2Array
var indices: PackedInt32Array

var mesh_instance: MeshInstance3D
var body: StaticBody3D
var shape_node: CollisionShape3D
var rng := RandomNumberGenerator.new()
var time_accum := 0.0

func _ready() -> void:
	# SEED FIRST, and by the same call the legacy line made when rng_seed is -1,
	# so the default draws the identical sequence it always drew.
	if rng_seed < 0:
		rng.randomize()
	else:
		rng.seed = rng_seed
	_build_nodes()
	_build_flat_grid()
	original_verts = verts.duplicate()  # Save original positions
	_make_bell_curve()
	_commit_mesh()
	_update_collider()

func _process(delta: float) -> void:
	time_accum += delta
	if time_accum >= update_interval and randomize_on_ready:
		time_accum = 0.0
		_make_bell_curve()
		_commit_mesh()
		await get_tree().process_frame
		_update_collider()

# ---------------------------------------------------------------------
# --- node + geometry setup ------------------------------------------
func _build_nodes() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	# Apply SimpleGrid shader material
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	mesh_instance.material_override = shader_mat

	body = StaticBody3D.new()
	add_child(body)

	shape_node = CollisionShape3D.new()
	body.add_child(shape_node)

func _build_flat_grid() -> void:
	var vx := quads_x + 1
	var vz := quads_z + 1

	verts = PackedVector3Array()
	uvs = PackedVector2Array()
	indices = PackedInt32Array()
	verts.resize(vx * vz)
	uvs.resize(vx * vz)

	var width := float(quads_x) * cell_size
	var depth := float(quads_z) * cell_size
	var x0 := -width * 0.5
	var z0 := -depth * 0.5

	for z in range(vz):
		for x in range(vx):
			var idx := z * vx + x
			var px := x0 + float(x) * cell_size
			var pz := z0 + float(z) * cell_size
			verts[idx] = Vector3(px, 0.0, pz)
			uvs[idx] = Vector2(float(x) / quads_x, float(z) / quads_z)

	for z in range(quads_z):
		for x in range(quads_x):
			var i0 := z * vx + x
			var i1 := i0 + 1
			var i2 := i0 + vx
			var i3 := i2 + 1
			indices.push_back(i0)
			indices.push_back(i2)
			indices.push_back(i1)
			indices.push_back(i1)
			indices.push_back(i2)
			indices.push_back(i3)

# ---------------------------------------------------------------------
# --- bell-curve deformation -----------------------------------------
func _make_bell_curve() -> void:
	if verts.is_empty() or original_verts.is_empty():
		return

	var center_x := 0.0
	var center_z := 0.0
	var h := height_scale * rng.randf_range(0.8, 1.2)
	var s := spread * rng.randf_range(0.8, 1.2)

	for i in range(verts.size()):
		# Start from the original flat grid position
		var orig := original_verts[i]
		var dx := orig.x - center_x
		var dz := orig.z - center_z
		var dist_sq := (dx * dx + dz * dz) / (s * s)

		# Apply bell curve to Y (height)
		var y := h * exp(-dist_sq)

		# Apply subtle random noise to Z-axis only
		var z_noise := 0.0
		if add_noise:
			z_noise = rng.randf_range(-noise_strength, noise_strength)

		verts[i] = Vector3(orig.x, y, orig.z + z_noise)

# ---------------------------------------------------------------------
# --- mesh + collider update -----------------------------------------
func _commit_mesh() -> void:
	# CONSTITUTION, dispatched at the LAST step of the build. Everything above
	# this line — the flat grid, the RNG draws, the deformed vertex field — has
	# already run and is identical for all four values; only the body written
	# out of that field changes. `skin` is the legacy lineage.
	match constitution_name():
		"terrace":
			mesh_instance.mesh = _body_terrace()
		"column":
			mesh_instance.mesh = _body_column()
		"rib":
			mesh_instance.mesh = _body_rib()
		_:
			mesh_instance.mesh = _body_skin()


## SKIN — the legacy body, moved here unchanged: one continuous surface over the
## whole vertex field.
func _body_skin() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in indices.size():
		var idx := indices[i]
		st.set_uv(uvs[idx])
		st.add_vertex(verts[idx])
	st.generate_normals()
	var mesh := st.commit()
	return mesh

func _update_collider() -> void:
	if verts.is_empty():
		return

	var size_x := quads_x + 1
	var size_z := quads_z + 1
	var heights := PackedFloat32Array()

	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			heights.append(verts[idx].y)

	var shape := HeightMapShape3D.new()
	shape.map_width = size_x
	shape.map_depth = size_z
	shape.map_data = heights
	shape_node.shape = shape

	# Drop collider slightly for safe walking margin
	body.transform.origin.y = -0.05

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the constitution is configurable from a map. A placement that does not
	# name one returns here having done nothing, which is why all 12 existing
	# rooms keep the smooth hill they have always had.
	if not config.has("constitution"):
		return
	var want: String = str(config["constitution"]).strip_edges().to_lower()
	if not CONSTITUTIONS.has(want):
		push_warning("RandomBellCurve: unknown constitution '%s' — keeping '%s'" % [want, constitution])
		return
	if want == constitution:
		return
	constitution = want
	# Re-body only. The vertex field, the RNG draws and the collider are already
	# built and are not touched: this rewrites what the law LOOKS like, not where
	# the player's feet land.
	if mesh_instance != null and not verts.is_empty():
		_commit_mesh()


# ── THE CONSTITUTION ─────────────────────────────────────────────────────────
# One body per value, all four read from the SAME `verts` field. Nothing below
# calls rng: the draws happened once, in _make_bell_curve, before any of this.

## The reader. Lower, strip, and fall back to the legacy value on anything
## unrecognised: a typo must not dissolve ground 12 rooms expect to be solid.
func constitution_name() -> String:
	var v: String = constitution.strip_edges().to_lower()
	if CONSTITUTIONS.has(v):
		return v
	if v != "":
		push_warning("RandomBellCurve: unknown constitution '%s' — keeping 'skin'" % v)
	return "skin"


## TERRACE — the same surface with every vertex snapped to one of ten levels.
## The law is still under there; its face is now a staircase of contours, which
## is what binning does to a continuum and what a contour map has always been.
func _body_terrace() -> Mesh:
	var peak: float = 0.0
	for i in range(verts.size()):
		peak = maxf(peak, verts[i].y)
	var step: float = maxf(peak / float(TERRACE_LEVELS), 0.001)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in indices.size():
		var idx := indices[i]
		var v: Vector3 = verts[idx]
		var q: float = floor(v.y / step) * step
		st.set_uv(uvs[idx])
		st.add_vertex(Vector3(v.x, q, v.z))
	st.generate_normals()
	return st.commit()


## COLUMN — 400 standing boxes, one per cell, each as tall as the law is there
## and 78% of the cell wide so the gaps between them are visible. A histogram
## with two axes of bins: the surface is gone and only counts are left.
func _body_column() -> Mesh:
	var vx: int = quads_x + 1
	var w: float = cell_size * COLUMN_FILL
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(quads_z):
		for x in range(quads_x):
			var i0: int = z * vx + x
			var i1: int = i0 + 1
			var i2: int = i0 + vx
			var i3: int = i2 + 1
			var h: float = (verts[i0].y + verts[i1].y + verts[i2].y + verts[i3].y) * 0.25
			h = maxf(h, FLOOR_HEIGHT)
			var cx: float = (verts[i0].x + verts[i1].x) * 0.5
			var cz: float = (verts[i0].z + verts[i2].z) * 0.5
			_add_box(st, Vector3(cx, h * 0.5, cz), Vector3(w, h, w))
	st.generate_normals()
	return st.commit()


## RIB — eleven standing sections through the same field, one every other row,
## each a thin wall whose top edge follows the curve exactly. The law as a set
## of drawn profiles: you read the 1-D bell eleven times and see daylight
## between the readings.
func _body_rib() -> Mesh:
	var vx: int = quads_x + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z: int = 0
	while z <= quads_z:
		for x in range(quads_x):
			_add_curtain(st, verts[z * vx + x], verts[z * vx + x + 1], RIB_THICKNESS)
		z += RIB_STRIDE
	st.generate_normals()
	return st.commit()


## One segment of a rib: a slab of thickness `t` standing from y=0 up to the
## curve, its top edge sloping from a to b. Front, back and top only — the two
## ends are left open because the field is ~0 there and nothing sees inside.
func _add_curtain(st: SurfaceTool, a: Vector3, b: Vector3, t: float) -> void:
	var hz: float = t * 0.5
	var ay: float = maxf(a.y, FLOOR_HEIGHT)
	var by: float = maxf(b.y, FLOOR_HEIGHT)
	var af := Vector3(a.x, 0.0, a.z + hz)
	var bf := Vector3(b.x, 0.0, b.z + hz)
	var atf := Vector3(a.x, ay, a.z + hz)
	var btf := Vector3(b.x, by, b.z + hz)
	var ab := Vector3(a.x, 0.0, a.z - hz)
	var bb := Vector3(b.x, 0.0, b.z - hz)
	var atb := Vector3(a.x, ay, a.z - hz)
	var btb := Vector3(b.x, by, b.z - hz)
	_add_quad(st, af, atf, btf, bf)     # front  (+Z)
	_add_quad(st, ab, bb, btb, atb)     # back   (−Z)
	_add_quad(st, atb, btb, btf, atf)   # top    (+Y)


## An axis-aligned box. Wound clockwise-from-outside, which is Godot's
## front-face convention, so generate_normals() gives outward normals.
func _add_box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: Array[Vector3] = [
		center + Vector3(-h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z),
		center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z),
		center + Vector3(-h.x, h.y, h.z),
	]
	_add_quad(st, p[4], p[5], p[6], p[7])   # top
	_add_quad(st, p[0], p[3], p[2], p[1])   # bottom
	_add_quad(st, p[0], p[1], p[5], p[4])   # −Z
	_add_quad(st, p[2], p[3], p[7], p[6])   # +Z
	_add_quad(st, p[3], p[0], p[4], p[7])   # −X
	_add_quad(st, p[1], p[2], p[6], p[5])   # +X


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(a)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(b)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(c)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(a)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(c)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(d)
