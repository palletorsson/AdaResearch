# composition_twins.gd
# A worktable of small primitives on the bridge, and the SAME primitives ten
# times bigger standing on the floor of the pool below. Move a small one and the
# big one moves with it — same relative place, same rotation, ten times the
# offset and ten times the size.

# @identity
# essence: a table on a bridge holds three primitives you can pick up; four metres down, on the floor of the pool, the same three stand at ten times the size and follow the hand exactly — the table is a control surface and the pool is its consequence
# desire: to make scale a RELATION rather than a property — to be the one place in the project where a thing you can hold and a thing you cannot are the same object seen at two sizes
# critical_parameter: twin_scale x offset_scale — the similarity that binds the two worlds; at 10 a 24 cm shove on the table is a 2.4 m walk in the pool
# triggers: _ready builds bench + leads + twins; _process polls each lead's local transform and re-places its twin (there is no grab signal on desktop — see the note at _process); apply_grid_config rebuilds only on a changed signature
# emerges: the pool floor IS the table top, ten times over — the reach clamp guarantees a twin can never leave the basin, so the bounded control volume and the pool are one shape at two scales
# relationships: stands over a map_info.museum.basin (depth 4, glass true, fire off); the flat sibling of the plinth's one-thing-enshrined; wears station_bench as its surface, the first placement that bench has ever had
# truth: a scale is not a number on an object, it is a relation between two of them; you cannot feel ten times bigger until you are holding the smaller one

extends Node3D

class_name CompositionTwins

const PBR := preload("res://commons/render/pbr_kit.gd")
## The table. station_bench is grid-modular, its top sits EXACTLY at top_height
## (station_bench.gd:97) and it carries a box collider over its own volume, so a
## body let go above it lands on it. Measured 2.0 x 0.92 x 1.01 m, and until this
## artifact it had zero placements in 2049 maps.
const BENCH := preload("res://commons/artifacts/station/station_bench.tscn")
## The addon scene, not a hand-rolled RigidBody3D: collision_layer 4 (= layer 3),
## collision_mask 196615 and freeze_mode 1 all come from here already, and layer 3
## is the one layer BOTH hands can reach (desktop carry masks 3/18/19, the VR
## pickup area masks 3/17/19).
const PICKABLE := preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const GRAB_POINT_FMT := "res://addons/godot-xr-tools/objects/grab_points/grab_point_hand_%s.tscn"

## The vocabulary. Each one is authored to fill the same body_m cube so the set
## reads as a set — a family of solids at one size, not a jumble.
const SHAPES: Array[String] = ["cube", "sphere", "cone", "cylinder", "wedge", "torus", "tetra"]
const MAX_OBJECTS: int = 6
## The leader's cross-section. A tether can run 8 m from a small object to its
## twin's top, and 12 mm of radius is 24 mm across — one clear line at that
## distance, and thin enough not to become a bar in the middle of the room.
const TETHER_R: float = 0.012
## The glass lid is a 0.06 m slab centred at y = -0.03 (endless_museum.gd:6039),
## so its underside is -0.06. Twins stop 0.12 m below zero, which leaves 6 cm of
## water between the highest lift and the glass.
const LID_CLEAR: float = 0.12

@export_group("The set")
## How many primitives on the table. Three reads as a composition; six needs a
## pool wide enough for six ten-times bodies, and _build says so if it is not.
@export var object_count: int = 3
## Comma-separated, from SHAPES. Unknown names are dropped; an empty result
## falls back to one cube rather than to an empty table.
@export var primitives: String = "cube,sphere,cone"
## The small body, across. 0.16 m is the smallest thing a hand reliably catches
## in this corpus — grab_cube_show is the warning at the other end, a 0.1 m
## sphere collider under a 1 m cube mesh.
@export var body_m: float = 0.16
## FIVE VARIANTS MUST NOT BE FIVE OBJECTS. The only randomness here is the
## resting yaw of each piece, and it comes from this.
@export var layout_seed: int = 7

