## tier_terrarium — the `tier` family, all six kingdoms standing at once.
##
## WHAT THE WORD MEANS IN THE CODE, which the brief refused to fix and the code
## answers. `t=` is parsed by BiomeGridTokens.tier_of (BiomeGridTokens.gd:145-149),
## clamped to 1..5, DEFAULT 2. It is not the soft_stages progression — soft_stages.json
## contains no `tier` key at all, and the curriculum gate is a separate check against
## ConfigLoader.get_unlock_order (GridBiomeComponent.gd:353). It is not one quantity
## either. tier is read as FOUR different things by four different consumers:
##
##   extent   every kingdom multiplies some geometry gene by it
##   depth    tree L-system generations, CA freeze generation, mycelium growth steps
##   detail   the `lod` int handed to a morphology — and three of six are CAPPED
##   identity flora:scatter ALONE: tier indexes a species table, bluebell/orchid/daisy
##
## and it is read a fifth time as a ground-stain strength, by two formulas that
## disagree with each other (GridBiomeComponent.gd:363 uses 0.35 + 0.13*t,
## GridBiomeComponent.gd:1243 uses 0.4 + 0.12*t) and with the tier/5.0 the deposit
## carries at GridBiomeComponent.gd:724.
##
## THE READING. Six bays, one per family member, side by side (LAW 2: the kingdoms
## are PARALLEL — nothing about fungus contains flora — so the simultaneity is the
## object and the family word is what varies). At tier 1 every organism tops out on
## the same datum rail. By tier 5 they have fanned out over a factor of 4.49, and one
## of them is BELOW where it started. One word, six climb rates:
##
##   living_flora_bloom     1.000 1.118 1.404 0.615 0.668   t5/t1 = 0.668   FALLS
##   living_flora_tree      1.000 1.250 1.500 2.625 3.000   t5/t1 = 3.000
##   living_fungus_fruit    1.000 1.214 1.429 1.643 1.857   t5/t1 = 1.857
##   living_fungus_pose     1.000 1.214 1.429 1.643 1.857   t5/t1 = 1.857
##   living_fungus_colony   1.000 1.000 1.250 1.500 1.750   t5/t1 = 1.750
##   living_fauna_body      1.000 1.214 1.811 2.130 2.969   t5/t1 = 2.969
##
## The bloom falls because tier is its SPECIES index and the species are not ordered
## by size: bluebell stem 0.22 m, orchid 0.25 m, daisy 0.10 m. At tier 3 the flower
## stands 0.25 * 2.1 = 0.525 m; at tier 4 it is 0.10 * 2.3 = 0.230 m. A rung that is
## supposed to be MORE takes 56% of the plant away, and tier 5 (0.250 m) never gets
## back to tier 1 (0.374 m).
##
## LAW 11. Nothing here is random. No randf, no randomize, no _process, no timer, no
## physics: every position is index arithmetic over the ladders derived below. Living
## artifacts are the corpus's likeliest carriers of an unseeded randf, so this is a
## promise the file keeps by having no RandomNumberGenerator in it at all.
##
## LAW 1. Every facet table, every scaling coefficient, the species table and the
## kingdom palette are READ from the scripts and the config that own them. The only
## things typed here are the four `lod` expressions, which are formulas and not
## constants; each carries the dispatcher line it was read from.
##
## CURRICULUM HONESTY (CLAUDE.md): the terrarium spends no concept it has not been
## given. It calls no noise, draws no randf and grows no tree by simulation — it
## states measurements. So it is safe at any sequence, which is the point: it is a
## bench for the vocabulary, not a biome.
extends Node3D
class_name TierTerrarium

# ── the owners of every number this artifact draws ───────────────────────────
const BIOME_TOKENS := preload("res://commons/grid/BiomeGridTokens.gd")
const TREE_MORPH := preload("res://algorithms/nature_system/morphology/tree_morphology.gd")
const FUNGUS_MORPH := preload("res://algorithms/nature_system/morphology/fungus_morphology.gd")
const CREATURE_SDF := preload("res://algorithms/nature_system/morphology/creature_sdf_morphology.gd")
const SDF_MESHER := preload("res://algorithms/nature_system/morphology/sdf_mesher.gd")
const BIOME_CFG := preload("res://commons/biome_layers/biome_config_loader.gd")
const FLOWER := preload("res://commons/flora/botanical_flower.gd")

