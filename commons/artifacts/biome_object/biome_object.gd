extends Node3D
class_name BiomeObject
## biome_object.gd — THE BIOME AS ONE OBJECT (2026-09-18, Palle: "skip the glass cage and the
## whole museum for now, just make the biome... look at the old biome and make it better and
## better. Use RSI to make the object and the integrated tiles").
##
## July's biome shot every kingdom alone on a bare platform (/biome-gallery: a tree, a web, a
## grub, each in its own cell). This is the other picture: one ground, and everything on it
## placed by ECOLOGY and CONNECTED —
##
##   substrate   a height field with a basin: relief from noise, the basin dug where the seed
##               puts the water; a flat floor under the pool and a wet shelf round it as the
##               shore (gen 1); the moisture PAINTED on as brush layers (gen 1) — the WHOLE
##               gradient, ochre wherever it is dry, moss wherever wet, a sand shore on the
##               shelf, silt darkest at the middle of the pool (gen 2); the canopy's SHADE
##               painted last, read off the measured canopy — dark moss at the trunk (gen 4);
##               bare ROCK painted at every crystal cluster and under its scree (gen 5); the
##               shade painted where the rig's SUN throws it — the trunk carried along
##               SUN_XZ by the crown's height — and a slope facing the sun drier than its
##               lee at the same height and distance from the water (gen 11)
##   water       a pool in the basin (the old biome's own pool: disc, ripple rings, reeds), the
##               disc lapping the shelf and the reeds standing on the shore (gen 1); one thin
##               ring set toward the oldest tree — an edge, not a target (gen 2); the disc a
##               vertex-coloured fan, deep at the middle and pale at the rim, DARKENED under
##               the measured canopy — built after the bodies so it can read it (gen 7)
##   mineral     crystal clusters on the dry ridge — 3 cells from the water and off the outer
##               ring, the spires tallest where it is high and dry (gen 3); SCREE from every
##               cluster — small shards at growing intervals down the slope (the height
##               gradient; the basin's way when it is flat or falls off the plate), stopping
##               at the water, the edge or a rise: the ridge comes down to the water, the
##               web's arrow reversed (gen 5); the spires' glow cut to 0.15 of their colour and
##               rougher — a mineral, not a lamp (gen 7)
##   fungus      mycelium filaments on the wet rim of the pool, and a mycelium PATH from the
##               pool out to every tree — the network that joins water to wood; sampled ON the
##               line every 0.5 m, dry cells only, the last mat touching the trunk, finished at
##               the water and still growing at the tip (gen 2); the web's light by its growth
##               — 0.55 at the water down to 0.22 at the tip (gen 7)
##   flora       trees on the mid-moist slope, flowers in the wet meadow, tiers by moisture;
##               SUCCESSION from the water — the shore tree the oldest, the frontier tree a
##               sapling (gen 2); the bodies GROWN by the object — every node the dispatcher
##               hands back is scaled: a tree by its rank and the moisture (the shore tree
##               ~5 m, capped so its measured canopy stays inside the footprint), a flower by
##               the moisture, a creature 1.6x (gen 3); every tree one species (inten 1-4) and
##               the meadow at the DRIP LINE — no flower under a canopy, a ring round it (gen 4),
##               the ring's bonus only on the LIT side of the trunk (gen 11)
##   fauna       creatures beside the flowers and the fungus
##   cover       grass and stubble by moisture, on the surface, everywhere; the understory
##               follows the canopy — ferns and toadstools under a tree, toadstools along the
##               web, the grass green where wet and straw where dry, bare where driest (gen 3);
##               none within 0.8 m of a crystal cluster — bare rock (gen 5); moisture-sized
##               tufts, shore beds and litter inside the canopy; every member checks water,
##               bare rock and its mesh footprint, capped at 864 cover instances (gen 6); the
##               ferns and toadstools in the SHADOW, where the paint is, the litter still at
##               the foot — leaves fall straight down (gen 11)
##
## Every organism is the old biome's builder, reached through BiomePaintDispatcher exactly as
## a painted map cell would reach it, only the CELL is chosen by moisture, height and slope
## instead of by hand. The DNA is five numbers: seed, size, moisture, relief, wildness.
##
## RSI: this file carries its GENERATION and CHANGELOG; tools/biome_rsi.py renders the same
## six DNAs every generation, measures the tiles (integration-v1: kingdoms present +
## connections, named), records the lineage, and a critic proposes the next change. A
## critic records a kept/culled verdict after looking at matched images: named measures
## can flag a regression but do not replace that judgment.
##
## Record: with record=on the build writes res://ada_run/biome_rsi/state/<label>.json — the
## counts the driver reads (organisms per kingdom, connections, cover, heights, build ms).

const Residents := preload("res://commons/artifacts/biome_object/biome_residents.gd")
const Dispatcher := preload("res://commons/biome_layers/biome_paint_dispatcher.gd")
const Ground := preload("res://commons/biome_layers/biome_ground_substrate.gd")
const Cover := preload("res://commons/biome_layers/ground_cover.gd")
const FoliageCards := preload("res://commons/biome_layers/foliage_cards.gd")

const GENERATION := 13
const CHANGELOG: Array[String] = [
	"gen 0: the object — basin terrain, pool, ridge crystals, rim mycelium + a mycelium path to every tree, slope trees, meadow flowers, creatures beside them, cover by moisture",
	"gen 1: the basin filled (a flat floor under the water, a wet shelf as shore, the disc lapping the shelf, reeds on the shore, a bluer water material) and the moisture painted onto the ground as wet, dry and silt brush layers",
	"gen 2: succession from the water (the trees ranked by distance to it, the shore tree inten 3-5 and the frontier tree a sapling), the mycelium path sampled on the line every 0.5 m from 0.85 m past the pool to 0.45 m short of the trunk, skipping flooded cells, gen 25 at the water and 10 at the tree; the ground painted with the whole gradient (ochre wherever dry, moss, a sand shore, silt by depth) and the pool's two glowing rings replaced by one thin ring set toward the oldest tree, the disc at alpha 0.72",
	"gen 3: the bodies grown by the object — every node the dispatcher hands back scaled about its foot: a tree by k = (1.5 + 1.3·rank)(0.75 + 0.35·moisture), capped so the measured canopy (the merged branch mesh's AABB + 0.25·dna.scale) stays inside the footprint, a flower by 1.4 + 0.4·moisture, a creature 1.6, a mat 1.0; an edge cell scores 0.4 less in the tree draw; each kingdom's spawn timed into ms_<kingdom>. The understory follows the canopy: cover accepted at 0.06 + 0.94·m², ferns and toadstools under a canopy, toadstools within 0.7 m of a mat, grass lerped green to straw by dryness, scale (0.5 + 0.7·m)·1.4. The minerals leave the shore: 2.5 cells from the water, off the outer ring, a retry at h > 0.5, the spires scaled by height and dryness",
	"gen 4: the canopy casts a layer — the ground built AFTER the bodies (terrain, ecology, pool, minerals, dispatch, ground, cover) so the paint reads the canopy _dispatch() measured; a fifth brush layer, shade [0.11, 0.17, 0.09], painted last: per dry-land cell v = max over trees of 0.85·(1 − d/canopy)^0.6, kept over 0.02; the meadow at the drip line — u the cell's distance to the nearest trunk over rs = 0.6·(0.6 + 0.2·inten)·k, no flower under u 0.85, the ring to 1.6 scoring 0.25 more (the jitter still drawn, so the creatures' stream holds); the succession clamped to inten 1..4, so no tree flips to the lod-3 flat-leaf species — the six canopies one species",
	"gen 5: scree — the ridge comes down to the water. After each cluster's shard loop (its draws untouched) a second rng seeded from the cell lays 3 + round(4·relief) shards down the slope: down = −(height gradient at the cluster, ±0.5 m samples), toward the basin when |g| < 0.02 or when downhill leads away from it (measured: from the rim's ridge cells the bare gradient ran 11 of 16 trails off the plate and none to the water); shard i at p + down·(0.55 + 0.5i + 0.08i²), the trail ending at a water cell, the edge (the prism's half-diagonal 0.12·scale inside it), a flooded sample (h < wl + 0.02) or a rise (h over the trail's lowest point + 0.02); each a PrismMesh (0.09, randf(0.08, 0.2)·(1 − 0.6i/n), 0.09)·scale lying at rotation (0.6..1.3, 0..TAU, ±0.3), the crystal colour at emission ×0.2, added to the patch at the sample, its centre 0.3 h above the surface. A _rock map — 0.6 at the cluster, 0.3 on its eight neighbours, 0.35 per scree cell (max) — painted as a sixth layer, rock [0.56, 0.55, 0.50], after the silt and before the shade; the cover skips samples within 0.8 m of a cluster; the ridge is 3.0 cells from the water",
	"gen 6: ground cover grows in moisture-sized tufts, reed beds at the shore and flat litter beneath the inner canopy; each member respects water, mineral ground and the footprint, the group has a private seeded rng, the budget is at most 864 instances; all other kingdom placement rules are unchanged",
	"gen 7: water depth under the canopy, the web's light by its growth. The pool's disc is a 48-segment SurfaceTool fan, 6 rings deep (289 vertices, 528 tris — one ring cannot carry a profile), its vertex colours the albedo, no emission, roughness 0.08, metallic 0.3: centre (0.06, 0.20, 0.44, 0.92) to rim (0.24, 0.50, 0.68, 0.62) by u^1.5, every vertex's rgb × (1 − 0.45·vs), vs = max over trees of (1 − d/canopy)^0.6 with d the vertex's distance to the trunk — the ground's shade law — the alpha kept so the shaded water is darker, not thinner; the pool built AFTER _dispatch() (terrain, ecology, minerals, dispatch, pool, ground, cover) so vs reads the measured canopy — nothing between read the Pool node and the pool's rng is the seed's, so no draw moved. Each mycelium mat's MyceliumWeb material duplicated (mats share no instance) and its emission_energy_multiplier set to lerp(0.55, 0.22, t), t = (25 − gen)/15 — a rim mat carries no gen and reads 25 — the colour kept, the spores untouched. The cluster spires' emission col × 0.15 (was 0.5), roughness 0.35 (was 0.22); the scree untouched Amended before the render by the gen-6 critic: the ring dropped (the depth gradient is the edge) and the web's light reversed — dim (0.22) at the finished rim, bright (0.55) at the growing tip on the bark",
	"gen 8: grass and plant foliage as transparent images (Palle) — the cover's grass, reeds, ferns, meadow plants and litter are alpha-cut cards on two crossed quads, images from commons/biome_layers/foliage/ (tools/make_foliage_cards.py draws the defaults, any same-named PNG replaces one) loaded at runtime, tinted near white by dryness and shade; mushrooms keep their mesh; a missing image falls back to the old mesh",
	"gen 9: the foliage cards drawn IN the engine from the seed (Palle: can we make the foliage card procedurally?) — commons/biome_layers/foliage_cards.gd paints grass, reed, fern, plant and litter on an Image at build time with a disc brush along Bézier strokes and sin-profiled leaves; the seed shapes them, the moisture changes what grows (blade count and straw, cattail heads only when wet, fuller ferns and broader leaves when wet, redder litter when dry); cached per kind, seed and moisture band; `#foliage:files` keeps the PNG set",
	"gen 10: the ground in section - four soil/rock bands and a sealed underside follow the existing terrain boundary exactly; a thicker dark organic layer reads the local moisture, the surface strip reads mineral ground; a schematic profile, not simulated geology; one mesh/material, 864 triangles at size 12, no changed organism placement or foliage",
	"gen 11: aspect — the sun is a layer (the gen-6 critic's proposal 1). The rig's key light is frozen at rotation (−42°, −35°): it travels along xz SUN_XZ = (0.574, −0.819) at 42° elevation, SUN_RUN = 1/tan 42° = 1.111 m of run per metre of height. (a) _dispatch() measures each tree's crown height _crown = 0.6·(merged branch top)·k (1.2·r·k without a mesh); a tree's shade centre is trunk + SUN_XZ·SUN_RUN·crown, and ONE law, _shade_at(p) = max over trees of (1 − |p − sc|/canopy)^0.6, now feeds the ground's shade layer (×0.85), the pool's vertex darkening (gen 7's, moved with it) and the cover's `shaded` (ferns and toadstools in the shadow, darker and smaller there); the litter keeps the trunk — leaves fall straight down; the meadow's drip-line bonus is +0.25 only on the LIT side of its nearest trunk ((cell − trunk)·SUN_XZ < 0), +0.05 on the shaded side. No new draw: (a) moved the paint, the understory and the meadow's side and left every other count. (b) the moisture loop takes an aspect term after its jitter draw: g = (h(x+1) − h(x−1), h(z+1) − h(z−1))·0.5 in metres, m −= 0.12·clamp(g·SUN_XZ/0.25, −1, 1) — the flank facing the sun dries, the lee holds — which re-rolls the layout by the seed (trees, meadow, rim, creatures, the ridge)",
	"gen 12: catalogue residents share the ground but carry independent community DNA; up to six fruiting-fungus colonies use existing CritterDNA presets and FungusMorphology, choose moist gaps beside mycelium, respect an explicit footprint and clear cover beneath them; changing community_seed keeps terrain, water, trees and networks fixed; each resident records catalogue identity, preset, expressed genes, seed and habitat",
	"gen 13: two more catalogue builders on Astra's contract, the object handing over slots it already owns instead of adding bodies. (a) living_flora_bloom — the nine BotanicalFlower species are families with designed habitat preferences (moisture, shade, the sun's side of the trunk); _ecology() marks every second or third meadow cell `resident` by a stride and phase drawn from the HABITAT seed (never the community's, never the ecology's stream), _dispatch() leaves those cells, and populate() stands a species there chosen by the community seed and the slot's habitat, the SIZE still the habitat's (the dispatcher's overall_scale on the cell's intensity, the moisture growth 1.4 + 0.4·m) — another community, another species, the same size; the meadow count is unchanged and the flag is a fact about the seed, so residents:off rebuilds gen 12 exactly. (b) living_fauna_body — every creature cell (1–4) is handed over, so the animal count does not double; three body plans (shore_grub: low, more rings, social, dark, drawn to the water; meadow_walker: taller, fewer rings, lighter, sun-side; rock_lurker: iridescent, metallic, coiled, drawn to the crystals) are CritterDNA gene overrides on the dispatcher's own walker recipe, built by CreatureSdfMorphology, each body's xz centred on its slot and TURNED to face what it lives by — the nearest water cell within 3 cells, else the nearest flower cell — rotation.y = atan2(−dx, −dz) since the eyes look down local −Z; the record carries `faces` and `footprint`. These are PLACED bodies: no movement, no simulation. Each slot's cover clearing is a fixed radius (0.32 m a bloom, 0.5 m a body), so the cover is the same under every community. Three facts learned building it: a bloom slot must stand BLOOM_EDGE_M = 1.0 m inside the plate (a crown imperial at overall_scale 2.5 × growth 1.74 measured 0.67 m of reach from an outer-ring slot 0.31 m off the edge); a body's bounds must be composed from LOCAL transforms (measured through inverse(root.global) × node.global, a twin standing 30 m along x recorded a reach 1.6e-6 m different — the record drifted with the address); and the SDF builder's skin must be re-created with the body seed (the mapper draws pattern_rotation from the global randi() when handed no seed)",
]
const STATE_DIR := "res://ada_run/biome_rsi/state"
## gen 11: THE SUN. The capture rig's key light (commons/testing/capture_config_sweep.gd,
## _stage_default — frozen, it took every published tile): `key.rotation_degrees =
## Vector3(-42, -35, 0)`, Godot's YXZ order, shining along local −Z, so in world it travels
## along Y(−35°)·X(−42°)·(0, 0, −1) = (0.426, −0.669, −0.609): horizontally along xz
## (0.574, −0.819), at 42° elevation. A point h above the ground throws its shadow
## h / tan 42° = 1.111·h along SUN_XZ. The rig is frozen; the object READS the light, it does
## not carry one (the gen-6 critic: "do not replace it").
const SUN_XZ := Vector2(0.574, -0.819)
const SUN_RUN := 1.111   # 1 / tan 42°
## gen 13: a meadow cell is a resident slot only when its body point stands this far inside
## the plate — a bloom there may be any species at the habitat's size (measured: a crown
## imperial at overall_scale 2.5 × growth 1.74 reaches 0.67 m; an iris's leaves ~0.9 m).
const BLOOM_EDGE_M := 1.0
const K_TREE := 0
const K_CREATURE := 1
const K_FLOWER := 2
const K_FUNGUS := 3