@export_group("The link")
## Ten times the SIZE.
@export var twin_scale: float = 10.0
## Ten times the OFFSET. Kept separate from twin_scale because they answer
## different questions — how big the consequence is, and how far it travels —
## and the resting base lands on the pool floor for any pair of values.
@export var offset_scale: float = 10.0
## The pool floor is at y = -basin_depth, which is exactly what the museum
## builds: the floor slab is drawn at centre -depth-0.1 with size 0.2, so its
## top is -depth (endless_museum.gd:6009). 0 means there is no pool under this
## token and the twins stand on the floor in front of the table instead.
@export var basin_depth: float = 0.0
## The basin's inside measure, across, in metres. This is what bounds the hand:
## the control bed is this divided by offset_scale, so nothing you can do to a
## small object can push its twin through a rim wall.
@export var pool_m: float = 7.0
## Where the pool is, relative to the table. Zero means straight down, which is
## the bridge-over-the-basin case. From a token: pool_offset:0,0,2.4
@export var pool_offset: Vector3 = Vector3.ZERO
## How the pair is MARKED. none — you have to notice; line — a lit leader from
## each small body to its twin's top; halo — a bright ring on the pool floor
## around each twin. (A promotion candidate, deliberately not declared as a
## dna axis until a sweep has measured whether it bites.)
@export var tether: String = "line"

@export_group("The table")
@export var table_cells: int = 2
@export var table_depth_cells: int = 1
## The bench's top surface, and the zero of every measurement in this file.
@export var table_height: float = 0.92
## How high above the table a small object may be lifted. With reach_fit on and
## a basin declared this is derived instead — see _build.
@export var reach_m: float = 0.22
## Derive reach_m from the basin so the biggest lift stops under the glass.
@export var reach_fit: bool = true
## Hold each small object inside the control bed, re-asserted every frame.
@export var clamp_reach: bool = true

@export_group("Colour")
@export var hue_start: float = 0.03
@export var hue_span: float = 0.58
## The twins get their own lamp. Nothing in the museum lights a basin — see the
## note at _add_pool_key.
@export var pool_light: bool = true

# Resolved in _build and read by the frame loop. Held as plain members rather
# than re-clamped per frame because _process touches every one of them.
var _leads: Array[Node3D] = []
var _twins: Array[Node3D] = []
var _tethers: Array[MeshInstance3D] = []
var _last: Array[Transform3D] = []
var _heights: Array[float] = []
var _owned: Array[Node] = []
var _table_anchor: Vector3 = Vector3(0.0, 0.92, 0.0)
var _pool_anchor: Vector3 = Vector3.ZERO
var _twin_s: float = 10.0
var _off_s: float = 10.0
var _bed_x: float = 0.27
var _bed_z: float = 0.27
var _reach: float = 0.22
var _built: bool = false
var _built_sig: String = ""


func _ready() -> void:
	# AFTER THE HANDS. The desktop pointer writes a carried object's
	# global_position in _process (DesktopInteractionPointer.gd, lerp 0.4 per
	# frame); the VR grab driver is a RemoteTransform3D and writes it in
	# _physics_process. Following in _process at a positive priority means the
	# twin reads the position the hand just wrote, in the same frame, whatever
	# order the tree happens to be in — and the museum stamps artifacts long
	# after the Walker that carries the pointer.
	process_priority = 10
	_read_metadata_overrides()
	_build()


## Grid system integration.
##
## THE TWO CALL TIMES. The museum calls this DIRECTLY, outside the tree, BEFORE
## _ready (endless_museum.gd:9718); the grid calls it deferred, AFTER _ready
## (GridInteractablesComponent.gd:1795). So it has to be safe with nothing built
## yet, and it must not rebuild for a config that says the same thing — a
## rebuild during a grab would free the XRTools grab driver out from under a hand.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _signature() == _built_sig:
		return
	_build()