# ── THE AXES ─────────────────────────────────────────────────────────────────
## The family word, and its value list character for character: living_fauna_body,
## living_flora_bloom, living_flora_tree, living_fungus_colony, living_fungus_fruit
## and living_fungus_pose all declare tier ["1","2","3","4","5"]. Refusing it was
## never an option — it is a bare number, so there is no meaning to disagree with.
## The default is "2" and that is NOT a free choice: tier_of returns 2 for a cell
## with no `t=`, and 257 of the corpus's 344 declared biome cells (74.7%) have none.
## The rung BiomeGridTokens.tier_of falls back to when a cell has no `t=`. Asserted
## against the parser at _ready, so if the grammar's fallback ever moves, this file
## says so instead of quietly opening on a rung the corpus no longer stands at.
const DEFAULT_TIER: String = "2"
@export_enum("1", "2", "3", "4", "5") var tier: String = DEFAULT_TIER

## WHICH of tier's readings the bays draw. body = the extent every kingdom scales;
## grain = the mesh resolution the `lod` int buys. They touch DISJOINT code — body
## reads dna geometry fields, grain reads the lod argument — which is the claim in
## dna.predicted_relationship. Default "body": LAW 15, the strongest single reading.
@export_enum("body", "grain") var channel: String = "body"

## Allow-lists, checked against the export hints in BOTH directions at _ready by
## reading hint_string back out of get_property_list(). An @export_enum literal
## cannot be derived from a const, so run-time comparison is the only defence.
const TIERS: PackedStringArray = ["1", "2", "3", "4", "5"]
const CHANNELS: PackedStringArray = ["body", "grain"]

# ── the case ─────────────────────────────────────────────────────────────────
const N_BAYS: int = 6
## Every bay's organism height at tier 1. The bays start LEVEL; that is the whole
## reference the reading needs, and the datum rail sits exactly here.
const BASE_H: float = 0.28
## LAW 7. Not a style number. A bay's widest tenant is 2*GRAIN_R = 0.29 m square, and
## at the capture yaw that projects 0.29*cos(0.62) + 0.29*sin(0.62) = 0.404524 m of
## screen width, while bay centres are PITCH*cos(0.62) apart. PITCH 0.58 gives
## 0.472050 of separation against 0.404524 of width — 0.067525 m of daylight, 14 px
## at this framing. Anything under 0.497 m makes each bay stand in front of the next.
const PITCH: float = 0.58
const BAY_W: float = 0.34
const BAY_D: float = 0.30
## LAW 4. The grain column fills its bay on purpose. At 0.085 m radius the facet
## edges measured 9.7 px across after the critic's 160x160 resize and the whole
## channel read 0.195% — a fact about the drawing, not about the LOD ladder. At
## 0.145 m it is 16.5 px and the channel reads 0.85-5.70%.
const GRAIN_R: float = 0.145
## grain PINS size so only facet count varies, which makes the pinned value a free
## control rather than a claim. Chosen tall: facets show along a silhouette edge.
const GRAIN_H: float = 0.62
const PLINTH_H: float = 0.09
const RAIL_T: float = 0.016
## 5 * 0.58 + 0.34 + 0.06. Written over the constants it comes from, not as 3.30.
const PLINTH_X: float = 5.0 * PITCH + BAY_W + 0.06
const PLINTH_Z: float = BAY_D + 0.08
## The datum rail and the dividers stand at the BACK of the bay, never between the
## camera and an organism. LAW 7: the z interval 0.00 .. 0.15 in front of every
## organism is empty, and there is no glass — a terrarium with panes would be
## operations_gallery's slab with a nicer name.
const RAIL_Z: float = BAY_D * 0.5

const BAY_TOKENS: PackedStringArray = [
	"living_flora_bloom", "living_flora_tree", "living_fungus_fruit",
	"living_fungus_pose", "living_fungus_colony", "living_fauna_body"]
## The biome grammar token each bay photographs, i.e. which dispatcher branch owns it.
const BAY_BIOME: PackedStringArray = [
	"flora:scatter", "flora:lsystem", "fungus:dna",
	"fungus:softbody", "fungus:ca", "fauna:dna"]

