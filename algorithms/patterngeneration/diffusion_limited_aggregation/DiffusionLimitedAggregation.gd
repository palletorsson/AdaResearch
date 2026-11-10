# @identity
# essence: a Brownian-motion crystal that grows one sticking particle at a time — random walkers launched from a circle drift inward and freeze the moment they touch the aggregate, building a fractal dendrite in real time
# desire: to make visible the invisible physics beneath frost on glass, lightning paths, mineral veins, and river deltas — these shapes are all frozen random walks; DLA is the proof
# critical_parameter: stickiness (1.0) — the chance a walker freezes on first touch; at 1 the arms screen their own interior and the cluster is a dendrite of dimension ~1.71, lower values let walkers slip into the fjords and the crystal thickens toward a blob
# triggers: one walker at a time is launched just outside the cluster, strides on circles while it is far away and takes unit steps near it, and freezes on touch; growth paced by grow_per_second and a per-frame step budget
# emerges: branching structure self-organizes from purely local decisions — no particle knows the global shape it is building; the fractal arm is the aggregate's own shadow blocking new growth
# needs: VR interaction to add particles manually [missing]; speed control slider [missing]
# relationships: placed in PatternGeneration_Diffusion_Limited_Aggregation_DLA; conceptually pairs with reaction_diffusion (both are Turing-class morphogenesis); DLA is the dry limit of Laplacian growth — same equation, no chemistry
# truth: the fractal was always there — a random walk in two dimensions will eventually touch any convex seed, and the branching arm it builds is a literal drawing of probability space
#
# REBUILT 2026-11-10 (improvement pass). The old work launched walkers on a 6 m circle that took one 0.1 m step a
# FRAME, so a walker needed thousands of frames to arrive and ~90 % escaped past 8 m first: the crystal grew about one
# particle a minute and stood as a seed and a few yellow specks (a pink dot in the tower, floors 121-122), beside two
# bar indicators 8 m out that made the fit pass shrink it to 0.4 and lift it 2.7 m. Now the textbook method: launch just
# outside the cluster, stride on circles while far, unit steps near, freeze on touch (a spatial grid answers "touching?"
# in nine cells). The cluster grows on a dark glass disc - particles as one MultiMesh, the contact that froze each one as
# a second (the arm reads as an arm) - coloured from the first arrivals (gold) to the newest (pale blue), with the last
# walker's final steps left as a faint trail and N and the measured mass-radius dimension under it.

extends Node3D

@export_group("Growth")
@export_range(0.0, 1.0) var stickiness := 1.0          ## chance to freeze on first touch (1 = DLA dendrite)
@export var max_points := 1800                          ## the crystal restarts after this many (or when it fills the disc)
@export var grow_per_second := 30.0                     ## particles frozen per second at most
@export var steps_per_frame := 300                      ## walker steps a frame may spend (the frame cost bound)
@export var hold_seconds := 8.0                         ## the finished crystal stays this long, then a new seed
@export var prewarm_points := 0                         ## grow this many at once on start (captures)
@export var seed_value := 0                             ## 0 = a new crystal every time
@export_group("Size")
@export var particle_radius := 0.016                    ## metres
@export var plate_radius := 1.25                        ## metres; the disc stands with its centre at plate_radius + 0.2

const KILL_MARGIN := 60.0   # cluster units beyond the cluster where a lost walker is launched again
const FAR := 8.0            # beyond rmax + FAR a walker strides on circles

var rng := RandomNumberGenerator.new()
var aggregate_points := PackedVector2Array()   # cluster units: a particle has radius 1
var _parent := PackedInt32Array()
var _r2 := PackedFloat32Array()              # squared distance of each particle from the seed
var _head := PackedInt32Array()                # dense grid of 2-unit cells: first particle in the cell, -1 none
var _next := PackedInt32Array()                # the next particle in the same cell
var _near := PackedByteArray()                 # 1 where a cell or one of its eight neighbours holds a particle
var _half := 0                                 # cells from the seed to the grid's edge
var _rmax := 0.0
var _walker := Vector2.ZERO
var _walking := false
var _trail := PackedVector2Array()
var _owed := 0.0
var _hold := 0.0
var time := 0.0

var _plate: Node3D
var _dots: MultiMeshInstance3D
var _bonds: MultiMeshInstance3D
var _steps: MultiMeshInstance3D
var _readout: Label3D
var _readout_age := 0.0

func _ready() -> void:
	if seed_value != 0: rng.seed = seed_value
	else: rng.randomize()
	_build()
	initialize_dla()
	if prewarm_points > 0:
		_grow(prewarm_points, 1 << 30)
		_trail.clear()
		_update_readout()

