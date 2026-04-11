# MorphoPipeline.gd — Composable form recipe for the universal morphology engine
#
# A pipeline chains: skeleton → surface → modifiers → instancing → children (recursive).
# This is the grammar of form:
#
#   Form = Skeleton -> Surface -> Modifier* -> Instance? -> Material
#        | Primitive -> Modifier* -> Material
#        | Form + Form  (composition via children)
#
# Pipelines can be:
#   1. Generated from CritterDNA via build_from_dna() (the DNA encodes process genes)
#   2. Hand-authored as Resources for specific artifacts
#   3. Composed at runtime by stacking stages
#
# The children field makes it recursive — a tree trunk pipeline has branch children,
# which have leaf children. This captures the vast majority of biological forms.

class_name MorphoPipeline
extends Resource

# ── Skeleton type ─────────────────────────────────────────────
enum SkeletonType { NONE, SPINE, LSYSTEM, SPIRAL, COLONIZATION }

# ── Surface type ──────────────────────────────────────────────
enum SurfaceType { SWEEP, REVOLUTION, SDF, PRIMITIVE, PARTICLE }

# ── Primitive mesh type (when SurfaceType == PRIMITIVE) ───────
enum PrimitiveType { SPHERE, CYLINDER, BOX, TORUS, CAPSULE, PRISM, QUAD, CONE, PLANE }

# ── Child attachment point ────────────────────────────────────
enum Attachment { ALONG_SKELETON, AT_TIPS, ON_SURFACE, AT_ORIGIN }

# ── Form process taxonomy ─────────────────────────────────────
enum FormProcess { GROWN, EXTRUDED, CARVED, FOLDED, CRYSTALLIZED, DISSOLVED, ASSEMBLED, INSTANCED }


# ═══════════════════════════════════════════════════════════════
# PIPELINE STAGES
# ═══════════════════════════════════════════════════════════════

@export var skeleton_type: SkeletonType = SkeletonType.NONE
@export var surface_type: SurfaceType = SurfaceType.SWEEP
@export var primitive_type: PrimitiveType = PrimitiveType.SPHERE

# Skeleton parameters
@export var spine_points: int = 4           ## Number of points along spine
@export var spine_curvature: float = 0.0    ## How much the spine curves
@export var spine_length: float = 1.0       ## Total length of spine

# Surface parameters
@export var sides: int = 8                  ## Cross-section resolution
@export var start_radius: float = 0.1       ## Radius at start
@export var end_radius: float = 0.05        ## Radius at end
@export var profile: Array = []             ## For revolution: Array of Vector2

# Modifier stack (applied in order)
@export var modifier_stack: Array[Dictionary] = []
## Each entry: { "type": "taper"|"twist"|"bend"|"noise"|"inflate"|"wave"|"spherize"|"axis_scale",
##               "params": { ... modifier-specific parameters ... } }

# Instance rule
@export var instance_count: int = 0         ## 0 = no instancing
@export var instance_arrangement: int = 0   ## 0=radial, 1=along_skeleton, 2=scatter
@export var instance_symmetry: int = 1      ## Copies around axis

# Children (recursive sub-pipelines)
@export var children: Array[Resource] = []  ## Array of MorphoPipeline
@export var child_attachment: Attachment = Attachment.AT_TIPS
@export var child_per_parent: int = 1       ## How many children per attachment point


# ═══════════════════════════════════════════════════════════════
# BUILD — Execute the pipeline, return a Node3D with mesh(es)
# ═══════════════════════════════════════════════════════════════