@export var seed: int = 7
## Vary the catalogue bodies without rerolling the terrain or its established ecology.
@export var community_seed: int = 0
@export_enum("on", "off") var residents: String = "on"
## Cells across (one metre each).
@export_range(4, 24) var size: int = 12
## How wet the ground is: the basin's reach, the meadow's extent, the cover's density.
@export_range(0.0, 1.0) var moisture: float = 0.5
## Height of the terrain: 0 is a plain, 1 a hill of two metres with a ridge.
@export_range(0.0, 1.0) var relief: float = 0.5
## How much grows: tree count, flower density, creature count, cover.
@export_range(0.0, 1.0) var wildness: float = 0.6
@export_enum("on", "off") var record: String = "on"
## The foliage cards: `drawn` (gen 9 — drawn in the engine from the seed and the moisture, no
## files) or `files` (the PNGs in commons/biome_layers/foliage/, a hand-painted set).
@export_enum("drawn", "files") var foliage: String = "drawn"

var _residents: Array[Dictionary] = []
var _built: bool = false
var _field: PackedFloat32Array = PackedFloat32Array()   # per cell 0..1
var _max_h: float = 1.0
var _water: Dictionary = {}          # Vector2i -> true
var _basin_c: Vector2 = Vector2.ZERO
var _basin_r: float = 2.0
var _pool_r: float = 1.2             # gen 2: the water's radius (cells), read by the paint and the pool
var _moist: PackedFloat32Array = PackedFloat32Array()
var _cells: Dictionary = {}          # Vector2i -> {kingdom: String, inten: int, algo: String[, gen: String]}
var _trees: Array[Vector2i] = []     # gen 2: sorted by distance to the water, the shore tree first
var _pos: Dictionary = {}            # gen 2: Vector2i -> Vector2 world xz, the trunks and the path's mats
var _paths: Dictionary = {}          # gen 2: Vector2i tree -> Array[Vector2i] path cells, water to trunk
var _canopy: Dictionary = {}         # gen 3: Vector2i tree -> float, the SCALED canopy radius (m), measured at dispatch
var _crown: Dictionary = {}          # gen 11: Vector2i tree -> float, the crown's height (m) at the body's scale — the shadow's run is SUN_RUN × this
var _meadow_cand: Array = []         # gen 11: every meadow candidate past the canopy — {key, base, u, lit}; the probe replays the ring's rule on it
var _mats: Array[Vector2] = []       # gen 3: every fungus body's world xz as placed — the cover's "along the web"
var _rock: Dictionary = {}           # gen 5: Vector2i -> float, bare rock at the clusters and under the scree — the paint reads it
var _clusters: Array[Vector2] = []   # gen 5: every crystal holder's world xz — the cover keeps 0.8 m off
var _patch: Node3D
var _dispatcher: Node3D
var _counts: Dictionary = {}
var _build_ms: int = 0
var _section_columns: Array[Dictionary] = [] # the four cut faces: local positions, moisture, layer levels
var _cover_tufts: Array[Dictionary] = [] # CPU placement plan: groups share type, colour and neighbours


func apply_grid_config(config: Dictionary) -> void:
	if config.has("community_seed"):
		community_seed = int(str(config["community_seed"]).to_int())
	if config.has("residents"):
		residents = "off" if str(config["residents"]).to_lower() in ["off", "0", "false"] else "on"
	if config.has("seed"):
		seed = int(str(config["seed"]).to_int())
	if config.has("size"):
		size = clampi(int(str(config["size"]).to_int()), 4, 24)
	if config.has("moisture"):
		moisture = clampf(float(str(config["moisture"]).to_float()), 0.0, 1.0)
	if config.has("relief"):
		relief = clampf(float(str(config["relief"]).to_float()), 0.0, 1.0)
	if config.has("wildness"):
		wildness = clampf(float(str(config["wildness"]).to_float()), 0.0, 1.0)
	if config.has("record"):
		record = "off" if str(config["record"]).to_lower() in ["off", "0", "false"] else "on"
	if config.has("foliage"):
		foliage = "files" if str(config["foliage"]).to_lower() == "files" else "drawn"
	if _built and is_inside_tree():
		_rebuild()


func _ready() -> void:
	if _built:
		return
	_build()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_built = false
	_build()


func label() -> String:
	var base := "s%d_m%02d_r%02d_w%02d" % [seed, int(round(moisture * 100.0)), int(round(relief * 100.0)), int(round(wildness * 100.0))]
	return base + ("_c%d" % community_seed if community_seed != 0 else "")


