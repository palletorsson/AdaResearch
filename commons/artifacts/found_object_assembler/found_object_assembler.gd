extends Node3D
class_name FoundObjectAssembler

# @identity
# essence: a heap of offcuts on one side of the room and a bare table on the other — seven mismatched fragments nobody designed together, each one two hands wide and leaning on the next, and a surface that quietly squares whatever you set down on it
# desire: to give the bricolage sequence the moment before composition, where the parts are still junk and the only order in the room is the one your hands have not made yet
# critical_parameter: snap_step — the coarseness of the table's grid. Fine steps let you place; coarse steps make the table an opinion about where things go, and the fragment obeys it either way
# triggers: _physics_process watches every fragment that is not held; once one comes to rest over the table it is quantised to the nearest snap_step cell, squared to the nearest right angle, and frozen there
# emerges: the difference between a pile and an assembly is not the parts, it is a grid. The same offcut reads as debris on the heap and as a component on the table, and nothing about it changed
# needs: grab_cube.tscn [present — the pickable body is reused, its mesh and collider swapped per fragment]; Grid.gdshader [present]; a seeded RNG so the heap is the same heap on every load; TextScreen PAD plate [present]
# relationships: the front door of the bricolage sequence — it deals the stock that specimen_plinth shelves and constraint_demo tests; the assembly table is dome_kit's derivation with the method removed
# truth: found objects are not found. Somebody decided where the grid starts, and after that the junk had somewhere to be.
# @qfep_term: Assemblage — composition without a designer, on a surface that is not neutral.

## Room-scale bricolage station, 3x1x3. Left: a low junk plinth carrying a
## deterministic heap of primitive offcuts — few, big and stacked against each
## other, each a real XRToolsPickable body. Right: a bare assembly table with a
## coarse grid scribed into it. Fragments dropped over the table snap and stay.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const GRAB_SCENE_PATH := "res://commons/primitives/cubes/grab_cube.tscn"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# --- geometry, in artifact-local metres -----------------------------------
const PILE_C := Vector3(-0.85, 0.0, 0.0)
## Drum radius, cut close to the heap it carries. A plinth wider than its load
## reads as an empty table with something dropped on it.
const PILE_R := 0.50
const PILE_TOP := 0.24

## Heap footprint and height. The base tier sits at HEAP_SPAN and the spiral
## closes inward as it rises, so the last fragment lands on the ones below.
const HEAP_SPAN := 0.28
const HEAP_RISE := 0.20
## Golden angle — successive fragments never line up, without a random draw.
const GOLDEN_ANGLE := 2.39996323

const TABLE_C := Vector3(0.82, 0.0, 0.0)
const TABLE_HX := 0.58
const TABLE_HZ := 0.44
const TABLE_TOP := 0.76

## How still a dropped fragment must be before the table is allowed to claim it.
const REST_SPEED := 0.3
## How far above the table top a fragment may be and still count as "on it".
const CLAIM_HEIGHT := 0.5

# --- knobs ----------------------------------------------------------------
## Fragments dealt onto the heap. Few and large: at room scale a dozen offcuts
## disappear into the plinth, where seven objects you could carry do not.
## Mismatched by construction — shape, proportion and colour are drawn
## independently, so no two agree.
@export var fragment_count: int = 7
## Cell size of the assembly table's grid, in metres. Coarser than the smallest
## fragment, so a placed piece covers a cell rather than getting lost in one.
@export var snap_step: float = 0.20
## Seed for the heap. Named `pile_seed` rather than `seed` because `seed()` is a
## global function and a property of that name would shadow it inside this class.
@export var pile_seed: int = 20260729

const SHAPES: PackedStringArray = ["box", "slab", "rod", "disc", "ring", "wedge"]

## Six palettes that do not go together. That is the specification.
const PALETTE: Array[Color] = [
	Color(0.78, 0.30, 0.24),
	Color(0.32, 0.56, 0.74),
	Color(0.74, 0.66, 0.26),
	Color(0.40, 0.62, 0.40),
	Color(0.58, 0.36, 0.66),
	Color(0.62, 0.60, 0.56),
]

