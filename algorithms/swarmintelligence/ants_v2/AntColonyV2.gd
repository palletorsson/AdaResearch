extends Node3D

# @identity
# essence: ant.move() = gradient_ascent(pheromone_grid) + wander; pheromone_grid *= decay + diffuse — ant and environment co-evolve
# desire: to walk across the terrain floor and watch ant highways emerge beneath you — paths that existed as pure probability before they were paths
# critical_parameter: anchorage — the geometry of the fixed points the self-written field is pinned to; grid_resolution only decides how finely that field is drawn
# triggers: two food clusters at asymmetric distances produce unequal trail widths as the colony allocates traffic proportional to yield and proximity
# emerges: trail Y-junctions that route ants to whichever food source is currently less depleted — an emergent load-balancer no one designed
# needs: [missing] no VR controls at all; no sliders for ant_count, evaporation, deposit_amount; learner cannot intervene with the colony in real time
# relationships: simpler predecessor to AntColonyOptimization (no quality weighting, no tandem running, no modes); AntColonyV2 is world-scale vs. ACO's compact heatmap
# truth: the map is written by the travelers — the territory and the route emerge together

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — anchorage
# ═══════════════════════════════════════════════════════════════════
#
# The colony writes its own map. What it CANNOT choose is the shape of the
# problem: where the fixed points are. `anchorage` varies exactly that — the
# geometry of the food, and nothing else. The home emission stays at the origin
# at every value, because in a stigmergic system the destination is the message
# and the nest is only the return address.
#
#   pair       the shipped build, unchanged: two 9 m discs on one diagonal at
#              (15,0,15) and (-15,0,-10), unequal radii 21.2 m and 18.0 m. Two
#              unequal trunks grow out of the origin.
#   triad      three anchors, all at exactly 18 m, 120° apart. No shortest
#              arm exists, so traffic must split three ways.
#   ring       six anchors on a 36 m-diameter circle, rotated 30° off triad's
#              spokes. A rim of anchors with the whole middle bare except the
#              home marker.
#   scattered  five anchors drawn once from a FIXED rng (seed 20260730)
#              inside ±20 m with a 10 m minimum separation — unequal radii,
#              sitting on no locus at all.
#
# WHAT AN ANCHOR IS DRAWN AS — and why the sentence above used to be a lie.
# The constellations were always real: _anchor_positions() has always returned
# 2 / 3 / 6 / 5 genuinely different points. Only the DRAWING was thin. An anchor
# was one 9 m disc, 0.5 m tall, alpha-0.3 green, lying flat. The sweep camera
# looks down at 15° (PITCH -0.26 in capture_config_sweep), which squashes a flat
# disc to about a quarter of its own depth, and alpha 0.3 over sand moves the
# luminance of those few pixels by roughly nine levels out of 255. Three, five and
# six of them therefore painted ONE PICTURE: the critic measured ring==triad at
# 0.81%, scattered==triad at 1.03%, ring==scattered at 1.12% — three twins inside
# a four-value axis. Sibling PhysarumColony carries the same axis and has no twins
# because its anchors are SPHERES up to 6.4 m across; the difference between the
# two artifacts was never the geometry, it was whether the geometry had a body.
#
# So a promoted anchor now stands a MAST on its own disc: same centre, same food,
# a 4 m opaque heap 6.8 m wide at the base, entirely inside the 9 m footprint.
# Nothing about the axis's meaning moved — count and position are still the whole
# of it — but count and position are now carried by silhouette and by the shadow
# the key light throws across the sand, instead of by a stain the camera angle
# flattens away.
#
# `pair` DOES NOT GET A MAST. It is the @export default, and the default is the
# pre-promotion look exactly, byte for byte, because it stands in shipped maps.
# So pair keeps its two bare wafers and the asymmetry lives in this comment rather
# than hidden in a render. pair was never one of the twins.
#
# TWIN CHECK, redone against what is actually on screen. Every promoted value
# differs from every other in MAST COUNT and in every mast POSITION:
#   triad vs ring       3 masts against 6, and RING_PHASE rotates the ring 30° so
#                       that the closest triad mast and ring mast are 9.32 m apart
#                       — wider than a mast — hence all nine silhouettes are
#                       disjoint on the ground and none cancels.
#   triad vs scattered  3 masts all at exactly 18 m against 5 the fixed draw puts
#                       anywhere inside ±20 m, on no common radius.
#   ring vs scattered   6 on a perfect 36 m circle against 5 that the
#                       minimum-separation draw guarantees sit on no locus.
#   pair vs any         2 flat wafers and no mast at all against 3–6 standing
#                       heaps: the largest step in the axis, as it should be,
#                       since pair is the one value with a different body.
#
# NO TIME-DOMAIN AXIS HERE. Nothing varies speed, decay, deposit rate or
# lifetime. The axis is the STANDING CONFIGURATION the rule is asked to solve,
# and it is legible in the first frame: the discs, the masts and the home marker
# are all built during _ready, and the source halos are laid in from physics
# tick 1. The mast in particular needs no simulated time at all — it is standing
# before the first ant has moved.

