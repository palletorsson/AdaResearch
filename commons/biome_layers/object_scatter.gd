extends Node3D
## object_scatter.gd — the universal ARTIFACT placer for the biome.
##
## ANY paint layer can carry a list of artifacts (`artifacts: ["a","b",...]`, or a
## single legacy `params.artifact`). This layer scatters them by the layer's own
## distribution — plane / random / curve / noise / FRACTAL / brush — picking an
## artifact from the list per placement. So every field, from mushroom to plant to
## pop-mesh, can be populated by its own per-map artifact set, distributed however
## the layer's mode says. A layer WITHOUT a list falls back to its element's default
## morphology (softbody_flora etc.); the dedicated `object` element defaults to
## prefab_sculpture. Palette is curriculum-gated (ArtifactPalette.unlock_order).
##
## DENSITY: small/sparse repeats are placed as real, interactive scene instances
## (full fidelity + collision + scripts). When ONE artifact repeats >= BATCH_AT
## times, we bake its static meshes into MultiMeshInstance3D(s) — one draw call per
## source mesh no matter how many copies — so "pop / prefab / DNA / mesh debris"
## can scatter by the hundreds cheaply. A fully procedural/deferred artifact (no
## static mesh to read at bake time) gracefully falls back to capped instancing.
## See doc/PAINT_LAYERS.md § Object scatter.

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const ArtifactPaletteLib = preload("res://commons/biome_layers/artifact_palette.gd")

const DEFAULT_ARTIFACT := "prefab_sculpture"
const INSTANCE_CAP := 24       # heavy full-scene (interactive) instances, total
const BATCH_CAP := 800         # cheap baked MultiMesh instances, total
const BATCH_AT := 8            # per-artifact repeat count at/above which we bake


func apply(ctx: Dictionary) -> void:
	var layers = ctx.get("paint_layers", [])
	if not (layers is Array):
		return
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var base: int = int(ctx.get("rng_seed", 0))
	var budget: float = float(ctx.get("budget_scale", 1.0))
	var stage_order: int = int(ctx.get("stage_order", 999))

	var inst_placed: int = 0       # interactive scene instances
	var batch_placed: int = 0      # baked MultiMesh instances
	var idx: int = 0
	for layer in layers:
		if not (layer is Dictionary):
			continue
		var is_object: bool = str(layer.get("element", "")) == "object"
		if not (is_object or DistributionField.is_artifact_layer(layer)):
			continue
		idx += 1
		# The layer's artifact list (the dedicated `object` element defaults to one),
		# filtered to what the spine has unlocked at this stage.
		var names: Array = _artifacts_of(layer)
		if names.is_empty() and is_object:
			names = [DEFAULT_ARTIFACT]
		var unlocked: Array = []
		for a in names:
			var nm := str(a)
			if ArtifactPaletteLib.has(nm) and ArtifactPaletteLib.unlock_order(nm) <= stage_order:
				unlocked.append(nm)
		if unlocked.is_empty():
			continue
		# Config handed to each artifact (its params, minus our routing key).
		var cfg: Dictionary = (layer.get("params") as Dictionary).duplicate() if (layer.get("params") is Dictionary) else {}
		cfg.erase("artifact")
		# Gather placements, grouped by the artifact picked at each cell.
		var pick := RandomNumberGenerator.new()
		pick.seed = base + idx * 911
		var groups: Dictionary = {}        # artifact name -> Array[Vector3]
		for pos in DistributionField.placements(layer, dims.x, dims.z, cube, base + idx * 131 + 7, budget):
			var nm: String = str(unlocked[pick.randi() % unlocked.size()])
			if not groups.has(nm):
				groups[nm] = []
			(groups[nm] as Array).append(pos)
		# Realize each group: bake big repeats, instance small/interactive ones.
		var yaw := RandomNumberGenerator.new()
		yaw.seed = base + idx * 733 + 1
		for nm in groups:
			var positions: Array = groups[nm]
			var scene: PackedScene = ArtifactPaletteLib.scene_for(nm)
			if scene == null:
				continue
			if positions.size() >= BATCH_AT and batch_placed < BATCH_CAP:
				var n := _bake_group(scene, positions, cfg, yaw, batch_placed)
				if n > 0:
					batch_placed += n
					continue
				# No static mesh found → fall through to instancing (capped).
			for pos in positions:
				if inst_placed >= INSTANCE_CAP:
					break
				var inst = scene.instantiate()
				if not (inst is Node3D):
					if inst:
						inst.queue_free()
					continue
				add_child(inst)
				(inst as Node3D).position = pos
				if not cfg.is_empty() and inst.has_method("apply_grid_config"):
					inst.call("apply_grid_config", cfg)
				inst_placed += 1
		if inst_placed >= INSTANCE_CAP and batch_placed >= BATCH_CAP:
			break
	if inst_placed > 0 or batch_placed > 0:
		print("  [object_scatter] %d instanced + %d batched artifact(s) across %d layer(s)" % [inst_placed, batch_placed, idx])