## Every numeric key here is a name already in GridInteractablesComponent's
## CONFIG_PARAM_NAMES list, and that is not cosmetic: a token `#key:12` whose key
## is NOT in that list is read as a tutorial shorthand — the artifact receives
## `true` and the map silently gains a 12 degree rotation. The descriptive names
## are accepted too, because the museum passes a plan config dict straight through
## and never goes near the token parser.
func _read_metadata_overrides() -> void:
	object_count = int(_cfg_num(["object_count", "count"], float(object_count)))
	twin_scale = _cfg_num(["twin_scale", "size"], twin_scale)
	offset_scale = _cfg_num(["offset_scale", "span"], offset_scale)
	basin_depth = _cfg_num(["basin_depth", "depth"], basin_depth)
	pool_m = _cfg_num(["pool_m", "width"], pool_m)
	body_m = _cfg_num(["body_m", "cube_size"], body_m)
	table_height = _cfg_num(["table_height", "height"], table_height)
	table_cells = int(_cfg_num(["table_cells", "columns"], float(table_cells)))
	table_depth_cells = int(_cfg_num(["table_depth_cells", "rows"], float(table_depth_cells)))
	reach_m = _cfg_num(["reach_m", "radius"], reach_m)
	layout_seed = int(_cfg_num(["layout_seed", "generation_seed"], float(layout_seed)))
	hue_start = _cfg_num(["hue_start"], hue_start)
	hue_span = _cfg_num(["hue_span"], hue_span)
	primitives = _cfg_str(["primitives", "shape"], primitives)
	tether = _cfg_str(["tether", "mode"], tether).strip_edges().to_lower()
	reach_fit = _cfg_bool(["reach_fit"], reach_fit)
	clamp_reach = _cfg_bool(["clamp_reach"], clamp_reach)
	pool_light = _cfg_bool(["pool_light"], pool_light)
	var po: Variant = _cfg_first(["pool_offset"])
	if po != null:
		# The museum coerces a plan value to the export's own type before it gets
		# here, so this arrives as a real Vector3; a map token arrives as the
		# string "0,0,2.4". Both are the same instruction.
		pool_offset = po if typeof(po) == TYPE_VECTOR3 else _parse_vec3(str(po), pool_offset)


func _cfg_first(keys: Array) -> Variant:
	for k in keys:
		if has_meta("config_%s" % str(k)):
			return get_meta("config_%s" % str(k))
	return null


func _cfg_num(keys: Array, current: float) -> float:
	var v: Variant = _cfg_first(keys)
	if v == null:
		return current
	if typeof(v) == TYPE_BOOL:
		# The shorthand trap fired: the key was not in CONFIG_PARAM_NAMES, the
		# number went into the token's rotation slot and only a flag arrived here.
		# Refusing it and naming the safe alias beats reading it as 1.0.
		push_warning("composition_twins: '%s' arrived as a flag, not a number — the map token used a key the grid reads as shorthand. Token-safe keys for this value: %s" % [str(keys[0]), str(keys)])
		return current
	return float(str(v))


func _cfg_str(keys: Array, current: String) -> String:
	var v: Variant = _cfg_first(keys)
	return current if v == null else str(v)


func _cfg_bool(keys: Array, current: bool) -> bool:
	var v: Variant = _cfg_first(keys)
	if v == null:
		return current
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["1", "true", "yes", "on"]


func _parse_vec3(raw: String, fallback: Vector3) -> Vector3:
	var parts: PackedStringArray = raw.split(",", false)
	if parts.size() < 3:
		return fallback
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


## What the built state depends on. Compared rather than trusted, so the grid's
## post-_ready call and the museum's pre-_ready call cannot build twice.
func _signature() -> String:
	return str([object_count, primitives, body_m, twin_scale, offset_scale,
		basin_depth, pool_m, pool_offset, tether, table_cells, table_depth_cells,
		table_height, reach_m, reach_fit, clamp_reach, layout_seed,
		hue_start, hue_span, pool_light])