@export_enum("pair", "triad", "ring", "scattered") var anchorage: String = "pair"

## Every accepted spelling of `anchorage`. A value outside this list is a typo
## and falls back to the shipped look rather than stranding the placement with
## no food at all.
const ANCHORAGES: PackedStringArray = ["pair", "triad", "ring", "scattered"]

## Non-geometry key. Default FALSE so the shipped build is byte-for-byte the
## pre-promotion look: plain alpha-green discs, an unlit home sphere. When a map
## or the curation station asks for it, the anchors light. Applied IN PLACE —
## it never triggers a rebuild.
@export var emissive: bool = false

@export var num_ants: int = 100
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var grid_resolution: int = 256 # Higher res for better trails

@export var ant_scene: PackedScene

# ── anchorage geometry constants ──────────────────────────────────
const DISC_RADIUS: float = 4.5      # 9 m diameter disc, as shipped
const DISC_HEIGHT: float = 0.5

const PAIR_A: Vector3 = Vector3(15, 0, 15)
const PAIR_B: Vector3 = Vector3(-15, 0, -10)

const TRIAD_RADIUS: float = 18.0
const TRIAD_A: Vector3 = Vector3(18, 0, 0)
const TRIAD_B: Vector3 = Vector3(-9, 0, 15.6)
const TRIAD_C: Vector3 = Vector3(-9, 0, -15.6)

const RING_COUNT: int = 6
const RING_RADIUS: float = 18.0
## Half a ring step, in radians: the ring's spacing is 60°, so this is 30°. At
## phase zero three of the six ring anchors sat EXACTLY on triad's three, so half
## of what should have separated the two values cancelled pixel for pixel. Rotated,
## the
## closest triad-to-ring distance is 9.32 m — wider than a 6.8 m mast — so the two
## constellations share no ground at all. Adjacent ring anchors are still 18 m
## apart and still on a 36 m circle; only the phase moved.
const RING_PHASE: float = PI / 6.0

# ── anchor mast: the standing part of a promoted anchor ───────────
# Sized by two hard limits, not by taste.
#
# WIDTH is capped by the disc: the mast is the food heap standing ON its own 9 m
# footprint, so a 3.4 m base radius keeps 1.1 m of green stain visible as a skirt
# all the way round.
#
# HEIGHT is capped by the caption. The bezel hangs at 4.185–4.815 m over
# (0, -22). The worst case the axis can put on the caption's own line is ring's
# (0, 0, -18), with a scattered draw able to reach about (0, 0, -20); projected
# through the sweep camera (YAW 0.62, PITCH -0.26, PAD 1.9, which puts the eye
# ~221 m out) the top rim of a 4.0 m mast at either point lands just below the
# bezel's bottom edge — a margin of roughly two pixels in a 760 px frame, so it
# is a CEILING and not a comfortable one. A taller mast would stand a pillar
# through the artifact's own name, which is the failure the one-label rule below
# exists to prevent. Raise this only with a fresh projection, or move the caption
# — and moving the caption changes pair's render, which law 4 forbids.
#
# The colour is a dark saturated green: against lit sand (albedo 0.8/0.7/0.5) it
# reads as a deep mass, and against the sweep's near-black background (0.055) the
# few masts that clear the far horizon still read as a body. Opaque on purpose —
# the wafer's alpha 0.3 is what flattened this axis in the first place.
const MAST_HEIGHT: float = 4.0
const MAST_BOTTOM_RADIUS: float = 3.4
const MAST_TOP_RADIUS: float = 2.4
const MAST_COLOR: Color = Color(0.07, 0.30, 0.10)