func _build() -> void:
	_built = true
	var t0 := Time.get_ticks_msec()
	_counts = {"water": 0, "mineral": 0, "scree": 0, "fungus": 0, "fungus_path": 0, "tree": 0, "flower": 0,
		"creature": 0, "cover": 0, "connections": 0, "paint": 0,
		"ms_tree": 0, "ms_flower": 0, "ms_fungus": 0, "ms_creature": 0,   # gen 3: the bill, by payer
		"slots_bloom": 0, "slots_body": 0, "flower_dispatched": 0, "creature_dispatched": 0,   # gen 13: the slots handed over, the bodies the dispatcher still built
		"residents_fungus": 0, "residents_bloom": 0, "residents_body": 0}
	_patch = Node3D.new()
	_patch.name = "Biome"
	add_child(_patch)
	_terrain()
	_ecology()
	_minerals()
	_dispatch()
	_water_pool() # gen 7: after the bodies — the disc's shade reads the canopy _dispatch() measured
	_ground()     # gen 4: after the bodies — the paint reads the canopy _dispatch() measured
	_section()
	_residents.clear()
	var residents_start := Time.get_ticks_msec()
	if residents == "on":
		_residents = Residents.populate(self, community_seed)
	_counts["residents"] = _residents.size()
	_counts["ms_residents"] = Time.get_ticks_msec() - residents_start
	# gen 13: the residents by artifact — the count line's "flowers" and "creatures" stay the
	# ecology's cells; a resident stands in a cell the dispatcher left, never beside its body
	for r in _residents:
		match String(r["artifact"]):
			"living_fungus_fruit": _counts["residents_fungus"] += 1
			"living_flora_bloom": _counts["residents_bloom"] += 1
			"living_fauna_body": _counts["residents_body"] += 1
	_cover()
	_build_ms = Time.get_ticks_msec() - t0
	print("[biome_object] gen %d %s: water %d, mineral %d (scree %d), fungus %d (path %d), trees %d, flowers %d, creatures %d, cover %d, connections %d, paint %d — %d ms (tree %d, flower %d, fungus %d, creature %d); residents %d (fungus %d, blooms %d of %d slots, bodies %d of %d slots) %d ms" % [
		GENERATION, label(), _counts["water"], _counts["mineral"], _counts["scree"], _counts["fungus"], _counts["fungus_path"],
		_counts["tree"], _counts["flower"], _counts["creature"], _counts["cover"], _counts["connections"], _counts["paint"], _build_ms,
		_counts["ms_tree"], _counts["ms_flower"], _counts["ms_fungus"], _counts["ms_creature"],
		_counts["residents"], _counts["residents_fungus"], _counts["residents_bloom"], _counts["slots_bloom"], _counts["residents_body"], _counts["slots_body"], _counts["ms_residents"]])
	if record == "on":
		_write_state()


# ── the ground: a height field with a basin ────────────────────────────────────
func _terrain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "terrain"])
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.13
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45
	_max_h = 0.5 + 1.7 * relief
	# the basin: where the seed puts the water, its reach grows with moisture
	_basin_c = Vector2(rng.randf_range(0.28, 0.72) * float(size), rng.randf_range(0.28, 0.72) * float(size))
	_basin_r = 1.4 + 2.2 * moisture + 0.15 * float(size) / 12.0
	_field.resize(size * size)
	var lo := 9.0
	var hi := -9.0
	for z in range(size):
		for x in range(size):
			var n: float = (noise.get_noise_2d(float(x) + 0.5, float(z) + 0.5) + 1.0) * 0.5
			_field[z * size + x] = n
			lo = minf(lo, n)
			hi = maxf(hi, n)
	for i in range(size * size):
		_field[i] = (_field[i] - lo) / maxf(0.001, hi - lo)
	_water.clear()
	# gen 1: the basin is FILLED, not dug to a point: a flat floor under the water cells and a
	# wet shelf one metre wide round them, rising 0.16 per metre. The shelf is the wet rim as
	# geometry; its cells (h <= 0.18) fall out of the tree rule, so trees step back from the shore.
	_pool_r = _basin_r * 0.62
	for z in range(size):
		for x in range(size):
			var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).distance_to(_basin_c)
			var w: float = clampf(1.0 - d / _basin_r, 0.0, 1.0)
			w = w * w * (3.0 - 2.0 * w)
			var h: float = _field[z * size + x] * (1.0 - w) * (0.75 + 0.25 * relief) + 0.08 * (1.0 - w)
			if d < _pool_r:
				h = minf(h, 0.02)                          # flat floor under the water
			elif d < _pool_r + 1.0:
				h = minf(h, 0.02 + 0.16 * (d - _pool_r))   # the wet shelf, a shore
			_field[z * size + x] = h
			if d < _pool_r:
				_water[Vector2i(x, z)] = true


func _h_cell(x: int, z: int) -> float:
	return _field[clampi(z, 0, size - 1) * size + clampi(x, 0, size - 1)] * _max_h


## Surface height at a world xz (bilinear over cell centres).
func _h_at(wx: float, wz: float) -> float:
	var fx: float = wx + float(size) * 0.5 - 0.5
	var fz: float = wz + float(size) * 0.5 - 0.5
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var tx: float = fx - float(x0)
	var tz: float = fz - float(z0)
	var a: float = lerpf(_h_cell(x0, z0), _h_cell(x0 + 1, z0), tx)
	var b: float = lerpf(_h_cell(x0, z0 + 1), _h_cell(x0 + 1, z0 + 1), tx)
	return lerpf(a, b, tz)


func _cell_world(x: int, z: int) -> Vector3:
	var wx: float = float(x) - float(size) * 0.5 + 0.5
	var wz: float = float(z) - float(size) * 0.5 + 0.5
	return Vector3(wx, _h_at(wx, wz), wz)


func _water_level() -> float:
	var lo := 9.0
	for k in _water.keys():
		lo = minf(lo, _h_cell(k.x, k.y))
	return lo + 0.08


