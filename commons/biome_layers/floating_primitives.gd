# floating_primitives.gd
# Biome layer for seq 1 (primitives). The Kusama/grid field.
#
# CURRICULUM HONESTY: seq 1 teaches primitives. Not randomness (seq 7),
# not noise (seq 8). So this layer uses ZERO randf/random/noise. Positions
# are array indices, types are modulo patterns, heights are fixed tiers.
# The grid IS the aesthetic. Slave to the rhythm.
#
# RENDERING: uses MultiMeshInstance3D (one per primitive type) instead of
# N individual MeshInstance3D nodes. Keeps VR draw-call count minimal and
# matches the existing BiomeRingComponent foliage rendering pattern.
#
# Applied by BiomeAccrualManager. Never instantiated directly.

extends Node3D

const TYPE_POINT := "point"
const TYPE_SEGMENT := "segment"
const TYPE_TRIANGLE := "triangle"
const TYPE_CUBE := "cube"

# The seq-1 field has TWO faces, chosen by the CURRENT map's stage:
#
#   • Primitives stage (the maps that teach seq 1) → a sparse GPU
#     particle sphere field. Soft motes drifting in the void —
#     presence-by-scarcity, the subtle successor to the rigid dot grid.
#   • Foundation beneath any LATER sequence (stage ≥ 2) → the original
#     MultiMesh dot lattice. Later layers (animated_primitives seq 2,
#     color_tint seq 3, force_field/lattice_snap/wave_displace seq 4–6)
#     find this layer's MultiMeshInstance3D children by name and
#     animate / tint / displace them. They need the lattice to exist,
#     so the foundation keeps rendering it.
#
# So: in the primitives sequence you see the drift; once you reach
# transformation, the substrate beneath everything is the lattice that
# the higher layers then bring to life.
const SPHERE_FIELD_SCENE := preload("res://commons/primitives/sphere_field/floating_sphere_field.tscn")


func apply(ctx: Dictionary) -> void:
	# Stage gate. Default 999 → if stage is somehow unknown, render the
	# lattice (the accrual-safe choice that never starves later layers).
	var stage_order: int = int(ctx.get("stage_order", 999))
	if stage_order <= 1:
		_apply_sphere_field(ctx)
		return

	var params: Dictionary = ctx.get("params", {})
	var bounds: float = float(params.get("bounds", 22.0))
	var types: Array = params.get("types", [TYPE_POINT])
	var step_override: float = float(params.get("step", 0.0))
	var y_tiers_param = params.get("y_tiers", [1.6, 3.2])

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	# Default step matches cube grid rhythm; params can override for denser arrays.
	var step: float = step_override if step_override > 0.0 else cube_size * 1.5
	var grid_half_x: float = float(grid_dims.x) * cube_size * 0.5
	var grid_half_z: float = float(grid_dims.z) * cube_size * 0.5
	var exclusion_x: float = grid_half_x + step * 0.5
	var exclusion_z: float = grid_half_z + step * 0.5

	# Y-tiers — one array per tier, not scrambled by modulo. Every tier is a
	# CLEAN grid at one height. Multiple tiers stack into a 3D field without
	# losing the 2D "Kusama dot-grid" reading at any single eye-level slice.
	var y_tiers: Array = y_tiers_param if y_tiers_param is Array else [1.6, 3.2]
	var radius_steps: int = int(ceilf(bounds / step))

	# Bucket transforms by primitive type — one MultiMesh per bucket.
	var buckets: Dictionary = {}
	for t in types:
		buckets[str(t)] = []

	# For each cell in the lattice, emit one instance PER TIER PER TYPE.
	# If there is only one type (e.g. "point"), every cell gets that type at
	# every tier → a full uniform array. Multi-type lists cycle per tier, so
	# tier 0 is all points, tier 1 is all cubes, etc. — still ordered.
	for ix in range(-radius_steps, radius_steps + 1):
		for iz in range(-radius_steps, radius_steps + 1):
			var wx: float = float(ix) * step
			var wz: float = float(iz) * step
			if absf(wx) < exclusion_x and absf(wz) < exclusion_z:
				continue
			if Vector2(wx, wz).length() > bounds:
				continue

			for tier_i in y_tiers.size():
				var y: float = float(y_tiers[tier_i])
				var kind: String = str(types[tier_i % types.size()])
				if not buckets.has(kind):
					continue
				# No rotation — preserves the array's readability.
				var tr := Transform3D(Basis.IDENTITY, grid_center + Vector3(wx, y, wz))
				(buckets[kind] as Array).append(tr)

	for kind in buckets.keys():
		var transforms: Array = buckets[kind]
		if transforms.is_empty():
			continue
		_spawn_multimesh(str(kind), transforms)


