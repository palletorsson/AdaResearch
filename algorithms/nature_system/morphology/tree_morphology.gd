# TreeMorphology.gd — Generates tree meshes from CritterDNA via L-system
#
# Uses the existing LSystem class (utils/lsystem.gd) to produce a rewrite
# string, then interprets it with a 3D turtle that emits MeshInstance3D
# tube segments. Leaves are batched into a single MultiMeshInstance3D
# for efficient rendering. All parameters are derived from CritterDNA
# genes so every tree is unique and breedable.
#
# DNA → L-system mapping:
#   body_type ≈ 0  → tree form (this generator)
#   segments       → L-system generations (2–5)
#   symmetry       → branches per fork (2–5)
#   branch_angle   → turtle rotation angle (15°–90°)
#   branch_decay   → radius & length taper per generation
#   leaf_density   → leaf probability at tips
#   part_length    → trunk segment length
#   part_width     → trunk radius
#   part_curve     → gravity droop / tropism
#   part_twist     → spiral twist per segment
#   phyllotaxis    → arrangement pattern (spiral vs opposite vs whorled)
#   root_type      → root visibility & style
#   inflorescence  → fruit/flower clustering at branch tips
#
# Architecture mirrors FlowerMorphology: static methods, RefCounted,
# returns Node3D tree under parent. Materials via CritterTraitMapper.

class_name TreeMorphology
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  LOD configuration
# ─────────────────────────────────────────────────────────────
const LOD_TUBE_SIDES := [3, 4, 6, 8]       # Cross-section resolution per LOD
const LOD_MAX_BRANCHES := [30, 80, 200, 500]  # Branch count cap per LOD
const LOD_LEAF_SKIP := [4, 2, 1, 1]          # Only place every Nth leaf


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Build a complete tree under `parent` from `dna`.
## Returns the root Node3D containing all tree geometry.
static func build(dna: CritterDNA, parent: Node3D, trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	var tree_root := Node3D.new()
	tree_root.name = "Tree"
	parent.add_child(tree_root)

	lod = clampi(lod, 0, 3)

	# ── Derive L-system parameters from DNA ──
	var params: Dictionary = _dna_to_lsystem_params(dna)

	# ── Generate L-system string ──
	var lsys: LSystem = _create_lsystem_from_dna(dna, params)
	var sentence: String = lsys.get_sentence()

	# ── Interpret with 3D turtle → mesh nodes ──
	_interpret_turtle(sentence, dna, params, tree_root, trait_mapper, lod)

	# ── Roots (below ground) ──
	if dna.root_type > 0.2:
		_build_roots(dna, tree_root, trait_mapper, lod)

	return tree_root


# ═══════════════════════════════════════════════════════════════
# DNA → L-SYSTEM PARAMETER EXTRACTION
# ═══════════════════════════════════════════════════════════════

## All turtle parameters derived from CritterDNA, bundled in a Dictionary
## for easy passing through the interpreter.
static func _dna_to_lsystem_params(dna: CritterDNA) -> Dictionary:
	# Generations: segments gene maps to L-system depth (2-5)
	var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)

	# Branching angle from DNA (already in degrees)
	var angle_deg: float = dna.branch_angle

	# Step length: trunk segment size, affected by scale
	var step_length: float = dna.part_length * dna.scale * 0.3

	# Radius: initial trunk radius from part_width
	var start_radius: float = dna.part_width * dna.scale * 0.08

	# Taper: how much radius shrinks per generation
	var radius_taper: float = dna.branch_decay

	# Length taper: branches get shorter
	var length_taper: float = dna.branch_decay * 0.9 + 0.05

	# Gravity / tropism: part_curve makes branches droop
	var tropism: float = dna.part_curve * 0.3

	# Twist per segment
	var twist_per_segment: float = dna.part_twist

	# Leaf probability at branch tips
	var leaf_chance: float = dna.leaf_density

	# Branches per fork based on symmetry
	var fork_count: int = clampi(roundi(dna.symmetry), 2, 5)

	# Phyllotaxis affects rotation between branches
	# 0 = spiral (golden angle), 0.5 = opposite (180°), 1.0 = whorled (equal)
	var phyllotaxis_mode: float = dna.phyllotaxis

	return {
		"generations": generations,
		"angle_deg": angle_deg,
		"step_length": step_length,
		"start_radius": start_radius,
		"radius_taper": radius_taper,
		"length_taper": length_taper,
		"tropism": tropism,
		"twist_per_segment": twist_per_segment,
		"leaf_chance": leaf_chance,
		"fork_count": fork_count,
		"phyllotaxis_mode": phyllotaxis_mode,
	}