## Free only what this artifact made. The XRTools grab driver parents itself as a
## SIBLING of the held pickable — an extra child of this node named
## <pickable>_driver — so a teardown that swept every child would free the driver
## mid-grab and drop whatever the hand was holding.
func _teardown() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()
	_leads.clear()
	_twins.clear()
	_tethers.clear()
	_last.clear()
	_heights.clear()
	set_process(false)


func _build() -> void:
	_teardown()
	_built = true
	_built_sig = _signature()

	var n: int = clampi(object_count, 1, MAX_OBJECTS)
	var m: float = clampf(body_m, 0.04, 0.5)
	_twin_s = clampf(twin_scale, 1.5, 40.0)
	_off_s = clampf(offset_scale, 1.0, 40.0)
	var big: float = m * _twin_s
	var depth: float = maxf(basin_depth, 0.0)
	var tw: float = float(maxi(table_cells, 1))
	var td: float = float(maxi(table_depth_cells, 1))
	_table_anchor = Vector3(0.0, maxf(table_height, 0.3), 0.0)

	# THE BED IS THE POOL, DIVIDED. Everything a hand can do to a small object
	# has to land inside the basin, so the control volume is the pool's own inside
	# measure carried back through the offset: a 7 m pool and a 1.6 m twin leave
	# (7.0 - 1.6) / 2 / 10 = 0.27 m of travel from the table's centre. The table
	# bounds it as well, because a body cannot rest past the edge of the bench.
	var bed: float = maxf((maxf(pool_m, big) - big) * 0.5 / _off_s, 0.02)
	_bed_x = maxf(minf(bed, tw * 0.5 - m * 0.5 - 0.05), 0.01)
	_bed_z = maxf(minf(bed, td * 0.5 - m * 0.5 - 0.05), 0.01)

	# The set is laid out along the bench's long axis at 1.5 body widths, or
	# tighter if the bed cannot hold that many at that spacing.
	var step: float = m * 1.5
	if n > 1:
		step = minf(step, _bed_x * 2.0 / float(n - 1))

	_reach = maxf(reach_m, 0.01)
	if reach_fit and depth > 0.01:
		# THE LID IS THE CEILING OF THE POOL. A 4 m basin and a 1.6 m twin allow
		# (4.0 - 1.6 - 0.12) / 10 = 0.228 m of lift on the table before the twin's
		# top would touch the glass.
		_reach = clampf((depth - big - LID_CLEAR) / _off_s, 0.01, 1.0)

	# WHERE THE POOL IS. Straight down is the bridge-over-the-basin case Palle
	# asked for. With no basin the anchor cannot stay under the table — the
	# ten-times bodies would be built THROUGH it — so they line up in front
	# instead, which is the only state the capture bench and the gallery ever see.
	var po: Vector3 = pool_offset
	if depth <= 0.01 and po.is_zero_approx():
		po = Vector3(0.0, 0.0, td * 0.5 + big * 0.75 + 0.4)
	_pool_anchor = po + Vector3(0.0, -depth, 0.0)

	_add_bench(tw, td)

	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var shapes: PackedStringArray = _shape_list()
	for i in range(n):
		var shape: String = shapes[i % shapes.size()]
		var col: Color = _hue(i, n)
		# ONE MATERIAL, TWO BODIES. The twin is not a model of the small object,
		# it IS the small object at another size, so it wears the same instance.
		# PbrKit triplanar is LOCAL (pbr_kit.gd:295), so the grain travels with
		# the mesh and the pair reads as one thing photographed twice, once close
		# and once far. The detail factor is the kit's own rule of thumb,
		# 1 / longest dimension: at 0.16 m that lands 5 repeats across the body.
		var mat: StandardMaterial3D = PBR.hard_plastic(col, 0.62, 0.05)
		PBR.scale_detail(mat, 1.0 / m)
		var mesh: Mesh = _mesh_for(shape, m)
		var ab: AABB = mesh.get_aabb()
		_heights.append(maxf(ab.size.y, 0.001))

		var lead: RigidBody3D = _make_lead(i, shape, mesh, mat, ab)
		var x: float = (float(i) - float(n - 1) * 0.5) * step
		# A small yaw so the row reads as arranged rather than machined, from the
		# seed so a re-capture is the same picture.
		lead.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(-0.22, 0.22)),
			Vector3(x, _table_anchor.y, 0.0))
		add_child(lead)
		_owned.append(lead)
		_leads.append(lead)
		_last.append(lead.transform)

		var twin: Node3D = _make_twin(i, mesh, mat, ab, col)
		add_child(twin)
		_owned.append(twin)
		_twins.append(twin)

		if tether == "line":
			var line: MeshInstance3D = _make_tether(i, col)
			add_child(line)
			_owned.append(line)
			_tethers.append(line)

		_place_twin(i, lead.transform)

	if pool_light:
		_add_pool_key(big, step * _off_s * float(n))

	set_process(true)
	print("[composition_twins] %d x %s | body %.3f m -> twin %.2f m | offset x%.0f | pool floor y=%.2f | lift %.3f m -> %.2f m"
		% [n, str(shapes), m, big, _off_s, _pool_anchor.y, _reach, _reach * _off_s])
	if n > 1 and step * _off_s < big * 1.02:
		var fits: int = int(float(maxf(pool_m, big)) / maxf(big, 0.01))
		push_warning("composition_twins: %d twins %.2f m across sit %.2f m apart and overlap. A %.1f m pool holds about %d at x%.0f — lower object_count, raise pool_m, or lower twin_scale."
			% [n, big, step * _off_s, pool_m, fits, _twin_s])
	if depth > 0.01 and big + LID_CLEAR > depth:
		push_warning("composition_twins: a %.2f m twin does not fit a %.2f m basin — it breaches the glass at rest. Raise museum.basin.depth or lower twin_scale."
			% [big, depth])