const SCATTER_COUNT: int = 5
const SCATTER_SEED: int = 20260730
const SCATTER_EXTENT: float = 20.0
const SCATTER_MIN_SEP: float = 10.0
## Hard bound on the rejection sampler. Five discs of 5 m exclusion inside a
## 40 x 40 m box is a loose packing, so this ceiling is never reached in
# practice — it exists so the build can never spin under --no-window.
const SCATTER_MAX_DRAWS: int = 500

## Used only if the bounded draw somehow fails to place five. Hand-checked:
## every pair is at least 17.0 m apart, every point inside ±20 m, radii from
## 8.1 m to 21.0 m. Guarantees the COUNT is 5 at every build.
const SCATTER_FALLBACK: Array = [
	Vector3(-6, 0, -5.5), Vector3(13, 0, 4), Vector3(2, 0, 17),
	Vector3(-18, 0, 9), Vector3(9, 0, -19)]

## Ant headings are drawn from each ant's own RandomNumberGenerator, which
## Godot auto-seeds from entropy. That made two builds of one anchorage value
## different pictures, which the critic would read as signal. Every ant is
## re-seeded from this constant before initialize() so the still is repeatable.
## The global seed()/randomize() is never called — reseeding the whole process
## from inside one artifact is not this artifact's business.
const ANT_SEED: int = 20260730
const ANT_SEED_STRIDE: int = 7919

# ── caption ───────────────────────────────────────────────────────
# ONE Label3D, billboard ENABLED so LabelFramer plates it properly. It floats
# over the far edge of the plane at -Z, 4.50 m up. The bezel bottom sits at
# 4.185 m; the tallest thing under it is a 4.0 m anchor mast, so the clearance in
# Y is 0.185 m and MAST_HEIGHT is what is holding it — read that constant's note
# before raising a mast. The masts also stand no further out than 21 m while the
# plate hangs at z = -22, so at the sweep camera the nearest one still projects
# below the bezel instead of through the word it is holding up.
# Deliberately NOT one caption per food cluster — two to six opaque plates lying
# flat on the pheromone texture would black out the trail junctions that are the
# entire point of the artifact.
const CAPTION_NAME: String = "AnchorageCaption"
const CAPTION_POS: Vector3 = Vector3(0.0, 4.50, -22.0)
const CAPTION_PIXEL_SIZE: float = 0.005
const CAPTION_FONT_SIZE: int = 100
const CAPTION_FORMAT: String = "ANT COLONY %-7s"

# Resources
var grid: PheromoneGrid
var p_texture: ImageTexture
var p_image: Image

# Nodes
@onready var terrain_mesh: MeshInstance3D = $ResultMesh

var emission_centers: Array = []