# ═══════════════════════════════════════════════════════════════
# L-SYSTEM CREATION — build rules from DNA
# ═══════════════════════════════════════════════════════════════

## Create an LSystem instance with rules derived from the DNA.
## Instead of using a fixed preset, we build rules that encode
## the DNA's branching structure.
static func _create_lsystem_from_dna(dna: CritterDNA, params: Dictionary) -> LSystem:
	var fork_count: int = params["fork_count"] as int
	var phyllotaxis: float = params["phyllotaxis_mode"] as float

	# Build the branch replacement rule for 'F'
	# Basic pattern: F grows, then forks into branches
	var branch_rule: String = "S"  # S = draw short segment (tapered)

	# Build fork pattern based on symmetry and phyllotaxis
	var fork_pattern: String = ""
	for i in fork_count:
		var rotation: String = _get_branch_rotation(i, fork_count, phyllotaxis)
		fork_pattern += "[%sF]" % rotation

	# The main rule: grow trunk, then fork
	# F → S + [fork branches]
	var f_rule: String = "S" + fork_pattern

	# Trunk extension rule: S grows into longer segment
	var s_rule: String = "FF"

	# Leaf rule: L produces a leaf marker (interpreted by turtle)
	# At tips, F may also produce leaves

	var lsys := LSystem.new("F")
	lsys.add_rule("F", f_rule)
	lsys.add_rule("S", s_rule)

	# Generate for the specified number of generations
	lsys.generate_n(params["generations"] as int)

	return lsys


## Get the rotation symbols for the i-th branch in a fork of `count` branches.
## Phyllotaxis mode controls the arrangement:
##   0.0 = spiral (golden angle offsets)
##   0.5 = opposite (alternating ±)
##   1.0 = whorled (evenly distributed)
static func _get_branch_rotation(index: int, count: int, phyllotaxis: float) -> String:
	var rotation: String = ""

	if phyllotaxis < 0.33:
		# SPIRAL — golden angle rotation between branches
		# Use pitch and yaw to create spiral
		var golden_frac: float = fmod(float(index) * 137.508, 360.0)
		var yaw_steps: int = roundi(golden_frac / 30.0)
		var pitch_up: bool = index % 2 == 0

		# Yaw: series of + or - turns
		for _j in absi(yaw_steps):
			rotation += "/" if yaw_steps > 0 else "\\"

		# Pitch: alternate up and down
		rotation += "&" if pitch_up else "^"

	elif phyllotaxis < 0.66:
		# OPPOSITE — branches in opposing pairs
		if index % 2 == 0:
			rotation += "+"
			# Roll for 3D variation
			for _j in (index / 2):
				rotation += "/"
		else:
			rotation += "-"
			for _j in ((index - 1) / 2):
				rotation += "/"

	else:
		# WHORLED — evenly spaced around axis
		var roll_steps: int = roundi(float(index) / float(count) * 8.0)
		for _j in roll_steps:
			rotation += "/"
		rotation += "&"  # Pitch outward

	return rotation


# ═══════════════════════════════════════════════════════════════
# TURTLE INTERPRETER — L-system string → mesh nodes
# ═══════════════════════════════════════════════════════════════