# ── THE TABLE ────────────────────────────────────────────────────────────────

func _add_bench(tw: float, td: float) -> void:
	var bench: Node3D = BENCH.instantiate()
	bench.name = "Bench"
	# BEFORE add_child. station_bench builds in _ready from its own properties,
	# so anything set afterwards leaves the old geometry standing — the same
	# ordering the museum's utility lane states at endless_museum.gd:5182.
	bench.set("length_cells", int(tw))
	bench.set("depth_cells", int(td))
	bench.set("top_height", _table_anchor.y)
	bench.set("drawers", false)
	bench.set("stencil_text", "COMPOSITION")
	# READ IT BACK. A typed set() with the wrong type is refused in SILENCE in
	# this engine, and a bench built at its default 0.92 under a table anchor of
	# 1.10 would leave every small object floating 18 cm with nothing logged.
	var got: float = float(bench.get("top_height"))
	if absf(got - _table_anchor.y) > 0.001:
		push_warning("composition_twins: bench top_height did not take (%.3f, wanted %.3f)" % [got, _table_anchor.y])
	add_child(bench)
	_owned.append(bench)


# ── THE PAIR ─────────────────────────────────────────────────────────────────

func _make_lead(i: int, shape: String, mesh: Mesh, mat: StandardMaterial3D, ab: AABB) -> RigidBody3D:
	var p: RigidBody3D = PICKABLE.instantiate()
	p.name = "Small%d_%s" % [i, shape]
	p.freeze = true                       # a table, not a physics toy
	p.set("release_mode", 1)              # FROZEN: it stays exactly where it is let go
	# The gravity gun rides the VR rig's right hand (base.tscn:155), masks layers
	# 1/2/3, and its _is_valid_target UNFREEZES a frozen body that has pick_up()
	# unless the body is in this group. Without it one stray ray sweeps the whole
	# table onto the floor.
	p.add_to_group("no_gravity_gun")

	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	mi.material_override = mat
	# ORIGIN AT THE BASE, not at the mesh centre. Every number in this file is a
	# delta from the resting place, so a flat torus and a cube have to rest at the
	# same value: with the base at the origin both rest at table_height and both
	# twins rest with their base exactly on the pool floor, for any scale pair.
	mi.position = Vector3(0.0, -ab.position.y, 0.0)
	p.add_child(mi)

	var cs: CollisionShape3D = p.get_node_or_null("CollisionShape3D")
	if cs != null:
		# A BOX FOR EVERY SHAPE, never thinner than half the body. A 0.16 m object
		# is at the edge of what a hand catches at all, and the corpus's warning is
		# grab_cube_show: a 0.1 m sphere collider under a 1 m cube mesh, which
		# looks grabbable and is not. The box is the forgiving read of a silhouette.
		var box := BoxShape3D.new()
		var floor_size: float = maxf(ab.size.x, ab.size.z) * 0.5
		box.size = Vector3(
			maxf(ab.size.x, floor_size),
			maxf(ab.size.y, floor_size),
			maxf(ab.size.z, floor_size))
		cs.shape = box
		cs.position = ab.get_center() + Vector3(0.0, -ab.position.y, 0.0)

	for side in ["left", "right"]:
		var gp_path: String = GRAB_POINT_FMT % side
		if ResourceLoader.exists(gp_path):
			p.add_child((load(gp_path) as PackedScene).instantiate())
	return p