var _rng := RandomNumberGenerator.new()
var _built := false
## Nodes parented onto self. Only these are torn down on a rebuild — the grid
## adds label plates and tags after us and those are not ours to free.
var _created: Array[Node] = []
## Fragments live under the GridScene, not under us, so the physics server is
## never asked to run a rigid body inside a transformed parent. Tracked here as
## { "body": RigidBody3D, "half_h": float, "placed": bool }.
var _fragments: Array = []


func _ready() -> void:
	_build_all()
	_built = true
	set_physics_process(true)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_rng.seed = pile_seed
	_build_pile()
	_build_table()
	_build_plate()
	_deal_fragments()


func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


## The heap: a squat drum with three half-buried slabs leaning off it, so it
## reads as accumulation rather than a second table.
func _build_pile() -> void:
	var body := StaticBody3D.new()
	body.name = "Heap"
	_own(body)

	var drum := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = PILE_R
	cyl.bottom_radius = PILE_R + 0.06
	cyl.height = PILE_TOP
	cyl.radial_segments = 14
	drum.mesh = cyl
	drum.position = PILE_C + Vector3(0.0, PILE_TOP * 0.5, 0.0)
	drum.material_override = _grid_material(Color(0.24, 0.24, 0.27), Color(0.45, 0.48, 0.55), 0.4)
	body.add_child(drum)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = PILE_R
	shape.height = PILE_TOP
	col.shape = shape
	col.position = drum.position
	body.add_child(col)

	# Buried slabs — junk the heap is made of, not junk you can take.
	for i in 3:
		var slab := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.46, 0.05, 0.19)
		slab.mesh = bm
		var ang: float = TAU * float(i) / 3.0 + 0.6
		slab.position = PILE_C + Vector3(cos(ang) * PILE_R * 0.62, PILE_TOP - 0.03, sin(ang) * PILE_R * 0.62)
		slab.rotation = Vector3(0.0, ang, 0.22)
		slab.material_override = _grid_material(Color(0.30, 0.29, 0.26), Color(0.55, 0.52, 0.44), 0.3)
		body.add_child(slab)


## The table: a bare top, four legs, and the grid scribed into the surface.
## No lip, no tray, no sockets — the only thing organising it is the spacing.
func _build_table() -> void:
	var body := StaticBody3D.new()
	body.name = "AssemblyTable"
	_own(body)

	var top := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(TABLE_HX * 2.0, 0.05, TABLE_HZ * 2.0)
	top.mesh = bm
	top.position = TABLE_C + Vector3(0.0, TABLE_TOP - 0.025, 0.0)
	top.material_override = _grid_material(Color(0.20, 0.21, 0.25), Color(0.40, 0.46, 0.56), 0.5)
	body.add_child(top)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bm.size
	col.shape = shape
	col.position = top.position
	body.add_child(col)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.05, TABLE_TOP - 0.05, 0.05)
			leg.mesh = lm
			leg.position = TABLE_C + Vector3(
				sx * (TABLE_HX - 0.07),
				(TABLE_TOP - 0.05) * 0.5,
				sz * (TABLE_HZ - 0.07))
			leg.material_override = _grid_material(Color(0.18, 0.18, 0.21), Color(0.35, 0.38, 0.44), 0.3)
			body.add_child(leg)

	_scribe_grid()