## Nodes THIS script created and may free. The caption is deliberately NOT in
## here — the framer plates a Label3D at spawn, so it is created once and only
## its .text is live-updated.
var _spawned: Array[Node] = []
var _food_mats: Array[StandardMaterial3D] = []
var _caption: Label3D = null
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD — synchronous, from @export values alone, and it RETURNS
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# Ensure Home Area detects Ants (Layer 2)
	var home_area: Area3D = get_node_or_null("HomeArea") as Area3D
	if home_area:
		home_area.collision_mask = 2

	# 1. Setup Grid
	grid = PheromoneGrid.new(grid_resolution, grid_resolution)

	# Home Emission (Type 0 = Home) — IDENTICAL at every anchorage value.
	var home_pos: Vector2i = _world_to_grid(Vector3.ZERO)
	emission_centers.append({
		"x": home_pos.x, "y": home_pos.y,
		"type": 0, "radius": 10.0, "amount": 5.0
	})

	# 2. Setup Texture
	p_image = grid.get_image()
	p_texture = ImageTexture.create_from_image(p_image)

	# 3. Setup Terrain Shader
	if terrain_mesh:
		var mat: Material = terrain_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("pheromone_texture", p_texture)

	# 4. Spawn Ants — deterministically seeded, bounded by num_ants
	if ant_scene:
		for i in range(num_ants):
			var ant: Node = ant_scene.instantiate()
			add_child(ant)
			_spawned.append(ant)
			var ant_rng: Variant = ant.get("rng")
			if ant_rng is RandomNumberGenerator:
				(ant_rng as RandomNumberGenerator).seed = ANT_SEED + i * ANT_SEED_STRIDE
			if ant.has_method("initialize"):
				ant.initialize(Vector3.ZERO, grid, terrain_size)

	# 5. Anchorage — the food geometry, and only the food geometry.
	# The disc, the emission centre and the Area3D are IDENTICAL at every value:
	# what the colony can smell and eat does not depend on how the anchor is drawn.
	# The mast is added on top, and only for the three promoted values — `pair`
	# ships the bare wafer it always shipped.
	var anchors: Array[Vector3] = _anchor_positions()
	var stands: bool = _resolved_anchorage() != "pair"
	for i in range(anchors.size()):
		_spawn_food_cluster(anchors[i], DISC_RADIUS)
		if stands:
			_spawn_anchor_mast(anchors[i])

	# 6. Caption — created once, text refreshed every build
	_ensure_caption()

	# 7. Non-geometry keys land last, in place
	_apply_emissive()


## The value this build will actually draw. A token outside ANCHORAGES is a typo
## and resolves to "pair", the shipped look. Everything that branches on the axis
## MUST go through here — the positions and the mast decision reading `anchorage`
## separately is how a typo would produce pair's two discs wearing masts, a fifth
## picture the registry never declared.
func _resolved_anchorage() -> String:
	return _pick_axis(anchorage, ANCHORAGES, "pair")


## The whole axis, in one table. Every branch returns a different COUNT or a
## different radius set; none of them no-ops.
func _anchor_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	match _resolved_anchorage():
		"triad":
			# Three discs, all exactly 18 m from home, 120° apart — no
			# shortest arm, so the colony has to split traffic three ways.
			out.append(TRIAD_A)
			out.append(TRIAD_B)
			out.append(TRIAD_C)
		"ring":
			# Six anchors on a 36 m-diameter circle: an anchored rim with a bare
			# middle. Adjacent anchors are 18 m apart, twice a disc's diameter, so
			# they read as six things and not as a green annulus. RING_PHASE keeps
			# every one of them off triad's spokes.
			for i in range(RING_COUNT):
				var a: float = TAU * float(i) / float(RING_COUNT) + RING_PHASE
				out.append(Vector3(cos(a) * RING_RADIUS, 0.0, sin(a) * RING_RADIUS))
		"scattered":
			out = _scatter_positions()
		_:
			# "pair" — the shipped build, byte-for-byte.
			out.append(PAIR_A)
			out.append(PAIR_B)
	return out