func _make_twin(i: int, mesh: Mesh, mat: StandardMaterial3D, ab: AABB, col: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Big%d" % i
	# NO BODY AT ALL. The survey's answer for a display object was
	# collision_layer = 0; a plain Node3D is one better, because there is nothing
	# for the pointer ray, the grab area or the walker to hit — a 1.6 m sphere
	# standing in a pool can neither shove a visitor nor be picked up by mistake.
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(0.0, -ab.position.y, 0.0)
	root.add_child(mi)
	# The contact shadow is a Decal, so it seats the twin on the pool floor
	# without adding a MeshInstance3D — which is what the capture AABB counts.
	var sh: Decal = PBR.ground_shadow(maxf(ab.size.x, ab.size.z) * 0.62, 0.5, 0.02)
	if sh != null:
		root.add_child(sh)
	if tether == "halo":
		root.add_child(_halo_ring(ab, col))
	return root


func _make_tether(i: int, col: Color) -> MeshInstance3D:
	var line := MeshInstance3D.new()
	line.name = "Tether%d" % i
	var cyl := CylinderMesh.new()
	cyl.top_radius = TETHER_R
	cyl.bottom_radius = TETHER_R
	cyl.height = 1.0                      # one metre, stretched by the basis
	cyl.radial_segments = 8
	line.mesh = cyl
	line.material_override = PBR.emissive(col, 2.2)
	return line


## A bright ring on the pool floor around a twin's foot. A child of the twin, so
## it scales and travels with it and costs the frame loop nothing.
func _halo_ring(ab: AABB, col: Color) -> MeshInstance3D:
	var rr: float = maxf(ab.size.x, ab.size.z) * 0.62
	var t := TorusMesh.new()
	t.inner_radius = maxf(rr - 0.006, 0.001)
	t.outer_radius = rr + 0.006
	t.rings = 6
	t.ring_segments = 36
	var mi := MeshInstance3D.new()
	mi.name = "Halo"
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 0.62)
	mi.material_override = m
	mi.position = Vector3(0.0, 0.004, 0.0)
	return mi