# ── the ecology: moisture, then the rules that place every kingdom ───────────────
func _ecology() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "ecology"])
	_moist.resize(size * size)
	_cells.clear()
	_trees.clear()
	_pos.clear()
	_paths.clear()
	var reach: float = float(size) * (0.35 + 0.35 * moisture)
	for z in range(size):
		for x in range(size):
			var d: float = _water_dist(x, z)
			var h: float = _field[z * size + x]
			var m: float = 0.25 * moisture + 0.75 * clampf(1.0 - d / reach, 0.0, 1.0) - 0.45 * h + rng.randf_range(-0.06, 0.06)
			# gen 11 (b): ASPECT — the flank facing the sun dries, the lee holds. g is the height
			# gradient in metres over ±1 cell (one-sided and halved at the plate's edge); a slope
			# whose uphill runs along SUN_XZ faces the sun — the light comes from −SUN_XZ and
			# falls on it — and loses up to 0.12, saturating at a 0.25 m/m grade; the lee gains
			# the same. Taken AFTER the jitter draw, so the dice are gen 10's: the re-roll is the
			# moisture's — the ridge, the trees, the meadow, the rim all read it
			var g := Vector2(_h_cell(x + 1, z) - _h_cell(x - 1, z), _h_cell(x, z + 1) - _h_cell(x, z - 1)) * 0.5
			m -= 0.12 * clampf(g.dot(SUN_XZ) / 0.25, -1.0, 1.0)
			_moist[z * size + x] = clampf(m, 0.0, 1.0)
	# minerals: the driest high cells, spaced. gen 3: 2.5 cells from the water and off the
	# outer ring — no crystal in a pond or on the rim (measured gen 2: two crystals stood at
	# s11's water's edge, a high cell two cells out passing because the height term pulled m
	# under 0.42); a world with no cell over 0.62 retries at 0.5 so the mineral kingdom stays
	var ridge: Array = _ridge(0.62)
	if ridge.is_empty():
		ridge = _ridge(0.5)
	ridge.sort_custom(func(p, q): return float(p["h"]) > float(q["h"]))
	var n_min: int = clampi(1 + int(round(relief * 3.0)), 1, 4)
	for r in ridge:
		if _counts["mineral"] >= n_min:
			break
		if _spaced(r["key"], 2):
			_cells[r["key"]] = {"kingdom": "mineral", "inten": 3, "algo": ""}
			_counts["mineral"] += 1
	# trees: the mid-moist slope, spaced two cells apart
	var cand: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var m: float = _moist[z * size + x]
			var h: float = _field[z * size + x]
			if m > 0.32 and m < 0.78 and h > 0.18 and h < 0.8 and _water_dist(x, z) > 1.4:
				# gen 3: an edge cell scores 0.4 less — a canopy there is capped at the footprint;
				# the draw stays so the rng stream is gen 2's
				var edge_pen: float = 0.4 if (x == 0 or z == 0 or x == size - 1 or z == size - 1) else 0.0
				cand.append({"key": key, "s": m * (1.0 - absf(h - 0.45)) + rng.randf() * 0.15 - edge_pen})
	cand.sort_custom(func(p, q): return float(p["s"]) > float(q["s"]))
	var n_tree: int = clampi(2 + int(round(wildness * 4.0)), 1, 7)
	for c in cand:
		if _trees.size() >= n_tree:
			break
		if _spaced(c["key"], 2):
			var inten: int = clampi(2 + int(round(wildness * 3.0)) + rng.randi_range(-1, 0), 1, 5)
			_cells[c["key"]] = {"kingdom": "tree", "inten": inten, "algo": ""}
			_trees.append(c["key"])
			_counts["tree"] += 1
	# gen 2: SUCCESSION from the water — the trees sorted by their distance to it, rank i of n
	# setting the age: the shore tree inten 3-5, the frontier tree 1 (scale is 0.6 + 0.2·inten,
	# so the shore tree is twice the sapling). The draw above stays so the rng stream the rim,
	# meadow and creatures read is gen 1's; the rank overrides what it drew.
	_trees.sort_custom(_nearer_water)
	var n_ranked: int = _trees.size()
	for i in range(n_ranked):
		var t: Vector2i = _trees[i]
		var rank: float = 1.0 - float(i) / float(maxi(1, n_ranked - 1))
		# gen 4: capped at 4 — inten 5 is lod 3 in _spawn_tree, the flat-leaf mesh; one species
		_cells[t]["inten"] = clampi(int(round(1.0 + 4.0 * rank * (0.4 + 0.4 * wildness + 0.2 * moisture))), 1, 4)
		# gen 3: the body's scale. The dispatcher's size knob stops at dna.scale 1.6 (~1.8 m); the
		# object owns the node it gets back and grows it by rank and moisture — the shore tree
		# 2.8x on wet ground, the frontier sapling 1.5x on dry. _dispatch() caps it at the footprint.
		_cells[t]["k"] = (1.5 + 1.3 * rank) * (0.75 + 0.35 * moisture)
		# the trunk's ±0.3 jitter, drawn here from the per-cell rng _dispatch() used to draw it,
		# so the path below can aim at the trunk and not at the cell
		var trng := RandomNumberGenerator.new()
		trng.seed = hash([seed, "cell", t.x, t.y])
		var cw: Vector3 = _cell_world(t.x, t.y)
		_pos[t] = Vector2(cw.x + trng.randf_range(-0.3, 0.3), cw.z + trng.randf_range(-0.3, 0.3))
	# fungus: the wet rim of the pool
	var rim: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var d: float = _water_dist(x, z)
			if d >= 0.9 and d <= 2.3 and _moist[z * size + x] > 0.45:
				rim.append(key)
	_shuffle(rim, rng)
	var n_rim: int = clampi(2 + int(round(moisture * 5.0)), 2, 7)
	for key in rim:
		if _counts["fungus"] >= n_rim:
			break
		if _spaced(key, 1):
			_cells[key] = {"kingdom": "fungus", "inten": clampi(2 + int(round(moisture * 2.0)), 1, 4), "algo": "mycelium"}
			_counts["fungus"] += 1
	# the mycelium PATH: from the pool rim out to every tree. gen 2: the web ON THE LINE — the
	# line from the basin centre (world xz) to the TRUNK, sampled every 0.5 m from 0.85 m past
	# the water to 0.45 m short of the bark, skipping water, occupied cells and flooded samples
	# (the shelf under the water level); one mat per NEW cell, its position the sample itself
	# (clamped 0.7 m inside the footprint, the mat's radius at inten 2 being 0.60 m), the LAST
	# mat forced to 0.45 m from the trunk so it reaches 0.15 m past the bark. Each mat carries
	# gen 25 at the water down to 10 at the tree (the dispatcher reads it into max_steps): the
	# network finished at the water, 40 % grown at the tip — still growing outward.
	var basin_w: Vector2 = _basin_c - Vector2(float(size), float(size)) * 0.5
	var wl: float = _water_level()
	var lim: float = float(size) * 0.5 - 0.7
	for t in _trees:
		var trunk: Vector2 = _pos[t]
		var span: float = trunk.distance_to(basin_w)
		if span < 0.001:
			continue
		var dir: Vector2 = (trunk - basin_w) / span
		var s0: float = _pool_r + 0.85
		var s1: float = span - 0.45
		var placed: Array = []
		# a tree standing closer than 1.3 m to the water has no room for the ladder; it gets
		# its one sample at the trunk end (the critic's range is empty there), at t = 0: nearer
		# the water than any ladder's first rung
		var s: float = s0 if s0 <= s1 else s1
		while s <= s1 + 0.001:
			var p: Vector2 = basin_w + dir * s
			var tt: float = clampf((s - s0) / maxf(0.001, s1 - s0), 0.0, 1.0)
			s += 0.5
			var key := Vector2i(int(floor(p.x + float(size) * 0.5)), int(floor(p.y + float(size) * 0.5)))
			if key.x < 0 or key.y < 0 or key.x >= size or key.y >= size:
				continue
			if _water.has(key) or _cells.has(key):
				continue
			if _h_at(p.x, p.y) < wl + 0.02:
				continue
			if _counts["fungus"] + _counts["fungus_path"] >= 16:
				break
			_cells[key] = {"kingdom": "fungus", "inten": 2, "algo": "mycelium",
				"gen": str(int(round(lerpf(25.0, 10.0, tt))))}
			_pos[key] = Vector2(clampf(p.x, -lim, lim), clampf(p.y, -lim, lim))
			placed.append(key)
			_counts["fungus_path"] += 1
		if placed.is_empty() and _counts["fungus"] + _counts["fungus_path"] < 16:
			# the SHORE tree's case (measured gen 2: the oldest tree was the one left unwebbed on
			# two of three probe DNAs): its only sample, 0.45 m short of the trunk, lies in the
			# tree's OWN cell, which is not new. The mat keeps that position and is keyed to the
			# tree's nearest free neighbour — the cell is the mat's name, the sample its place.
			var q: Vector2 = trunk - dir * 0.45
			var nk: Vector2i = _free_neighbour(t, q)
			if nk.x >= 0 and _h_at(q.x, q.y) >= wl + 0.02:
				var tq: float = clampf((s1 - s0) / maxf(0.001, s1 - s0), 0.0, 1.0)
				_cells[nk] = {"kingdom": "fungus", "inten": 2, "algo": "mycelium",
					"gen": str(int(round(lerpf(25.0, 10.0, tq))))}
				_pos[nk] = q
				placed.append(nk)
				_counts["fungus_path"] += 1
		if not placed.is_empty():
			# on the segment between two interior points, so inside the footprint without a clamp
			_pos[placed.back()] = trunk - dir * 0.45
		_paths[t] = placed
	# flowers: the wet meadow, density by wildness. gen 4: the DRIP LINE — u is the cell centre's
	# distance to the nearest trunk in units of that tree's rs = 0.6·(0.6 + 0.2·inten)·k (the
	# dispatcher's canopy radius at the body's scale; the measured canopy is not known until
	# _dispatch()): no flower under a canopy (u < 0.85), and the ring 0.85..1.6 scores 0.25 more
	# — a meadow ringing the tree. The jitter is drawn before the skip, so the stream the
	# creatures read is gen 3's.
	var rs: Dictionary = {}
	for t in _trees:
		rs[t] = 0.6 * (0.6 + 0.2 * float(int(_cells[t]["inten"]))) * float(_cells[t]["k"])
	var meadow: Array = []
	_meadow_cand.clear()
	# the count is a share of the WET MEADOW, not of what is left after the canopies take
	# their floor — otherwise a shore tree costs the world its flowers (gen 4's builder)
	var meadow_pool := 0
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var m: float = _moist[z * size + x]
			if m > 0.42 and _field[z * size + x] < 0.7:
				meadow_pool += 1
				var base: float = m + rng.randf() * 0.1
				var cwm: Vector3 = _cell_world(x, z)
				var u := 99.0
				var ut := Vector2i(-1, -1)   # gen 11: the tree the ring belongs to — its side decides the bonus
				for t in _trees:
					var ud: float = Vector2(cwm.x, cwm.z).distance_to(_pos[t]) / float(rs[t])
					if ud < u:
						u = ud
						ut = t
				if u < 0.85:
					continue
				# gen 11: the ring's +0.25 only on the LIT side of its trunk — the sun comes from
				# −SUN_XZ, so the lit side is where (cell − trunk)·SUN_XZ < 0; the shaded side +0.05
				var lit: bool = ut.x >= 0 and (Vector2(cwm.x, cwm.z) - (_pos[ut] as Vector2)).dot(SUN_XZ) < 0.0
				var score: float = base
				if u <= 1.6:
					score += 0.25 if lit else 0.05
				# the candidate as scored, before the side's bonus — the probe replays both rules on it
				_meadow_cand.append({"key": key, "base": base, "u": u, "lit": lit})
				meadow.append({"key": key, "m": score})
	meadow.sort_custom(func(p, q): return float(p["m"]) > float(q["m"]))
	var n_fl: int = clampi(int(round(float(meadow_pool) * (0.25 + 0.5 * wildness))), 3, 24)
	# gen 13: the meadow's RESIDENT SLOTS — every `period`-th flower cell (2 or 3) from `phase`,
	# in the order the meadow takes them, is handed to the residents layer: it stays a flower
	# cell (the drip line, the creatures' "beside", the count and the connections all read
	# it) but _dispatch() leaves it and populate() stands a catalogue species there. The
	# stride is drawn from a rng of the HABITAT seed alone — not the community's, so the
	# slots are the same under every community; not the ecology's, whose stream the
	# creatures below still read, so no gen-12 draw moves
	var srng := RandomNumberGenerator.new()
	srng.seed = hash([seed, "bloom_slots"])
	var period: int = srng.randi_range(2, 3)
	var phase: int = srng.randi_range(0, period - 1)
	var fi := 0
	var half_w: float = float(size) * 0.5
	for f in meadow:
		if _counts["flower"] >= n_fl:
			break
		var inten: int = clampi(1 + int(round(float(f["m"]) * 4.5)), 1, 5)
		_cells[f["key"]] = {"kingdom": "flower", "inten": inten, "algo": ""}
		# only a cell whose body point (the jittered centre, _body_xz) stands BLOOM_EDGE_M
		# inside the plate can be a slot: a resident may be any species at the habitat's size,
		# and the largest preset at the largest size reaches ~0.9 m — the outer ring keeps the
		# dispatcher's own flowers, which no rule measures
		var bxz: Vector2 = _body_xz(f["key"])
		if half_w - maxf(absf(bxz.x), absf(bxz.y)) >= BLOOM_EDGE_M:
			if (fi + phase) % period == 0:
				_cells[f["key"]]["resident"] = true
				_counts["slots_bloom"] += 1
			fi += 1
		_counts["flower"] += 1
	# creatures: beside the flowers and the fungus
	var beside: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var near := 0
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var nk := Vector2i(x + dx, z + dz)
					if _cells.has(nk) and String(_cells[nk]["kingdom"]) in ["flower", "fungus"]:
						near += 1
			if near >= 2:
				beside.append(key)
	_shuffle(beside, rng)
	var n_cr: int = clampi(1 + int(round(wildness * 3.0)), 1, 4)
	for key in beside:
		if _counts["creature"] >= n_cr:
			break
		# a creature lives BESIDE things, so the spacing is against other creatures only
		if _spaced_from(key, 2, "creature"):
			# gen 13: EVERY creature cell is a resident slot — the body is the community's (a
			# plan on the dispatcher's recipe), the cell, its intensity and its neighbours the
			# habitat's; the dispatcher leaves it, so the animal count does not double
			_cells[key] = {"kingdom": "creature", "inten": 2 + rng.randi_range(0, 1), "algo": "", "resident": true}
			_counts["creature"] += 1
			_counts["slots_body"] += 1
	# connections: fungus cells with a tree or flower next to them — the network touches the wood
	for key in _cells.keys():
		if String(_cells[key]["kingdom"]) != "fungus":
			continue
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var nk: Vector2i = key + Vector2i(dx, dz)
				if nk != key and _cells.has(nk) and String(_cells[nk]["kingdom"]) in ["tree", "flower"]:
					_counts["connections"] += 1
	_counts["water"] = _water.size()


## Array.shuffle() draws from the GLOBAL random and would make the same seed grow two
## different worlds; this one draws from the ecology's rng.
func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


## gen 2: the succession order — nearer the water first; a tie falls to the row-major index so
## the order is a fact about the seed, not about the sort.
func _nearer_water(p: Vector2i, q: Vector2i) -> bool:
	var dp: float = _water_dist(p.x, p.y)
	var dq: float = _water_dist(q.x, q.y)
	if absf(dp - dq) < 0.0001:
		return (p.y * size + p.x) < (q.y * size + q.x)
	return dp < dq


## gen 3: the ridge — the cells above h_min that are dry (m < 0.42), not water, at least 2.5
## cells from any water cell and off the outer ring. gen 5: 3.0 cells — the scree needs the
## slope between the cluster and the water to run down.
func _ridge(h_min: float) -> Array:
	var out: Array = []
	for z in range(1, size - 1):
		for x in range(1, size - 1):
			var key := Vector2i(x, z)
			if _water.has(key):
				continue
			var h: float = _field[z * size + x]
			if h > h_min and _moist[z * size + x] < 0.42 and _water_dist(x, z) >= 3.0:
				out.append({"key": key, "h": h})
	return out


func _water_dist(x: int, z: int) -> float:
	var best := 99.0
	var p := Vector2(float(x), float(z))
	for k in _water.keys():
		best = minf(best, p.distance_to(Vector2(float(k.x), float(k.y))))
	return best


