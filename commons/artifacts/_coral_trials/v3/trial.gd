# CoralTrialV3 — STAGHORN coral (Acropora), a dendritic branching colony.
#
# Non-primitive: the whole colony is one recursive branching grammar. A thick
# trunk splits repeatedly into 2-3 thinner, shorter children at an upward-biased
# spread, recursing to a depth scaling with `complexity` (4-6 levels). Each
# branch SEGMENT is a tapered tube (MorphoPrimitive.multi_tube over a curved
# centreline of a few points with shrinking radii), gravitropically bent toward
# vertical with seed-jitter so it reads organic. A blob sphere welds every fork,
# a rounded cap closes every growing tip, and the surface is studded with small
# raised corallite cups (oriented to the surface normal via Basis), denser
# toward the tips. A subset of cups + every tip glow fluorescent green.
#
# Toolkit: MorphoPrimitive.multi_tube (branch tubes), MorphoPrimitive.sphere
# (forks / tips / corallite bumps). Everything is deterministic from seed 4242
# via a local RandomNumberGenerator — no global randf/randi. Every orientation
# is built with Basis (no out-of-tree look_at). Recursion is depth-guarded.

class_name CoralTrialV3
extends Node3D

# ── Palette (matches the coral brief) ───────────────────────────────────────
const SKELETON_COLOR := Color(0.90, 0.86, 0.78)   # pale calcite ivory
const TISSUE_COLOR := Color(0.95, 0.45, 0.35)     # warm living coral tissue
const FLUORO_COLOR := Color(0.40, 1.00, 0.45)     # fluorescent polyp green

# ── Colony shape knobs ──────────────────────────────────────────────────────
const SEED := 4242
const TARGET_HEIGHT := 2.3          # ~2.0-2.5 m tall
const COMPLEXITY := 6               # recursion depth (4-6 levels)
const TRUNK_RADIUS := 0.10          # base thickness
const TRUNK_LENGTH := 0.40          # first segment length (short → forks low)
const RADIUS_DECAY := 0.74          # each child this fraction of parent radius
const LENGTH_DECAY := 0.80          # each child this fraction of parent length
const TUBE_SIDES := 8               # cross-section resolution of branch tubes
const SEG_SAMPLES := 5             # centreline points per branch segment
const GRAVITROPISM := 0.30          # how strongly branches curve toward vertical

# ── Accumulated geometry stats (for the report) ─────────────────────────────
var _rng := RandomNumberGenerator.new()
var _fork_count: int = 0
var _branch_count: int = 0
var _corallite_count: int = 0
var _mesh_count: int = 0
var _max_reached_depth: int = 0

# Lazily-built shared materials.
var _mat_skeleton: StandardMaterial3D
var _mat_tissue: StandardMaterial3D
var _mat_fluoro: StandardMaterial3D

# Batched corallite scatter (skeleton + tissue + glow buckets).
var _cup_xforms_skel: Array[Transform3D] = []
var _cup_xforms_glow: Array[Transform3D] = []


func _ready() -> void:
	_rng.seed = SEED
	_build_materials()

	var colony := Node3D.new()
	colony.name = "Colony"
	add_child(colony)

	# Grow from the floor (y = 0), trunk pointing up with a touch of jitter so
	# the whole colony leans organically rather than rod-straight.
	var start := Vector3.ZERO
	var trunk_dir := Vector3(
		_rng.randf_range(-0.06, 0.06),
		1.0,
		_rng.randf_range(-0.06, 0.06)
	).normalized()

	# A small foot pad so the trunk sits cleanly on the ground plane (a holdfast,
	# not a snowball — keep it just above trunk radius).
	_add_blob(colony, start + Vector3.UP * TRUNK_RADIUS * 0.3, TRUNK_RADIUS * 1.02, _mat_skeleton)

	_grow_branch(colony, start, trunk_dir, TRUNK_RADIUS, TRUNK_LENGTH, 0)

	# Flush the batched corallite cups into two MultiMeshInstances.
	_flush_corallites(colony)

	# Recentre the colony horizontally so the capture AABB frames it.
	_recentre(colony)

	print("CoralTrialV3: seed=%d depth=%d branches=%d forks=%d corallites=%d meshes=%d" % [
		SEED, _max_reached_depth, _branch_count, _fork_count, _corallite_count, _mesh_count
	])


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════
# RECURSIVE BRANCHING GRAMMAR
# ═══════════════════════════════════════════════════════════════════════════