## The snap grid, scribed proud of the table top. This is the only instruction
## the table gives, and it gives it before anything is placed — so it has to be
## legible across the room, not a hairline you find once you are leaning over it.
## Ruled lines set the cells; a tick at every crossing names the seat itself.
func _scribe_grid() -> void:
	var step: float = maxf(0.04, snap_step)
	var line_mat := _grid_material(Color(0.42, 0.55, 0.70), Color(0.60, 0.80, 1.0), 1.4)
	var tick_mat := _grid_material(Color(0.55, 0.72, 0.92), Color(0.78, 0.92, 1.0), 2.2)
	var nx: int = int(TABLE_HX / step)
	var nz: int = int(TABLE_HZ / step)
	for i in range(-nx, nx + 1):
		var line := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.014, 0.008, TABLE_HZ * 1.9)
		line.mesh = lm
		line.position = TABLE_C + Vector3(float(i) * step, TABLE_TOP + 0.004, 0.0)
		line.material_override = line_mat
		_own(line)
	for j in range(-nz, nz + 1):
		var line2 := MeshInstance3D.new()
		var lm2 := BoxMesh.new()
		lm2.size = Vector3(TABLE_HX * 1.9, 0.008, 0.014)
		line2.mesh = lm2
		line2.position = TABLE_C + Vector3(0.0, TABLE_TOP + 0.004, float(j) * step)
		line2.material_override = line_mat
		_own(line2)
	# One tick per crossing: the grid stops being ruling and becomes addresses.
	for i2 in range(-nx, nx + 1):
		for j2 in range(-nz, nz + 1):
			var tick := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(step * 0.22, 0.010, step * 0.22)
			tick.mesh = tm
			tick.position = TABLE_C + Vector3(
				float(i2) * step,
				TABLE_TOP + 0.005,
				float(j2) * step)
			tick.material_override = tick_mat
			_own(tick)


func _build_plate() -> void:
	# Configure BEFORE add_child — TextScreen rebuilds on each setter only once
	# in-tree, so driving the properties after adding costs a rebuild per line.
	var ts := TextScreenScript.new()
	ts.name = "AssemblerPlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.40
	# Clear of the scribed grid, which now stands 0.010 proud of the top.
	ts.position = TABLE_C + Vector3(0.0, TABLE_TOP + 0.016, TABLE_HZ - 0.09)
	if ts.has_method("set_text"):
		ts.set_text("FOUND OBJECT ASSEMBLER", "take from the heap — the table squares it")
	_own(ts)


# ═══════════════════════════════════════════════════════════════════
# FRAGMENTS
# ═══════════════════════════════════════════════════════════════════

## Deal the heap. Every draw comes off the seeded RNG in a fixed order, so the
## heap is byte-identical on every load — the pile is authored, not rolled.
func _deal_fragments() -> void:
	var host: Node = _fragment_host()
	var n: int = clampi(fragment_count, 3, 14)
	for i in n:
		var kind: String = SHAPES[_rng.randi() % SHAPES.size()]
		var col: Color = PALETTE[_rng.randi() % PALETTE.size()]
		var mesh: Mesh = _fragment_mesh(kind)
		var aabb: AABB = mesh.get_aabb()
		var half_h: float = maxf(aabb.size.y * 0.5, 0.02)

		var node: Node3D = _wrap_pickable(mesh, aabb, col)
		host.add_child(node)

		# Heaped, not scattered, and frozen: no settling drift, so the arrangement
		# you see is exactly the arrangement the seed describes. The spiral closes
		# inward as it rises, so each fragment leans on the ones already down —
		# they interpenetrate a little, which is what distinguishes a heap from a
		# display of parts laid out not touching.
		var tier: float = 0.0 if n <= 1 else float(i) / float(n - 1)
		var ang: float = GOLDEN_ANGLE * float(i) + _rng.randf_range(-0.18, 0.18)
		var rad: float = HEAP_SPAN * (1.0 - tier * 0.85) + _rng.randf_range(-0.03, 0.03)
		var lift: float = PILE_TOP + half_h * 0.85 + tier * HEAP_RISE
		var local := PILE_C + Vector3(cos(ang) * rad, lift, sin(ang) * rad)
		node.global_position = to_global(local)
		# Tilt grows with the tier: the ones on top are the ones lying askew.
		var lean: float = 0.18 + tier * 0.34
		node.global_rotation = Vector3(
			_rng.randf_range(-lean, lean),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-lean, lean))

		if node is RigidBody3D:
			var rb := node as RigidBody3D
			rb.freeze = true
			# Connected by name: `picked_up` belongs to XRToolsPickable, not to
			# RigidBody3D, so a typed reference cannot see it at compile time.
			if rb.has_signal("picked_up"):
				rb.connect("picked_up", Callable(self, "_on_fragment_taken").bind(rb))
		_fragments.append({"body": node, "half_h": half_h, "placed": false})