# --- the stand ---------------------------------------------------------------------------------------------------------

func _unit() -> float:
	return particle_radius   # metres per cluster unit

func _build() -> void:
	for old in ["Seed", "ParticleCount", "StructureSize", "AggregateStructure", "WalkingParticles"]:
		var n := get_node_or_null(old)
		if n: n.queue_free()
	var centre_y := plate_radius + 0.2
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.05, 0.06, 0.08); dark.roughness = 0.35; dark.metallic = 0.2
	var rim := StandardMaterial3D.new(); rim.albedo_color = Color(0.32, 0.34, 0.38); rim.roughness = 0.5
	var foot := MeshInstance3D.new(); var fm := CylinderMesh.new(); fm.top_radius = 0.28; fm.bottom_radius = 0.32; fm.height = 0.05
	foot.mesh = fm; foot.material_override = rim; foot.position = Vector3(0, 0.025, -0.06); add_child(foot)
	var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.035; pm.bottom_radius = 0.035; pm.height = centre_y
	post.mesh = pm; post.material_override = rim; post.position = Vector3(0, centre_y * 0.5, -0.06); add_child(post)
	_plate = Node3D.new(); _plate.name = "Plate"; _plate.position = Vector3(0, centre_y, 0); add_child(_plate)
	var back := MeshInstance3D.new(); var bm := CylinderMesh.new(); bm.top_radius = plate_radius + 0.04; bm.bottom_radius = plate_radius + 0.04; bm.height = 0.03
	bm.radial_segments = 96; back.mesh = bm; back.material_override = rim; back.rotation.x = PI / 2; back.position.z = -0.035; _plate.add_child(back)
	var glass := MeshInstance3D.new(); var gm := CylinderMesh.new(); gm.top_radius = plate_radius; gm.bottom_radius = plate_radius; gm.height = 0.02
	gm.radial_segments = 96; glass.mesh = gm; glass.material_override = dark; glass.rotation.x = PI / 2; glass.position.z = -0.02; _plate.add_child(glass)

	var lit := StandardMaterial3D.new(); lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; lit.vertex_color_use_as_albedo = true
	var sphere := SphereMesh.new(); sphere.radius = 1.0; sphere.height = 2.0; sphere.radial_segments = 10; sphere.rings = 5
	_dots = MultiMeshInstance3D.new(); _dots.name = "Crystal"
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = sphere
	mm.instance_count = max_points + 1; mm.visible_instance_count = 0
	_dots.multimesh = mm; _dots.material_override = lit; _plate.add_child(_dots)
	var rod := CylinderMesh.new(); rod.top_radius = 1.0; rod.bottom_radius = 1.0; rod.height = 1.0; rod.radial_segments = 6; rod.rings = 0
	_bonds = MultiMeshInstance3D.new(); _bonds.name = "Contacts"
	var bm2 := MultiMesh.new(); bm2.transform_format = MultiMesh.TRANSFORM_3D; bm2.use_colors = true; bm2.mesh = rod
	bm2.instance_count = max_points + 1; bm2.visible_instance_count = 0
	_bonds.multimesh = bm2; _bonds.material_override = lit; _plate.add_child(_bonds)
	var nothing := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)   # unused slots measure as nothing
	for i in mm.instance_count:
		mm.set_instance_transform(i, nothing); bm2.set_instance_transform(i, nothing)
	# the extent the capture and the fit measure: the disc, not the first few particles
	_dots.custom_aabb = AABB(Vector3(-plate_radius, -plate_radius, -0.05), Vector3(plate_radius * 2, plate_radius * 2, 0.1))
	_bonds.custom_aabb = _dots.custom_aabb

	var faint := StandardMaterial3D.new(); faint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; faint.vertex_color_use_as_albedo = true
	faint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var dot := SphereMesh.new(); dot.radius = 1.0; dot.height = 2.0; dot.radial_segments = 6; dot.rings = 3
	_steps = MultiMeshInstance3D.new(); _steps.name = "LastWalk"   # the final steps of the walker that froze last
	var sm := MultiMesh.new(); sm.transform_format = MultiMesh.TRANSFORM_3D; sm.use_colors = true; sm.mesh = dot
	sm.instance_count = 220; sm.visible_instance_count = 0
	_steps.multimesh = sm; _steps.material_override = faint; _steps.custom_aabb = _dots.custom_aabb; _plate.add_child(_steps)

	var title := Label3D.new(); title.text = "each walker wanders until it touches the crystal - then it freezes"
	title.font_size = 40; title.pixel_size = 0.003; title.outline_size = 8; title.modulate = Color(0.92, 0.92, 0.95)
	title.position = Vector3(0, plate_radius + 0.14, 0); _plate.add_child(title)
	_readout = Label3D.new(); _readout.font_size = 34; _readout.pixel_size = 0.003; _readout.outline_size = 8
	_readout.modulate = Color(0.85, 0.9, 1.0); _readout.position = Vector3(0, -plate_radius - 0.12, 0); _plate.add_child(_readout)

