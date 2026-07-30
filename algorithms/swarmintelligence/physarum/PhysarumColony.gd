extends Node3D

# @identity
# essence: trail(x,y) = deposit(agent_positions) * diffuse - evaporate — no neurons, no memory, just chemistry
# desire: to feel what it's like to be a network that designs itself — the moment a random scatter becomes a vascular web
# critical_parameter: emission_centers layout — the attractor geometry determines every possible network the colony can grow
# triggers: adding a new attractor causes the colony to re-route all trails within seconds, like rewiring a circuit live
# emerges: shortest-path trees, Steiner networks, and load-balanced branching — solutions that take mathematicians centuries to formalize
# needs: [missing] no VR sliders; attractor positions could be grabbed and moved; deposit/evaporation rate sliders would let learner push colony to collapse or overgrowth
# relationships: unlocks AntColonyV2 and ant_colony_optimization; contrasts with FlowFieldMain (external field vs. self-created field); depends on PhysarumGrid and PhysarumAgent
# truth: intelligence is a property of the medium, not the agent — the slime mold's network is smarter than any individual cell

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — anchorage
# ═══════════════════════════════════════════════════════════════════
#
# The header has named `emission_centers layout` the critical parameter since the
# day this artifact was written, and it has never been addressable. Four layouts
# already lived inside set_distribution(), reachable only by standing still for
# twenty seconds and waiting for a hardcoded timer to hand you the next one. A map
# could not ask for one; a still could not show one on purpose.
#
# anchorage is the geometry of the fixed points the self-written field is pinned
# to — the shape of the problem the colony is asked to solve. Not `sources` (the
# plural is already a live value word and source/sources at two levels is the rig
# failure), not `attractor` (jargon), not `larder`/`provision` (both read as
# quantity, and this is geometry), not `errand` (charming, not a taxonomy).
#
# The word is shared with AntColonyV2, because the two are structurally a family:
# both write a chemical field no agent remembers, both pin it to a list literally
# called emission_centers, both convert metres to cells with the same _world_to_grid.
# The DEFAULT is not shared — physarum ships a triad, ants ship a pair, and law 4
# (the default is the pre-promotion look, exactly) outranks tidiness.
#
# NOT A TIME AXIS. Nothing here varies speed, decay-per-second, spawn interval or
# the twenty-second carousel. What varies is the standing configuration the rule is
# given: how many anchors, and where.

## The geometry of the fixed points the self-written field is moored to.
##   pair      — two anchors 40 m apart on X, nothing between them; one thick trunk.
##   triad     — the shipped layout: centre + two diagonal outliers; a three-armed Y.
##   ring      — eight anchors on a 40 m circle; a rim with a hollow 30 m middle.
##   scattered — five anchors from a fixed seed, min 8 m apart; unequal arms.
@export_enum("pair", "triad", "ring", "scattered") var anchorage: String = "triad"

## The allow-list. A token outside it is a typo and falls back to the shipped look
## rather than stranding a placement with no anchors at all.
const ANCHORAGES: PackedStringArray = ["pair", "triad", "ring", "scattered"]

## The shipped carousel order, unchanged: triad → ring → pair → scattered. The axis
## picks the STARTING index; the cycle then runs the same four in the same order, so
## `triad` reproduces today's behaviour frame for frame and no timing becomes a variable.
const CAROUSEL: PackedStringArray = ["triad", "ring", "pair", "scattered"]

# ── Determinism ────────────────────────────────────────────────────
# Every draw in the build path is seeded from a constant declared here. The global
# seed()/randomize() is never called — one artifact reseeding the whole process is
# how a swarm sequence turns noise into apparent signal.
const AGENT_SEED: int = 20260730          # agent spawn ring (position)
const AGENT_HEADING_SEED: int = 771_400   # base for each agent's own rng.seed
const SCATTER_SEED: int = 20260730        # `scattered` anchor constellation
const SCATTER_MIN_SEP: float = 8.0        # metres between any two scattered anchors
const SCATTER_TRIES: int = 200            # HARD cap per point — the loop is bounded

