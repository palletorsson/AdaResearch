extends RefCounted
## One habitat, independent community DNA. Catalogue recipes occupy bounded gaps
## beside existing mycelium. This adapter builds forms, not a living-agent simulation.
##
## gen 12 (Astra): the fungus stage — catalogue fruiting bodies in moist gaps beside the
## mycelium, up to six, their slots a fact about the habitat.
## gen 13: two more builders on the same contract, each in a stage of its own AFTER the
## fungus stage (the fungus draws are keyed by the count so far, so the order is the record):
##   flower_preset  — living_flora_bloom. The object hands the residents layer about every
##                    second or third meadow cell (marked `resident` in _ecology() from the
##                    habitat seed); the community seed picks a BotanicalFlower species for
##                    each by its moisture, its shade and whether it lies on the sun's side
##                    of its trunk; the SIZE is the habitat's — the dispatcher's overall_scale
##                    law on the cell's intensity, and _dispatch()'s growth by the moisture —
##                    so another community grows another species in the same slot at the same
##                    size.
##   creature_dna   — living_fauna_body. The object's creature cells (1–4 per world) are all
##                    handed over, so the animal count does not double; a body plan is a set
##                    of CritterDNA gene overrides on top of the dispatcher's own walker
##                    recipe; each body is TURNED to face what it lives by — the nearest water
##                    cell within 3 cells, else the nearest flower cell — and the record says
##                    so. These are PLACED bodies: no movement, no simulation.
## Every slot is independent of community_seed; every body stays inside the footprint; the
## cover keeps clear of a fixed radius under each (a slot fact, so the cover is the same
## under every community).
const Fungus := preload("res://algorithms/nature_system/morphology/fungus_morphology.gd")
const CreatureSdf := preload("res://algorithms/nature_system/morphology/creature_sdf_morphology.gd")
const SpawnService := preload("res://commons/biome_layers/spawn_service.gd")
const ConfigLoader := preload("res://commons/biome_layers/biome_config_loader.gd")
const Dispatcher := preload("res://commons/biome_layers/biome_paint_dispatcher.gd")
const BotanicalFlowerScene := preload("res://commons/flora/botanical_flower.tscn")
const CATALOG := "res://commons/artifacts/biome_object/resident_catalog.json"