# --- the crystal -------------------------------------------------------------------------------------------------------

## Arrival order as colour, gold to blue, scaled to the crystal the disc can hold: N ~ 0.55 (R/a)^1.65 for an
## off-lattice cluster of reach R (measured here: ~600 particles fill a 1.25 m disc of 16 mm particles).
func _color(i: int) -> Color:
	var fill := minf(float(max_points), 0.55 * pow(plate_radius / _unit(), 1.65))
	var t := clampf(float(i) / maxf(1.0, fill), 0.0, 1.0)
	return Color(1.0, 0.7, 0.25).lerp(Color(0.35, 0.78, 1.0), t)

func initialize_dla() -> void:
	aggregate_points.clear(); _parent.clear(); _r2.clear(); _next.clear(); _rmax = 0.0
	_half = int(ceil((plate_radius / _unit() + 12.0) * 0.5))
	var cells := (2 * _half + 1) * (2 * _half + 1)
	_head.resize(cells); _head.fill(-1); _near.resize(cells); _near.fill(0)
	_walking = false; _trail.clear(); _hold = 0.0; _owed = 0.0
	if _dots: _dots.multimesh.visible_instance_count = 0
	if _bonds: _bonds.multimesh.visible_instance_count = 0
	if _steps: _steps.multimesh.visible_instance_count = 0
	_add(Vector2.ZERO, -1)
	_update_readout()

func _add(p: Vector2, parent: int) -> void:
	var i := aggregate_points.size()
	aggregate_points.append(p); _parent.append(parent); _r2.append(p.length_squared())
	var cx := int(floor(p.x * 0.5)) + _half; var cy := int(floor(p.y * 0.5)) + _half
	var side := 2 * _half + 1
	var c0 := cy * side + cx
	_next.append(_head[c0]); _head[c0] = i
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx := cx + dx; var ny := cy + dy
			if nx >= 0 and ny >= 0 and nx < side and ny < side: _near[ny * side + nx] = 1
	_rmax = maxf(_rmax, p.length() + 1.0)
	var u := _unit()
	var c := _color(i)
	var mm := _dots.multimesh
	mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * u), Vector3(p.x * u, p.y * u, 0.0)))
	mm.set_instance_color(i, Color(1, 1, 1) if i > 0 else Color(1.0, 0.55, 0.15))
	if i > 0: mm.set_instance_color(i - 1, _color(i - 1) if i - 1 > 0 else Color(1.0, 0.55, 0.15))
	mm.visible_instance_count = i + 1
	if parent >= 0:
		var a := aggregate_points[parent] * u; var b := p * u
		var d := Vector3(b.x - a.x, b.y - a.y, 0.0)
		var y_axis := d                                            # unit cylinder: height 1 along Y
		var x_axis := Vector3(-d.y, d.x, 0.0).normalized() * (u * 0.42)
		var z_axis := Vector3(0, 0, u * 0.42)
		var bonds := _bonds.multimesh
		bonds.set_instance_transform(i, Transform3D(Basis(x_axis, y_axis, z_axis), Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)))
		bonds.set_instance_color(i, c)
		bonds.visible_instance_count = i + 1
	else:
		_bonds.multimesh.set_instance_transform(0, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))

func _touching(p: Vector2) -> int:
	var side := 2 * _half + 1
	var cx := int(floor(p.x * 0.5)) + _half; var cy := int(floor(p.y * 0.5)) + _half
	if cx < 1 or cy < 1 or cx >= side - 1 or cy >= side - 1 or _near[cy * side + cx] == 0: return -1
	for dy in range(-1, 2):
		var row := (cy + dy) * side
		for dx in range(-1, 2):
			var j := _head[row + cx + dx]
			while j >= 0:
				if p.distance_squared_to(aggregate_points[j]) < 4.0: return j
				j = _next[j]
	return -1

func _launch() -> void:
	var a := rng.randf() * TAU
	_walker = Vector2(cos(a), sin(a)) * (_rmax + 5.0)
	_walking = true; _trail.clear()