func _spaced(key: Vector2i, r: int) -> bool:
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if (dx != 0 or dz != 0) and _cells.has(key + Vector2i(dx, dz)):
				return false
	return true


## gen 2: the free cell (in range, not water, not taken) among a cell's eight neighbours whose
## centre is nearest to the world point q; (-1, -1) when none is free.
func _free_neighbour(key: Vector2i, q: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 99.0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var nk: Vector2i = key + Vector2i(dx, dz)
			if (dx == 0 and dz == 0) or nk.x < 0 or nk.y < 0 or nk.x >= size or nk.y >= size:
				continue
			if _water.has(nk) or _cells.has(nk):
				continue
			var cw: Vector3 = _cell_world(nk.x, nk.y)
			var d: float = q.distance_to(Vector2(cw.x, cw.z))
			if d < best_d:
				best_d = d
				best = nk
	return best


func _spaced_from(key: Vector2i, r: int, kingdom: String) -> bool:
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var nk: Vector2i = key + Vector2i(dx, dz)
			if (dx != 0 or dz != 0) and _cells.has(nk) and String(_cells[nk]["kingdom"]) == kingdom:
				return false
	return true


## Where a cell's body stands, world xz: a trunk or a path mat where the ecology put it
## (_pos), any other cell at its centre plus the ±0.3 m jitter drawn from the per-cell rng —
## the two draws _dispatch() has always made. gen 13: one law, so a resident stands exactly
## where the dispatcher would have stood the cell's own body.
func _body_xz(key: Vector2i) -> Vector2:
	if _pos.has(key):
		return _pos[key] as Vector2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "cell", key.x, key.y])
	var cw: Vector3 = _cell_world(key.x, key.y)
	return Vector2(cw.x + rng.randf_range(-0.3, 0.3), cw.z + rng.randf_range(-0.3, 0.3))


## gen 13: the meadow's side rule (gen 11) at any world xz — true when the point lies on the
## SUN's side of its nearest trunk, nearest in that tree's own rs units as the meadow measures
## it: (p − trunk)·SUN_XZ < 0, the light coming from −SUN_XZ. Open ground with no tree is lit.
func _lit_side(at: Vector2) -> bool:
	var u := 99.0
	var ut := Vector2i(-1, -1)
	for t in _trees:
		var rs: float = 0.6 * (0.6 + 0.2 * float(int(_cells[t]["inten"]))) * float(_cells[t].get("k", 1.0))
		var ud: float = at.distance_to(_pos[t]) / rs
		if ud < u:
			u = ud
			ut = t
	if ut.x < 0:
		return true
	return (at - (_pos[ut] as Vector2)).dot(SUN_XZ) < 0.0


# ── the bodies ────────────────────────────────────────────────────────────────
## gen 4: built AFTER _dispatch() — the substrate composes its paint texture in its _ready()
## (the add_child below), so the layers must be set before it enters the tree, and the shade
## layer reads _canopy, which the dispatcher measures. Nothing before it reads the ground
## node: the pool, the crystals and the dispatcher's builders place by _h_at / world_pos.
func _ground() -> void:
	var g = Ground.new()
	g.name = "Ground"
	g.set_base_offset(0.0)
	g.configure(size, size, 1.0, Vector3.ZERO)
	g.set_field(_field, size, size, _max_h)
	g.set_paint_layers(_moisture_paint(), seed)
	_patch.add_child(g)


## The cut edge is a schematic soil profile, not a geological simulation. The
## top stays exactly where it was; only the sides and underside are added.
const SECTION_BASE_Y := -0.42


func _section() -> void:
	var started := Time.get_ticks_msec()
	var ground = _patch.get_node("Ground")
	var steps: int = ground.resolution # match the actual top mesh, including size 4's minimum
	var half := float(size) * 0.5
	var corners: Array[Vector2] = [Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)]
	var normals: Array[Vector3] = [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_section_columns.clear()
	for edge in range(4):
		var columns: Array[Dictionary] = []
		for i in range(steps + 1):
			var p: Vector2 = corners[edge].lerp(corners[(edge + 1) % 4], float(i) / float(steps))
			var column := _section_column(p)
			columns.append(column)
			_section_columns.append(column)
		for i in range(steps):
			var a: Dictionary = columns[i]
			var b: Dictionary = columns[i + 1]
			for band in range(4):
				var pa: Vector2 = a["at"]
				var pb: Vector2 = b["at"]
				var vertices: Array[Vector3] = [Vector3(pa.x, a["levels"][band], pa.y),
					Vector3(pb.x, b["levels"][band], pb.y),
					Vector3(pa.x, a["levels"][band + 1], pa.y),
					Vector3(pb.x, b["levels"][band + 1], pb.y)]
				# Godot's clockwise front faces; explicit outward normals keep each cut flat.
				for ix in [0, 2, 1, 1, 2, 3]:
					st.set_normal(normals[edge])
					st.set_color(a["colours"][band] if ix % 2 == 0 else b["colours"][band])
					st.add_vertex(vertices[ix])
	# Seal the underside with the same perimeter subdivisions as the sides. This
	# avoids T-junctions and keeps the closed boundary inspectable from below.
	for edge in range(4):
		for i in range(steps):
			var a: Vector2 = corners[edge].lerp(corners[(edge + 1) % 4], float(i) / float(steps))
			var b: Vector2 = corners[edge].lerp(corners[(edge + 1) % 4], float(i + 1) / float(steps))
			for p in [Vector2.ZERO, b, a]:
				st.set_normal(Vector3.DOWN)
				st.set_color(Color(0.24, 0.25, 0.25))
				st.add_vertex(Vector3(p.x, SECTION_BASE_Y, p.y))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true # these soil swatches are authored as display colours
	mat.roughness = 0.94
	var section := MeshInstance3D.new()
	section.name = "Section"
	section.mesh = st.commit()
	section.material_override = mat
	_patch.add_child(section)
	_counts["section_triangles"] = steps * 4 * 9
	_counts["ms_section"] = Time.get_ticks_msec() - started


func _section_column(p: Vector2) -> Dictionary:
	var half := float(size) * 0.5
	var x := clampi(int(floor(p.x + half)), 0, size - 1)
	var z := clampi(int(floor(p.y + half)), 0, size - 1)
	var m: float = clampf(_moist[z * size + x], 0.0, 1.0)
	var rock: float = clampf(float(_rock.get(Vector2i(x, z), 0.0)), 0.0, 1.0)
	var top := _h_at(p.x, p.y)
	var soil_bottom := top - 0.06
	var humus_bottom := soil_bottom - (0.04 + 0.22 * m)
	# The rock boundary rises with the terrain; enough subsoil remains even at
	# the lowest shore. All bands remain ordered with the full moisture range.
	var rock_top := minf(humus_bottom - 0.08, lerpf(SECTION_BASE_Y, top, 0.42))
	var skin := Color(0.62, 0.55, 0.39).lerp(Color(0.25, 0.34, 0.16), m)
	skin = skin.lerp(Color(0.56, 0.55, 0.50), rock)
	var humus := Color(0.30, 0.23, 0.14).lerp(Color(0.13, 0.12, 0.09), m)
	var subsoil := Color(0.53, 0.40, 0.26).lerp(Color(0.40, 0.32, 0.23), m)
	var bedrock := Color(0.32, 0.34, 0.35).lerp(Color(0.42, 0.42, 0.40), rock)
	return {"at": p, "moisture": m, "levels": PackedFloat32Array([
		top, soil_bottom, humus_bottom, rock_top, SECTION_BASE_Y]),
		"colours": PackedColorArray([skin, humus, subsoil, bedrock])}


## gen 1: the moisture painted onto the ground as "shader" brush layers, the shape the
## substrate reads (element / mode / density / color / brush{w, d, cells[[x, z, v]]}), composed
## into its paint texture. gen 2: the WHOLE gradient, so six DNAs give six grounds — ochre
## wherever the ground is dry (no height gate; the height only deepens it), moss from m 0.28
## up, a sand SHORE on the shelf fading out over one metre, silt under the water darkest at the
## middle. Painted dry, wet, shore, silt — each over the one before; gen 5: then the rock,
## bare stone at the clusters and under the scree; gen 4: then the shade, over everything.
func _moisture_paint() -> Array:
	var wet: Array = []
	var dry: Array = []
	var shore: Array = []
	var silt: Array = []
	for z in range(size):
		for x in range(size):
			var i: int = z * size + x
			var m: float = _moist[i]
			var vw: float = clampf((m - 0.28) / 0.42, 0.0, 1.0)
			if vw > 0.0:
				wet.append([x, z, vw])
			var vd: float = clampf((0.45 - m) / 0.35, 0.0, 1.0) * (0.55 + 0.45 * _field[i])
			if vd > 0.0:
				dry.append([x, z, vd])
			var d_c: float = Vector2(float(x) + 0.5, float(z) + 0.5).distance_to(_basin_c)
			if _water.has(Vector2i(x, z)):
				silt.append([x, z, 0.45 + 0.55 * (1.0 - d_c / _pool_r)])
			elif d_c < _pool_r + 1.0:
				shore.append([x, z, 0.8 * (1.0 - (d_c - _pool_r))])
	# gen 4: the canopy casts a layer — per dry-land cell the strongest of the trees' shade by
	# the MEASURED canopy (_canopy, filled in _dispatch(); the ground is built after it for
	# this): v = 0.85·(1 − d / canopy)^0.6, kept over 0.02, painted LAST so it darkens whatever
	# lies under it — moss, ochre or shore. gen 11: d is the distance to the SHADE CENTRE, the
	# trunk carried along the sun (_shade_at) — the paint lies where the rendered shadow lies
	var shade: Array = []
	for z in range(size):
		for x in range(size):
			if _water.has(Vector2i(x, z)):
				continue
			var cw: Vector3 = _cell_world(x, z)
			var v: float = 0.85 * _shade_at(Vector2(cw.x, cw.z))
			if v > 0.02:
				shade.append([x, z, v])
	# gen 5: the rock — _rock as _minerals() left it (0.6 at a cluster, 0.3 round it, 0.35 under
	# the scree), walked row-major so the layer is a fact about the grid; painted after the
	# silt and BEFORE the shade, so a cluster under a canopy is dark rock, not moss
	var rock: Array = []
	for z in range(size):
		for x in range(size):
			var rk := Vector2i(x, z)
			if _rock.has(rk):
				rock.append([x, z, float(_rock[rk])])
	_counts["paint"] = wet.size() + dry.size() + shore.size() + silt.size() + rock.size() + shade.size()
	return [_brush_layer([0.74, 0.66, 0.50], dry, "dry"), _brush_layer([0.20, 0.34, 0.18], wet, "wet"),
		_brush_layer([0.58, 0.54, 0.42], shore, "shore"), _brush_layer([0.16, 0.14, 0.11], silt, "silt"),
		_brush_layer([0.56, 0.55, 0.50], rock, "rock"), _brush_layer([0.11, 0.17, 0.09], shade, "shade")]


## gen 4: each layer carries a name — the probe's handle; the substrate reads past it.
func _brush_layer(color: Array, cells: Array, layer_name: String) -> Dictionary:
	return {"element": "shader", "mode": "brush", "density": 1.0, "color": color, "name": layer_name,
		"brush": {"w": size, "d": size, "cells": cells}}


## gen 11: where a tree's shadow lands — the trunk carried along the sun by the crown's
## height: sc = trunk + SUN_XZ · SUN_RUN · crown. Before _dispatch() has measured the crown
## this is the trunk (the ecology's own rules read the trunk and the side, never the shadow).
func _shade_centre(t: Vector2i) -> Vector2:
	return (_pos[t] as Vector2) + SUN_XZ * SUN_RUN * float(_crown.get(t, 0.0))


## gen 11: THE shade law, in one place — the strongest of the trees' shade at a world xz,
## (1 − d/canopy)^0.6 with d the distance to the tree's SHADE CENTRE and canopy its measured
## radius; 0 outside every shadow. The ground's shade layer paints 0.85× this, the pool's
## disc darkens by 0.45× it (gen 7's law, moved with the centre), and the cover calls a sample
## shaded where it is over 0 — so the ferns stand on the dark paint, not beside it.
func _shade_at(at: Vector2) -> float:
	var vs := 0.0
	for t in _trees:
		var cr: float = float(_canopy.get(t, 0.0))
		if cr <= 0.001:
			continue
		vs = maxf(vs, pow(clampf(1.0 - at.distance_to(_shade_centre(t)) / cr, 0.0, 1.0), 0.6))
	return vs


const POOL_SEGMENTS := 48
const POOL_RINGS := 6
const POOL_CENTRE := Color(0.06, 0.20, 0.44, 0.92)
const POOL_RIM := Color(0.24, 0.50, 0.68, 0.62)


## gen 7: built after _dispatch() — the disc's vertex colours read the measured canopy.
## Nothing before the ground reads the Pool node (the minerals and the dispatcher's builders
## place by _h_at / _water / _water_level()), and the pool's rng is seeded from the seed
## alone, so the move changes no draw: the ring and the reeds stand where gen 6 stood them.
func _water_pool() -> void:
	if _water.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "pool"])
	var holder := Node3D.new()
	holder.name = "Pool"
	var c: Vector3 = Vector3(_basin_c.x - float(size) * 0.5, _water_level(), _basin_c.y - float(size) * 0.5)
	holder.position = c
	_patch.add_child(holder)
	var r: float = _pool_r + 0.35   # gen 1: the disc laps the shelf
	# gen 7: the disc is a vertex-coloured fan — deep at the middle, pale at the rim, darkened
	# wherever a measured canopy hangs over it; no emission, the colour is the albedo. Its
	# surface stands at 0.01 above the water level, where the cylinder's top stood.
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	disc.mesh = _pool_fan(r, Vector2(c.x, c.z))
	disc.position = Vector3(0.0, 0.01, 0.0)
	var wmat := StandardMaterial3D.new()
	wmat.vertex_color_use_as_albedo = true
	wmat.albedo_color = Color.WHITE
	wmat.metallic = 0.3
	wmat.roughness = 0.08
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = wmat
	holder.add_child(disc)
	# gen 7 (the gen-6 critic): no ring — the depth gradient is the water's edge
	var reeds: int = 3 + int(round(moisture * 5.0))
	for i in range(reeds):
		var reed := MeshInstance3D.new()
		reed.name = "Reed_%d" % i
		var rc := CylinderMesh.new()
		rc.top_radius = 0.012
		rc.bottom_radius = 0.02
		var rh: float = rng.randf_range(0.35, 0.7)
		rc.height = rh
		reed.mesh = rc
		var remat := StandardMaterial3D.new()
		remat.albedo_color = Color(0.3, 0.5, 0.42)
		reed.material_override = remat
		var a: float = rng.randf_range(0.0, TAU)
		# gen 1: the reeds stand on the SHORE, past the water's edge, their feet on the shelf
		var rr: float = r * rng.randf_range(0.95, 1.15)
		var lx: float = cos(a) * rr
		var lz: float = sin(a) * rr
		reed.position = Vector3(lx, _h_at(c.x + lx, c.z + lz) - c.y + rh * 0.5, lz)
		reed.rotation = Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
		holder.add_child(reed)