## NOTHING IN THE MUSEUM LIGHTS A BASIN. em_lighting mounts every family above
## the deck — the ambient key at y 2.55, the two daylight spots at 5.12 — and a
## basin cell never becomes a slot, so it gets no key light and no floor fill: a
## 4 m pool floor sits about two thirds of a stop under the deck with no aimed
## beam and no contact specular. This is the twin's own lamp, and it is the only
## light below the water anywhere in the building.
func _add_pool_key(big: float, spread: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.name = "PoolKey"
	lamp.position = _pool_anchor + Vector3(0.0, big * 0.9, 0.0)
	lamp.light_energy = 1.7
	lamp.omni_range = maxf(spread + big * 2.0, 6.0)
	lamp.omni_attenuation = 0.9
	lamp.shadow_enabled = false            # scenery budget, and nothing down there receives one
	add_child(lamp)
	_owned.append(lamp)


# ── THE LINK ─────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	for i in range(_leads.size()):
		var p: Node3D = _leads[i]
		if not is_instance_valid(p):
			continue
		if clamp_reach:
			_constrain(p)
		# POLLING, AND NOTHING ELSE COVERS BOTH HANDS.
		# DesktopInteractionPointer._grab_held never calls pick_up(), never emits
		# and never marks the object — it writes global_position each frame and
		# restores freeze/layer/mask on release, silently. So on desktop, which is
		# the walk Palle does daily, there is no grab signal to connect to at all.
		# XRToolsPickable does emit picked_up/grabbed/released, but only at the two
		# ends of a grab and never during the motion. The transform is the one
		# thing both hands actually touch.
		# is_equal_approx compares the basis too, which is what makes this work in
		# VR: the grab driver is a RemoteTransform3D and writes rotation as well.
		# LOCAL transform, not global: neither hand reparents the pickable, so
		# local coordinates are stable and are already the table space this
		# artifact measures in.
		var lt: Transform3D = p.transform
		if lt.is_equal_approx(_last[i]):
			continue
		_last[i] = lt
		_place_twin(i, lt)


## THE WHOLE IDEA, IN ONE TRANSFORM. The pool is the table put through a
## similarity: the offset from the table's anchor times offset_scale, the body
## times twin_scale. At rest the delta is zero, so a twin's base sits exactly on
## the pool floor whatever the two factors are — and lift a small object 2 cm and
## its twin rises 20.
func _place_twin(i: int, lt: Transform3D) -> void:
	if i >= _twins.size():
		return
	var tw: Node3D = _twins[i]
	if tw == null or not is_instance_valid(tw):
		return
	var pos: Vector3 = _pool_anchor + (lt.origin - _table_anchor) * _off_s
	# Right-multiplied, so the scale is in the twin's OWN frame. Basis.scaled()
	# multiplies rows — a scale in the parent frame — which would shear a rotated
	# body instead of enlarging it.
	tw.transform = Transform3D(
		lt.basis.orthonormalized() * Basis.from_scale(Vector3.ONE * _twin_s), pos)
	if i < _tethers.size():
		_aim_tether(i,
			lt.origin + Vector3(0.0, _heights[i] * 0.5, 0.0),
			pos + Vector3(0.0, _heights[i] * _twin_s, 0.0))


## Clamped and WRITTEN BACK every frame, the way value_mapper_3d holds its handle
## inside its box (commons/interfaces/value_mapper_3d.gd). The desktop carry lerps
## 0.4 toward the camera every frame and never asks permission, so the boundary
## has to be re-asserted rather than checked once on release — and on desktop
## there is no release to check. The floor of the clamp is the table top, which
## is what makes the pool floor the table top ten times over.
func _constrain(p: Node3D) -> void:
	var q: Vector3 = p.position
	var c := Vector3(
		clampf(q.x, -_bed_x, _bed_x),
		clampf(q.y, _table_anchor.y, _table_anchor.y + _reach),
		clampf(q.z, -_bed_z, _bed_z))
	if not c.is_equal_approx(q):
		p.position = c


func _aim_tether(i: int, a: Vector3, b: Vector3) -> void:
	var line: MeshInstance3D = _tethers[i]
	if line == null or not is_instance_valid(line):
		return
	var d: Vector3 = b - a
	var dist: float = d.length()
	if dist < 0.02:
		line.visible = false
		return
	line.visible = true
	line.transform = Transform3D(
		_aim_basis(d / dist) * Basis.from_scale(Vector3(1.0, dist, 1.0)), a + d * 0.5)


## An orthonormal basis with +Y along dir. The reference axis swaps near vertical
## because a cross product with a parallel vector is zero, and a vertical leader
## is the common case here — the pool is usually straight down.
func _aim_basis(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.94 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	return Basis(x, y, x.cross(y))


# ── THE VOCABULARY ───────────────────────────────────────────────────────────

func _shape_list() -> PackedStringArray:
	var out: PackedStringArray = []
	for raw in primitives.split(",", false):
		var s: String = str(raw).strip_edges().to_lower()
		if SHAPES.has(s):
			out.append(s)
	if out.is_empty():
		out.append("cube")
	return out


## Every shape fills the same m-cube, so the set is a family at one size. The
## returned mesh is SHARED between a small body and its twin — see _build.
func _mesh_for(shape: String, m: float) -> Mesh:
	match shape:
		"sphere":
			var s := SphereMesh.new()
			s.radius = m * 0.5
			s.height = m
			s.radial_segments = 32
			s.rings = 16
			return s
		"cone":
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = m * 0.5
			c.height = m
			c.radial_segments = 28
			return c
		"cylinder":
			var y := CylinderMesh.new()
			y.top_radius = m * 0.42
			y.bottom_radius = m * 0.42
			y.height = m
			y.radial_segments = 28
			return y
		"wedge":
			var p := PrismMesh.new()
			p.size = Vector3(m, m, m)
			return p
		"torus":
			var t := TorusMesh.new()
			t.inner_radius = m * 0.22
			t.outer_radius = m * 0.5
			t.rings = 8
			t.ring_segments = 32
			return t
		"tetra":
			return _tetra_mesh(m)
		_:
			var b := BoxMesh.new()
			b.size = Vector3(m, m, m)
			return b


## The regular tetrahedron inscribed in the body cube — four of the cube's eight
## corners, so its AABB is exactly the same m-cube as every other shape and it
## needs no rescaling to belong to the set. Godot ships no primitive for it.
## Flat-shaded on purpose: four faces with four normals is what makes it read as
## the minimum enclosure of a volume instead of a lumpy sphere.
func _tetra_mesh(m: float) -> ArrayMesh:
	var r: float = m * 0.5
	var v: Array[Vector3] = [
		Vector3(1, 1, 1) * r,
		Vector3(1, -1, -1) * r,
		Vector3(-1, 1, -1) * r,
		Vector3(-1, -1, 1) * r]
	var faces: Array = [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var tri: Array[Vector3] = [v[int(f[0])], v[int(f[1])], v[int(f[2])]]
		var nrm: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
		for pt in tri:
			st.set_normal(nrm)
			st.set_uv(Vector2(pt.x, pt.z) / maxf(m, 0.001) + Vector2(0.5, 0.5))
			st.add_vertex(pt)
	st.generate_tangents()
	return st.commit()


## An even hue ramp rather than a palette lookup: the colour is the other mark of
## the pair, so it has to be derivable from the index alone and identical on both
## bodies. No randomness, so no seed is spent on it.
func _hue(i: int, n: int) -> Color:
	var t: float = 0.0 if n <= 1 else float(i) / float(n - 1)
	return Color.from_hsv(fposmod(hue_start + hue_span * t, 1.0), 0.58, 0.86)


# ── READERS (for probes and for the museum's own inspection) ─────────────────

func lead_count() -> int:
	return _leads.size()


func lead_node(i: int) -> Node3D:
	return _leads[i] if i >= 0 and i < _leads.size() else null


func twin_node(i: int) -> Node3D:
	return _twins[i] if i >= 0 and i < _twins.size() else null


## The similarity the pair is bound by, so a probe can assert against the
## artifact's own numbers rather than against a copy of them.
func link_report() -> Dictionary:
	return {
		"count": _leads.size(),
		"twin_scale": _twin_s,
		"offset_scale": _off_s,
		"table_anchor": _table_anchor,
		"pool_anchor": _pool_anchor,
		"bed": Vector2(_bed_x, _bed_z),
		"reach_m": _reach,
	}


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "hero",
		"footprint":    Vector2i(2, 2),
		"approach":     "front",
		"reading_dist": 1.2,
		"height":       0.92,
		"budget_ms":    1.2,
		"tags":         ["interactive", "grab", "scale"],
	}