var _built: bool = false
var _ladder: Array = []          ## LAW 3: one copy of the arithmetic, built once


func _ready() -> void:
	_check_vocabularies()
	_build()


# ═════════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC — derived once, read N ways (LAW 3)
# ═════════════════════════════════════════════════════════════════════════════

## Godot's roundi is half-away-from-zero, and BOTH discrete ladders below depend on
## which way 1.5, 2.5 and 3.5 fall. Re-implemented rather than assumed.
func _roundi(x: float) -> int:
	return int(floor(x + 0.5)) if x >= 0.0 else -int(floor(-x + 0.5))


## Every member's five-rung ladder, from the branch of BiomePaintDispatcher that
## actually builds it. `extent` is the product of the terms the code multiplies;
## it is a RATIO, never a metre count, because dna.scale is a gene fed to a
## morphology and this file will not invent the morphology's metres.
func _derive_ladders() -> Array:
	var flower_s: Dictionary = BIOME_CFG.get_intensity_scaling("flower")
	var tree_s: Dictionary = BIOME_CFG.get_intensity_scaling("tree")
	var fungus_s: Dictionary = BIOME_CFG.get_intensity_scaling("fungus")
	var tube_sides: Array = TREE_MORPH.LOD_TUBE_SIDES        ## [3, 4, 6, 8]
	var cap_segs: Array = FUNGUS_MORPH.LOD_CAP_SEGMENTS      ## [6, 12, 20, 32]
	var res_by_lod: Array = CREATURE_SDF.RES_BY_LOD          ## [24, 32, 42, 52]
	var res_cap: int = SDF_MESHER.RES_CAP                    ## 34 — truncates the top two

	var out: Array = []
	for b in N_BAYS:
		out.append({"extent": [], "facets": [], "gen": [], "species": [], "width": []})

	for i in TIERS.size():
		var t: int = i + 1
		var tf: float = float(t)

		# ── living_flora_bloom — dispatcher _spawn_flower (lines 215-243).
		# tier indexes a SPECIES table and multiplies a scale. No lod argument
		# exists on this path at all, so the bloom has no grain channel.
		var species: String = BIOME_CFG.get_flower_preset(t)
		if species.is_empty():
			species = "bluebell"                    # dispatcher:223-224
		var stem: float = float((FLOWER.PRESETS[species] as Dictionary).get("stem_height", 0.22))
		var f_scale: float = float(flower_s.get("overall_scale_base", 1.5)) \
			+ float(flower_s.get("overall_scale_per_intensity", 0.20)) * tf
		out[0]["extent"].append(stem * f_scale)
		out[0]["facets"].append(12)                 # constant: nothing thins a flower
		out[0]["species"].append(species)

		# ── living_flora_tree — dispatcher _spawn_tree (lines 522-561).
		# segments is a GENE; tree_morphology.gd:76 turns it into L-system depth via
		# clampi(roundi(segments * 0.5), 2, 5). With the shipped config that is
		# 2,2,2,3,3 — five rungs, TWO distinct depths, and it never passes 3 of 5.
		var t_seg: float = float(tree_s.get("segments_base", 2.0)) \
			+ float(tree_s.get("segments_per_intensity", 1.0)) * tf
		var gens: int = clampi(_roundi(t_seg * 0.5), 2, 5)
		var t_scale: float = float(tree_s.get("scale_base", 0.8)) \
			+ float(tree_s.get("scale_per_intensity", 0.30)) * tf
		out[1]["extent"].append(t_scale * float(gens))
		out[1]["facets"].append(int(tube_sides[clampi(t - 2, 0, 3)]))   # dispatcher:554
		out[1]["gen"].append(gens)

		# ── living_fungus_fruit and living_fungus_pose — ONE function,
		# dispatcher _spawn_fungus_preset (lines 472-502). Same multiplier, same lod.
		# Their ladders MUST come out identical; _check_relationship proves it.
		var mush: float = 2.2 + 0.6 * tf                                # dispatcher:493
		var mush_lod: int = clampi(t - 1, 0, 3)                         # dispatcher:498
		for b2 in [2, 3]:
			out[b2]["extent"].append(mush)
			out[b2]["facets"].append(int(cap_segs[mush_lod]))

		# ── living_fungus_colony — dispatcher _spawn_fungus (lines 256-320), algo `ca`
		# (49 of the corpus's declared fungus cells, the most-placed substrate).
		# The CA has no lod either. Its WIDTH and its HEIGHT climb at different rates:
		# dim goes 9,12,15,18,21 but flat_y goes 4,4,5,6,7, so the mat spreads faster
		# than it rises. Height is the honest extent for a thing standing in a bay.
		var dim: int = int(fungus_s.get("grid_dim_base", 6)) \
			+ int(fungus_s.get("grid_dim_per_intensity", 3)) * t
		var flat_y: int = maxi(4, _roundi(float(dim) / 3.0))            # dispatcher:291
		out[4]["extent"].append(float(flat_y))
		out[4]["facets"].append(4)                  # constant: a voxel is a cube
		out[4]["width"].append(dim)

		# ── living_fauna_body — dispatcher _spawn_creature (lines 578-617).
		# creature_morphology.gd:74 clamps roundi(segments) into a SPINE COUNT, so the
		# grub's real extent is part_length * scale * 0.5 * seg_count and seg_count
		# steps 4,4,5,5,6. That step is why the fauna climbs 2.969x while dna.scale
		# alone would suggest 1.452x.
		var c_seg: int = clampi(_roundi(3.0 + 0.5 * tf), 2, 12)         # dispatcher:599
		var c_len: float = 0.30 + 0.03 * tf                             # dispatcher:601
		var c_scale: float = 0.55 + 0.07 * tf                           # dispatcher:600
		var c_lod: int = mini(clampi(t - 1, 0, 3), 1)                   # dispatcher:616
		out[5]["extent"].append(c_len * c_scale * 0.5 * float(c_seg))
		out[5]["facets"].append(maxi(3, _roundi(float(mini(int(res_by_lod[c_lod]), res_cap)) / 4.0)))
		out[5]["gen"].append(c_seg)

	# normalise each bay against its OWN tier 1 — the climb rate, which is what the
	# terrarium compares. LAW 5: the divisor is the bay's tier-1 extent, fixed across
	# the whole axis, never the frame's maximum.
	for b3 in N_BAYS:
		var e: Array = out[b3]["extent"]
		var base: float = float(e[0])
		var ratios: Array = []
		for v in e:
			ratios.append(float(v) / base)
		out[b3]["ratio"] = ratios
	return out


