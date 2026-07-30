# non_teleological_evolution.gd
# Bodies exist in a space. No fitness function. No selection pressure.
# They reproduce based on proximity and energy (gained by moving to
# unvisited areas, lost by existing). Over generations, forms diversify —
# not toward any goal, just expanding possibility space.
# No "best" creature. No optimization. Just drift, variation, persistence.
#
# @identity
#   essence: evolution without purpose — bodies persisting through drift alone
#   desire: players witness diversification without optimization or progress narratives
#   critical_parameter: energy_decay — how fast creatures lose energy by merely existing
#   triggers: instantiation, runs continuously
#   emerges: the realization that evolution needs no goal to produce complexity
#   needs: [implemented] MultiMesh creatures, energy model, reproduction, death, Label3D stats
#   relationships: evolved_creatures (fitness-driven counterpart), 9_5_evolving_bloops_vr (similar)
#   truth: there is no ladder of progress — only a bush of persistence
#
# ── Stage-2 DNA ───────────────────────────────────────────────────────────────
# ONE axis: `selection` — what a selection pressure did to this population, and
# whether any pressure was applied at all.
#
# Before this pass the artifact had no axes and a bare `apply_grid_config`, so
# the artifact whose whole argument is that evolution has no goal could only ever
# be placed in one condition: its own. The counter-case was unbuildable, which
# means the claim was asserted rather than demonstrated — a map could not stand
# the goal-less field next to a field that had a goal imposed on it.
#
# `drift` is the default and is the shipped look, byte for byte: the live
# simulation, the same `hash("non_teleological")` seed, the same 30 mixed bodies.
# The other four values are what naming a goal COSTS — uniformity, a cull, a
# paved field, a schism.
#
# The temporal exports are the obvious trap and all four are refused as axes:
# energy_decay, energy_from_exploration and reproduction_threshold are per-second
# rates, and mutation_strength only expresses itself over generations. None can
# be photographed. At 2.0 m across this is a small body, so the values move
# COUNT, SIZE BAND and HUE BAND together — one creature's diameter change would
# not read at room distance, while 30 mid-sized dots against 120 large ones is
# legible from the doorway.

extends Node3D

# --- Configuration ---
@export var world_size: float = 2.0
@export var initial_population: int = 30
@export var max_population: int = 120
@export var energy_decay: float = 0.15  # Energy lost per second
@export var energy_from_exploration: float = 0.8  # Energy gained from unvisited cells
@export var reproduction_threshold: float = 3.0
@export var mutation_strength: float = 0.15
@export var grid_resolution: int = 20  # For tracking visited cells

## Stage-2 DNA axis — what a selection pressure did to this population.
##
##   drift    30 bodies, radius 0.02-0.05 m, random hues, scattered across the
##            2.0 x 2.0 m plane. The shipped state and the only one this file's
##            own header calls honest: no fitness function, no goal. The live
##            simulation runs.
##   uniform  30 bodies, ALL radius 0.035 m, ALL one hue, on an even 6 x 5 grid
##            at 0.32 m pitch. Same count, same field, the variety gone: what a
##            single reward looks like once it has finished.
##   culled   six bodies of one hue on the bare plane, 0.6 m apart, the other 114
##            MultiMesh instances parked off-screen. A goal was imposed and this
##            is the remnant.
##   runaway  the population at its own max_population ceiling: 120 bodies, all
##            radius 0.05 m, one hue, 0.15 m pitch. The plane is nearly paved and
##            the field has no empty cell left to explore.
##   split    two clusters of fifteen with a ~0.7 m empty corridor between them —
##            small 0.022 m blue bodies on -x, large 0.048 m red bodies on +x.
##            Ambiguous pressure, two answers, one field.
@export_enum("drift", "uniform", "culled", "runaway", "split") var selection: String = "drift"

## Every value this artifact actually builds. A typo in a map token has to fall
## back to the shipped look rather than strand a placement in an empty field.
const SELECTIONS: PackedStringArray = ["drift", "uniform", "culled", "runaway", "split"]

# --- Value geometry constants -------------------------------------------------
# Named so the numbers in the doc comment above and the numbers in the build are
# the same numbers.

## Every body sits at this Y, at every value, forever. The merged caption plate
## floats 0.46 m above the tallest body; lifting a creature in Y would turn that
## plate from a nameplate into a lid.
const BODY_Y: float = 0.03

const UNIFORM_RADIUS: float = 0.035
const UNIFORM_HUE: Color = Color(0.30, 0.78, 0.85)