## Interpret an L-system sentence with a 3D turtle, emitting
## MeshInstance3D segments for each 'F' or 'S' command.
## Leaf placements are collected and batched into a single MultiMeshInstance3D.
static func _interpret_turtle(sentence: String, dna: CritterDNA, params: Dictionary,
		root: Node3D, mapper: CritterTraitMapper, lod: int) -> void:

	var tube_sides: int = LOD_TUBE_SIDES[lod]
	var max_branches: int = LOD_MAX_BRANCHES[lod]
	var leaf_skip: int = LOD_LEAF_SKIP[lod]

	var angle_rad: float = deg_to_rad(params["angle_deg"] as float)
	var tropism: float = params["tropism"] as float
	var twist_rad: float = deg_to_rad(params["twist_per_segment"] as float)
	var leaf_chance: float = params["leaf_chance"] as float

	# Turtle state
	var pos: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3.UP        # Trees grow upward
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3.BACK       # Initial "forward" for the tree
	var radius: float = params["start_radius"] as float
	var seg_length: float = params["step_length"] as float

	# Stack for branching
	var stack: Array = []

	var branch_count: int = 0
	var segment_count: int = 0  # For unique seeds
	var leaf_counter: int = 0
	var depth: int = 0          # Current recursion depth for taper

	var base_seed: int = root.get_instance_id()

	# Leaf collection for MultiMesh batching
	var leaf_placements: Array[Dictionary] = []

	# Track tip positions for leaf placement
	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	for ci in sentence.length():
		if branch_count >= max_branches:
			break

		var ch: String = sentence[ci]
		match ch:
			"F":
				# Move forward and draw a thick tube (primary branch)
				var end_pos: Vector3 = pos + dir * seg_length
				# Apply tropism (gravity droop)
				end_pos.y -= tropism * seg_length * 0.5

				_add_branch_segment(dna, root, mapper, base_seed + segment_count,
					pos, end_pos, radius, radius * (params["radius_taper"] as float),
					tube_sides, depth)

				pos = end_pos
				radius *= params["radius_taper"] as float
				seg_length *= params["length_taper"] as float
				branch_count += 1
				segment_count += 1

				# Apply twist
				if absf(twist_rad) > 0.001:
					right = (right * cos(twist_rad) + up * sin(twist_rad)).normalized()
					up = right.cross(dir).normalized()

			"S":
				# Short segment (trunk extension) — same as F but shorter
				var short_length: float = seg_length * 0.6
				var end_pos: Vector3 = pos + dir * short_length
				end_pos.y -= tropism * short_length * 0.3

				_add_branch_segment(dna, root, mapper, base_seed + segment_count,
					pos, end_pos, radius, radius * 0.95,  # Minimal taper for trunk
					tube_sides, depth)

				pos = end_pos
				radius *= 0.95
				branch_count += 1
				segment_count += 1

			"+":
				# Yaw right
				dir = (dir * cos(angle_rad) + right * sin(angle_rad)).normalized()
				right = dir.cross(up).normalized()

			"-":
				# Yaw left
				dir = (dir * cos(angle_rad) - right * sin(angle_rad)).normalized()
				right = dir.cross(up).normalized()

			"&":
				# Pitch down
				dir = (dir * cos(angle_rad) + up * sin(angle_rad)).normalized()
				up = right.cross(dir).normalized()

			"^":
				# Pitch up
				dir = (dir * cos(angle_rad) - up * sin(angle_rad)).normalized()
				up = right.cross(dir).normalized()

			"/":
				# Roll clockwise
				right = (right * cos(angle_rad) + up * sin(angle_rad)).normalized()
				up = right.cross(dir).normalized()

			"\\":
				# Roll counter-clockwise
				right = (right * cos(angle_rad) - up * sin(angle_rad)).normalized()
				up = right.cross(dir).normalized()

			"|":
				# Turn around 180°
				dir = -dir
				right = -right

			"[":
				# Push state — entering a branch
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"radius": radius,
					"length": seg_length,
					"depth": depth,
				})
				depth += 1

			"]":
				# Pop state — returning from a branch
				# Before popping, potentially collect a leaf placement at the tip
				if leaf_chance > 0.1 and rng.randf() < leaf_chance:
					leaf_counter += 1
					if leaf_counter % leaf_skip == 0:
						_collect_leaf_placements(dna, base_seed + segment_count + 10000,
							pos, dir, radius, lod, leaf_placements)

				# Also place fruit/flowers at tips if inflorescence > 0
				if dna.inflorescence > 0.3 and depth >= (params["generations"] as int) - 1:
					if rng.randf() < dna.inflorescence * 0.5:
						_add_tip_cluster(dna, root, mapper, base_seed + segment_count + 20000,
							pos, dir, radius, lod)

				if stack.size() > 0:
					var state: Dictionary = stack.pop_back() as Dictionary
					pos = state["pos"] as Vector3
					dir = state["dir"] as Vector3
					right = state["right"] as Vector3
					up = state["up"] as Vector3
					radius = state["radius"] as float
					seg_length = state["length"] as float
					depth = state["depth"] as int

			"!":
				# Decrease radius
				radius *= 0.7

	# Collect final leaf at the last turtle position
	if leaf_chance > 0.3 and branch_count > 0:
		_collect_leaf_placements(dna, base_seed + 99999, pos, dir, radius, lod, leaf_placements)

	# Batch all leaves into a single MultiMeshInstance3D
	if leaf_placements.size() > 0:
		_build_leaf_multimesh(dna, root, mapper, base_seed, leaf_placements, lod)