## gen 7: the disc as a fan of POOL_SEGMENTS segments and POOL_RINGS rings about one centre
## vertex, indexed, clockwise seen from above (Godot's front face), normals up, the colour
## from _pool_colour. No rng: the fan is a fact about the basin and the canopy.
func _pool_fan(r: float, centre: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0.5, 0.5))
	st.set_color(_pool_colour(0.0, centre))
	st.add_vertex(Vector3.ZERO)
	var ring_v: Array[int] = []   # ring -> its first vertex index
	var idx := 1
	for ring in range(1, POOL_RINGS + 1):
		var u: float = float(ring) / float(POOL_RINGS)
		ring_v.append(idx)
		for s in range(POOL_SEGMENTS):
			var a: float = TAU * float(s) / float(POOL_SEGMENTS)
			var p := Vector2(cos(a), sin(a)) * (u * r)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5 + 0.5 * p.x / r, 0.5 + 0.5 * p.y / r))
			st.set_color(_pool_colour(u, centre + p))
			st.add_vertex(Vector3(p.x, 0.0, p.y))
			idx += 1
	for s in range(POOL_SEGMENTS):
		var s1: int = (s + 1) % POOL_SEGMENTS
		st.add_index(0)
		st.add_index(ring_v[0] + s)
		st.add_index(ring_v[0] + s1)
	for ring in range(1, POOL_RINGS):
		var inner: int = ring_v[ring - 1]
		var outer: int = ring_v[ring]
		for s in range(POOL_SEGMENTS):
			var s1: int = (s + 1) % POOL_SEGMENTS
			st.add_index(inner + s)
			st.add_index(outer + s)
			st.add_index(outer + s1)
			st.add_index(inner + s)
			st.add_index(outer + s1)
			st.add_index(inner + s1)
	return st.commit()


## gen 7: the water's colour at u (0 the centre, 1 the rim) and a world xz: POOL_CENTRE to
## POOL_RIM by u^1.5, then every channel × (1 − 0.45·vs), vs the strongest of the trees'
## shade by the MEASURED canopy, (1 − d/canopy)^0.6 — the law the ground's shade layer reads
## (_shade_at; gen 11: d to the shade centre, so the water darkens under the shadow, not under
## the trunk). The alpha is kept: shaded water is darker, not thinner.
func _pool_colour(u: float, at: Vector2) -> Color:
	var col: Color = POOL_CENTRE.lerp(POOL_RIM, pow(u, 1.5))
	var f: float = 1.0 - 0.45 * _shade_at(at)
	return Color(col.r * f, col.g * f, col.b * f, col.a)


## gen 5: after each cluster's shards, its SCREE — the ridge comes down to the water. The
## cluster's rng is left as gen 3 drew it; the scree draws from a second rng seeded from the
## cell. Down is the height gradient at the cluster (±0.5 m samples), the basin's direction
## when the ground is flat there (|g| < 0.02) or falls away from it; n = 3 + round(4·relief) samples at
## 0.55 + 0.5i + 0.08i² m along it, the trail ended by a water cell, the grid edge, a flooded
## sample (under the water level) or a rise — the scree does not climb. Each shard is a small
## prism lying on the surface, the crystal's colour at a fifth of its glow, an object mesh
## like the spires, added to the patch at its world sample (the holder is yawed). The rock
## map takes 0.6 at the cluster, 0.3 on its eight neighbours and 0.35 per scree cell.
func _minerals() -> void:
	_rock.clear()
	_clusters.clear()
	var wl: float = _water_level() if not _water.is_empty() else -99.0
	var basin_w: Vector2 = _basin_c - Vector2(float(size), float(size)) * 0.5
	var lim: float = float(size) * 0.5
	for key in _cells.keys():
		if String(_cells[key]["kingdom"]) != "mineral":
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed, "crystal", key.x, key.y])
		var holder := Node3D.new()
		holder.name = "Crystal_%d_%d" % [key.x, key.y]
		var p: Vector3 = _cell_world(key.x, key.y)
		p.x += rng.randf_range(-0.25, 0.25)
		p.z += rng.randf_range(-0.25, 0.25)
		p.y = _h_at(p.x, p.z)
		holder.position = p
		holder.rotation.y = rng.randf_range(0.0, TAU)
		_patch.add_child(holder)
		var scale: float = (0.9 + 0.5 * relief) * 1.4
		# gen 3: the spires by height and dryness — the dry world grows spires where it grows no canopy
		scale *= (0.7 + 0.6 * _field[key.y * size + key.x]) * (1.0 + 0.8 * (1.0 - moisture))
		var shards: int = rng.randi_range(6, 9)
		for _i in range(shards):
			var mi := MeshInstance3D.new()
			var pm := PrismMesh.new()
			var hgt: float = rng.randf_range(0.24, 0.62) * scale
			pm.size = Vector3(0.11 * scale, hgt, 0.11 * scale)
			mi.mesh = pm
			var tint: float = rng.randf_range(-0.04, 0.14)
			var col := Color(0.58 + tint, 0.66 + tint, 0.86 + tint * 0.4)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = col
			mat.metallic = 0.4
			mat.roughness = 0.35   # gen 7: rougher (was 0.22) — a mineral, not a lamp
			mat.emission_enabled = true
			mat.emission = col * 0.15   # gen 7: 0.15 of the colour (was 0.5); the scree keeps its 0.2
			mi.material_override = mat
			var off := Vector2(rng.randf_range(-0.17, 0.17), rng.randf_range(-0.17, 0.17)) * scale
			mi.position = Vector3(off.x, hgt * 0.5, off.y)
			mi.rotation = Vector3(rng.randf_range(-0.42, 0.42), rng.randf_range(0.0, TAU), rng.randf_range(-0.42, 0.42))
			holder.add_child(mi)
		# gen 5: the rock under the cluster, then the scree down the slope
		_clusters.append(Vector2(p.x, p.z))
		_rock[key] = 0.6
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var nk: Vector2i = key + Vector2i(dx, dz)
				if nk == key or nk.x < 0 or nk.y < 0 or nk.x >= size or nk.y >= size or _water.has(nk):
					continue
				_rock[nk] = maxf(float(_rock.get(nk, 0.0)), 0.3)
		var srng := RandomNumberGenerator.new()
		srng.seed = hash([seed, "scree", key.x, key.y])
		var g := Vector2(_h_at(p.x + 0.5, p.z) - _h_at(p.x - 0.5, p.z), _h_at(p.x, p.z + 0.5) - _h_at(p.x, p.z - 0.5))
		var to_basin: Vector2 = (basin_w - Vector2(p.x, p.z)).normalized()
		var down: Vector2 = -g.normalized() if g.length() >= 0.02 else to_basin
		# measured on the six DNAs (gen 5's builder): the ridge's cells are the rim's high dry
		# cells, and from 11 of 16 clusters the local downhill led OFF the plate — the critic's
		# rule as written ran no trail to the water. So the basin's direction also stands in
		# for a downhill that leads away from it; the rise stop below keeps the trail honest
		# where the ground climbs toward the water (a cluster behind a crest gets no scree)
		if down.dot(to_basin) <= 0.0:
			down = to_basin
		var n: int = 3 + int(round(4.0 * relief))
		# the prism's half-diagonal at this scale: no shard's mesh past the footprint's edge
		var margin: float = 0.12 * scale
		var scol := Color(0.62, 0.70, 0.88)
		var low_h: float = p.y   # the lowest surface the trail has reached
		for i in range(n):
			var q: Vector2 = Vector2(p.x, p.z) + down * (0.55 + 0.5 * float(i) + 0.08 * float(i * i))
			if absf(q.x) > lim - margin or absf(q.y) > lim - margin:
				break   # the grid edge
			var qk := Vector2i(int(floor(q.x + lim)), int(floor(q.y + lim)))
			if _water.has(qk):
				break   # a water cell
			var hq: float = _h_at(q.x, q.y)
			if hq < wl + 0.02:
				break   # a flooded sample — the shelf under the water
			if hq > low_h + 0.02:
				break   # a rise — scree runs down, never over a lip
			var mi := MeshInstance3D.new()
			mi.name = "Scree_%d_%d_%d" % [key.x, key.y, i]
			var pm := PrismMesh.new()
			var sh: float = srng.randf_range(0.08, 0.2) * (1.0 - 0.6 * float(i) / float(n))
			pm.size = Vector3(0.09, sh, 0.09) * scale
			mi.mesh = pm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = scol
			mat.metallic = 0.4
			mat.roughness = 0.22
			mat.emission_enabled = true
			mat.emission = scol * 0.2
			mi.material_override = mat
			# lying on the surface: the centre 0.3 h up, so the lowest edge sinks a few cm in
			mi.position = Vector3(q.x, hq + 0.3 * pm.size.y, q.y)
			mi.rotation = Vector3(srng.randf_range(0.6, 1.3), srng.randf_range(0.0, TAU), srng.randf_range(-0.3, 0.3))
			_patch.add_child(mi)
			_rock[qk] = maxf(float(_rock.get(qk, 0.0)), 0.35)
			_counts["scree"] += 1
			low_h = minf(low_h, hq)