const CULLED_COUNT: int = 6
const CULLED_COLS: int = 3
const CULLED_PITCH: float = 0.6
const CULLED_RADIUS: float = 0.035
const CULLED_HUE: Color = Color(0.92, 0.74, 0.32)

const RUNAWAY_COLS: int = 12
const RUNAWAY_PITCH: float = 0.15
const RUNAWAY_RADIUS: float = 0.05
const RUNAWAY_HUE: Color = Color(0.72, 0.90, 0.26)

const SPLIT_PER_CLUSTER: int = 15
const SPLIT_COLS: int = 3
const SPLIT_PITCH: float = 0.26
## Cluster centres. Inner columns land at ±0.40 m, so with a 0.022 m and a
## 0.048 m body on either lip the void between the clusters measures ~0.73 m.
const SPLIT_CENTRE_X: float = 0.66
const SPLIT_SMALL_RADIUS: float = 0.022
const SPLIT_LARGE_RADIUS: float = 0.048
const SPLIT_SMALL_HUE: Color = Color(0.28, 0.45, 0.92)
const SPLIT_LARGE_HUE: Color = Color(0.90, 0.26, 0.26)

## Starting energy, identical at every value so the alpha ramp in
## _update_multimesh reads the same everywhere.
const START_ENERGY: float = 1.5

# --- Internal ---
var _creatures: Array = []  # Array of dictionaries
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _visited_grid: Array = []  # 2D bool grid
var _generation_count: int = 0
var _total_born: int = 0
var _total_died: int = 0
var _max_species_diversity: float = 0.0

var _stats_label: Label3D
var _title_label: Label3D
var _no_fitness_label: Label3D

var _creature_mesh: SphereMesh
var _time_elapsed: float = 0.0
var _rng := RandomNumberGenerator.new()

## Non-geometry key from curation_station.gd:367-372, which hands EVERY artifact
## it curates {"emissive": false} one line after framing its labels. Applied IN
## PLACE on the live material — no rebuild, and never a silently ignored key.
var emissive: bool = true

## Only the nodes THIS script added. Freeing get_children() would destroy the
## caption plates and support furniture the grid parents onto us after spawn.
var _owned: Array[Node] = []

var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ------------------------------------------------------------------
# Build — synchronous, from @export values alone
# ------------------------------------------------------------------

## Everything the sweep needs happens here, from `selection` alone, with no
## call_deferred anywhere: a deferred rebuild that removes children first makes
## the grid's auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	_rng.seed = hash("non_teleological")
	_creatures.clear()
	_generation_count = 0
	_total_born = 0
	_total_died = 0
	_max_species_diversity = 0.0
	_time_elapsed = 0.0

	_init_visited_grid()
	_create_creature_mesh()
	_create_multimesh()
	_spawn_population()
	_create_labels()
	_create_ground_plane()

	# Push the seeded field into the MultiMesh immediately. Shipped code only did
	# this from _process, so frame zero was a bare plane — a still taken at spawn
	# read INERT. Every later frame is unchanged by this call.
	_update_multimesh()
	_update_stats()

	# `drift` is the live artifact and keeps its simulation. The other four values
	# are terminal states the spec names as finished — "once it has finished",
	# "the remnant", "at its own ceiling" — so they hold still. They have to: one
	# second of wander would dissolve uniform's grid and close split's corridor.
	set_process(selection == "drift")


func _rebuild_now() -> void:
	for c in _owned:
		if c != null and is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_multimesh_instance = null
	_multimesh = null
	_creature_mesh = null
	_title_label = null
	_no_fitness_label = null
	_stats_label = null
	_build_all()


func _track(n: Node) -> void:
	_owned.append(n)
	add_child(n)


# ------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------

func _init_visited_grid() -> void:
	_visited_grid.resize(grid_resolution)
	for x in range(grid_resolution):
		_visited_grid[x] = []
		_visited_grid[x].resize(grid_resolution)
		for z in range(grid_resolution):
			_visited_grid[x][z] = false


## `runaway` has paved the field: there is no unvisited cell left to explore, and
## that is the point of the value, not decoration on it.
func _fill_visited_grid() -> void:
	for x in range(grid_resolution):
		for z in range(grid_resolution):
			_visited_grid[x][z] = true


func _create_creature_mesh() -> void:
	_creature_mesh = SphereMesh.new()
	_creature_mesh.radius = 0.03
	_creature_mesh.height = 0.06
	_creature_mesh.radial_segments = 8
	_creature_mesh.rings = 4