func build(parent: Node3D, lod: int = 2) -> Node3D:
	var root := Node3D.new()
	root.name = "PipelineForm"
	parent.add_child(root)

	# Step 1: Generate skeleton (positions + radii along the path)
	var positions: Array = []
	var radii: Array = []
	_generate_skeleton(positions, radii)

	# Step 2: Generate surface mesh from skeleton
	var mesh: Mesh = _generate_surface(positions, radii, lod)
	if mesh == null:
		return root

	# Step 3: Apply modifier stack
	for mod_def in modifier_stack:
		var modified: Mesh = _apply_modifier(mesh, mod_def)
		if modified != null:
			mesh = modified

	# Step 4: Create MeshInstance3D or MultiMeshInstance3D
	if instance_count > 1:
		_create_instanced(root, mesh)
	else:
		var mi := MeshInstance3D.new()
		mi.name = "FormMesh"
		mi.mesh = mesh
		root.add_child(mi)

	# Step 5: Recurse into children
	for child_res in children:
		if child_res is MorphoPipeline:
			var child_pipeline: MorphoPipeline = child_res as MorphoPipeline
			var attachment_points: Array = _get_attachment_points(positions)
			for point in attachment_points:
				var anchor := Node3D.new()
				anchor.position = point as Vector3
				root.add_child(anchor)
				for _ci in child_per_parent:
					child_pipeline.build(anchor, lod)

	return root


# ═══════════════════════════════════════════════════════════════
# DNA → PIPELINE — Generate a pipeline from CritterDNA process genes
# ═══════════════════════════════════════════════════════════════