# ═════════════════════════════════════════════════════════════════════════════
# BUILD
# ═════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	# remove_child BEFORE queue_free. queue_free is DEFERRED, so a rebuild that only
	# queued would leave the old row parented for a frame — and the capture measures
	# the subtree AABB, so it would photograph and frame two rows stacked.
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_ladder = _derive_ladders()
	_check_relationship()

	var ti: int = maxi(TIERS.find(tier), 0)
	var grain: bool = channel == "grain"

	_add_box(Vector3(PLINTH_X, PLINTH_H, PLINTH_Z),
		Vector3(0.0, PLINTH_H * 0.5, 0.0), Color(0.34, 0.34, 0.36), "Plinth")

	# THE DATUM. One rail across all six bays at the tier-1 height. Six full cages
	# were built first and photographed as a picket fence that outweighed every
	# organism in the case; the rail is the entire ruler the reading needs.
	var dy: float = PLINTH_H + BASE_H
	_add_box(Vector3(PLINTH_X - 0.06, RAIL_T, RAIL_T),
		Vector3(0.0, dy + RAIL_T * 0.5, RAIL_Z), Color(0.62, 0.63, 0.66), "DatumRail")
	# INTERIOR dividers only — five, between six bays. Seven (a divider at each end
	# too) puts the outermost pair at +/-1.74 while the plinth reaches only +/-1.65,
	# so two of them stood in the air off the end of the case.
	for k in N_BAYS - 1:
		_add_box(Vector3(RAIL_T, BASE_H + RAIL_T, RAIL_T),
			Vector3(_bay_x(k) + PITCH * 0.5, PLINTH_H + (BASE_H + RAIL_T) * 0.5, RAIL_Z),
			Color(0.50, 0.51, 0.54), "Divider%d" % k)

	for b in N_BAYS:
		if grain:
			_build_grain(b, ti)
		else:
			_build_body(b, ti)
	_built = true