## Five positions from one fixed RandomNumberGenerator, rejected until they are
## at least SCATTER_MIN_SEP apart. Bounded twice over: the draw counter can
## never exceed SCATTER_MAX_DRAWS, and if it ever ran out the hand-checked
## fallback set is used whole (never mixed, which could violate separation).
func _scatter_positions() -> Array[Vector3]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED
	var out: Array[Vector3] = []
	var draws: int = 0
	while out.size() < SCATTER_COUNT and draws < SCATTER_MAX_DRAWS:
		draws += 1
		var p: Vector3 = Vector3(
			rng.randf_range(-SCATTER_EXTENT, SCATTER_EXTENT),
			0.0,
			rng.randf_range(-SCATTER_EXTENT, SCATTER_EXTENT))
		var ok: bool = true
		for j in range(out.size()):
			if p.distance_to(out[j]) < SCATTER_MIN_SEP:
				ok = false
				break
		if ok:
			out.append(p)
	if out.size() < SCATTER_COUNT:
		out.clear()
		for j in range(SCATTER_FALLBACK.size()):
			out.append(SCATTER_FALLBACK[j])
	return out


func _spawn_food_cluster(pos: Vector3, radius: float) -> void:
	# Add to emission centers (Type 1 = Food)
	var grid_pos: Vector2i = _world_to_grid(pos)
	emission_centers.append({
		"x": grid_pos.x, "y": grid_pos.y,
		"type": 1, "radius": 10.0, "amount": 5.0
	})

	# Create a visual marker
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = DISC_HEIGHT
	mesh.mesh = cyl
	mesh.position = pos
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.0, 1.0, 0.0, 0.3)
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)
	_spawned.append(mesh)
	_food_mats.append(mat)

	# Create Area3D for detection
	var area: Area3D = Area3D.new()
	area.collision_mask = 2 # Detect Ants (Layer 2)
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	col.shape = shape
	area.add_child(col)
	area.position = pos
	area.body_entered.connect(_on_food_entered)
	add_child(area)
	_spawned.append(area)


## The standing part of a promoted anchor: a 4 m tapered heap seated on the disc
## it shares a centre with. VISUAL ONLY — it adds no emission centre and no Area3D,
## so the colony's problem is byte-for-byte what it was before the mast existed and
## an ant can still walk through where the heap appears to be. Its material joins
## _food_mats so the non-geometry `emissive` key lights the heap and its skirt
## together instead of leaving a lit disc under an unlit lump.
func _spawn_anchor_mast(pos: Vector3) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = MAST_TOP_RADIUS
	cyl.bottom_radius = MAST_BOTTOM_RADIUS
	cyl.height = MAST_HEIGHT
	mesh.mesh = cyl
	# CylinderMesh is centre-origin, so half the height lifts the base to y = 0 —
	# the plane, and the mid-plane of the 0.5 m disc — rather than burying the
	# heap to its waist. The bottom 0.25 m stands inside the translucent disc,
	# which is what a heap sitting in its own stain should look like.
	mesh.position = Vector3(pos.x, pos.y + MAST_HEIGHT * 0.5, pos.z)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = MAST_COLOR
	mat.roughness = 0.9
	mat.metallic = 0.0
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)
	_spawned.append(mesh)
	_food_mats.append(mat)


## One label, no stack, no merge. Created once so LabelFramer plates it at the
## size its first text needs; later config changes only rewrite .text, which is
## the sanctioned live-update.
func _ensure_caption() -> void:
	if _caption == null or not is_instance_valid(_caption):
		var lab: Label3D = Label3D.new()
		lab.name = CAPTION_NAME
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.pixel_size = CAPTION_PIXEL_SIZE
		lab.font_size = CAPTION_FONT_SIZE
		lab.position = CAPTION_POS
		add_child(lab)
		_caption = lab
	_caption.text = CAPTION_FORMAT % [anchorage.to_upper()]