# ── Caption ────────────────────────────────────────────────────────
# One label. A 50 m artifact stood unnamed; four to eight per-anchor captions would
# become four to eight opaque plates punched through the very field whose geometry
# this axis is about, so there is exactly one and it stands clear of the body.
const CAPTION_NAME: String = "AnchorageCaption"
const CAPTION_FMT: String = "PHYSARUM  %-8s"
const CAPTION_POS: Vector3 = Vector3(0.0, 6.00, -22.0)
const CAPTION_PIXEL_SIZE: float = 0.005
const CAPTION_FONT_SIZE: int = 140

# Config
@export var num_agents: int = 500
@export var grid_resolution: int = 256
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var agent_scene: PackedScene

# Internal
var grid: PhysarumGrid
var p_image: Image
var p_texture: ImageTexture
var emission_centers = []
var markers = []
var dist_timer: float = 0.0
var dist_mode: int = 0
const DURATION = 20.0

var _built: bool = false
## Only nodes THIS script created. Freeing get_children() would destroy the plates
## and bezels the grid's LabelFramer adds after us.
var _owned: Array[Node] = []
## Created once, never freed by a rebuild — the framer needs the Label3D to survive,
## and its plate is parented to it.
var _caption: Label3D = null
## Non-geometry key from curation_station: {"emissive": false} arrives on every
## curated artifact one line after its labels are framed. false is the shipped look.
var _emissive: bool = false

# Nodes
@onready var result_mesh: MeshInstance3D = $ResultMesh

func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD — synchronous, from @export values alone, and it RETURNS
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# 1. Setup Grid
	grid = PhysarumGrid.new(grid_resolution, grid_resolution)

	# 2. Setup Texture
	p_image = grid.get_image()
	p_texture = ImageTexture.create_from_image(p_image)

	# 3. Apply to Shader
	if result_mesh:
		var mat = result_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("slime_texture", p_texture)

	# 4. Spawn Agents (Random Circle) — seeded, never global randf()
	if agent_scene:
		var rng := RandomNumberGenerator.new()
		rng.seed = AGENT_SEED
		for i in range(num_agents):
			var agent = agent_scene.instantiate()
			# Seed the agent's own generator BEFORE it enters the tree, so its
			# initial heading and every motor-stage coin flip are reproducible.
			# PhysarumAgent constructs an unseeded RandomNumberGenerator; left
			# alone, two builds of one axis value would not be pixel-identical.
			if "rng" in agent and agent.rng is RandomNumberGenerator:
				agent.rng.seed = AGENT_HEADING_SEED + i
			add_child(agent)
			_owned.append(agent)

			# Random pos in circle
			var angle: float = rng.randf() * TAU
			var rad: float = rng.randf() * 5.0
			var start_pos := Vector3(cos(angle) * rad, 0, sin(angle) * rad)

			agent.initialize(start_pos, grid, terrain_size)

	# 5. Start the carousel AT the declared anchorage, then let it run as it always has.
	dist_timer = 0.0
	dist_mode = maxi(CAROUSEL.find(_pick_axis(anchorage, ANCHORAGES, "triad")), 0)
	set_distribution(dist_mode)

	# 6. Name the thing.
	_ensure_caption()


func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	markers.clear()
	emission_centers.clear()
	grid = null
	p_image = null
	p_texture = null
	_build_all()


func _physics_process(delta: float) -> void:
	if grid == null:
		return

	# Sequence Logic
	dist_timer += delta
	if dist_timer >= DURATION:
		dist_timer = 0.0
		dist_mode = (dist_mode + 1) % CAROUSEL.size()
		set_distribution(dist_mode)

	# Update Grid Logic (Decay + Diffuse)
	grid.process_attractors(emission_centers)
	grid.process_step()

	# Update Texture
	p_image = grid.get_image()
	p_texture.update(p_image)


