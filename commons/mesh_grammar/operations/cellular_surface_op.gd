## CellularSurfaceOp — Run cellular automata rules on the mesh face grid.
## Treats each face as a cell and face adjacency as the cell neighborhood.
## After running CA steps, "alive" faces get tagged for subsequent grammar ops.
## Inspired by: Game of Life, organic growth patterns spreading across surfaces.
## Params:
##   ca_steps: int = 3            — number of CA iterations
##   rule: String = "life"        — "life" (B3/S23), "grow" (B12/S012345), "decay" (B/S01), "custom"
##   birth: PackedInt32Array = [3] — neighbor counts that cause birth (for "custom" rule)
##   survival: PackedInt32Array = [2,3] — neighbor counts that cause survival (for "custom")
##   initial_density: float = 0.3  — probability of each selected face starting alive
##   seed_value: int = -1          — random seed (-1 = random)
##   alive_tag: String = "ca_alive"
##   dead_tag: String = "ca_dead"
##   tag_only: bool = true         — if true, only tags faces; if false, deletes dead faces
extends MeshRule
class_name CellularSurfaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var ca_steps: int = params.get("ca_steps", 3)
	var rule: String = params.get("rule", "life")
	var birth: PackedInt32Array = params.get("birth", PackedInt32Array([3]))
	var survival: PackedInt32Array = params.get("survival", PackedInt32Array([2, 3]))
	var initial_density: float = clampf(params.get("initial_density", 0.3), 0.0, 1.0)
	var seed_val: int = params.get("seed_value", -1)
	var alive_tag: String = params.get("alive_tag", "ca_alive")
	var dead_tag: String = params.get("dead_tag", "ca_dead")
	var tag_only: bool = params.get("tag_only", true)

	# Parse rule presets
	match rule:
		"life":
			birth = PackedInt32Array([3])
			survival = PackedInt32Array([2, 3])
		"grow":
			# Aggressive growth — cells born easily, survive easily
			birth = PackedInt32Array([1, 2])
			survival = PackedInt32Array([0, 1, 2, 3, 4, 5])
		"decay":
			# Quick decay — hard to be born, hard to survive
			birth = PackedInt32Array()
			survival = PackedInt32Array([0, 1])
		"coral":
			# Coral-like: moderate birth, good survival
			birth = PackedInt32Array([2])
			survival = PackedInt32Array([1, 2, 3])
		"custom":
			pass  # Use provided birth/survival arrays

	# Build set for fast lookup
	var birth_set: Dictionary = {}
	for b in birth:
		birth_set[b] = true
	var survival_set: Dictionary = {}
	for s in survival:
		survival_set[s] = true

	# Initialize cell states
	var rng := RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	# Track which faces are in our CA grid
	var cell_set: Dictionary = {}
	for fi in selected:
		if fi < mesh.faces.size():
			cell_set[fi] = true

	# Initialize alive/dead state
	var alive: Dictionary = {}
	for fi in cell_set:
		alive[fi] = rng.randf() < initial_density

	# Run CA steps
	for _step in range(ca_steps):
		var next_alive: Dictionary = {}
		for fi in cell_set:
			# Count alive neighbors
			var neighbors := mesh.get_face_neighbors(fi)
			var alive_count: int = 0
			for ni in neighbors:
				if alive.get(ni, false):
					alive_count += 1

			# Apply birth/survival rules
			if alive.get(fi, false):
				# Cell is alive — check survival
				next_alive[fi] = survival_set.has(alive_count)
			else:
				# Cell is dead — check birth
				next_alive[fi] = birth_set.has(alive_count)

		alive = next_alive

	# Apply results: tag faces
	var dead_faces: PackedInt32Array = PackedInt32Array()
	for fi in cell_set:
		if alive.get(fi, false):
			mesh.tag_face(fi, alive_tag)
		else:
			mesh.tag_face(fi, dead_tag)
			if not tag_only:
				dead_faces.append(fi)

	# Optionally delete dead faces
	if not tag_only and dead_faces.size() > 0:
		mesh.remove_faces(dead_faces)

	mesh._adjacency_dirty = true