## The living kingdoms go through the old biome's dispatcher, one deposit per cell, each
## carrying its exact surface position — the same road a painted map cell takes.
func _dispatch() -> void:
	_dispatcher = Dispatcher.new()
	_dispatcher.name = "Dispatcher"
	_patch.add_child(_dispatcher)
	var ctx := {
		"biome_paint": [],
		"stage_order": 999,
		"parent": _patch,
		"grid_center": Vector3.ZERO,
		"grid_dims": Vector3i(size, 1, size),
		"cube_size": 1.0,
	}
	var ids := {"tree": K_TREE, "creature": K_CREATURE, "flower": K_FLOWER, "fungus": K_FUNGUS}
	_canopy.clear()
	_crown.clear()
	_mats.clear()
	var keys: Array = _cells.keys()
	keys.sort_custom(func(a, b): return (a.y * size + a.x) < (b.y * size + b.x))
	for key in keys:
		var c: Dictionary = _cells[key]
		var kname := String(c["kingdom"])
		if not ids.has(kname):
			continue
		# gen 13: a cell marked `resident` is the residents layer's while that layer is on —
		# the dispatcher leaves it and populate() stands a catalogue body in the same place
		# (_body_xz); with residents off every cell is built here, as gen 12 built it
		if residents == "on" and bool(c.get("resident", false)):
			continue
		if kname == "flower":
			_counts["flower_dispatched"] += 1
		elif kname == "creature":
			_counts["creature_dispatched"] += 1
		# gen 2: a trunk or a path mat stands where the ecology put it; any other body at its
		# cell's centre with the per-cell jitter (gen 13: _body_xz, one law with the residents)
		var xz: Vector2 = _body_xz(key)
		var wp := Vector3(xz.x, _h_at(xz.x, xz.y), xz.y)
		# the dispatcher's builders place by GLOBAL position (a painted map cell's world_pos
		# is global), so the surface point goes out in the patch's global frame
		var deposit := {"x": key.x, "z": key.y, "kingdom": int(ids[kname]),
			"strength": float(int(c["inten"])) / 5.0, "sterile": false,
			"raw": "%s%d" % [kname.substr(0, 1), int(c["inten"])], "world_pos": _patch.global_position + wp,
			"density": 0.8 + 0.2 * moisture}
		if String(c["algo"]) != "":
			deposit["algo"] = String(c["algo"])
		if c.has("gen"):
			# gen 2: the path's growth — _spawn_mycelium reads "gen" into the colony's max_steps
			deposit["gen"] = String(c["gen"])
		# gen 3: each kingdom's spawn timed into ms_<kingdom> — the budget's bill, by payer
		var before: int = _patch.get_child_count()
		var t1: int = Time.get_ticks_msec()
		_dispatcher.spawn_cell(deposit, 999, ctx, _patch)
		_counts["ms_" + kname] += Time.get_ticks_msec() - t1
		# gen 3: the object GROWS what it gets back. The root the dispatcher added stands with its
		# foot at the surface point, so a scale about it keeps the foot. A tree by its succession
		# rank and the moisture, capped so the measured canopy — the merged branch mesh's
		# root-local AABB plus a leaf margin of 0.25·dna.scale — stays 0.05 m inside the
		# footprint (floor 1.0: gen 2's size); a flower by the moisture; a creature 1.6x; a mat
		# 1.0, the mats being sized to overlap on the line.
		var inten: int = int(c["inten"])
		for i in range(before, _patch.get_child_count()):
			var n: Node = _patch.get_child(i)
			if not (n is Node3D):
				continue
			var k: float = 1.0
			match kname:
				"tree":
					k = float(c.get("k", 1.0))
					var r: float = 0.6 * (0.6 + 0.2 * float(inten))
					var top := -1.0   # gen 11: the merged branch mesh's top, root-local, unscaled
					var mb: Node = n.find_child("MergedBranches", true, false)
					if mb is MeshInstance3D and (mb as MeshInstance3D).mesh != null:
						var bb: AABB = (mb as MeshInstance3D).mesh.get_aabb()
						r = maxf(maxf(absf(bb.position.x), absf(bb.end.x)), maxf(absf(bb.position.z), absf(bb.end.z))) + 0.25 * (0.6 + 0.2 * float(inten))
						top = bb.end.y
					var edge: float = float(size) * 0.5 - maxf(absf(wp.x), absf(wp.z))
					k = maxf(1.0, minf(k, (edge - 0.05) / r))
					_canopy[key] = r * k
					# gen 11: the crown's height at the body's scale — 0.6 of the branch top (the
					# leaves' mass sits there), 1.2 r without a mesh; the shadow runs SUN_RUN × it
					_crown[key] = (0.6 * top if top > 0.0 else 1.2 * r) * k
				"flower":
					k = 1.4 + 0.4 * moisture
				"creature":
					k = 1.6
				"fungus":
					k = 1.0
					_mats.append(Vector2(wp.x, wp.z))
					_web_light(n, c)
			(n as Node3D).scale = Vector3.ONE * k


## gen 7: the web's light by its growth — a mat at the water (gen 25, the network finished)
## glows at 0.55, the tip at the tree (gen 10, still growing) at 0.22, lerped by
## t = (25 − gen)/15; a rim mat carries no gen and reads as 25. The colony's MyceliumWeb
## material (its own instance, cached per colony) is DUPLICATED before the edit, so no two
## mats share one; the colour is kept — the cyan is the albedo's. The spores are not the
## web and keep their light.
func _web_light(n: Node, c: Dictionary) -> void:
	var web: Node = n.find_child("MyceliumWeb", true, false)
	if not (web is MeshInstance3D) or (web as MeshInstance3D).material_override == null:
		return
	var t: float = (25.0 - float(int(String(c.get("gen", "25"))))) / 15.0
	var mat: Material = (web as MeshInstance3D).material_override.duplicate()
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).emission_energy_multiplier = lerpf(0.22, 0.55, t)   # gen-6 critic: bright at the growing tip, dim at the finished rim
		(web as MeshInstance3D).material_override = mat


## Cover by zone — the old ring's small covers (its "tree" type is a 2.5 m column and its
## "bush" a 0.7 m ball; neither is cover). Reeds at the water's rim, blooms in the meadow,
## grass everywhere. gen 3: the understory FOLLOWS THE CANOPY and reads the gradient — accepted
## by m² so the driest ground is bare; ferns and toadstools under a tree's measured canopy,
## darker and smaller in its shade; toadstools within 0.7 m of a fungus mat; the grass lerped
## green to straw by dryness. Gen 6 groups the samples: each tuft shares a colour and
## species, has its own seeded member stream, and reads canopy/shore conditions. Each
## member checks its own landing and mesh bounds; counts and the CPU plan remain inspectable.
## FOLIAGE CARDS (gen 8, Palle: "can we add grass and plant foliage? transparent image").
## The cover's kinds are drawn as alpha-cut images on two crossed quads instead of a plain
## quad, a cylinder and a sphere. The images are commons/biome_layers/foliage/<kind>.png
## (tools/make_foliage_cards.py draws the defaults; any 512 x 512 RGBA PNG of the same name
## replaces one), loaded at runtime by name so no import step and no editor is needed; a
## missing image falls back to the old mesh for that kind. Card height in metres at scale 1:
const FOLIAGE_DIR := "res://commons/biome_layers/foliage/"
const CARD_KIND := {"grass": "grass", "reed": "reed", "fern": "fern", "flower": "plant", "litter": "litter"}
const CARD_HEIGHT := {"grass": 0.42, "reed": 0.85, "fern": 0.50, "flower": 0.55, "litter": 0.45}
static var _card_tex: Dictionary = {}
static var _card_mesh: Mesh = null


## The image for a kind, or null when the file is not there.
static func _foliage_texture(card: String) -> Texture2D:
	if _card_tex.has(card):
		return _card_tex[card]
	var path: String = FOLIAGE_DIR + card + ".png"
	var tex: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(path)) == OK:
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_card_tex[card] = tex
	return tex


## Two crossed unit quads, the foot at the origin, the top at y = 1, normals UP so both sides
## light like the ground they stand on and no card is a dark backface.
static func _crossed_card() -> Mesh:
	if _card_mesh != null:
		return _card_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(2):
		var ax: Vector3 = Vector3.RIGHT if k == 0 else Vector3.BACK
		var corners := [ax * -0.5, ax * 0.5, ax * 0.5 + Vector3.UP, ax * -0.5 + Vector3.UP]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		var order := [0, 2, 1, 0, 3, 2]
		for i in order:
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[i])
			st.add_vertex(corners[i])
	_card_mesh = st.commit()
	return _card_mesh


