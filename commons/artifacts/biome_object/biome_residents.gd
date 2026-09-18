extends RefCounted
## One habitat, independent community DNA. Catalogue recipes occupy bounded gaps
## beside existing mycelium. This adapter builds forms, not a living-agent simulation.
const Fungus := preload("res://algorithms/nature_system/morphology/fungus_morphology.gd")
const CATALOG := "res://commons/artifacts/biome_object/resident_catalog.json"


static func populate(host, community_seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if not (parsed is Dictionary) or not parsed.has("families"):
		push_warning("Biome resident catalogue is unavailable or invalid")
		return result
	var catalog: Dictionary = parsed
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
				continue # another builder needs its own tested mounting adapter
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
		var genes: Dictionary = dna.to_dict()
		for key in genes.keys():
			if genes[key] is Color:
				var col: Color = genes[key]
				genes[key] = [col.r, col.g, col.b, col.a]
		result.append({"node": String(holder.name), "artifact": family["artifact"], "family": family["id"],
			"preset": path, "variant": variant, "body_seed": body_seed, "dna": genes,
			"position": [p.x, holder.position.y, p.y], "radius": radius, "scale": k,
			"moisture": slot["moisture"], "shade": slot["shade"], "role": family["role"],
			"network": [slot["network"].x, slot["network"].y]})
	return result


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


static func _bounds(root: Node3D) -> AABB:
	var result := AABB()
	var have := false
	var stack: Array[Node] = [root]
	var inverse := root.global_transform.affine_inverse()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is MeshInstance3D and node.mesh != null:
			var box: AABB = (inverse * node.global_transform) * node.mesh.get_aabb()
			result = result.merge(box) if have else box
			have = true
	return result