func _create_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = _creature_mesh
	_multimesh.instance_count = max_population

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.multimesh = _multimesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = emissive
	mat.emission_energy_multiplier = 0.3
	_multimesh_instance.material_override = mat
	_track(_multimesh_instance)

	# Hide all instances initially
	for i in range(max_population):
		var xf := Transform3D.IDENTITY
		xf.origin = Vector3(0, -100, 0)  # Off-screen
		_multimesh.set_instance_transform(i, xf)
		_multimesh.set_instance_color(i, Color.TRANSPARENT)


# ------------------------------------------------------------------
# Population — the axis lives here
# ------------------------------------------------------------------

func _spawn_population() -> void:
	match selection:
		"uniform":
			_spawn_uniform()
		"culled":
			_spawn_culled()
		"runaway":
			_spawn_runaway()
		"split":
			_spawn_split()
		_:
			_spawn_initial_population()


## The shipped population, unchanged: 30 bodies of random hue, random radius in
## the 0.02-0.05 m band, random speed, scattered over the middle 80% of the
## plane. Drawn from the same fixed seed as before this pass.
func _spawn_initial_population() -> void:
	for i in range(initial_population):
		_spawn_creature(
			Vector3(
				_rng.randf_range(-world_size * 0.4, world_size * 0.4),
				BODY_Y,
				_rng.randf_range(-world_size * 0.4, world_size * 0.4)
			),
			Color(_rng.randf_range(0.3, 1.0), _rng.randf_range(0.3, 1.0), _rng.randf_range(0.3, 1.0)),
			_rng.randf_range(0.02, 0.05),  # size
			_rng.randf_range(0.1, 0.4),     # speed
			START_ENERGY  # starting energy
		)


## One reward, run to completion. Same count and same field as drift, laid out on
## an even grid at one radius in one hue: the variety is what the goal spent.
func _spawn_uniform() -> void:
	var count: int = maxi(1, initial_population)
	var cols: int = maxi(1, int(ceil(sqrt(float(count)))))
	var rows: int = int(ceil(float(count) / float(cols)))
	var pitch: float = (world_size * 0.8) / float(maxi(1, maxi(cols - 1, rows - 1)))
	var spots: Array = _grid_positions(count, cols, pitch, 0.0)
	for p in spots:
		_spawn_creature(p, UNIFORM_HUE, UNIFORM_RADIUS, 0.0, START_ENERGY)


## A goal was imposed. Six survivors of one hue, 0.6 m apart on an otherwise bare
## plane; the remaining MultiMesh instances stay parked off-screen, which is 95%
## of a 120-instance buffer showing nothing.
func _spawn_culled() -> void:
	var spots: Array = _grid_positions(CULLED_COUNT, CULLED_COLS, CULLED_PITCH, 0.0)
	for p in spots:
		_spawn_creature(p, CULLED_HUE, CULLED_RADIUS, 0.0, START_ENERGY)
	# The nameplate must not lie about a cull. _spawn_creature counted six births;
	# the honest reading is that the field started at initial_population and the
	# imposed goal removed the difference.
	_total_born = maxi(initial_population, CULLED_COUNT)
	_total_died = _total_born - CULLED_COUNT


## The ceiling. Every instance the MultiMesh owns is a body, all at the top of the
## size band, at a pitch narrower than their own diameter plus a gap — the plane
## is paved and the visited grid is full.
func _spawn_runaway() -> void:
	var count: int = maxi(1, max_population)
	var cols: int = mini(RUNAWAY_COLS, count)
	var rows: int = int(ceil(float(count) / float(cols)))
	var pitch: float = minf(RUNAWAY_PITCH, (world_size * 0.9) / float(maxi(1, maxi(cols - 1, rows - 1))))
	var spots: Array = _grid_positions(count, cols, pitch, 0.0)
	for p in spots:
		_spawn_creature(p, RUNAWAY_HUE, RUNAWAY_RADIUS, 0.0, START_ENERGY)
	_fill_visited_grid()


## Ambiguous pressure, two answers. Fifteen small blue bodies on -x, fifteen large
## red bodies on +x, and nothing at all in the corridor between them.
func _spawn_split() -> void:
	var left: Array = _grid_positions(SPLIT_PER_CLUSTER, SPLIT_COLS, SPLIT_PITCH, -SPLIT_CENTRE_X)
	for p in left:
		_spawn_creature(p, SPLIT_SMALL_HUE, SPLIT_SMALL_RADIUS, 0.0, START_ENERGY)
	var right: Array = _grid_positions(SPLIT_PER_CLUSTER, SPLIT_COLS, SPLIT_PITCH, SPLIT_CENTRE_X)
	for p in right:
		_spawn_creature(p, SPLIT_LARGE_HUE, SPLIT_LARGE_RADIUS, 0.0, START_ENERGY)