## Spend up to `budget` steps; freeze up to `want` walkers. Returns how many froze.
func _grow(want: int, budget: int) -> int:
	var frozen := 0
	var full_r := plate_radius / _unit() - 3.0
	while frozen < want and budget > 0:
		if aggregate_points.size() > max_points or _rmax >= full_r: break
		if not _walking: _launch()
		budget -= 1
		var d := _walker.length()
		if d > _rmax + KILL_MARGIN:
			_launch(); continue
		if d > _rmax + FAR:   # far: a circle of this radius cannot touch the cluster - stride across it
			var a := rng.randf() * TAU
			_walker += Vector2(cos(a), sin(a)) * (d - _rmax - 2.0)
			_trail.clear(); continue
		var s := rng.randf() * TAU
		_walker += Vector2(cos(s), sin(s))
		_trail.append(_walker)
		if _trail.size() > 220: _trail = _trail.slice(_trail.size() - 160)
		if _walker.length() > _rmax + 1.0: continue
		var j := _touching(_walker)
		if j < 0: continue
		if stickiness < 1.0 and rng.randf() > stickiness:
			_walker = aggregate_points[j] + (_walker - aggregate_points[j]).normalized() * 2.2; continue
		var q := aggregate_points[j]
		_add(q + (_walker - q).normalized() * 2.0, j)
		_walking = false; frozen += 1
	return frozen

func _draw_trail() -> void:
	var u := _unit()
	var sm := _steps.multimesh
	var n := mini(_trail.size(), sm.instance_count)
	var from := _trail.size() - n
	var b := Basis().scaled(Vector3.ONE * u * 0.42)
	for i in n:
		var q := _trail[from + i]
		sm.set_instance_transform(i, Transform3D(b, Vector3(q.x * u, q.y * u, 0.006)))
		sm.set_instance_color(i, Color(1, 1, 1, 0.12 + 0.7 * float(i) / n))
	sm.visible_instance_count = n

func _process(delta: float) -> void:
	time += delta
	var full := aggregate_points.size() > max_points or _rmax >= plate_radius / _unit() - 3.0
	if full:
		_hold += delta
		if _hold > hold_seconds: initialize_dla()
		return
	_owed = minf(_owed + grow_per_second * delta, 3.0)
	var want := int(_owed)
	if want > 0:
		var got := _grow(want, steps_per_frame)
		_owed -= got
		if got > 0: _draw_trail()
	_readout_age += delta
	if _readout_age > 0.5:
		_readout_age = 0.0; _update_readout()

# --- what it measures --------------------------------------------------------------------------------------------------

func _update_readout() -> void:
	if _readout == null: return
	var n := aggregate_points.size()
	if n < 40:
		_readout.text = "N = %d" % n
	else:
		_readout.text = "N = %d     mass-radius dimension D = %.2f     (DLA in the plane: 1.71)" % [n, estimate_fractal_dimension()]

func get_dla_info() -> Dictionary:
	return {
		"aggregate_size": aggregate_points.size(),
		"walking_particles": 1 if _walking else 0,
		"max_radius": _rmax * _unit(),
		"fractal_dimension": estimate_fractal_dimension()
	}

## The mass-radius dimension: the slope of log N(r) against log r, N(r) the particles within r of the seed, over the
## inner part of the crystal (r from 5 radii to 70 % of its reach, where the growth front no longer thins the count).
func estimate_fractal_dimension() -> float:
	var n := aggregate_points.size()
	if n < 40 or _rmax < 12.0: return 1.0
	var sx := 0.0; var sy := 0.0; var sxx := 0.0; var sxy := 0.0; var m := 0
	var sorted := _r2.duplicate(); sorted.sort()
	var r := 5.0
	while r < _rmax * 0.7:
		var count := sorted.bsearch(r * r, false)   # particles within r
		var x := log(r); var y := log(float(max(count, 1)))
		sx += x; sy += y; sxx += x * x; sxy += x * y; m += 1
		r *= 1.25
	if m < 3: return 1.0
	return (m * sxy - sx * sy) / (m * sxx - sx * sx)

func apply_grid_config(config: Dictionary) -> void:
	if config.has("stickiness"): stickiness = clampf(float(str(config["stickiness"])), 0.0, 1.0)
	if config.has("grow_per_second"): grow_per_second = float(str(config["grow_per_second"]))
	if config.has("prewarm_points") and aggregate_points.size() <= 1:
		_grow(int(str(config["prewarm_points"])), 1 << 30); _trail.clear(); _update_readout()