## Reuse the project's pickable body and swap its geometry. The grab behaviour,
## highlight ring and hand points all come from grab_cube.tscn unchanged; only
## the mesh and the collider are ours. If the scene is missing the fragment is
## still built as plain geometry, because an artifact that does not draw is a
## worse failure than one you cannot lift.
func _wrap_pickable(mesh: Mesh, aabb: AABB, col: Color) -> Node3D:
	var mat: Material = _grid_material(col, col.lightened(0.45), 1.6)
	if ResourceLoader.exists(GRAB_SCENE_PATH):
		var packed: PackedScene = load(GRAB_SCENE_PATH)
		if packed:
			var inst: Node3D = packed.instantiate()
			var mi := inst.get_node_or_null("MeshInstance3D") as MeshInstance3D
			if mi:
				mi.mesh = mesh
				mi.material_override = mat
			var cs := inst.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if cs:
				var box := BoxShape3D.new()
				box.size = aabb.size
				cs.shape = box
				cs.position = aabb.position + aabb.size * 0.5
			# UNFROZEN release: without this the body restores the frozen state it
			# had on the heap and would hang in mid-air the moment you let go.
			inst.set("release_mode", 0)
			inst.set("snap_to_shelf", false)
			inst.set("mass", 0.5)
			return inst
	var fallback := MeshInstance3D.new()
	fallback.mesh = mesh
	fallback.material_override = mat
	return fallback


## Offcuts. Every kind is a built-in primitive cut to a proportion no catalogue
## would list — the point is that they were made for something else. Sized
## 0.15–0.35 m across: an offcut you would carry with both hands, not a chip.
## Below that the whole station reads as furniture with crumbs on it.
func _fragment_mesh(kind: String) -> Mesh:
	match kind:
		"slab":
			var slab := BoxMesh.new()
			slab.size = Vector3(_rng.randf_range(0.24, 0.35), _rng.randf_range(0.06, 0.10), _rng.randf_range(0.15, 0.23))
			return slab
		"rod":
			var rod := CylinderMesh.new()
			rod.top_radius = _rng.randf_range(0.045, 0.07)
			rod.bottom_radius = rod.top_radius
			rod.height = _rng.randf_range(0.24, 0.35)
			rod.radial_segments = 10
			return rod
		"disc":
			var disc := CylinderMesh.new()
			disc.top_radius = _rng.randf_range(0.11, 0.17)
			disc.bottom_radius = disc.top_radius
			disc.height = _rng.randf_range(0.05, 0.09)
			disc.radial_segments = 16
			return disc
		"ring":
			var ring := TorusMesh.new()
			ring.inner_radius = _rng.randf_range(0.08, 0.11)
			ring.outer_radius = ring.inner_radius + _rng.randf_range(0.045, 0.07)
			ring.rings = 14
			ring.ring_segments = 8
			return ring
		"wedge":
			var wedge := PrismMesh.new()
			wedge.size = Vector3(_rng.randf_range(0.20, 0.31), _rng.randf_range(0.16, 0.24), _rng.randf_range(0.14, 0.20))
			return wedge
	# "box" and anything unrecognised: an offcut cube with no two sides equal.
	var box := BoxMesh.new()
	box.size = Vector3(
		_rng.randf_range(0.15, 0.25),
		_rng.randf_range(0.15, 0.25),
		_rng.randf_range(0.15, 0.25))
	return box


## Parent grabbables under the GridScene so the hands can reach them and no
## rigid body ends up inside a transformed parent. Falls back to self.
func _fragment_host() -> Node:
	var cur: Node = self
	while cur:
		if cur.name == "GridScene":
			return cur
		cur = cur.get_parent()
	return self