## Row-major grid of `count` slots, `cols` wide, centred on (x_center, 0) in the
## plane and always seated at BODY_Y. No RNG: these layouts are the evidence.
func _grid_positions(count: int, cols: int, pitch: float, x_center: float) -> Array:
	var c: int = maxi(1, cols)
	var rows: int = int(ceil(float(maxi(1, count)) / float(c)))
	var x0: float = x_center - float(c - 1) * pitch * 0.5
	var z0: float = -float(rows - 1) * pitch * 0.5
	var out: Array = []
	for i in range(count):
		var idx: int = i
		var row: int = idx / c
		var col: int = idx % c
		out.append(Vector3(x0 + float(col) * pitch, BODY_Y, z0 + float(row) * pitch))
	return out


func _spawn_creature(pos: Vector3, col: Color, creature_size: float, speed: float, energy: float) -> void:
	if _creatures.size() >= max_population:
		return
	var creature := {
		"position": pos,
		"color": col,
		"size": creature_size,
		"speed": speed,
		"energy": energy,
		"direction": Vector3(
			_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)
		).normalized(),
		"age": 0.0,
		"generation": _generation_count
	}
	_creatures.append(creature)
	_total_born += 1


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

## Three Label3D, one parent, one column at x = 0, gaps of 0.08 m — well inside
## the 0.16 m the framer merges on. That is deliberate: LabelFramer turns the
## stack into ONE opaque anthracite nameplate roughly 0.5 x 0.25 m centred near
## (0, 0.63, 0), and the middle line of that nameplate is the artifact's thesis.
##
## The tallest body tops out at y = 0.08 m (a 0.05 m radius seated at 0.03 m), so
## the plate floats 0.46 m clear of it and frontal crossing is 0 at every value,
## runaway's paved field included. Nothing is authored ON a surface here, so all
## three stay billboarded and let the framer do its job.
func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Non-Teleological Evolution"
	_title_label.font_size = 20
	_title_label.modulate = Color(0.9, 0.85, 0.7)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 0.7, 0)
	_title_label.pixel_size = 0.001
	_track(_title_label)

	_no_fitness_label = Label3D.new()
	_no_fitness_label.text = "No fitness function. No goal. Just drift."
	_no_fitness_label.font_size = 14
	_no_fitness_label.modulate = Color(0.7, 0.6, 0.5, 0.8)
	_no_fitness_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_no_fitness_label.position = Vector3(0, 0.62, 0)
	_no_fitness_label.pixel_size = 0.001
	_track(_no_fitness_label)

	_stats_label = Label3D.new()
	_stats_label.text = ""
	_stats_label.font_size = 14
	_stats_label.modulate = Color(0.8, 0.8, 0.75)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 0.54, 0)
	_stats_label.pixel_size = 0.001
	_track(_stats_label)


func _create_ground_plane() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(world_size, world_size)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.09, 0.1)
	mat.metallic = 0.3
	mat.roughness = 0.8
	mi.material_override = mat
	_track(mi)


# ------------------------------------------------------------------
# GRID CONFIG INTEGRATION
# ------------------------------------------------------------------

## GridInteractablesComponent calls this via call_deferred, after _ready() and
## first in the deferred queue — so the artifact is already built and this either
## changes nothing or rebuilds it in place, synchronously.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_selection: String = selection

	if config_data.has("selection"):
		selection = _pick_axis(str(config_data["selection"]), SELECTIONS, selection)

	# Non-geometry key, applied IN PLACE and BEFORE the early returns. The
	# curation station's {"emissive": false} carries no axis key, so it must fall
	# through the return below having still done exactly what it says.
	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
		if _multimesh_instance != null:
			var mat: StandardMaterial3D = _multimesh_instance.material_override as StandardMaterial3D
			if mat != null:
				mat.emission_enabled = emissive

	if not _built:
		return
	if selection == before_selection:
		return

	_rebuild_now()
	print("[NonTeleologicalEvolution] Config applied - selection=%s" % [selection])


