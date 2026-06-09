# ground_substrate.gd — accrual layer: the default walkable bump-map ground.
#
# On every biome map by default (order 1, "always"). With no "ground" paint layer
# it builds a FLAT level ground at the floor — the surface the biome brush paints
# onto. A "ground" paint layer (plane / random / curve / noise / brush) supplies a
# height field that deforms the walkable mesh into terrain. Toggle off per map with
#   settings.biome_overrides.disable = ["ground_substrate"]
# See doc/PAINT_LAYERS.md.

extends Node3D

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const BiomeGroundSubstrate = preload("res://commons/biome_layers/biome_ground_substrate.gd")


func apply(ctx: Dictionary) -> void:
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var gw: int = maxi(1, dims.x)
	var gd: int = maxi(1, dims.z)
	var center: Vector3 = ctx.get("grid_center", Vector3(float(gw) * cube * 0.5, 0.0, float(gd) * cube * 0.5))

	# A "ground" paint layer → height field; otherwise a flat level ground.
	var field := PackedFloat32Array()
	field.resize(gw * gd)   # default: all zeros = flat
	var max_h: float = 0.0
	var painted: bool = false
	for layer in ctx.get("paint_layers", []):
		if layer is Dictionary and str(layer.get("element", "")) == "ground":
			# The ground field is a HEIGHT map, not a scatter density — build it at full
			# strength (density 1.0) so the painted SHAPE drives the terrain and only the
			# `height` (max_h) scales it. DistributionField.build_field otherwise multiplies
			# a brush field by the layer's `density`, which would shrink the hills whenever
			# the DEFINE/density slider (a scatter knob) is lowered. Height owns height.
			var ground_spec: Dictionary = (layer as Dictionary).duplicate()
			ground_spec["density"] = 1.0
			field = DistributionField.build_field(ground_spec, gw, gd, int(ctx.get("rng_seed", 0)))
			max_h = float(layer.get("height", 1.4))
			painted = true
			break

	var sub = BiomeGroundSubstrate.new()
	sub.name = "BiomeGroundSubstrate"
	# A PAINTED ground is a visible height-map: lift its field-zero plane to the grid
	# FLOOR SURFACE (cube top ≈ +0.5·cube) so the hills rise above the floor and read as
	# undulating terrain. An UNPAINTED (flat) ground keeps the historic backdrop a metre
	# below the floor (decision B in PAINT_LAYERS.md) — pure scenery, unchanged.
	if painted and max_h > 0.0 and sub.has_method("set_base_offset"):
		sub.set_base_offset(cube * 0.5 + 0.02)
	sub.configure(gw, gd, cube, center)
	sub.set_field(field, gw, gd, max_h)
	# The full layer list drives the ground COLOUR overlay: "shader" layers paint
	# their colour, plant layers (tree/flower/…) bleed their kingdom colour — but
	# only once the kingdom is curriculum-unlocked (stage_order gate, matching spawn).
	sub.set_paint_layers(ctx.get("paint_layers", []), int(ctx.get("rng_seed", 0)), int(ctx.get("stage_order", 999)))
	add_child(sub)
	print("[ground_substrate] %dx%d ground, max_height=%.2f%s" % [gw, gd, max_h, "  (flat default)" if max_h == 0.0 else ""])