## Kept as the carousel's entry point; `mode` indexes CAROUSEL, which is the
## shipped order. The geometry itself now lives in _build_anchorage.
func set_distribution(mode: int) -> void:
	var idx: int = posmod(mode, CAROUSEL.size())
	_build_anchorage(CAROUSEL[idx])


func _build_anchorage(value: String) -> void:
	# Clear old
	emission_centers.clear()
	for m in markers:
		if is_instance_valid(m):
			_owned.erase(m)
			remove_child(m)
			m.queue_free()
	markers.clear()

	match value:
		"pair":
			# Two anchors, 40 m apart on X, and NOTHING between them. The old mode-2
			# "distraction" attractor at (0,0,10) r4 is deleted here on purpose: with
			# it, pair read as a lopsided triangle and was a twin of triad. Without it
			# the colony grows one thick trunk, which is the whole point of the value.
			add_attractor(Vector3(-20, 0, 0), 8.0)
			add_attractor(Vector3(20, 0, 0), 8.0)
		"triad":
			# The shipped layout, byte for byte.
			add_attractor(Vector3(0, 0, 0), 8.0)
			add_attractor(Vector3(15, 0, 15), 6.0)
			add_attractor(Vector3(-15, 0, -15), 6.0)
		"ring":
			for i in range(8):
				var angle: float = i * (TAU / 8.0)
				var r: float = 20.0
				add_attractor(Vector3(cos(angle) * r, 0, sin(angle) * r), 5.0)
		"scattered":
			for pos in _scattered_positions():
				add_attractor(pos, 6.0)
		_:
			add_attractor(Vector3(0, 0, 0), 8.0)
			add_attractor(Vector3(15, 0, 15), 6.0)
			add_attractor(Vector3(-15, 0, -15), 6.0)

	_apply_emissive()
	_update_caption(value)


## Five anchors inside ±20 m, drawn from a FIXED generator and rejected while any
## two would sit within SCATTER_MIN_SEP. The rejection loop is capped at
## SCATTER_TRIES per point and falls back to the best candidate seen, so this
## function is bounded no matter what the seed does — a headless capture that never
## returns costs the pipeline a stall.
func _scattered_positions() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED
	var out: Array = []
	for _i in range(5):
		var best := Vector3.ZERO
		var best_sep: float = -1.0
		var placed: bool = false
		for _attempt in range(SCATTER_TRIES):
			var cand := Vector3(rng.randf_range(-20.0, 20.0), 0.0, rng.randf_range(-20.0, 20.0))
			var sep: float = 1.0e9
			for p in out:
				sep = minf(sep, cand.distance_to(p))
			if sep > best_sep:
				best_sep = sep
				best = cand
			if sep >= SCATTER_MIN_SEP:
				out.append(cand)
				placed = true
				break
		if not placed:
			out.append(best)
	return out


func add_attractor(pos_world: Vector3, radius: float) -> void:
	var grid_pos = _world_to_grid(pos_world)
	emission_centers.append({"x": grid_pos.x, "y": grid_pos.y, "radius": radius, "amount": 2.0})
	_spawn_marker(pos_world, radius)

func _spawn_marker(pos: Vector3, radius: float) -> void:
	var m = MeshInstance3D.new()
	m.mesh = SphereMesh.new()
	m.mesh.radius = radius * 0.4 # Scale visual to be slightly smaller than influence
	m.mesh.height = radius * 0.8
	m.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.set_surface_override_material(0, mat)
	add_child(m)
	markers.append(m)
	_owned.append(m)

func _world_to_grid(pos: Vector3) -> Vector2i:
	var gx = int(remap(pos.x, -terrain_size.x/2, terrain_size.x/2, 0, grid.width))
	var gy = int(remap(pos.z, -terrain_size.y/2, terrain_size.y/2, 0, grid.height))
	return Vector2i(gx, gy)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# CAPTION — one plate, above the body, out of the corridor
