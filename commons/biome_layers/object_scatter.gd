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
## See doc/PAINT_LAYERS.md § Object scatter.

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const ArtifactPaletteLib = preload("res://commons/biome_layers/artifact_palette.gd")

const DEFAULT_ARTIFACT := "prefab_sculpture"
const MAX_OBJECTS := 24            # real artifacts are heavy — keep the scatter sparse (total)


func apply(ctx: Dictionary) -> void:
	var layers = ctx.get("paint_layers", [])
	if not (layers is Array):
		return
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var base: int = int(ctx.get("rng_seed", 0))
	var budget: float = float(ctx.get("budget_scale", 1.0))
	var stage_order: int = int(ctx.get("stage_order", 999))

	var placed: int = 0
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
		var pick := RandomNumberGenerator.new()
		pick.seed = base + idx * 911
		for pos in DistributionField.placements(layer, dims.x, dims.z, cube, base + idx * 131 + 7, budget):
			if placed >= MAX_OBJECTS:
				break
			var nm: String = str(unlocked[pick.randi() % unlocked.size()])   # pick from the list
			var scene: PackedScene = ArtifactPaletteLib.scene_for(nm)
			if scene == null:
				continue
			var inst = scene.instantiate()
			if not (inst is Node3D):
				if inst:
					inst.queue_free()
				continue
			add_child(inst)
			(inst as Node3D).position = pos
			if not cfg.is_empty() and inst.has_method("apply_grid_config"):
				inst.call("apply_grid_config", cfg)
			placed += 1
		if placed >= MAX_OBJECTS:
			break
	if placed > 0:
		print("  [object_scatter] placed %d artifact(s) across %d layer(s)" % [placed, idx])


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