## Grow one branch from `start` along `dir`, then either terminate in a rounded
## growing tip or fork into 2-3 thinner, shorter children. Depth-guarded.
func _grow_branch(parent: Node3D, start: Vector3, dir: Vector3,
		radius: float, length: float, depth: int) -> void:

	if depth > _max_reached_depth:
		_max_reached_depth = depth

	# Hard recursion guard — terminate on depth or vanishingly thin branches.
	if depth >= COMPLEXITY or radius < 0.006:
		_add_tip(parent, start, dir, radius)
		return

	# Build a gently curving centreline that bends toward vertical
	# (gravitropism) with a little per-branch noise, and a tip radius that
	# tapers along the segment.
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var end_radius: float = radius * 0.78          # taper within the segment
	var cur := start
	var cur_dir := dir
	var step := length / float(SEG_SAMPLES - 1)

	for i in SEG_SAMPLES:
		var t: float = float(i) / float(SEG_SAMPLES - 1)
		positions.append(cur)
		radii.append(lerpf(radius, end_radius, t))
		# Advance along the (curving) direction.
		if i < SEG_SAMPLES - 1:
			# Bend toward vertical, scaled by gravitropism and a tiny wobble.
			var pull: float = GRAVITROPISM * step
			var wobble := Vector3(
				_rng.randf_range(-0.04, 0.04),
				0.0,
				_rng.randf_range(-0.04, 0.04)
			)
			cur_dir = (cur_dir + Vector3.UP * pull + wobble).normalized()
			cur += cur_dir * step

	var tip_pos: Vector3 = positions[positions.size() - 1]
	var tip_dir: Vector3 = (tip_pos - (positions[positions.size() - 2] as Vector3)).normalized()

	# Emit the tapered tube for this segment.
	var tube: Mesh = MorphoPrimitive.multi_tube(positions, radii, TUBE_SIDES)
	if tube != null:
		var mi := MeshInstance3D.new()
		mi.name = "Branch_d%d_%d" % [depth, _branch_count]
		mi.mesh = tube
		mi.material_override = _mat_skeleton
		parent.add_child(mi)
		_mesh_count += 1
	_branch_count += 1

	# Scatter corallite cups along this segment's surface (denser toward tips).
	_scatter_corallites_along(positions, radii, depth)

	# A smooth joint blob at the fork point, just proud of the branch so it
	# welds the children without reading as a separate bead. Lower (thicker)
	# forks get a relatively smaller blob so the trunk stays clean.
	var joint_scale: float = lerpf(0.98, 1.08, float(depth) / float(COMPLEXITY))
	_add_blob(parent, tip_pos, end_radius * joint_scale, _mat_skeleton)
	_fork_count += 1

	# Decide the fork: 2-3 children, thinner and shorter. The trunk (depth 0)
	# always splits into 3 so the colony fans out into a bushy candelabra
	# rather than a single pole.
	var children: int
	if depth == 0:
		children = 3
	else:
		children = 2 if _rng.randf() < 0.45 else 3
	# Near the canopy, sometimes a single whip-like continuation for fine tips.
	if depth >= COMPLEXITY - 1 and _rng.randf() < 0.35:
		children = 1

	var child_radius: float = end_radius * RADIUS_DECAY
	var child_length: float = length * LENGTH_DECAY

	# Build a local frame around the tip direction to spread children around it.
	var basis := _basis_from_forward(tip_dir)
	var side_a: Vector3 = basis.x
	var side_b: Vector3 = basis.z

	# Upward-biased spread: wider near the base, tighter (more vertical) higher.
	var spread_deg: float = lerpf(40.0, 22.0, float(depth) / float(COMPLEXITY))

	var roll0: float = _rng.randf_range(0.0, TAU)
	for c in children:
		# Distribute children evenly around the branch axis (full 3D fan),
		# jittered so it never reads as a flat plane.
		var roll: float = roll0 + TAU * float(c) / float(children) + _rng.randf_range(-0.35, 0.35)
		var spread: float = deg_to_rad(spread_deg * _rng.randf_range(0.75, 1.2))
		# Direction = tip_dir tilted out by `spread` around the rolled side axis.
		var out_dir: Vector3 = (cos(roll) * side_a + sin(roll) * side_b).normalized()
		var child_dir: Vector3 = (tip_dir * cos(spread) + out_dir * sin(spread)).normalized()
		# Re-bias toward vertical so children sweep up like antlers.
		child_dir = (child_dir + Vector3.UP * 0.28).normalized()

		_grow_branch(parent, tip_pos, child_dir,
			child_radius * _rng.randf_range(0.9, 1.05),
			child_length * _rng.randf_range(0.82, 1.05),
			depth + 1)


