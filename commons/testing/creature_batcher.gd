extends RefCounted
class_name CreatureBatcher

## creature_batcher.gd
##
## Post-process step that takes a critter built by CreatureMorphology
## and consolidates groups of similar MeshInstance3D children into
## MultiMeshInstance3Ds — one draw call per group instead of one per
## member.
##
## Goal: cut a fully-built critter from ~80 draw calls down to ~6.
##
## How it works
## ────────────
## CreatureMorphology names each part consistently:
##   "Body_<i>"        spine segments
##   "Limb_<seed>_<j>" every joint of every limb
##   "Tip_<i>"         foot / claw tips
##   "Head"            head dome
##   "Eye_<i>"         eye spheres
##   "Antenna_<i>"     antennae / horns
##   "Tail_<i>"        tail segments
##
## Limbs and tips are by far the bulk (32–64 of each at LOD 2-3). The
## batcher picks the most common mesh shape in each name-prefix bucket
## as the "canonical" mesh, computes per-instance Transform3D from each
## original mesh's global_transform + AABB, then deletes the originals
## and adds one MultiMeshInstance3D.
##
## Materials: the canonical mesh's material_override is reused on the
## MultiMeshInstance3D. This is important — all limbs of one critter
## share one DNA, so they share one trait-mapper shader material; the
## shader runs identically across all instances. (For multi-DNA swarm
## batching see Tier 3 in doc/CRITTER_VR_PLAN.md — different shader
## refactor.)
##
## Caveat: per-instance Transform3D applied as Basis-with-scale gives
## a CYLINDER OF UNIFORM RADIUS along its length. The original
## creature_morphology builds tapered tubes (different start/end
## radii). The batched form averages the two radii. This is a small
## visual loss — limbs look slightly less anatomical. A follow-up
## (Tier 2.5) is a vertex shader that reads INSTANCE_CUSTOM.x as a
## taper factor and scales vertex.xz by lerp(1, taper, vertex.y).


## Run the batcher on a creature_root produced by CreatureMorphology.
## Returns {before: int, after: int, saved: int} draw-call counts.
##
## Tier 2-full — batches three buckets, in order from biggest win to
## smallest:
##   1. Limb_*   segments (32-64 per critter)
##   2. LimbTip_* (8-32 per critter)
##   3. Body_*   segments (3-11 per critter)
##
## Each bucket goes into its own MultiMeshInstance3D using metadata
## stamped by creature_morphology.gd. Materials are pulled from the
## first member of each bucket — all members share one DNA → one
## shader material in this prototype, so it's safe.
##
## Per-bucket caveats:
##   - Limbs: tubes are arbitrarily oriented (along limb_dir), so we
##     need (start, end, radius) metadata. Output is uniform-radius
##     cylinders — taper is averaged.
##   - Tips: position + basis are set on the inst itself. We use a
##     canonical tip mesh and scale per-instance via tip_size.
##     Different tip kinds (claw / fin / pad) get separate buckets
##     because their canonical meshes differ.
##   - Body: spine segments are tubes between two spine positions,
##     same logic as limbs. Body segments alternate primary_color
##     darkening every other segment, which we LOSE in batching —
##     all share one material now. Subtle.
static func batch_critter(creature_root: Node3D) -> Dictionary:
	var before := _count_draw_calls(creature_root)
	_batch_limbs(creature_root)
	_batch_tips(creature_root)
	_batch_bodies(creature_root)
	var after := _count_draw_calls(creature_root)
	return {
		"before": before,
		"after":  after,
		"saved":  before - after,
	}