static func _card_material(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## The card image for a cover kind: drawn from this world's seed and moisture (gen 9), or the
## PNG of that name when the knob says `files`; null for a kind without a card (mushrooms).
func _card_for(kind: String) -> Texture2D:
	if not CARD_KIND.has(kind):
		return null
	var card := String(CARD_KIND[kind])
	if foliage == "files":
		return _foliage_texture(card)
	return FoliageCards.card(card, seed, moisture)


## The tint a card member carries: the image is already green, so the tint sits near white
## and only says dry (straw) or shaded; the old flat-colour tints would blacken it.
static func _card_tint(kind: String, m: float, shaded: bool, rng: RandomNumberGenerator) -> Color:
	var j: float = rng.randf_range(-0.05, 0.05)
	var c := Color(0.96 + j, 0.98 + j, 0.92 + j)
	if kind == "grass" or kind == "reed":
		c = c.lerp(Color(1.0, 0.86, 0.55), clampf(1.0 - 1.4 * m, 0.0, 1.0))
	if shaded:
		c = Color(c.r * 0.72, c.g * 0.72, c.b * 0.72)
	return c


func _cover() -> void:
	var started := Time.get_ticks_msec()
	_cover_tufts.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "cover"])
	var want: int = clampi(int(round(float(size * size) * (1.2 + 2.6 * wildness) * (0.5 + 0.6 * moisture))), 40, 480)
	var budget := int(floor(float(want) * 1.8))
	var by_type: Dictionary = {}
	var cards: Dictionary = {}       # kind -> Texture2D (a card) or null (the old mesh)
	var meshes: Dictionary = {}
	var placed := 0
	var tries := 0
	var green := Color(0.22, 0.42, 0.14)
	var straw := Color(0.68, 0.60, 0.30)
	var half := float(size) * 0.5
	while placed < budget and tries < want * 4:
		tries += 1
		var wx: float = rng.randf_range(-half + 0.2, half - 0.2)
		var wz: float = rng.randf_range(-half + 0.2, half - 0.2)
		var here := Vector2(wx, wz)
		if not _cover_land(here):
			continue
		var cx: int = clampi(int(floor(wx + half)), 0, size - 1)
		var cz: int = clampi(int(floor(wz + half)), 0, size - 1)
		var m: float = _moist[cz * size + cx]
		var d: float = _water_dist(cx, cz)
		var acceptance: float = 0.06 + 0.94 * m * m
		if d < 1.6:
			acceptance = maxf(acceptance, 0.5)
		if rng.randf() > acceptance:
			continue
		# the nearest TRUNK: the litter's law — leaves fall straight down (gen 11 keeps it here)
		var dt := 99.0
		var cr := 0.0
		for tree in _trees:
			var dd: float = here.distance_to(_pos[tree])
			if dd < dt:
				dt = dd
				cr = float(_canopy.get(tree, 0.0))
		var dw := 99.0
		for mp in _mats:
			dw = minf(dw, here.distance_to(mp))
		var kind := "grass"
		var choice: float = rng.randf()
		# gen 11: shaded is a fact about the SHADOW, not the trunk — the same law the paint
		# reads (_shade_at > 0: inside some tree's shadow disc), so the ferns and toadstools
		# stand on the dark paint and the grass at the sunlit foot is grass
		var shaded: bool = _shade_at(here) > 0.0
		if cr > 0.0 and dt < cr * 0.35:
			kind = "litter"
		elif d < 1.6 and choice < 0.45:
			kind = "reed"
		elif shaded:
			kind = "fern" if choice < 0.6 else "mushroom"
		elif dw < 0.7 and choice < 0.5:
			kind = "mushroom"
		elif m > 0.45 and choice < 0.55:
			kind = "flower"
		var sc: float = (0.5 + 0.7 * m) * 1.4
		var col: Color = Cover.color_for(kind, rng)
		if kind == "grass":
			var j: float = rng.randf_range(-0.04, 0.04)
			col = green.lerp(straw, clampf(1.0 - 1.3 * m, 0.0, 1.0)) + Color(j, j, j, 0.0)
		if shaded:
			sc *= 0.8
			col = Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, col.a)
		if kind == "litter":
			sc *= 0.6
			col = Color(0.36, 0.30, 0.14)
		var yaw: float = rng.randf_range(0.0, TAU)
		# The group has its own stream: adding a member cannot consume the centre sampler.
		var tuft_rng := RandomNumberGenerator.new()
		tuft_rng.seed = hash([seed, "cover_tuft", tries])
		var count := 2 + int(round(6.0 * m))
		var radius := 0.15 + 0.30 * m
		match kind:
			"reed":
				count = 4 + int(round(6.0 * m))
				radius = 0.25 + 0.20 * m
			"fern":
				count = 2 + int(round(3.0 * m))
			"mushroom":
				count = tuft_rng.randi_range(1, 2)
				radius = 0.18
			"flower": count = 3 + int(round(4.0 * m))
			"litter": count = 3 + int(round(3.0 * m))
		if not meshes.has(kind):
			var card_tex: Texture2D = _card_for(kind)
			meshes[kind] = _crossed_card() if card_tex != null else Cover.mesh_for("fern" if kind == "litter" else kind)
			cards[kind] = card_tex
		var mesh: Mesh = meshes[kind]
		# one tint per tuft (a group shares its colour, as gen 6 ruled): near white, dry or shaded
		var tuft_tint: Color = _card_tint(kind, m, shaded, tuft_rng) if cards.get(kind) != null else col
		if cards.get(kind) != null and kind == "litter":
			tuft_tint = Color(0.9, 0.86, 0.8)
		var members: Array = []
		for blade in count:
			if placed >= budget:
				break
			var angle: float = tuft_rng.randf() * TAU
			var rad: float = radius * sqrt(tuft_rng.randf())
			var q: Vector2 = here + Vector2(cos(angle), sin(angle)) * rad
			if not _cover_land(q):
				continue
			# A litter member must remain under an inner canopy, including at a tuft's edge.
			if kind == "litter":
				var under := false
				for tree in _trees:
					if q.distance_to(_pos[tree]) < float(_canopy.get(tree, 0.0)) * 0.35:
						under = true
						break
				if not under:
					continue
			var scale_: float = sc * (1.0 - 0.4 * rad / radius) * tuft_rng.randf_range(0.85, 1.15)
			if cards.get(kind) != null:
				scale_ *= float(CARD_HEIGHT.get(kind, 0.5))
			var basis := Basis(Vector3.UP, yaw + angle)
			if kind == "litter":
				basis = basis * Basis(Vector3.RIGHT, -PI * 0.5)
			basis = basis.scaled(Vector3.ONE * scale_)
			var bounds: AABB = Transform3D(basis, Vector3.ZERO) * mesh.get_aabb()
			if q.x + bounds.position.x < -half or q.x + bounds.end.x > half or q.y + bounds.position.z < -half or q.y + bounds.end.z > half:
				continue
			# All cover meshes sit by their foot; centred reed/cap meshes must not be half buried.
			var xf := Transform3D(basis, Vector3(q.x, _h_at(q.x, q.y) - bounds.position.y + 0.012, q.y))
			var mcol: Color = tuft_tint
			members.append([xf, mcol])
			if not by_type.has(kind):
				by_type[kind] = []
			(by_type[kind] as Array).append([xf, mcol])
			placed += 1
		if not members.is_empty():
			_cover_tufts.append({"type": kind, "centre": here, "moisture": m, "radius": radius, "members": members})
	for kind in by_type.keys():
		var items: Array = by_type[kind]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[kind]
		mm.instance_count = items.size()
		for i in items.size():
			mm.set_instance_transform(i, items[i][0])
			mm.set_instance_color(i, items[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Cover_%s" % String(kind)
		mmi.multimesh = mm
		mmi.material_override = _card_material(cards[kind]) if cards.get(kind) != null else Cover.foliage_material()
		_patch.add_child(mmi)
	_counts["cover"] = placed
	_counts["cover_cards"] = 0
	for kind in by_type.keys():
		if cards.get(kind) != null:
			_counts["cover_cards"] += (by_type[kind] as Array).size()
	_counts["cover_tufts"] = _cover_tufts.size()
	_counts["cover_litter"] = (by_type.get("litter", []) as Array).size()
	_counts["ms_cover"] = Time.get_ticks_msec() - started


## Check every displaced tuft member: a dry centre does not guarantee dry neighbours.
func _cover_land(p: Vector2) -> bool:
	for resident in _residents:
		var at: Array = resident["position"]
		if p.distance_to(Vector2(at[0], at[2])) < float(resident["radius"]):
			return false
	var half := float(size) * 0.5
	if absf(p.x) > half - 0.02 or absf(p.y) > half - 0.02:
		return false
	var cx := int(floor(p.x + half))
	var cz := int(floor(p.y + half))
	var key := Vector2i(cx, cz)
	if _water.has(key) or _moist[cz * size + cx] < 0.18:
		return false
	if not _water.is_empty() and _h_at(p.x, p.y) < _water_level() + 0.02:
		return false
	if float(_rock.get(key, 0.0)) >= 0.35:
		return false
	for cp in _clusters:
		if cp.distance_to(p) < 0.8:
			return false
	return true

# ── the record ────────────────────────────────────────────────────────────────
func get_state() -> Dictionary:
	var kinds := {}
	for key in _cells.keys():
		var k := String(_cells[key]["kingdom"])
		kinds[k] = int(kinds.get(k, 0)) + 1
	var lo := 9.0
	var hi := -9.0
	for i in range(size * size):
		lo = minf(lo, _field[i] * _max_h)
		hi = maxf(hi, _field[i] * _max_h)
	return {"generation": GENERATION, "label": label(),
		"dna": {"seed": seed, "size": size, "moisture": moisture, "relief": relief, "wildness": wildness},
		"community_dna": {"seed": community_seed, "enabled": residents},
		"residents": _residents.duplicate(true),
		"cells": kinds, "counts": _counts.duplicate(), "trees": _trees.size(),
		"kingdoms_present": _present(), "height_range": [lo, hi], "water_level": _water_level(),
		"organisms": _patch.get_child_count() if _patch != null else 0, "build_ms": _build_ms,
		"changelog": CHANGELOG}


func _present() -> Array:
	var out: Array = []
	if _counts["water"] > 0:
		out.append("water")
	if _counts["mineral"] > 0:
		out.append("mineral")
	if _counts["fungus"] + _counts["fungus_path"] > 0:
		out.append("fungus")
	if _counts["tree"] + _counts["flower"] > 0:
		out.append("flora")
	if _counts["creature"] > 0:
		out.append("fauna")
	if _counts["cover"] > 0:
		out.append("cover")
	return out


func _write_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STATE_DIR))
	var f := FileAccess.open("%s/%s.json" % [STATE_DIR, label()], FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(get_state(), " "))
	f.close()