# ═══════════════════════════════════════════════════════════════
# BRANCH SEGMENT — tapered tube from SurfaceTool
# ═══════════════════════════════════════════════════════════════

## Create a single branch tube segment as a MeshInstance3D.
static func _add_branch_segment(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, start: Vector3, end: Vector3,
		start_radius: float, end_radius: float,
		sides: int, depth: int) -> void:

	var forward: Vector3 = end - start
	var length: float = forward.length()
	if length < 0.001:
		return
	forward = forward.normalized()

	# Build coordinate frame
	var right: Vector3
	if absf(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(forward).normalized()

	# Build tube mesh with SurfaceTool
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: int = 2  # Two rings per segment (start and end)

	var ring_verts: Array = []  # Array of Array[Vector3]

	for ri in rings:
		var t: float = float(ri) / float(rings - 1)
		var pos: Vector3 = start.lerp(end, t)
		var radius: float = lerpf(start_radius, end_radius, t)

		var ring: Array = []
		for si in sides:
			var angle: float = TAU * float(si) / float(sides)
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * radius
			ring.append(pos + offset)
		ring_verts.append(ring)

	# Connect rings with triangles
	for ri in range(rings - 1):
		var ring_a: Array = ring_verts[ri] as Array
		var ring_b: Array = ring_verts[ri + 1] as Array
		for si in range(sides):
			var si_next: int = (si + 1) % sides

			var v00: Vector3 = ring_a[si] as Vector3
			var v01: Vector3 = ring_a[si_next] as Vector3
			var v10: Vector3 = ring_b[si] as Vector3
			var v11: Vector3 = ring_b[si_next] as Vector3

			var t0: float = float(ri) / float(rings - 1)
			var t1: float = float(ri + 1) / float(rings - 1)
			var s0: float = float(si) / float(sides)
			var s1: float = float(si + 1) / float(sides)

			# Triangle 1
			var n1: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1); st.set_uv(Vector2(s0, t0)); st.add_vertex(v00)
			st.set_normal(n1); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n1); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)

			# Triangle 2
			var n2: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n2); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)
			st.set_normal(n2); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n2); st.set_uv(Vector2(s1, t1)); st.add_vertex(v11)

	st.generate_normals()
	var mesh: Mesh = st.commit()

	if not mesh:
		return

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Branch_%d" % seed_val
	mesh_inst.mesh = mesh

	# Material: bark color (secondary), rougher at depth 0, smoother at tips
	var mat := mapper.create_material_from_dna(dna, seed_val)
	# Bark uses secondary color as base
	mat.set_shader_parameter("primary_color", dna.secondary_color.darkened(depth * 0.05))
	mat.set_shader_parameter("secondary_color", dna.secondary_color.darkened(0.2 + depth * 0.05))
	# Higher roughness for bark
	mat.set_shader_parameter("roughness", clampf(dna.roughness + 0.2, 0.4, 1.0))
	# Bark pattern: low-frequency noise or cracking
	mat.set_shader_parameter("pattern_density", 0.3 + dna.cracking * 0.5)
	mapper.apply_variation(mat, seed_val)
	mesh_inst.material_override = mat

	root.add_child(mesh_inst)


# ═══════════════════════════════════════════════════════════════
# LEAVES — placed at branch tips
# ═══════════════════════════════════════════════════════════════