## Non-geometry. Food disc materials are ours outright; the HomeVisual override
## is set when lit and cleared to null when not, which restores the scene's own
## unlit default exactly.
func _apply_emissive() -> void:
	var energy: float = 1.6 if emissive else 0.0
	for i in range(_food_mats.size()):
		var m: StandardMaterial3D = _food_mats[i]
		m.emission_enabled = emissive
		m.emission = Color(0.0, 1.0, 0.2)
		m.emission_energy_multiplier = energy
	var home_visual: MeshInstance3D = get_node_or_null("HomeVisual") as MeshInstance3D
	if home_visual:
		if emissive:
			var hm: StandardMaterial3D = StandardMaterial3D.new()
			hm.albedo_color = Color(1.0, 1.0, 1.0)
			hm.emission_enabled = true
			hm.emission = Color(0.4, 0.6, 1.0)
			hm.emission_energy_multiplier = 1.6
			home_visual.set_surface_override_material(0, hm)
		else:
			home_visual.set_surface_override_material(0, null)


func _on_food_entered(body) -> void:
	if body is SimpleAnt:
		body.set_found_food()


func _physics_process(_delta):
	if grid == null or p_texture == null:
		return

	# 1. Source Emission
	grid.process_source_emission(emission_centers)

	# 2. Diffusion (Blur)
	grid.process_diffusion()

	# 3. Decay
	grid.process_decay()

	# Update Texture
	p_image = grid.get_image()
	p_texture.update(p_image)


# Home Area (Implicit at 0,0,0)
func _on_home_area_entered(body) -> void:
	if body is SimpleAnt:
		body.set_reached_home()


func _world_to_grid(pos: Vector3) -> Vector2i:
	var gx: int = int(remap(pos.x, -terrain_size.x / 2.0, terrain_size.x / 2.0, 0, grid.width))
	var gy: int = int(remap(pos.z, -terrain_size.y / 2.0, terrain_size.y / 2.0, 0, grid.height))
	return Vector2i(gx, gy)


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════
#
# Called via call_deferred AFTER _ready(). curation_station hands every curated
# artifact {"emissive": false} with no axis key, so that call must resolve to
# no change at all — and it does: emissive is applied in place above the
# early-return, and the geometry comparison below sees nothing moved.

func apply_grid_config(config_data: Dictionary) -> void:
	var before_anchorage: String = anchorage
	var before_ants: int = num_ants
	var before_resolution: int = grid_resolution

	if config_data.has("anchorage"):
		anchorage = _pick_axis(str(config_data["anchorage"]), ANCHORAGES, anchorage)
	if config_data.has("num_ants"):
		num_ants = clampi(int(config_data["num_ants"]), 1, 400)
	if config_data.has("grid_resolution"):
		grid_resolution = clampi(int(config_data["grid_resolution"]), 32, 512)
	if config_data.has("emissive"):
		emissive = _pick_bool(config_data["emissive"], emissive)

	# Non-geometry, applied IN PLACE before any return.
	_apply_emissive()

	if not _built:
		return
	if anchorage == before_anchorage \
			and num_ants == before_ants \
			and grid_resolution == before_resolution:
		return

	_rebuild_now()
	print("[AntColonyV2] Config applied — anchorage=%s, ants=%s, grid=%s" % [
		anchorage, num_ants, grid_resolution])


## Free ONLY what this script made, then rebuild inline. No call_deferred: a
## deferred rebuild that removes children first makes auto-grounding measure a
## zero AABB and bail. No await: an await can hang a headless capture, and this
## family is the named hang class.
func _rebuild_now() -> void:
	for i in range(_spawned.size()):
		var c: Node = _spawned[i]
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()
	_food_mats.clear()
	emission_centers.clear()
	grid = null
	p_image = null
	p_texture = null
	_build_all()


## Accept an axis value only if it names something we actually build. A typo in
## a map token falls back to the legacy look rather than leaving the colony with
## nothing to find.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Never bool() — bool("false") is TRUE and would invert the meaning of every
## map that spells the key out.
func _pick_bool(raw: Variant, fallback: bool) -> bool:
	if raw is bool:
		return raw == true
	if raw is int or raw is float:
		return float(raw) != 0.0
	var s: String = str(raw).to_lower().strip_edges()
	if s == "true" or s == "1" or s == "yes" or s == "on":
		return true
	if s == "false" or s == "0" or s == "no" or s == "off":
		return false
	return fallback