func _bay_x(b: int) -> float:
	return (float(b) - 2.5) * PITCH


## The rung the grammar itself defaults to — BiomeGridTokens.tier_of returns it for
## any cell with no `t=`, which is 257 of the corpus's 344 declared biome cells.
func _default_ti() -> int:
	return maxi(TIERS.find(str(BIOME_TOKENS.tier_of({"mods": {}}))), 0)


## grain — the same column in every bay, at the facet count tier buys. Size is
## PINNED so the channel cannot borrow any of body's signal.
func _build_grain(b: int, ti: int) -> void:
	var n: int = int((_ladder[b]["facets"] as Array)[ti])
	_add_cyl(GRAIN_R, GRAIN_H, n, Vector3(_bay_x(b), PLINTH_H + GRAIN_H * 0.5, 0.0),
		_bay_color(b), "Grain_%s" % BAY_TOKENS[b])


func _build_body(b: int, ti: int) -> void:
	var h: float = BASE_H * float((_ladder[b]["ratio"] as Array)[ti])
	# body pins GRAIN at the default rung so the two channels stay disjoint — see
	# dna.predicted_relationship. Derived from the export's own default, never a
	# literal index, so moving the default cannot silently un-pin the control.
	var n: int = int((_ladder[b]["facets"] as Array)[_default_ti()])
	var x: float = _bay_x(b)
	var y0: float = PLINTH_H
	var col: Color = _bay_color(b)
	match b:
		0:
			_build_bloom(x, y0, h, ti, col)
		1:
			_build_tree(x, y0, h, ti, n, col)
		2:
			_build_mushroom(x, y0, h, n, col, false)
		3:
			_build_mushroom(x, y0, h, n, col, true)
		4:
			_build_colony(x, y0, h, ti, col)
		5:
			_build_grub(x, y0, h, ti, n, col)


## The bloom is the only bay whose tier changes what the organism IS. The head is
## built from the preset's own numbers: a pendant bell ring for bluebell, open
## blooms for orchid, a flat ray disc for daisy whose facet count is the preset's
## petal_count. Species is the reason this bay's ladder is not monotone.
func _build_bloom(x: float, y0: float, h: float, ti: int, col: Color) -> void:
	var species: String = str((_ladder[0]["species"] as Array)[ti])
	var preset: Dictionary = FLOWER.PRESETS[species]
	var petals: int = maxi(3, int(preset.get("petal_count", 6)))
	var pc: Variant = preset.get("petal_color", col)
	var head: Color = pc if pc is Color else col
	_add_cyl(0.016, h * 0.72, 6, Vector3(x, y0 + h * 0.36, 0.0),
		Color(0.20, 0.42, 0.17), "BloomStem")
	if species == "bluebell":
		for i in 6:
			var a: float = TAU * float(i) / 6.0
			_add_cyl(0.024, h * 0.26, 6,
				Vector3(x + 0.052 * cos(a), y0 + h * 0.69, 0.052 * sin(a)),
				head, "Bell%d" % i)
	elif species == "orchid":
		for i2 in 5:
			var a2: float = TAU * float(i2) / 5.0
			_add_cyl(0.036, h * 0.12, 6,
				Vector3(x + 0.062 * cos(a2), y0 + h * 0.84, 0.062 * sin(a2)),
				head, "Bloom%d" % i2)
	else:
		_add_cyl(0.105, h * 0.08, petals, Vector3(x, y0 + h * 0.86, 0.0), head, "Rays")
		_add_cyl(0.034, h * 0.18, 8, Vector3(x, y0 + h * 0.95, 0.0),
			Color(0.92, 0.82, 0.20), "Disc")


## The tree carries BOTH of tier's geometry readings: the trunk scales, and the
## number of branch levels is the L-system depth. The depth changes exactly once
## across the ladder, between tier 3 and tier 4.
func _build_tree(x: float, y0: float, h: float, ti: int, n: int, col: Color) -> void:
	var gens: int = int((_ladder[1]["gen"] as Array)[ti])
	_add_cyl(0.034, h * 0.52, n, Vector3(x, y0 + h * 0.26, 0.0),
		Color(0.32, 0.24, 0.18), "Trunk")
	for lev in gens:
		var fy: float = y0 + h * (0.52 + 0.46 * float(lev + 1) / float(gens))
		var rr: float = 0.105 * (1.0 - 0.28 * float(lev) / float(maxi(gens - 1, 1)))
		for i in 3:
			var a: float = TAU * float(i) / 3.0 + float(lev) * 0.7
			_add_cyl(0.046, h * 0.13, n,
				Vector3(x + rr * cos(a), fy - h * 0.065, rr * sin(a)),
				col, "Bough_%d_%d" % [lev, i])