# ═══════════════════════════════════════════════════════════════════
#
# LabelFramer turns every hanging Label3D into an opaque anthracite panel with a
# bezel. Billboard is ENABLED because this text hangs in air with nothing behind it
# — claiming the BILLBOARD_DISABLED exemption for a floating label is the dodge.
# So it is placed as if it were already a solid board:
#
#   text     18 chars at font_size 140 x pixel_size 0.005 → cap 0.70 m
#   plate    7.03 x 0.77 m      (text + 0.10 w, + 0.07 h)
#   bezel    7.09 x 0.83 m
#   at y=6.00 the bezel spans 5.585 → 6.415
#   tallest body element is the r8 marker sphere at y = 3.2 → 2.39 m of clearance
#   at z=-22.0 it stands over the FAR edge of the 50 m plane, never between an
#   approaching viewer and the field
#
# One label, no stack, so nothing merges.
func _ensure_caption() -> void:
	if is_instance_valid(_caption):
		_update_caption(CAROUSEL[posmod(dist_mode, CAROUSEL.size())])
		return
	var l := Label3D.new()
	l.name = CAPTION_NAME
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = CAPTION_PIXEL_SIZE
	l.font_size = CAPTION_FONT_SIZE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate = Color(0.94, 0.94, 0.90)
	l.position = CAPTION_POS
	l.text = CAPTION_FMT % [CAROUSEL[posmod(dist_mode, CAROUSEL.size())]]
	add_child(l)
	_caption = l
	# Deliberately NOT in _owned: a rebuild must not free the node the framer
	# hung its plate on. Its text is live-updated instead.


func _update_caption(value: String) -> void:
	if is_instance_valid(_caption):
		_caption.text = CAPTION_FMT % [value]


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_anchorage: String = anchorage
	var before_agents: int = num_agents
	var before_res: int = grid_resolution
	var before_terrain: Vector2 = terrain_size

	if config_data.has("anchorage"):
		anchorage = _pick_axis(str(config_data["anchorage"]), ANCHORAGES, anchorage)
	if config_data.has("num_agents"):
		num_agents = clampi(int(config_data["num_agents"]), 1, 4000)
	if config_data.has("grid_resolution"):
		grid_resolution = clampi(int(config_data["grid_resolution"]), 32, 512)

	# Non-geometry key, applied IN PLACE before any early return. curation_station
	# hands EVERY curated artifact {"emissive": false} and there is no axis key in
	# that call, so the returns below fire — an accepted key that only took effect
	# inside the rebuild would be a key that does nothing.
	# bool() is not used: bool("false") is TRUE and would invert the meaning.
	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if anchorage == before_anchorage and num_agents == before_agents \
			and grid_resolution == before_res and terrain_size == before_terrain:
		return

	_rebuild_now()
	print("[PhysarumColony] Config applied — anchorage=%s, agents=%d" % [anchorage, num_agents])


## Accept an axis value only if it names something we actually build. A typo has to
## fall back to the shipped look; a half-recognised value would leave the colony
## with no anchors and nothing to grow toward.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Coerce a config value to bool without bool(), which is true for any non-empty
## string including "false".
func _as_bool(v, fallback: bool) -> bool:
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	var s: String = str(v).strip_edges().to_lower()
	if s in ["true", "1", "yes", "on"]:
		return true
	if s in ["false", "0", "no", "off", ""]:
		return false
	return fallback


## emissive=false is the shipped marker: translucent yellow, no emission. Only
## emissive=true adds glow, and it lights the anchors — the thing the axis is about.
func _apply_emissive() -> void:
	for m in markers:
		if not is_instance_valid(m):
			continue
		var mat: Material = m.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			var sm: StandardMaterial3D = mat
			sm.emission_enabled = _emissive
			if _emissive:
				sm.emission = Color(1.0, 0.95, 0.25)
				sm.emission_energy_multiplier = 1.6