# ═══════════════════════════════════════════════════════════════════════════
# TIPS — rounded fluorescent growing points
# ═══════════════════════════════════════════════════════════════════════════

## Close a branch end with a pale/bright rounded tip (Acropora growing tips
## are fluorescent) plus a tiny terminal corallite mouth.
func _add_tip(parent: Node3D, pos: Vector3, dir: Vector3, radius: float) -> void:
	var tip_r: float = maxf(radius, 0.012) * 1.15
	var mi := MeshInstance3D.new()
	mi.name = "Tip_%d" % _branch_count
	mi.mesh = MorphoPrimitive.sphere(tip_r, 10, 6)
	mi.material_override = _mat_fluoro
	mi.position = pos
	parent.add_child(mi)
	_mesh_count += 1

	# A small raised glowing corallite cup right at the apex, facing outward.
	var cup_basis := _basis_from_up(dir)
	var cup_xf := Transform3D(cup_basis.scaled(Vector3(tip_r * 0.9, tip_r * 0.6, tip_r * 0.9)),
		pos + dir * tip_r * 0.5)
	_cup_xforms_glow.append(cup_xf)
	_corallite_count += 1


# ═══════════════════════════════════════════════════════════════════════════
# CORALLITES — small raised polyp cups studding the branch surface
# ═══════════════════════════════════════════════════════════════════════════

## Walk a branch segment's centreline and place small raised cups on the
## surface, oriented to the local surface normal. Density rises toward the
## thinner (tip) end of the segment. A fraction glow fluorescent.
func _scatter_corallites_along(positions: Array[Vector3], radii: Array[float], depth: int) -> void:
	var n: int = positions.size()
	if n < 2:
		return
	# Cups all along the colony, denser toward the canopy and toward each
	# segment's thin (tip) end so the branches look studded with polyp mouths.
	var per_ring: int = 5 + depth * 2
	for i in range(1, n):
		var seg_a: Vector3 = positions[i - 1]
		var seg_b: Vector3 = positions[i]
		var seg_dir: Vector3 = (seg_b - seg_a)
		if seg_dir.length() < 0.0001:
			continue
		seg_dir = seg_dir.normalized()
		var frame := _basis_from_forward(seg_dir)
		var r_here: float = radii[i]
		# Bias toward tips but keep a healthy scatter near the base too.
		var tip_bias: float = float(i) / float(n - 1)
		var ring_cups: int = int(round(float(per_ring) * lerpf(0.7, 1.4, tip_bias)))
		for k in ring_cups:
			# Random point along this sub-segment and around the circumference.
			var along: float = _rng.randf()
			var center: Vector3 = seg_a.lerp(seg_b, along)
			var ang: float = _rng.randf_range(0.0, TAU)
			var normal: Vector3 = (cos(ang) * frame.x + sin(ang) * frame.z).normalized()
			var surf: Vector3 = center + normal * r_here * 0.90
			# Cup size scales with branch radius but with a floor so trunk cups
			# are still visibly raised bumps.
			var cup_r: float = clampf(r_here * _rng.randf_range(0.22, 0.34), 0.012, 0.04)
			# Orient the cup so its +Y points out along the surface normal,
			# then raise it off the surface so it reads as a corallite bump.
			var cup_basis := _basis_from_up(normal)
			var raised: Vector3 = surf + normal * cup_r * 0.35
			var cup_xf := Transform3D(
				cup_basis.scaled(Vector3(cup_r, cup_r * 0.7, cup_r)),
				raised
			)
			# A minority of polyps fluoresce; more near the tips.
			if _rng.randf() < lerpf(0.08, 0.32, tip_bias):
				_cup_xforms_glow.append(cup_xf)
			else:
				_cup_xforms_skel.append(cup_xf)
			_corallite_count += 1