func _on_fragment_taken(_pickable, body: RigidBody3D) -> void:
	for entry in _fragments:
		if entry["body"] == body:
			entry["placed"] = false
			return


# ═══════════════════════════════════════════════════════════════════
# THE TABLE'S OPINION
# ═══════════════════════════════════════════════════════════════════

## A fragment that has come to rest over the table gets quantised: its position
## to the nearest snap_step cell, its yaw to the nearest right angle, and then
## frozen. Nothing is checked about what it is — the grid does not care which
## offcut it caught.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for entry in _fragments:
		var node = entry["body"]
		if not is_instance_valid(node) or not (node is RigidBody3D):
			continue
		var body := node as RigidBody3D
		if body.has_method("is_picked_up") and bool(body.call("is_picked_up")):
			entry["placed"] = false
			continue
		if bool(entry["placed"]) or body.freeze:
			continue
		if body.linear_velocity.length() > REST_SPEED:
			continue
		var local: Vector3 = to_local(body.global_position)
		var dx: float = local.x - TABLE_C.x
		var dz: float = local.z - TABLE_C.z
		if absf(dx) > TABLE_HX or absf(dz) > TABLE_HZ:
			continue
		var dy: float = local.y - TABLE_TOP
		if dy < -0.06 or dy > CLAIM_HEIGHT:
			continue
		_seat(entry, body, dx, dz)


func _seat(entry: Dictionary, body: RigidBody3D, dx: float, dz: float) -> void:
	var step: float = maxf(0.04, snap_step)
	var cell_x: float = round(dx / step) * step
	var cell_z: float = round(dz / step) * step
	cell_x = clampf(cell_x, -TABLE_HX + step * 0.5, TABLE_HX - step * 0.5)
	cell_z = clampf(cell_z, -TABLE_HZ + step * 0.5, TABLE_HZ - step * 0.5)
	var half_h: float = float(entry["half_h"])
	var seated := Vector3(TABLE_C.x + cell_x, TABLE_TOP + half_h + 0.002, TABLE_C.z + cell_z)

	var quarter: float = PI * 0.5
	var rel_yaw: float = body.global_rotation.y - global_rotation.y
	var snapped_yaw: float = round(rel_yaw / quarter) * quarter

	body.freeze = true
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.global_position = to_global(seated)
	body.global_rotation = Vector3(0.0, global_rotation.y + snapped_yaw, 0.0)
	entry["placed"] = true


# ═══════════════════════════════════════════════════════════════════
# MATERIAL / CONFIG
# ═══════════════════════════════════════════════════════════════════

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.45
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	for entry in _fragments:
		var n = entry["body"]
		if is_instance_valid(n):
			n.queue_free()
	_fragments.clear()
	_build_all()


## Grid config. Keys: "fragment_count", "snap_step", "seed" (alias "pile_seed").
func apply_grid_config(config_data: Dictionary) -> void:
	var before_count: int = fragment_count
	var before_step: float = snap_step
	var before_seed: int = pile_seed

	if config_data.has("fragment_count"):
		fragment_count = clampi(int(config_data["fragment_count"]), 3, 14)
	if config_data.has("snap_step"):
		snap_step = clampf(float(config_data["snap_step"]), 0.04, 0.4)
	if config_data.has("seed"):
		pile_seed = int(config_data["seed"])
	if config_data.has("pile_seed"):
		pile_seed = int(config_data["pile_seed"])

	if not _built:
		return
	if fragment_count == before_count and is_equal_approx(snap_step, before_step) and pile_seed == before_seed:
		# curation_station hands every artifact it curates {"emissive": false} right
		# after framing the plate. Rebuilding on that would throw the framing away.
		return

	_rebuild_now()
	print("[FoundObjectAssembler] Config applied — fragments=%d, snap_step=%.3f, seed=%d" % [
		fragment_count, snap_step, pile_seed])