# Primitives-stage face: instance the floating_sphere_field artifact
# (single source of truth for the GPU-particle look), sized to the grid
# and centred over it. Params from the contribution entry can override
# the field's DNA so the biome stays tunable from biome_contributions.json.
func _apply_sphere_field(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(20, 1, 20))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var half_x: float = float(grid_dims.x) * cube_size * 0.5
	var half_z: float = float(grid_dims.z) * cube_size * 0.5

	var field: Node3D = SPHERE_FIELD_SCENE.instantiate()
	# Set DNA BEFORE add_child so _ready()/_build_field use these values.
	# (apply_grid_config's string round-trip is for map_data tokens; here
	# we own typed values, so assign the @export vars directly.)
	field.bounds = Vector3(
		float(params.get("field_half_x", half_x + 1.0)),
		float(params.get("field_half_y", 2.6)),
		float(params.get("field_half_z", half_z + 1.0)))
	# Centre the drift volume a little above the floor.
	field.volume_offset = Vector3(0.0, float(params.get("field_centre_y", 2.6)), 0.0)
	# Phase 5: scale the field population by the budget (1.0 = unchanged).
	field.sphere_count = maxi(0, int(round(float(params.get("sphere_count", 60)) * float(ctx.get("budget_scale", 1.0)))))
	field.sphere_radius = float(params.get("sphere_radius", 0.06))
	field.drift_speed = float(params.get("drift_speed", 0.18))
	field.turbulence = float(params.get("turbulence", 0.6))
	field.emission_energy = float(params.get("emission_energy", 1.6))
	if params.has("color"):
		field.color = _parse_color_param(params.get("color"))

	field.position = grid_center
	add_child(field)
	print("  [floating_primitives] sphere-field face — count=%d bounds=%s" % [
		field.sphere_count, str(field.bounds)])


func _parse_color_param(v) -> Color:
	if v is Color:
		return v
	var s := str(v)
	if s.begins_with("#"):
		return Color(s)
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]))
	return Color(0.72, 0.88, 1.0)


func _posmod(a: int, b: int) -> int:
	var r: int = a % b
	return r + b if r < 0 else r


func _spawn_multimesh(kind: String, transforms: Array) -> void:
	var mesh := _mesh_for_kind(kind)
	# Attach material to the mesh surface directly instead of via
	# MultiMeshInstance3D.material_override. In VR, override materials on
	# MultiMesh can silently fail to render — surface material is the robust path.
	var mat := _void_material(kind)
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	# Allocate color buffer up front. MultiMesh requires use_colors set BEFORE
	# instance_count — flipping it later leaves the buffer unallocated, so
	# color_tint (seq 3) couldn't tint these instances. Default everyone white;
	# color_tint overwrites with per-instance HSL at higher stages.
	mm.use_colors = true
	mm.use_custom_data = false
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, Color.WHITE)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Kusama_%s" % kind
	mmi.multimesh = mm
	# Extend AABB so Godot doesn't cull the whole MultiMesh when player's frustum
	# doesn't include the centroid. This is a known gotcha with sparse lattices
	# around a grid — the default AABB is tiny and gets culled in VR.
	mmi.custom_aabb = AABB(Vector3(-50, -10, -50), Vector3(100, 60, 100))
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mmi)
	print("  [floating_primitives] spawned MultiMesh kind=%s count=%d" % [kind, transforms.size()])


func _mesh_for_kind(kind: String) -> Mesh:
	match kind:
		TYPE_POINT:
			# Kusama-style bold dot — sized to read clearly from VR eye height
			# across a ~20m bound without becoming specks at the far edge.
			var m := SphereMesh.new()
			m.radius = 0.22
			m.height = 0.44
			m.radial_segments = 14
			m.rings = 8
			return m
		TYPE_SEGMENT:
			var m := CylinderMesh.new()
			m.top_radius = 0.035
			m.bottom_radius = 0.035
			m.height = 1.2
			m.radial_segments = 6
			return m
		TYPE_TRIANGLE:
			var m := PrismMesh.new()
			m.size = Vector3(0.45, 0.06, 0.45)
			return m
		TYPE_CUBE:
			var m := BoxMesh.new()
			m.size = Vector3(0.35, 0.35, 0.35)
			return m
	return BoxMesh.new()


func _void_material(_kind: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	# Unshaded = albedo is the final pixel, no lighting dependency. No emission
	# on top — it would wash out the vertex-color tint that color_tint (seq 3)
	# applies later by adding white.
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Instance color (stored in the MultiMesh) multiplies with albedo. Default
	# instance color is white so dots stay white in seqs 1-2. When color_tint
	# applies per-instance HSL, the multiplication produces the tint.
	mat.vertex_color_use_as_albedo = true
	return mat