## Collect leaf placement data at a branch tip (for later MultiMesh batching).
## Each leaf in the cluster becomes one entry in the placements array.
static func _collect_leaf_placements(dna: CritterDNA, seed_val: int,
		pos: Vector3, _dir: Vector3, branch_radius: float, lod: int,
		placements: Array[Dictionary]) -> void:

	# Leaf size relative to branch radius and DNA scale
	var leaf_size: float = branch_radius * 3.0 + 0.02 * dna.scale
	var leaf_count: int = clampi(roundi(dna.leaf_density * 4.0), 1, 6)

	if lod <= 1:
		leaf_count = 1  # Fewer leaves at low LOD

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for i in leaf_count:
		# Position: spread around the tip
		var offset: Vector3 = Vector3(
			rng.randf_range(-leaf_size, leaf_size),
			rng.randf_range(-leaf_size * 0.3, leaf_size * 0.5),
			rng.randf_range(-leaf_size, leaf_size)
		)
		var leaf_pos: Vector3 = pos + offset

		# Rotation: point roughly along branch direction with variation
		var leaf_rot: Vector3 = Vector3(
			rng.randf_range(-0.5, 0.5),
			rng.randf_range(0.0, TAU),
			rng.randf_range(-0.3, 0.3)
		)

		# Per-leaf color drift
		var drift_r: float = rng.randf_range(-0.04, 0.04)
		var drift_g: float = rng.randf_range(-0.04, 0.04)
		var drift_b: float = rng.randf_range(-0.04, 0.04)

		# Per-leaf pattern rotation (0-1 → 0-TAU in shader)
		var pattern_rot: float = rng.randf()

		placements.append({
			"position": leaf_pos,
			"rotation": leaf_rot,
			"size": leaf_size,
			"color_drift_r": drift_r,
			"color_drift_g": drift_g,
			"color_drift_b": drift_b,
			"pattern_rot": pattern_rot,
		})


## Build a MultiMeshInstance3D containing all leaves from collected placements.
static func _build_leaf_multimesh(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		base_seed: int, placements: Array[Dictionary], lod: int) -> void:

	var leaf_mesh: Mesh = _create_leaf_mesh(dna, lod)
	var count: int = placements.size()
	if count == 0:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = leaf_mesh
	mm.instance_count = count  # Must be set AFTER mesh/format/flags

	for i in count:
		var p: Dictionary = placements[i]
		var leaf_pos: Vector3 = p["position"] as Vector3
		var leaf_rot: Vector3 = p["rotation"] as Vector3
		var leaf_size: float = p["size"] as float

		var basis := Basis.from_euler(leaf_rot)
		basis = basis.scaled(Vector3.ONE * leaf_size)
		mm.set_instance_transform(i, Transform3D(basis, leaf_pos))

		# Per-leaf color tint (drift around white = neutral)
		var drift_r: float = p["color_drift_r"] as float
		var drift_g: float = p["color_drift_g"] as float
		var drift_b: float = p["color_drift_b"] as float
		mm.set_instance_color(i, Color(
			clampf(1.0 + drift_r, 0.0, 1.1),
			clampf(1.0 + drift_g, 0.0, 1.1),
			clampf(1.0 + drift_b, 0.0, 1.1),
			1.0
		))

		# Per-leaf pattern rotation in custom data
		mm.set_instance_custom_data(i, Color(p["pattern_rot"] as float, 0.0, 0.0, 0.0))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Leaves"
	mmi.multimesh = mm

	# Shared leaf material: primary color (foliage)
	var mat: ShaderMaterial = mapper.create_material_from_dna(dna, base_seed + 80000)
	mat.set_shader_parameter("primary_color", dna.primary_color)
	mat.set_shader_parameter("secondary_color", dna.primary_color.darkened(0.15))
	mat.set_shader_parameter("roughness", clampf(dna.roughness - 0.2, 0.05, 0.6))
	if dna.transparency > 0.1:
		mat.set_shader_parameter("transparency", dna.transparency * 0.5)
	mmi.material_override = mat

	root.add_child(mmi)


## Create a canonical leaf mesh (unit-size, to be scaled per instance).
## High LOD: flat quad with curvature. Low LOD: simple sphere billboard.
static func _create_leaf_mesh(dna: CritterDNA, lod: int) -> Mesh:
	if lod < 2:
		# Low LOD: simple sphere billboard
		var sphere := SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 4
		sphere.rings = 2
		return sphere

	# High LOD: flat quad leaf with curvature (unit-size)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segments_along: int = 3 if lod >= 3 else 2
	var segments_across: int = 2

	var curvature: float = dna.part_curve * 0.3
	var width: float = 0.3 + dna.part_width * 0.4  # Unit-size proportions

	# Leaf shape: tapered ellipse
	for zi in segments_along:
		for xi in segments_across:
			var zt: float = float(zi) / float(segments_along - 1)
			var xt: float = float(xi) / float(segments_across - 1)

			# Width taper: leaf shape (widest at 40%, pointed at tip)
			var width_at_z: float = sin(PI * zt) * width
			if zt > 0.6:
				width_at_z *= (1.0 - (zt - 0.6) / 0.4)  # Taper to point

			var x: float = (xt - 0.5) * width_at_z * 2.0
			var y: float = curvature * sin(PI * xt) * sin(PI * zt) * 0.1
			var z: float = zt

			st.set_uv(Vector2(xt, zt))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x, y, z))

	# Index the triangles
	for zi in range(segments_along - 1):
		for xi in range(segments_across - 1):
			var base_idx: int = zi * segments_across + xi
			var next_row: int = base_idx + segments_across

			st.add_index(base_idx)
			st.add_index(next_row)
			st.add_index(base_idx + 1)

			st.add_index(base_idx + 1)
			st.add_index(next_row)
			st.add_index(next_row + 1)

	st.generate_normals()
	st.generate_tangents()

	var mesh: Mesh = st.commit()
	if not mesh:
		# Fallback
		var fallback := SphereMesh.new()
		fallback.radius = 0.5
		fallback.height = 1.0
		return fallback

	return mesh