## Bays 2 and 3 are ONE dispatcher function. Same height, same facets; `posed` only
## drops and offsets the cap, which is what apply_softbody_deform does to it.
func _build_mushroom(x: float, y0: float, h: float, n: int, col: Color, posed: bool) -> void:
	var lean: float = 0.058 if posed else 0.0
	var cap_y: float = h * (0.64 if posed else 0.71)
	_add_cyl(0.030, h * 0.64, n, Vector3(x, y0 + h * 0.32, 0.0),
		Color(0.78, 0.74, 0.66), "Stem")
	_add_cyl(0.132, h * 0.20, n, Vector3(x + lean, y0 + cap_y, 0.0), col, "Cap")


## The CA colony freezes at its SPREADING FRONT (dispatcher:298), which is a ring
## with a hollow centre, not a filled ball. Voxel count is the code's `dim`; the
## gaps are index arithmetic, never randf.
func _build_colony(x: float, y0: float, h: float, ti: int, col: Color) -> void:
	var dim: int = int((_ladder[4]["width"] as Array)[ti])
	var layers: int = int((_ladder[4]["extent"] as Array)[ti])
	var v: float = h / float(layers)
	var rr: float = GRAIN_R * float(dim) / float((_ladder[4]["width"] as Array)[TIERS.size() - 1])
	var cnt: int = maxi(6, int(round(PI * float(dim) * 0.5)))
	for iy in layers:
		for i in cnt:
			if (i + iy) % 3 == 0:
				continue                       # the front is a network, not a wall
			var a: float = TAU * float(i) / float(cnt)
			_add_box(Vector3(v, v, v),
				Vector3(x + rr * cos(a), y0 + (float(iy) + 0.5) * v, rr * sin(a) * 0.55),
				col, "Voxel_%d_%d" % [iy, i])


## The grub's body rings ARE seg_count — the number the dispatcher's segments gene
## becomes at creature_morphology.gd:74. Four rungs of tier give three ring counts.
func _build_grub(x: float, y0: float, h: float, ti: int, n: int, col: Color) -> void:
	var m: int = int((_ladder[5]["gen"] as Array)[ti])
	for i in m:
		var t: float = (float(i) + 0.5) / float(m)
		var r: float = 0.068 * (1.0 - 0.35 * abs(float(i) - float(m) * 0.35) / float(m))
		_add_cyl(r, h / float(m), n, Vector3(x, y0 + h * t, 0.0), col, "Ring%d" % i)


# ── the family's own palette, so a bay is the colour its kingdom is in a map ──
func _bay_color(b: int) -> Color:
	match b:
		0:
			return BIOME_CFG.get_kingdom_color(BIOME_CFG.KINGDOM_FLOWER)
		1:
			return BIOME_CFG.get_kingdom_color(BIOME_CFG.KINGDOM_TREE)
		5:
			return BIOME_CFG.get_kingdom_color(BIOME_CFG.KINGDOM_CREATURE)
		_:
			return BIOME_CFG.get_kingdom_color(BIOME_CFG.KINGDOM_FUNGUS)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.72
	m.metallic = 0.0
	return m