## Commit the batched corallite cups into two MultiMeshInstance3D nodes
## (skeleton-tinted and fluorescent), each from a low-poly sphere template.
func _flush_corallites(parent: Node3D) -> void:
	var cup_mesh: Mesh = MorphoPrimitive.sphere(1.0, 6, 4)

	if _cup_xforms_skel.size() > 0:
		var skel_xf: Array = []
		for xf in _cup_xforms_skel:
			skel_xf.append(xf)
		var mmi_skel: MultiMeshInstance3D = MorphoPrimitive.multimesh_scatter(cup_mesh, skel_xf)
		mmi_skel.name = "Corallites_skeleton"
		mmi_skel.material_override = _mat_tissue
		parent.add_child(mmi_skel)
		_mesh_count += 1

	if _cup_xforms_glow.size() > 0:
		var glow_xf: Array = []
		for xf in _cup_xforms_glow:
			glow_xf.append(xf)
		var mmi_glow: MultiMeshInstance3D = MorphoPrimitive.multimesh_scatter(cup_mesh, glow_xf)
		mmi_glow.name = "Corallites_fluoro"
		mmi_glow.material_override = _mat_fluoro
		parent.add_child(mmi_glow)
		_mesh_count += 1


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

## A smooth joint blob (sphere) at a fork or base.
func _add_blob(parent: Node3D, pos: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Joint_%d" % _fork_count
	mi.mesh = MorphoPrimitive.sphere(radius, 8, 5)
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	_mesh_count += 1


## Orthonormal Basis whose -Z (forward) aligns with `forward`. Used to spread
## children and place corallites around a branch axis. Built explicitly so we
## never call look_at on a node outside the tree.
func _basis_from_forward(forward: Vector3) -> Basis:
	var f := forward.normalized()
	var right: Vector3
	if absf(f.dot(Vector3.UP)) < 0.99:
		right = f.cross(Vector3.UP).normalized()
	else:
		right = f.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(f).normalized()
	# Columns: x=right, y=up, z=forward.
	return Basis(right, up, f)


## Orthonormal Basis whose +Y (up) aligns with `up_axis`. Used to orient
## corallite cups so they sit raised along the surface normal.
func _basis_from_up(up_axis: Vector3) -> Basis:
	var up := up_axis.normalized()
	var right: Vector3
	if absf(up.dot(Vector3.FORWARD)) < 0.99:
		right = Vector3.FORWARD.cross(up).normalized()
	else:
		right = Vector3.RIGHT.cross(up).normalized()
	var fwd: Vector3 = right.cross(up).normalized()
	return Basis(right, up, fwd)


## Recentre the colony on X/Z so the capture frames the whole thing, and lift
## any geometry that dipped below y=0 back onto the floor.
func _recentre(colony: Node3D) -> void:
	var aabb := _colony_aabb(colony)
	if aabb.size == Vector3.ZERO:
		return
	var center := aabb.get_center()
	colony.position.x -= center.x
	colony.position.z -= center.z
	# Keep the base resting on y=0.
	colony.position.y -= aabb.position.y


func _colony_aabb(node: Node) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var a: AABB = mi.transform * mi.mesh.get_aabb()
			# Walk up to accumulate the local transform relative to `node`.
			var p: Node = mi.get_parent()
			while p != null and p != node:
				if p is Node3D:
					a = (p as Node3D).transform * a
				p = p.get_parent()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child in current.get_children():
			stack.append(child)
	return total


# ═══════════════════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# SKELETON — pale calcite ivory, faint emission floor.
	_mat_skeleton = StandardMaterial3D.new()
	_mat_skeleton.albedo_color = SKELETON_COLOR
	_mat_skeleton.roughness = 0.7
	_mat_skeleton.metallic = 0.0
	_mat_skeleton.emission_enabled = true
	_mat_skeleton.emission = SKELETON_COLOR * 0.4
	_mat_skeleton.emission_energy_multiplier = 0.10

	# TISSUE — warm living coral, subsurface scatter.
	_mat_tissue = StandardMaterial3D.new()
	_mat_tissue.albedo_color = TISSUE_COLOR
	_mat_tissue.roughness = 0.6
	_mat_tissue.metallic = 0.0
	_mat_tissue.subsurf_scatter_enabled = true
	_mat_tissue.subsurf_scatter_strength = 0.25
	_mat_tissue.emission_enabled = true
	_mat_tissue.emission = TISSUE_COLOR * 0.5
	_mat_tissue.emission_energy_multiplier = 0.12

	# FLUORESCENCE — glowing green polyp tips/cups, near-unshaded.
	_mat_fluoro = StandardMaterial3D.new()
	_mat_fluoro.albedo_color = FLUORO_COLOR
	_mat_fluoro.roughness = 0.4
	_mat_fluoro.metallic = 0.0
	_mat_fluoro.emission_enabled = true
	_mat_fluoro.emission = FLUORO_COLOR
	_mat_fluoro.emission_energy_multiplier = 3.0
	_mat_fluoro.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