# ═══════════════════════════════════════════════════════════════
# TIP CLUSTERS — fruit/flowers at branch ends (inflorescence gene)
# ═══════════════════════════════════════════════════════════════

## Add a small fruit/flower cluster at a branch tip.
## When inflorescence > 0.3, trees can bear flowers or fruit at tips.
static func _add_tip_cluster(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, pos: Vector3, dir: Vector3, branch_radius: float, lod: int) -> void:

	var cluster_size: float = branch_radius * 2.0 + 0.01 * dna.scale
	var cluster_count: int = clampi(roundi(dna.inflorescence * 4.0), 1, 5)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for i in cluster_count:
		var sphere := SphereMesh.new()
		sphere.radius = cluster_size * rng.randf_range(0.5, 1.0)
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 4 + lod * 2
		sphere.rings = 2 + lod

		var inst := MeshInstance3D.new()
		inst.name = "Fruit_%d_%d" % [seed_val, i]
		inst.mesh = sphere
		inst.position = pos + Vector3(
			rng.randf_range(-cluster_size, cluster_size),
			rng.randf_range(-cluster_size * 0.3, cluster_size),
			rng.randf_range(-cluster_size, cluster_size)
		)

		# Fruit/flower uses tertiary color (accent)
		var mat := mapper.create_material_from_dna(dna, seed_val + i * 200)
		mat.set_shader_parameter("primary_color", dna.tertiary_color)
		mat.set_shader_parameter("secondary_color", dna.tertiary_color.lightened(0.15))
		mat.set_shader_parameter("roughness", 0.3)
		# Slight emission for ripe fruit
		if dna.nectar_quality > 0.5:
			mat.set_shader_parameter("emission_energy", dna.nectar_quality * 0.2)
		mapper.apply_variation(mat, seed_val + i * 33)
		inst.material_override = mat

		root.add_child(inst)


# ═══════════════════════════════════════════════════════════════
# ROOTS — below-ground structure from root_type gene
# ═══════════════════════════════════════════════════════════════

## Build visible root structures emerging from the trunk base.
## root_type: 0=none/fibrous 0.3=surface roots 0.6=buttress 1.0=aerial/deep
static func _build_roots(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper, lod: int) -> void:
	var base_seed: int = root.get_instance_id() + 50000
	var root_count: int = clampi(roundi(dna.symmetry + 1), 3, 8)
	var root_length: float = dna.part_length * dna.scale * 0.4
	var root_radius: float = dna.part_width * dna.scale * 0.04
	var tube_sides: int = LOD_TUBE_SIDES[lod]

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	for i in root_count:
		var angle: float = TAU * float(i) / float(root_count) + rng.randf_range(-0.2, 0.2)

		# Root direction: outward and downward
		var root_dir: Vector3 = Vector3(cos(angle), -0.5 - dna.root_type * 0.8, sin(angle)).normalized()
		var end_pos: Vector3 = root_dir * root_length

		# Slightly curved root path
		var mid_pos: Vector3 = root_dir * root_length * 0.5
		mid_pos.y *= 0.6  # Less deep at midpoint for surface roots

		if dna.root_type > 0.6:
			# Buttress roots: stay more above ground
			mid_pos.y = minf(mid_pos.y, -0.02)

		_add_branch_segment(dna, root, mapper, base_seed + i,
			Vector3.ZERO, mid_pos, root_radius, root_radius * 0.8,
			tube_sides, 0)

		_add_branch_segment(dna, root, mapper, base_seed + i + 1000,
			mid_pos, end_pos, root_radius * 0.8, root_radius * 0.3,
			tube_sides, 1)