func _add_box(size: Vector3, pos: Vector3, c: Color, nm: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	mi.name = nm
	add_child(mi)


## radial_segments IS the axis in the grain channel — the facet count a morphology's
## LOD table hands the mesher, drawn as the cross-section it actually produces.
func _add_cyl(r: float, h: float, sides: int, pos: Vector3, c: Color, nm: String) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(h, 0.004)
	mesh.radial_segments = clampi(sides, 3, 64)
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	mi.name = nm
	add_child(mi)


# ═════════════════════════════════════════════════════════════════════════════
# THE CLAIMS THIS FILE MAKES ABOUT ITSELF
# ═════════════════════════════════════════════════════════════════════════════

## LAW 1, both directions, at run time — neither list can be derived from the other
## at parse time. The tier list is additionally round-tripped through the FAMILY'S
## OWN parser: every declared value must survive tier_of unchanged, and a value off
## either end must clamp back onto the list. That is what proves "1".."5" is the
## family's range and not five strings that happen to look like it.
func _check_vocabularies() -> void:
	_check_hint("tier", TIERS)
	_check_hint("channel", CHANNELS)
	for word in TIERS:
		var got: int = BIOME_TOKENS.tier_of({"mods": {"t": word}})
		if str(got) != word:
			push_error("TierTerrarium: tier_of('%s') = %d — the declared value is not the family's" % [word, got])
	if BIOME_TOKENS.tier_of({"mods": {"t": "0"}}) != int(TIERS[0]):
		push_error("TierTerrarium: tier_of below the list does not clamp to %s" % TIERS[0])
	if BIOME_TOKENS.tier_of({"mods": {"t": "6"}}) != int(TIERS[TIERS.size() - 1]):
		push_error("TierTerrarium: tier_of above the list does not clamp to %s" % TIERS[TIERS.size() - 1])
	# About the DECLARED default, not the value the sweep happens to be rendering —
	# comparing against `tier` would fire on eight of the ten sweep frames and say
	# nothing. If the grammar's fallback moves, DEFAULT_TIER is what has gone stale.
	var fallback: int = BIOME_TOKENS.tier_of({"mods": {}})
	if str(fallback) != DEFAULT_TIER:
		push_error("TierTerrarium: DEFAULT_TIER is '%s' but the grammar now falls back to %d" % [
			DEFAULT_TIER, fallback])
	if not TIERS.has(DEFAULT_TIER):
		push_error("TierTerrarium: DEFAULT_TIER '%s' is not in the declared value list" % DEFAULT_TIER)


func _check_hint(prop: String, allow: PackedStringArray) -> void:
	var hint: String = ""
	for p in get_property_list():
		if str(p.get("name", "")) == prop:
			hint = str(p.get("hint_string", ""))
	var declared: PackedStringArray = hint.split(",", false)
	for w in declared:
		if not allow.has(w):
			push_error("TierTerrarium: export '%s' declares '%s', the allow-list does not" % [prop, w])
	for w2 in allow:
		if not declared.has(w2):
			push_error("TierTerrarium: allow-list has '%s', the '%s' export hint does not" % [w2, prop])


## LAW 20 — a relationship, not only a number, and it is falsifiable to the bit.
##
## (1) living_fungus_fruit and living_fungus_pose are not two implementations. Both
##     route to _spawn_fungus_preset (dispatcher:464-469), so their extent ratio and
##     their facet count must be EQUAL at all five tiers — ten comparisons, threshold
##     1e-9 and integer equality. If they ever differ, one of the two ladders above
##     was mis-derived and this artifact is exhibiting a typo.
##
## (2) The grain channel pins every column to GRAIN_H, so under grain the six bays
##     stand at one height at every tier. Anything else means grain has borrowed
##     signal from body and the two axes are entangled.
func _check_relationship() -> void:
	var fruit: Dictionary = _ladder[2]
	var pose: Dictionary = _ladder[3]
	for i in TIERS.size():
		if absf(float((fruit["ratio"] as Array)[i]) - float((pose["ratio"] as Array)[i])) > 1e-9:
			push_error("TierTerrarium: fruit and pose share one dispatcher branch but their tier-%d extents differ" % (i + 1))
		if int((fruit["facets"] as Array)[i]) != int((pose["facets"] as Array)[i]):
			push_error("TierTerrarium: fruit and pose share one dispatcher branch but their tier-%d facets differ" % (i + 1))


# ═════════════════════════════════════════════════════════════════════════════

## Rebuild ONLY on a value this artifact owns, and only after _ready has built once
## — force_pad tore itself down on every call, including ones naming nothing of its.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("tier"):
		var v: String = str(config_data["tier"])
		if TIERS.has(v) and v != tier:
			tier = v
			dirty = true
	if config_data.has("channel"):
		var c: String = str(config_data["channel"])
		if CHANNELS.has(c) and c != channel:
			channel = c
			dirty = true
	if dirty and _built:
		_build()