## Accept an axis value only if it names something we actually build. A typo has
## to land on the shipped look, not on a half-recognised state.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ------------------------------------------------------------------
# Simulation loop — `drift` only; the other four values are finished states
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	_time_elapsed += delta

	# Update each creature
	var to_remove: Array[int] = []
	var to_spawn: Array = []

	for i in range(_creatures.size()):
		var c = _creatures[i]

		# Move
		c["age"] += delta
		var wander_angle := _rng.randf_range(-0.5, 0.5)
		var dir: Vector3 = c["direction"]
		dir = dir.rotated(Vector3.UP, wander_angle).normalized()
		c["direction"] = dir
		c["position"] += dir * c["speed"] * delta

		# Wrap around world
		var p: Vector3 = c["position"]
		var half := world_size * 0.5
		if p.x > half: p.x = -half
		if p.x < -half: p.x = half
		if p.z > half: p.z = -half
		if p.z < -half: p.z = half
		c["position"] = p

		# Check visited grid — gain energy from exploration
		var gx := int((p.x + half) / world_size * grid_resolution)
		var gz := int((p.z + half) / world_size * grid_resolution)
		gx = clampi(gx, 0, grid_resolution - 1)
		gz = clampi(gz, 0, grid_resolution - 1)
		if not _visited_grid[gx][gz]:
			_visited_grid[gx][gz] = true
			c["energy"] += energy_from_exploration

		# Lose energy by existing
		c["energy"] -= energy_decay * delta

		# Die if no energy
		if c["energy"] <= 0:
			to_remove.append(i)
			_total_died += 1
			continue

		# Reproduce if enough energy
		if c["energy"] > reproduction_threshold and _creatures.size() + to_spawn.size() < max_population:
			c["energy"] *= 0.5  # Split energy
			var child_color := Color(
				clampf(c["color"].r + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0),
				clampf(c["color"].g + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0),
				clampf(c["color"].b + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0)
			)
			var child_size := clampf(
				c["size"] + _rng.randf_range(-0.005, 0.005), 0.01, 0.08
			)
			var child_speed := clampf(
				c["speed"] + _rng.randf_range(-0.05, 0.05), 0.05, 0.6
			)
			to_spawn.append({
				"pos": c["position"] + Vector3(_rng.randf_range(-0.05, 0.05), 0, _rng.randf_range(-0.05, 0.05)),
				"color": child_color,
				"size": child_size,
				"speed": child_speed,
				"energy": c["energy"]
			})
			_generation_count += 1

	# Remove dead creatures (reverse order)
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		_creatures.remove_at(idx)

	# Spawn children
	for child_data in to_spawn:
		_spawn_creature(
			child_data["pos"], child_data["color"],
			child_data["size"], child_data["speed"], child_data["energy"]
		)

	# Slowly regenerate visited grid (areas become explorable again)
	if Engine.get_frames_drawn() % 120 == 0:
		var rx := _rng.randi_range(0, grid_resolution - 1)
		var rz := _rng.randi_range(0, grid_resolution - 1)
		_visited_grid[rx][rz] = false

	# Update visuals
	_update_multimesh()
	_update_stats()


func _update_multimesh() -> void:
	if _multimesh == null:
		return
	for i in range(max_population):
		if i < _creatures.size():
			var c = _creatures[i]
			var xf := Transform3D.IDENTITY
			var s: float = c["size"] / 0.03  # Normalize to base mesh size
			xf = xf.scaled(Vector3(s, s, s))
			xf.origin = c["position"]
			_multimesh.set_instance_transform(i, xf)
			var col: Color = c["color"]
			col.a = clampf(c["energy"] / reproduction_threshold, 0.3, 1.0)
			_multimesh.set_instance_color(i, col)
		else:
			var xf := Transform3D.IDENTITY
			xf.origin = Vector3(0, -100, 0)
			_multimesh.set_instance_transform(i, xf)
			_multimesh.set_instance_color(i, Color.TRANSPARENT)


func _update_stats() -> void:
	if _stats_label == null:
		return
	# Count unique "species" by color clustering (rough hue binning)
	var hue_bins: Dictionary = {}
	for c in _creatures:
		var hue_bin := int(c["color"].h * 12)
		hue_bins[hue_bin] = hue_bins.get(hue_bin, 0) + 1
	var diversity := hue_bins.size()
	if diversity > _max_species_diversity:
		_max_species_diversity = diversity

	_stats_label.text = "Pop: %d  |  Diversity: %d  |  Born: %d  |  Died: %d  |  Gen: %d" % [
		_creatures.size(), diversity, _total_born, _total_died, _generation_count
	]
