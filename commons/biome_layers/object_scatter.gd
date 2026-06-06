extends Node3D
## object_scatter.gd — the one biome layer that seeds a map with ARTIFACTS.
##
## Reads `object` paint layers and instantiates a registered artifact (pop-art,
## prefab sculpture, DNA form, any mesh, debris) at the painted placements. Each
## layer names its artifact in params.artifact (default: prefab_sculpture). The
## palette is curriculum-gated: an artifact only scatters once the spine has
## reached its unlock stage (ArtifactPalette.unlock_order) — so the made-world
## possibilities widen as you progress. Kept sparse (real artifacts are heavy).
## See doc/PAINT_LAYERS.md § Object scatter.

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const ArtifactPaletteLib = preload("res://commons/biome_layers/artifact_palette.gd")

const DEFAULT_ARTIFACT := "prefab_sculpture"
const MAX_OBJECTS := 24            # hero/debris objects are heavy — keep the scatter sparse


func apply(ctx: Dictionary) -> void:
	if not DistributionField.has_layer_for(ctx, "object"):
		return
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var base: int = int(ctx.get("rng_seed", 0))
	var budget: float = float(ctx.get("budget_scale", 1.0))
	var stage_order: int = int(ctx.get("stage_order", 999))

	var placed: int = 0
	var idx: int = 0
	for layer in ctx.get("paint_layers", []):
		if not (layer is Dictionary) or str(layer.get("element", "")) != "object":
			continue
		idx += 1
		var params: Dictionary = layer.get("params", {}) if (layer.get("params") is Dictionary) else {}
		var artifact: String = str(params.get("artifact", DEFAULT_ARTIFACT))
		# Curriculum honesty: the artifact must be unlocked by this point in the spine.
		if ArtifactPaletteLib.unlock_order(artifact) > stage_order:
			continue
		var scene: PackedScene = ArtifactPaletteLib.scene_for(artifact)
		if scene == null:
			push_warning("object_scatter: unknown artifact '%s'" % artifact)
			continue
		# Config to hand the artifact (its params minus our routing key).
		var cfg: Dictionary = params.duplicate()
		cfg.erase("artifact")
		for pos in DistributionField.placements(layer, dims.x, dims.z, cube, base + idx * 131 + 7, budget):
			if placed >= MAX_OBJECTS:
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
			placed += 1
		if placed >= MAX_OBJECTS:
			break
	if placed > 0:
		print("  [object_scatter] placed %d artifact(s)" % placed)