static func populate(host, community_seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if not (parsed is Dictionary) or not parsed.has("families"):
		push_warning("Biome resident catalogue is unavailable or invalid")
		return result
	var catalog: Dictionary = parsed
	# each stage billed into the host's counts (gen 3's habit): ms_residents_<stage>
	var t := Time.get_ticks_msec()
	_populate_fungus(host, community_seed, catalog, result)   # gen 12 — first, its draws are keyed by the count so far
	host._counts["ms_residents_fungus"] = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	_populate_blooms(host, community_seed, catalog, result)   # gen 13
	host._counts["ms_residents_bloom"] = Time.get_ticks_msec() - t
	t = Time.get_ticks_msec()
	_populate_bodies(host, community_seed, catalog, result)   # gen 13
	host._counts["ms_residents_body"] = Time.get_ticks_msec() - t
	return result


# ── gen 12: the fungus stage (Astra's, moved into its own function, its draws unchanged) ──
static func _populate_fungus(host, community_seed: int, catalog: Dictionary, result: Array[Dictionary]) -> void:
	var radius: float = catalog["radius_m"]
	var candidates: Array[Dictionary] = []
	var half: float = float(host.size) * 0.5
	# Slots are independent of community_seed: changing bodies does not move the habitat.
	for z in range(host.size * 2):
		for x in range(host.size * 2):
			var p := Vector2(float(x) * 0.5 + 0.25 - half, float(z) * 0.5 + 0.25 - half)
			if not _room_for(host, p, radius):
				continue
			var nearest := 999.0
			var source := Vector2.ZERO
			for mat in host._mats:
				var distance: float = p.distance_to(mat)
				if distance < nearest:
					nearest = distance
					source = mat
			if nearest > 2.2:
				continue
			var cx := clampi(int(floor(p.x + half)), 0, host.size - 1)
			var cz := clampi(int(floor(p.y + half)), 0, host.size - 1)
			var m: float = host._moist[cz * host.size + cx]
			if m < 0.24:
				continue
			candidates.append({"at": p, "moisture": m, "shade": host._shade_at(p),
				"network": source, "score": m * 0.7 + 0.3 / (0.4 + nearest)})
	candidates.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	var limit := mini(int(catalog["max_colonies"]), 2 + roundi(4.0 * host.wildness))
	for slot in candidates:
		if result.size() >= limit:
			break
		var p: Vector2 = slot["at"]
		var crowded := false
		for previous in result:
			var at: Array = previous["position"]
			if p.distance_to(Vector2(at[0], at[2])) < radius * 2.0 + 0.2:
				crowded = true
		if crowded:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([host.seed, "residents", community_seed, result.size()])
		var family: Dictionary = {}
		var best := -999.0
		for recipe in catalog["families"]:
			if recipe.get("builder", "") != "fungus_dna":
				continue # another builder has its own stage below
			# Several bodies can inhabit similar conditions. Preferences, not hard species zones.
			var fitness: float = -absf(slot["moisture"] - recipe["moisture"]) - 0.4 * absf(slot["shade"] - recipe["shade"]) + rng.randf() * 0.35
			for previous in result:
				if previous["family"] == recipe["id"]:
					fitness -= 0.14 # a bounded mixed community, not one best-scoring monoculture
			if fitness > best:
				best = fitness
				family = recipe
		if family.is_empty():
			break
		var variant := 1 + rng.randi_range(0, int(family["variants"]) - 1)
		var path := "%s/%s_%s_%02d.json" % [family["preset_dir"], family["prefix"], family["id"], variant]
		var loaded: Dictionary = host._dispatcher._load_fungus_preset(path)
		if loaded.is_empty():
			push_warning("Biome resident recipe unavailable: " + path)
			continue
		var dna = loaded["dna"]
		var body_seed: int = int(rng.randi() & 0x7fffffff)
		var holder := Node3D.new()
		holder.name = "Resident_%02d_%s" % [result.size(), family["id"]]
		host._patch.add_child(holder)
		var body := Fungus.build(dna, holder, host._dispatcher._get_trait_mapper(), 1, body_seed)
		var bounds := _bounds(holder)
		var raw_radius := Vector2(maxf(absf(bounds.position.x), absf(bounds.end.x)), maxf(absf(bounds.position.z), absf(bounds.end.z))).length()
		var k: float = minf(2.8 * (0.85 + 0.25 * slot["moisture"]), minf((radius - 0.04) / maxf(raw_radius, 0.01), 1.4 / maxf(bounds.size.y, 0.01)))
		holder.scale = Vector3.ONE * k
		holder.position = Vector3(p.x, host._h_at(p.x, p.y) - bounds.position.y * k, p.y)
		# Each ground-rooted member of a ring/cluster meets its own terrain height.
		for member in body.get_children():
			if member is Node3D and String(member.name).begins_with("Colony_"):
				var q: Vector3 = holder.position + member.position * k
				member.position.y += (host._h_at(q.x, q.z) - host._h_at(p.x, p.y)) / k
		result.append({"node": String(holder.name), "artifact": family["artifact"], "family": family["id"],
			"preset": path, "variant": variant, "body_seed": body_seed, "dna": _plain(dna.to_dict()),
			"position": [p.x, holder.position.y, p.y], "radius": radius, "scale": k,
			"moisture": slot["moisture"], "shade": slot["shade"], "role": family["role"],
			"network": [slot["network"].x, slot["network"].y]})


# ── gen 13: the meadow's resident slots — a species by the community, a size by the habitat ──
static func _populate_blooms(host, community_seed: int, catalog: Dictionary, result: Array[Dictionary]) -> void:
	var families: Array = _families(catalog, "flower_preset")
	if families.is_empty():
		return
	var radius: float = float(catalog.get("bloom_radius_m", 0.32))
	# the dispatcher's size law (_spawn_flower reads the same two numbers): the SIZE is the
	# cell's intensity through overall_scale, then _dispatch()'s growth by the moisture
	var s: Dictionary = ConfigLoader.get_intensity_scaling("flower")
	var scale_base: float = float(s.get("overall_scale_base", 1.5))
	var scale_per: float = float(s.get("overall_scale_per_intensity", 0.20))
	var k: float = 1.4 + 0.4 * float(host.moisture)
	var used: Dictionary = {}   # family id -> how many stand already: the diversity penalty's memory
	for key in _slot_keys(host, "flower"):
		var cell: Dictionary = host._cells[key]
		var inten: int = int(cell["inten"])
		var xz: Vector2 = host._body_xz(key)   # where the dispatcher would have stood it — the slot
		var habitat: Dictionary = _habitat_at(host, key, xz)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([host.seed, "residents", community_seed, "bloom", key.x, key.y])
		var family: Dictionary = _pick(families, habitat, rng, used)
		if family.is_empty():
			continue
		used[family["id"]] = int(used.get(family["id"], 0)) + 1
		var body_seed: int = int(rng.randi() & 0x7fffffff)
		var overall: float = scale_base + scale_per * float(inten)
		var flower = BotanicalFlowerScene.instantiate()
		flower.name = "Resident_%02d_%s" % [result.size(), family["id"]]
		flower.preset = String(family["preset"])
		flower.configure({"overall_scale": overall, "seed": body_seed})
		# add_child BEFORE the position, as the dispatcher does — the scene builds in _ready()
		host._patch.add_child(flower)
		var bounds: AABB = _bounds(flower)
		# the object keeps every bloom slot BLOOM_EDGE_M inside the plate (the largest preset at
		# the largest habitat size reaches ~0.9 m); this guard is for the day a preset outgrows
		# that margin — it is not the law, and the record says when it had to bite
		var reach := 0.0
		for cx in [bounds.position.x, bounds.end.x]:
			for cz in [bounds.position.z, bounds.end.z]:
				reach = maxf(reach, Vector2(cx, cz).length())
		var edge: float = float(host.size) * 0.5 - maxf(absf(xz.x), absf(xz.y))
		var capped := false
		if reach * k > edge - 0.05:
			push_warning("biome resident bloom %s reaches %.2f m at an edge of %.2f m — capped; widen BLOOM_EDGE_M" % [family["id"], reach * k, edge])
			k = (edge - 0.05) / maxf(reach, 0.01)
			capped = true
		flower.position = Vector3(xz.x, host._h_at(xz.x, xz.y), xz.y)   # the foot is the root's origin
		flower.scale = Vector3.ONE * k
		# the record carries no measured reach: BotanicalFlower aims an umbel's mounts with
		# look_at through global_position, so a translated instance measures ~1e-6 m differently
		# and the record would drift with the address (measured on an allium, 0 m against 120 m)
		result.append({"node": String(flower.name), "artifact": family["artifact"], "family": family["id"],
			"preset": String(family["preset"]), "variant": 0, "body_seed": body_seed, "dna": _plain(flower.config),
			"position": [xz.x, flower.position.y, xz.y], "radius": radius, "scale": k, "overall_scale": overall,
			"capped": capped, "intensity": inten, "moisture": habitat["moisture"], "shade": habitat["shade"], "lit": habitat["lit"] > 0.5,
			"role": family["role"], "slot": [key.x, key.y]})


# ── gen 13: the creature cells — a body plan by the community, turned to face its resource ──
static func _populate_bodies(host, community_seed: int, catalog: Dictionary, result: Array[Dictionary]) -> void:
	var families: Array = _families(catalog, "creature_dna")
	if families.is_empty():
		return
	var radius: float = float(catalog.get("body_radius_m", 0.5))
	var s: Dictionary = ConfigLoader.get_intensity_scaling("creature")
	var mob_base: float = float(s.get("mobility_base", 0.4))
	var mob_per: float = float(s.get("mobility_per_intensity", 0.1))
	var half: float = float(host.size) * 0.5
	var used: Dictionary = {}
	for key in _slot_keys(host, "creature"):
		var cell: Dictionary = host._cells[key]
		var inten: int = int(cell["inten"])
		var xz: Vector2 = host._body_xz(key)
		var habitat: Dictionary = _habitat_at(host, key, xz)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([host.seed, "residents", community_seed, "body", key.x, key.y])
		var family: Dictionary = _pick(families, habitat, rng, used)
		if family.is_empty():
			continue
		used[family["id"]] = int(used.get(family["id"], 0)) + 1
		# the base recipe is the dispatcher's: SpawnService's walker from a 16-bit seed, then the
		# four geometry genes, the mobility and the iridescence by the cell's intensity
		# (_spawn_creature's own lines) — and the family's plan on top of that
		var body_seed: int = 1 + int(rng.randi() % 65535)   # 1..65535: the recipe reads 16 bits, the mapper treats 0 as "no seed"
		var dna: CritterDNA = SpawnService.creature_dna_from_seed(body_seed)
		dna.segments = 3.0 + 0.5 * float(inten)
		dna.scale = 0.55 + 0.07 * float(inten)
		dna.part_length = 0.30 + 0.03 * float(inten)
		dna.part_width = 0.85 + 0.03 * float(inten)
		dna.mobility = mob_base + mob_per * float(inten)
		dna.iridescence = 0.1 + 0.1 * float(inten) / 5.0
		var plan: Dictionary = family.get("body", {})
		dna.segments = clampf(dna.segments + float(plan.get("segments_add", 0.0)), 2.0, 12.0)
		dna.scale = clampf(dna.scale * float(plan.get("scale_mul", 1.0)), 0.3, 3.0)
		dna.part_length = clampf(dna.part_length * float(plan.get("part_length_mul", 1.0)), 0.1, 2.0)
		dna.part_width = clampf(dna.part_width * float(plan.get("part_width_mul", 1.0)), 0.05, 1.0)
		var genes: Dictionary = family.get("genes", {})
		for gene in genes.keys():
			dna.set(String(gene), float(genes[gene]))
		var tint: Dictionary = family.get("tint", {})
		if not tint.is_empty():
			# the seed's hue kept; the plan says how saturated and how light the body is
			for col_name in ["primary_color", "secondary_color", "tertiary_color"]:
				var col: Color = dna.get(col_name)
				dna.set(col_name, Color.from_hsv(col.h, clampf(col.s * float(tint.get("saturation", 1.0)), 0.0, 1.0),
					clampf(col.v * float(tint.get("value", 1.0)), 0.0, 1.0)))
		var lod: int = mini(clampi(inten - 1, 0, 3), Dispatcher.BIOME_SDF_MAX_LOD_FAUNA)
		var holder := Node3D.new()
		holder.name = "Resident_%02d_%s" % [result.size(), family["id"]]
		host._patch.add_child(holder)
		var mapper: CritterTraitMapper = host._dispatcher._get_trait_mapper()
		var body: Node3D = CreatureSdf.build(dna, holder, mapper, lod)
		# the SDF builder asks the mapper for its skin with no instance seed, and the mapper
		# then draws pattern_rotation from the GLOBAL randi(); the same call with the body's
		# seed is the same skin, replayable — the eyes' materials are constants
		var skin: Node = body.find_child("Body", false, false)
		if skin is MeshInstance3D:
			(skin as MeshInstance3D).material_override = mapper.create_part_material(dna, CritterTraitMapper.PartType.TRUNK, body_seed)
		var bounds: AABB = _bounds(holder)
		# the spine runs +Z from the head at the origin: centre the body's xz on the slot so a
		# turn about the slot swings the tail as much as the head
		var centre := Vector3((bounds.position.x + bounds.end.x) * 0.5, 0.0, (bounds.position.z + bounds.end.z) * 0.5)
		body.position = -centre
		bounds.position -= centre
		# what it faces: the eyes look down local −Z, so yaw = atan2(−dx, −dz) turns them onto the target
		var faces: Dictionary = _faces(host, key, xz)
		var target: Array = faces["at"]
		var yaw: float = atan2(-(float(target[0]) - xz.x), -(float(target[1]) - xz.y))
		# the dispatcher grows a creature 1.6x; the plan's size on that, capped so the body,
		# whichever way it turns, stays 0.05 m inside the plate
		var reach := 0.0
		for cx in [bounds.position.x, bounds.end.x]:
			for cz in [bounds.position.z, bounds.end.z]:
				reach = maxf(reach, Vector2(cx, cz).length())
		var edge: float = half - maxf(absf(xz.x), absf(xz.y))
		var k: float = 1.6 * float(plan.get("size", 1.0))
		k = minf(k, (edge - 0.05) / maxf(reach, 0.01))
		holder.scale = Vector3.ONE * k
		holder.rotation.y = yaw
		holder.position = Vector3(xz.x, host._h_at(xz.x, xz.y) - bounds.position.y * k, xz.y)
		# the footprint in the patch frame — the four xz corners turned, scaled and stood at the slot
		var basis := Basis(Vector3.UP, yaw)
		var fx0 := 99.0
		var fz0 := 99.0
		var fx1 := -99.0
		var fz1 := -99.0
		for cx in [bounds.position.x, bounds.end.x]:
			for cz in [bounds.position.z, bounds.end.z]:
				var w: Vector3 = basis * Vector3(cx, 0.0, cz) * k
				fx0 = minf(fx0, xz.x + w.x)
				fx1 = maxf(fx1, xz.x + w.x)
				fz0 = minf(fz0, xz.y + w.z)
				fz1 = maxf(fz1, xz.y + w.z)
		result.append({"node": String(holder.name), "artifact": family["artifact"], "family": family["id"],
			"preset": String(family.get("preset", "creature_dna_from_seed")), "variant": 0, "body_seed": body_seed,
			"dna": _plain(dna.to_dict()), "position": [xz.x, holder.position.y, xz.y], "radius": radius, "scale": k,
			"intensity": inten, "moisture": habitat["moisture"], "shade": habitat["shade"], "lit": habitat["lit"] > 0.5,
			"near_water": habitat["near_water"], "near_mineral": habitat["near_mineral"], "role": family["role"],
			"slot": [key.x, key.y], "faces": {"what": faces["what"], "at": target, "distance": faces["distance"], "yaw": yaw},
			"footprint": [fx0, fz0, fx1, fz1], "motion": "placed body, not a simulation"})


## The catalogue's families for one builder, in catalogue order.
static func _families(catalog: Dictionary, builder: String) -> Array:
	var out: Array = []
	for recipe in catalog["families"]:
		if String(recipe.get("builder", "")) == builder:
			out.append(recipe)
	return out


## The object's cells of one kingdom that _ecology() marked `resident`, row-major — a fact
## about the habitat seed, the same list under every community.
static func _slot_keys(host, kingdom: String) -> Array:
	var keys: Array = []
	for key in host._cells.keys():
		var c: Dictionary = host._cells[key]
		if String(c["kingdom"]) == kingdom and bool(c.get("resident", false)):
			keys.append(key)
	keys.sort_custom(func(a, b): return (a.y * host.size + a.x) < (b.y * host.size + b.x))
	return keys


## What a slot is like: its moisture, the shade over it (the one law, _shade_at), whether it
## lies on the sun's side of its trunk (1.0 / 0.0), its distance to the water in cells and to
## the nearest crystal cluster in metres.
static func _habitat_at(host, key: Vector2i, xz: Vector2) -> Dictionary:
	var d_mineral := 9.0
	for cp in host._clusters:
		d_mineral = minf(d_mineral, xz.distance_to(cp))
	return {"moisture": float(host._moist[key.y * host.size + key.x]), "shade": float(host._shade_at(xz)),
		"lit": 1.0 if bool(host._lit_side(xz)) else 0.0,
		"near_water": float(host._water_dist(key.x, key.y)), "near_mineral": d_mineral}


## Astra's fitness, one draw per recipe: nearness to the family's moisture and shade, a jitter
## of 0.35, 0.14 off per body of the family standing already. gen 13 adds two optional terms a
## family may declare — `lit` (0 shade-side .. 1 sun-side; 0.3 × the distance to it) and
## `near` ("water" in cells or "mineral" in metres; up to `near_weight` at 0, nothing at 3).
static func _pick(families: Array, habitat: Dictionary, rng: RandomNumberGenerator, used: Dictionary) -> Dictionary:
	var family: Dictionary = {}
	var best := -999.0
	for recipe in families:
		var fitness: float = -absf(float(habitat["moisture"]) - float(recipe["moisture"])) - 0.4 * absf(float(habitat["shade"]) - float(recipe["shade"])) + rng.randf() * 0.35
		if recipe.has("lit"):
			fitness -= 0.3 * absf(float(habitat["lit"]) - float(recipe["lit"]))
		if recipe.has("near"):
			var d: float = float(habitat.get("near_" + String(recipe["near"]), 9.0))
			fitness += float(recipe.get("near_weight", 0.3)) * (1.0 - clampf(d / 3.0, 0.0, 1.0))
		fitness -= 0.14 * float(int(used.get(recipe["id"], 0)))
		if fitness > best:
			best = fitness
			family = recipe
	return family


## What a body lives by: the nearest water cell's centre when the slot is within 3 cells of
## water, else the nearest flower cell's centre, else the nearest mycelium mat, else +x.
static func _faces(host, key: Vector2i, xz: Vector2) -> Dictionary:
	var best := 999.0
	var at := Vector2(xz.x + 1.0, xz.y)
	var what := "none"
	if host._water_dist(key.x, key.y) <= 3.0:
		for wk in host._water.keys():
			var cw: Vector3 = host._cell_world(wk.x, wk.y)
			var d: float = xz.distance_to(Vector2(cw.x, cw.z))
			if d < best:
				best = d
				at = Vector2(cw.x, cw.z)
				what = "water"
	if what == "none":
		for fk in host._cells.keys():
			if String(host._cells[fk]["kingdom"]) != "flower":
				continue
			var cw: Vector3 = host._cell_world(fk.x, fk.y)
			var d: float = xz.distance_to(Vector2(cw.x, cw.z))
			if d < best:
				best = d
				at = Vector2(cw.x, cw.z)
				what = "flower"
	if what == "none":
		for mp in host._mats:
			var d: float = xz.distance_to(mp)
			if d < best:
				best = d
				at = mp
				what = "mycelium"
	return {"what": what, "at": [at.x, at.y], "distance": (best if what != "none" else 1.0)}


## A record's genes as JSON: every Color as [r, g, b, a].
static func _plain(genes: Dictionary) -> Dictionary:
	var out: Dictionary = genes.duplicate()
	for key in out.keys():
		if out[key] is Color:
			var col: Color = out[key]
			out[key] = [col.r, col.g, col.b, col.a]
	return out


static func _room_for(host, p: Vector2, radius: float) -> bool:
	var half: float = float(host.size) * 0.5
	if maxf(absf(p.x), absf(p.y)) + radius >= half - 0.05:
		return false
	var low := 999.0
	var high := -999.0
	for dz in [-radius, 0.0, radius]:
		for dx in [-radius, 0.0, radius]:
			var q := p + Vector2(dx, dz)
			if not host._cover_land(q):
				return false
			var h: float = host._h_at(q.x, q.y)
			low = minf(low, h)
			high = maxf(high, h)
	if high - low > 0.38:
		return false
	for key in host._cells:
		var kind: String = host._cells[key]["kingdom"]
		if kind not in ["tree", "flower", "creature"]:
			continue
		var wp: Vector3 = host._cell_world(key.x, key.y)
		var q: Vector2 = host._pos.get(key, Vector2(wp.x, wp.z))
		if p.distance_to(q) < radius + (0.35 if kind == "tree" else 0.55):
			return false
	return true


## The merged AABB of a body's MeshInstance3Ds in the ROOT's frame (the root's own transform
## left out). gen 13: composed from each node's LOCAL transform down from the root — the
## gen-12 form, inverse(root.global) × node.global, carried the object's world position into
## the arithmetic, and a twin standing 30 m along x measured a bloom's reach 1.6e-6 m
## differently: the record drifted with the address. Local composition is a fact about the
## body alone.
static func _bounds(root: Node3D) -> AABB:
	var result := AABB()
	var have := false
	var stack: Array = [[root, Transform3D.IDENTITY]]   # [node, its transform relative to the root]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var xf: Transform3D = item[1]
		for child in node.get_children():
			stack.append([child, (xf * (child as Node3D).transform) if child is Node3D else xf])
		if node is MeshInstance3D and node.mesh != null:
			var box: AABB = xf * node.mesh.get_aabb()
			result = result.merge(box) if have else box
			have = true
	return result