## Collect all "Limb_*" MeshInstance3Ds under root, read their
## metadata (limb_start, limb_end, limb_radius) to recover the
## limb's actual oriented axis, build a single MultiMesh of unit
## cylinders, and free the originals.
static func _batch_limbs(root: Node3D) -> void:
	# Collect limbs (don't mutate during traversal).
	var limbs: Array[MeshInstance3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).name.begins_with("Limb_"):
			# Only batch limbs that have the metadata — defends against
			# old creature_morphology.gd revisions or other "Limb_"-
			# named meshes that aren't tubes.
			if n.has_meta("limb_start"):
				limbs.append(n as MeshInstance3D)
		for c in n.get_children():
			stack.push_back(c)

	if limbs.size() < 2:
		return

	# Canonical unit cylinder: 1m tall along Y, centred at origin
	# (CylinderMesh default), radius 1. We'll position each instance
	# at the limb's midpoint and scale appropriately.
	var canonical: Mesh = _make_unit_cylinder_mesh()
	var canonical_material: Material = limbs[0].material_override

	# Per-instance data: Transform3D + taper factor (Tier 2.5).
	# Use the START radius for the basis xz scale (so the bottom of
	# the canonical cylinder matches the original tube's bottom),
	# and pack end_radius/start_radius as the taper factor — the
	# shader's vertex stage scales VERTEX.xz from 1.0 at y=-0.5 to
	# `taper` at y=+0.5, recovering the original tapered tube.
	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []
	for m in limbs:
		var start: Vector3 = m.get_meta("limb_start")
		var end:   Vector3 = m.get_meta("limb_end")
		var r0:    float   = m.get_meta("limb_start_radius")
		var r1:    float   = m.get_meta("limb_end_radius")
		var dir: Vector3 = end - start
		var length: float = dir.length()
		if length < 0.001:
			continue
		var axis: Vector3 = dir / length
		var midpoint: Vector3 = (start + end) * 0.5

		var x_axis: Vector3
		if absf(axis.dot(Vector3.UP)) < 0.99:
			x_axis = Vector3.UP.cross(axis).normalized()
		else:
			x_axis = Vector3.RIGHT.cross(axis).normalized()
		var z_axis: Vector3 = x_axis.cross(axis).normalized()
		# xz scale = 2 * START radius (so bottom matches the original).
		# Top will be scaled further by the shader's taper factor.
		var basis := Basis(
			x_axis * r0 * 2.0,
			axis   * length,
			z_axis * r0 * 2.0
		)
		transforms.append(Transform3D(basis, midpoint))
		# Taper = r1 / r0; w=1.0 enables the shader's per-instance
		# transform path.
		var taper: float = r1 / maxf(r0, 0.0001)
		customs.append(Color(taper, 0.0, 0.0, 1.0))

	if transforms.is_empty():
		return

	# Build MultiMesh.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.use_custom_data = true       # Tier 2.5 — per-instance taper.
	mm.mesh = canonical
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, customs[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Limbs_Multimesh"
	mmi.multimesh = mm
	if canonical_material:
		mmi.material_override = canonical_material
	root.add_child(mmi)

	for m in limbs:
		var parent := m.get_parent()
		if parent:
			parent.remove_child(m)
		m.free()


## Same shape as _batch_limbs but for body spine segments. Body tubes
## are oriented along the spine curve — also need metadata to recover.
static func _batch_bodies(root: Node3D) -> void:
	var bodies: Array[MeshInstance3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).name.begins_with("Body_"):
			if n.has_meta("body_start"):
				bodies.append(n as MeshInstance3D)
		for c in n.get_children():
			stack.push_back(c)

	if bodies.size() < 2:
		return

	var canonical: Mesh = _make_unit_cylinder_mesh()
	var canonical_material: Material = bodies[0].material_override

	# Tier 2.5: per-instance taper + alternating-darkness tint.
	# The original creature_morphology darkens odd-indexed segments
	# by 0.08 (line 162). We pack that into INSTANCE_COLOR so the
	# fragment shader's `base_color *= v_instance_color.rgb` reproduces
	# the alternation across all body instances sharing one MultiMesh.
	var transforms: Array[Transform3D] = []
	var customs: Array[Color] = []
	var colors: Array[Color] = []
	for m in bodies:
		var start: Vector3 = m.get_meta("body_start")
		var end:   Vector3 = m.get_meta("body_end")
		var r0:    float   = m.get_meta("body_start_radius")
		var r1:    float   = m.get_meta("body_end_radius")
		var idx:   int     = m.get_meta("body_index")
		var dir: Vector3 = end - start
		var length: float = dir.length()
		if length < 0.001:
			continue
		var axis: Vector3 = dir / length
		var midpoint: Vector3 = (start + end) * 0.5
		var x_axis: Vector3
		if absf(axis.dot(Vector3.UP)) < 0.99:
			x_axis = Vector3.UP.cross(axis).normalized()
		else:
			x_axis = Vector3.RIGHT.cross(axis).normalized()
		var z_axis: Vector3 = x_axis.cross(axis).normalized()
		var basis := Basis(
			x_axis * r0 * 2.0,
			axis   * length,
			z_axis * r0 * 2.0
		)
		transforms.append(Transform3D(basis, midpoint))
		var taper: float = r1 / maxf(r0, 0.0001)
		customs.append(Color(taper, 0.0, 0.0, 1.0))
		# Alternating darkness — odd segments get 0.92x tint to match
		# the original creature_morphology's `darkened(0.08)`.
		var tint: float = 0.92 if (idx % 2 == 1) else 1.0
		colors.append(Color(tint, tint, tint, 1.0))

	if transforms.is_empty():
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true            # Tier 2.5 — alternating tint.
	mm.use_custom_data = true       # Tier 2.5 — per-instance taper.
	mm.mesh = canonical
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
		mm.set_instance_custom_data(i, customs[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Body_Multimesh"
	mmi.multimesh = mm
	if canonical_material:
		mmi.material_override = canonical_material
	root.add_child(mmi)

	for m in bodies:
		var parent := m.get_parent()
		if parent:
			parent.remove_child(m)
		m.free()


## Tips have their own (position, basis) set as the MeshInstance3D's
## transform — we don't need start/end metadata. But their mesh
## SHAPE varies by `tip_kind` (claw / fin / pad), so we group by kind
## and produce one MultiMesh per kind. Within one critter, tip_kind is
## DNA-determined, so usually all tips share one kind → one MultiMesh.
static func _batch_tips(root: Node3D) -> void:
	# Group tips by kind.
	var by_kind: Dictionary = {}  # kind -> Array[MeshInstance3D]
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).name.begins_with("LimbTip_"):
			if n.has_meta("tip_kind"):
				var kind: String = n.get_meta("tip_kind")
				if not by_kind.has(kind):
					by_kind[kind] = []
				(by_kind[kind] as Array).append(n)
		for c in n.get_children():
			stack.push_back(c)

	for kind in by_kind:
		var tips: Array = by_kind[kind] as Array
		if tips.size() < 2:
			continue

		# Use the first tip's mesh as canonical (all tips of one kind
		# share the same mesh shape). Per-instance scale comes from
		# tip_size relative to the first tip's tip_size.
		var first_tip: MeshInstance3D = tips[0] as MeshInstance3D
		var canonical_mesh: Mesh = first_tip.mesh
		var canonical_material: Material = first_tip.material_override
		var canonical_size: float = float(first_tip.get_meta("tip_size"))

		var transforms: Array[Transform3D] = []
		for t in tips:
			var inst: MeshInstance3D = t as MeshInstance3D
			var size: float = float(inst.get_meta("tip_size"))
			# inst.transform already has position + basis. Per-instance
			# scale = size / canonical_size. Apply by post-multiplying
			# the transform's basis with a uniform scale.
			var s: float = size / maxf(canonical_size, 0.0001)
			var scaled: Transform3D = inst.transform.scaled_local(Vector3(s, s, s))
			transforms.append(scaled)

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = canonical_mesh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Tips_%s_Multimesh" % kind
		mmi.multimesh = mm
		if canonical_material:
			mmi.material_override = canonical_material
		root.add_child(mmi)

		for t in tips:
			var inst: MeshInstance3D = t as MeshInstance3D
			var parent := inst.get_parent()
			if parent:
				parent.remove_child(inst)
			inst.free()


## Count draw calls under root. Each MeshInstance3D = 1 call. Each
## MultiMeshInstance3D = 1 call regardless of instance count.
static func _count_draw_calls(root: Node) -> int:
	var n: int = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			if (node as MeshInstance3D).mesh != null:
				n += 1
		elif node is MultiMeshInstance3D:
			if (node as MultiMeshInstance3D).multimesh != null:
				n += 1
		for c in node.get_children():
			stack.push_back(c)
	return n


## Build a unit cylinder: 1m tall along +Y, radius 1, origin at the
## bottom (matches CreatureMorphology's tube convention). Returns a
## CylinderMesh with low-poly cross section so per-instance scale
## doesn't introduce heavy vertex cost.
static func _make_unit_cylinder_mesh() -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 1.0
	c.radial_segments = 6
	c.rings = 1
	# CylinderMesh origins at the centre, but we want the bottom at
	# y=0 so per-instance scale.y = length lifts the top to y=length.
	# We'll bake a translation into the unit mesh by wrapping it in an
	# ArrayMesh (later) — for the prototype, leave centred and accept
	# a half-length offset at each instance's Transform3D. Caller can
	# adjust by translating Transform3D origin up by length*0.5.
	# (TODO: bake a base-anchored cylinder via SurfaceTool.)
	return c