## Bake up to (BATCH_CAP - already) copies of `scene` at `positions` into
## MultiMeshInstance3D(s) — one per static MeshInstance3D in the scene, each
## rendering every copy in a single draw call, with a shared per-copy yaw so a
## multi-part artifact stays coherent. Returns the count baked, or 0 if the scene
## has no readable static mesh (procedural/deferred) so the caller can fall back.
func _bake_group(scene: PackedScene, positions: Array, cfg: Dictionary, yaw: RandomNumberGenerator, already: int) -> int:
	var n: int = mini(positions.size(), BATCH_CAP - already)
	if n <= 0:
		return 0
	var probe = scene.instantiate()
	if not (probe is Node3D):
		if probe:
			probe.queue_free()
		return 0
	add_child(probe)   # entering the tree runs _ready so procedural meshes build
	if not cfg.is_empty() and probe.has_method("apply_grid_config"):
		probe.call("apply_grid_config", cfg)
	var meshes: Array = []   # [{mesh, mat, xform}] in this node's local space
	_collect_meshes(probe, (probe as Node3D).global_transform.affine_inverse(), meshes)
	probe.queue_free()
	if meshes.is_empty():
		return 0
	# One shared yaw per copy keeps a multi-part artifact's parts rotating together.
	var yaws: Array = []
	for i in range(n):
		yaws.append(yaw.randf_range(0.0, TAU))
	for m in meshes:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = m["mesh"]
		mm.instance_count = n
		var local: Transform3D = m["xform"]
		for i in range(n):
			var b := Basis(Vector3.UP, float(yaws[i]))
			mm.set_instance_transform(i, Transform3D(b, positions[i]) * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if m["mat"] != null:
			mmi.material_override = m["mat"]
		add_child(mmi)
	return n


## Walk the probe, collecting every MeshInstance3D's mesh + material + transform
## (relative to the probe root, via `inv` = probe.global_transform.inverse).
func _collect_meshes(node: Node, inv: Transform3D, out: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi := node as MeshInstance3D
		var mat: Material = mi.material_override
		if mat == null and mi.get_surface_override_material_count() > 0:
			mat = mi.get_surface_override_material(0)
		out.append({"mesh": mi.mesh, "mat": mat, "xform": inv * mi.global_transform})
	for c in node.get_children():
		_collect_meshes(c, inv, out)


## The artifact names a layer offers: an `artifacts: [...]` list, or the legacy
## single `params.artifact`. Empty if neither (a non-object element with no list →
## handled by its default morphology instead).
func _artifacts_of(layer: Dictionary) -> Array:
	var arts = layer.get("artifacts", null)
	if arts is Array and not (arts as Array).is_empty():
		return (arts as Array).duplicate()
	var p = layer.get("params", null)
	if p is Dictionary and p.has("artifact"):
		return [str(p.get("artifact"))]
	return []