## Build a Node3D from CritterDNA using the universal pipeline.
## This is called by MorphologyRouter when body_type > 4.0 or
## when form_process genes are explicitly non-default.
static func build_from_dna(dna: CritterDNA, parent: Node3D,
		_trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:

	var pipeline := MorphoPipeline.new()

	# Map form_process gene to skeleton + surface types
	var fp: float = dna.form_process
	if fp < 0.15:
		# Grown: L-system skeleton
		pipeline.skeleton_type = SkeletonType.LSYSTEM
		pipeline.surface_type = SurfaceType.SWEEP
	elif fp < 0.45:
		# Extruded: spine skeleton with sweep
		pipeline.skeleton_type = SkeletonType.SPINE
		pipeline.surface_type = SurfaceType.SWEEP
	elif fp < 0.6:
		# Carved: no skeleton, SDF surface
		pipeline.skeleton_type = SkeletonType.NONE
		pipeline.surface_type = SurfaceType.SDF
	elif fp < 0.8:
		# Folded: spine with primitive (for fold deformation)
		pipeline.skeleton_type = SkeletonType.SPINE
		pipeline.surface_type = SurfaceType.PRIMITIVE
	else:
		# Crystallized: no skeleton, primitive mesh
		pipeline.skeleton_type = SkeletonType.NONE
		pipeline.surface_type = SurfaceType.PRIMITIVE
		pipeline.primitive_type = PrimitiveType.PRISM

	# Map surface_method gene
	var sm: float = dna.surface_method
	if sm > 0.7:
		pipeline.surface_type = SurfaceType.PRIMITIVE
		pipeline.primitive_type = PrimitiveType.SPHERE if sm < 0.85 else PrimitiveType.BOX
	elif sm > 0.4:
		pipeline.surface_type = SurfaceType.SDF
	elif sm > 0.2:
		pipeline.surface_type = SurfaceType.REVOLUTION

	# Map skeleton complexity
	pipeline.spine_points = int(lerpf(2.0, 12.0, dna.skeleton_complexity))
	pipeline.spine_curvature = dna.part_curve
	pipeline.spine_length = dna.scale * 0.5

	# Map surface parameters from existing genes
	pipeline.sides = [4, 6, 8, 12][clampi(lod, 0, 3)]
	pipeline.start_radius = dna.part_width * dna.scale * 0.1
	pipeline.end_radius = pipeline.start_radius * (1.0 - dna.part_taper * 0.8)

	# Build modifier stack from genes
	if absf(dna.part_taper) > 0.1:
		pipeline.modifier_stack.append({
			"type": "taper",
			"params": { "amount": dna.part_taper }
		})
	if absf(dna.part_twist) > 1.0:
		pipeline.modifier_stack.append({
			"type": "twist",
			"params": { "degrees": dna.part_twist * 4.0 }
		})
	if dna.volatility > 0.5:
		pipeline.modifier_stack.append({
			"type": "noise",
			"params": { "strength": dna.volatility * 0.05 }
		})

	# Map modularity to instancing
	if dna.modularity > 0.6:
		pipeline.instance_count = int(lerpf(1.0, floorf(dna.symmetry), dna.modularity))
		pipeline.instance_symmetry = int(dna.symmetry)

	# Map recursion depth to children
	if dna.recursion_depth > 0.3 and dna.skeleton_complexity > 0.4:
		var child := MorphoPipeline.new()
		child.skeleton_type = SkeletonType.SPINE
		child.surface_type = SurfaceType.SWEEP
		child.spine_points = 3
		child.spine_length = pipeline.spine_length * dna.branch_decay
		child.start_radius = pipeline.end_radius * 0.8
		child.end_radius = child.start_radius * 0.3
		child.sides = maxi(pipeline.sides - 2, 3)
		child.child_per_parent = int(clampf(dna.symmetry, 1.0, 4.0))
		pipeline.children.append(child)
		pipeline.child_attachment = Attachment.AT_TIPS

	return pipeline.build(parent, lod)


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Skeleton generation
# ═══════════════════════════════════════════════════════════════

func _generate_skeleton(positions: Array, radii_out: Array) -> void:
	match skeleton_type:
		SkeletonType.NONE:
			positions.append(Vector3.ZERO)
			radii_out.append(start_radius)

		SkeletonType.SPINE:
			for i in spine_points:
				var t: float = float(i) / maxf(spine_points - 1.0, 1.0)
				var y: float = t * spine_length
				var x: float = sin(t * PI) * spine_curvature * spine_length * 0.3
				positions.append(Vector3(x, y, 0))
				radii_out.append(lerpf(start_radius, end_radius, t))

		SkeletonType.SPIRAL:
			for i in spine_points:
				var t: float = float(i) / maxf(spine_points - 1.0, 1.0)
				var angle: float = t * TAU * 2.0
				var r: float = t * spine_length * 0.3
				positions.append(Vector3(cos(angle) * r, t * spine_length, sin(angle) * r))
				radii_out.append(lerpf(start_radius, end_radius, t))

		SkeletonType.LSYSTEM, SkeletonType.COLONIZATION:
			# Simplified: generate a branching spine
			for i in spine_points:
				var t: float = float(i) / maxf(spine_points - 1.0, 1.0)
				positions.append(Vector3(0, t * spine_length, 0))
				radii_out.append(lerpf(start_radius, end_radius, t))


func _generate_surface(positions: Array, radii_out: Array, _lod: int) -> Mesh:
	match surface_type:
		SurfaceType.SWEEP:
			if positions.size() >= 2:
				return MorphoPrimitive.multi_tube(positions, radii_out, sides)
			elif positions.size() == 1:
				return MorphoPrimitive.sphere(start_radius, sides, sides / 2)

		SurfaceType.REVOLUTION:
			if profile.size() >= 2:
				return MorphoPrimitive.revolution(profile, sides)
			else:
				# Default dome profile
				var dome: Array = []
				for i in 8:
					var t: float = float(i) / 7.0
					dome.append(Vector2(start_radius * sin(t * PI * 0.5), t * spine_length))
				return MorphoPrimitive.revolution(dome, sides)

		SurfaceType.SDF:
			var sdf: Callable = MorphoPrimitive.sdf_smooth_union(
				MorphoPrimitive.sdf_sphere(Vector3.ZERO, start_radius * 3.0),
				MorphoPrimitive.sdf_sphere(Vector3(0, spine_length * 0.5, 0), start_radius * 2.0),
				start_radius
			)
			var bounds := AABB(Vector3(-1, -1, -1) * start_radius * 5.0,
				Vector3(2, 2, 2) * start_radius * 5.0 + Vector3(0, spine_length, 0))
			return MorphoPrimitive.sdf_mesh(sdf, bounds, 12)

		SurfaceType.PRIMITIVE:
			match primitive_type:
				PrimitiveType.SPHERE: return MorphoPrimitive.sphere(start_radius, sides, sides / 2)
				PrimitiveType.CYLINDER: return MorphoPrimitive.cylinder(start_radius, end_radius, spine_length, sides)
				PrimitiveType.BOX: return MorphoPrimitive.box(Vector3(start_radius * 2, spine_length, start_radius * 2))
				PrimitiveType.TORUS: return MorphoPrimitive.torus(start_radius, start_radius * 2.0)
				PrimitiveType.CAPSULE: return MorphoPrimitive.capsule(start_radius, spine_length)
				PrimitiveType.PRISM: return MorphoPrimitive.prism(0.5, Vector3(start_radius * 2, spine_length, start_radius * 2))
				PrimitiveType.QUAD: return MorphoPrimitive.quad(Vector2(start_radius * 2, spine_length))
				PrimitiveType.CONE: return MorphoPrimitive.cone(start_radius, spine_length, sides)
				PrimitiveType.PLANE: return MorphoPrimitive.plane(Vector2(start_radius * 4, spine_length * 2))

	return MorphoPrimitive.sphere(start_radius)


func _apply_modifier(mesh: Mesh, mod_def: Dictionary) -> Mesh:
	var mod_type: String = mod_def.get("type", "") as String
	var params: Dictionary = mod_def.get("params", {}) as Dictionary

	match mod_type:
		"taper":
			var amount: float = params.get("amount", 0.5) as float
			return MorphoModifier.taper(mesh, Vector3.UP,
				func(t: float) -> float: return 1.0 - t * amount)
		"twist":
			var degrees: float = params.get("degrees", 90.0) as float
			return MorphoModifier.twist(mesh, Vector3.UP, degrees)
		"bend":
			var angle: float = params.get("angle", 45.0) as float
			return MorphoModifier.bend(mesh, Vector3.FORWARD, angle)
		"noise":
			var strength: float = params.get("strength", 0.1) as float
			var noise := FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
			noise.frequency = params.get("frequency", 0.5) as float
			return MorphoModifier.noise_displace(mesh, noise, strength)
		"inflate":
			var amount: float = params.get("amount", 0.05) as float
			return MorphoModifier.inflate(mesh, amount)
		"wave":
			var freq: float = params.get("frequency", 3.0) as float
			var amp: float = params.get("amplitude", 0.1) as float
			return MorphoModifier.wave(mesh, Vector3.RIGHT, Vector3.UP, freq, amp)
		"spherize":
			var factor: float = params.get("factor", 0.5) as float
			return MorphoModifier.spherize(mesh, factor)
		"axis_scale":
			var factor: float = params.get("factor", 2.0) as float
			var axis: Vector3 = Vector3.UP
			if params.has("axis"):
				axis = params.get("axis") as Vector3
			return MorphoModifier.axis_scale(mesh, axis, factor)
	return mesh


func _create_instanced(root: Node3D, mesh: Mesh) -> void:
	var transforms: Array = []
	var colors: Array = []

	for i in instance_count:
		var angle: float = TAU * float(i) / float(instance_count)
		var t := Transform3D()
		t = t.rotated(Vector3.UP, angle)
		transforms.append(t)
		# Slight color variation per instance
		var hue_shift: float = float(i) / float(instance_count) * 0.1
		colors.append(Color.from_hsv(hue_shift, 0.5, 0.8))

	var mmi := MorphoPrimitive.multimesh_scatter(mesh, transforms, colors)
	mmi.name = "InstancedForm"
	root.add_child(mmi)


func _get_attachment_points(positions: Array) -> Array:
	match child_attachment:
		Attachment.AT_TIPS:
			if positions.size() > 0:
				return [positions[positions.size() - 1]]
			return [Vector3.ZERO]
		Attachment.ALONG_SKELETON:
			return positions
		Attachment.AT_ORIGIN:
			return [Vector3.ZERO]
		Attachment.ON_SURFACE:
			return [Vector3.ZERO]  # TODO: sample mesh surface
	return [Vector3.ZERO]
