# @identity
# essence: trail(x,y) += deposit; next = argmax(pheromone[neighbors]) with P(random) = 1 - attraction — stigmergy
# desire: watch random walkers leave glowing trails that attract other walkers, building ridges from nothing
# critical_parameter: pheromone_attraction — the probability a walker follows pheromone vs moves randomly (0 = pure random, 1 = pure trail-following)
# triggers: _walk_step() deposits pheromone, raises terrain, then _choose_next_position() balances attraction vs random
# emerges: path networks self-organize — walkers converge on trails they collectively created without communication
# needs: PlaneMesh child with dynamic vertex modification [has]; VR observation [has]; controls [missing]
# relationships: feeds Random_Pheromone map; depends on random walk concept; contrasts with pixel_cloud (self-avoiding vs self-attracting)
# truth: Stigmergy is memory without a brain — the environment itself becomes the communication channel.

extends Node3D

## Pheromone Terrain - Walkers that follow pheromone trails
## Walkers deposit pheromones as they move and are attracted to existing pheromones
## Creates organic, path-like terrain deformation patterns

@export_category("Walker Settings")
@export var walker_count: int = 5
@export var walk_speed: float = 5.0  # Steps per second
@export var raise_amount: float = 0.05  # Height increase per step
@export var max_height: float = 3.0

@export_category("Pheromone Settings")
@export var pheromone_deposit: float = 0.5  # Amount of pheromone deposited per step
@export var pheromone_decay_rate: float = 0.2  # How fast pheromones decay per second
@export var pheromone_attraction: float = 0.3  # 0-1: How much walkers are attracted (vs random)
@export var sensor_distance: int = 2  # How far ahead walkers sense pheromones
@export var pheromone_color: Color = Color(1.0, 0.0, 1.0) # Magenta for "Queer Energy"

@export_category("Terrain Settings")
@export var border_size: int = 10  # Unmanipulated border size (in segments) for walkable edges

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## THE LAW A WALKER FOLLOWS WHEN IT DECIDES WHERE TO STEP. `rule` is mold_network's word
## for exactly this slot, seconded by structure_growth, complexity_pattern and
## lifeform_walker. The WORD carries; the VALUE LIST cannot and must not — those four are
## survive/born bands over a cell's neighbours, this is one walker choosing one of eight
## compass steps, a different alphabet in which "4-6/5-7" means nothing. These should NOT
## be compared as a family measurement.
##
## What is turned here is the LAW, never the rate: a still photograph cannot see a
## deposit-per-second or a decay, but it can see whether the ground ended up ridged,
## braided, rectilinear or evenly churned.
##   trail  the shipped law — eight compass neighbours, sensed `sensor_distance` ahead,
##          take the strongest scent (ties to the first direction, as it always has).
##          Self-reinforcing: the walkers converge on paths they made, and the ground
##          grows a few thick ridges.
##   sniff  the walker keeps a HEADING and sees only the three steps in front of it
##          (turn left, straight on, turn right). It cannot double back on itself, so
##          the same attraction lays long smooth arcs instead of knots. This is the
##          Physarum reading of stigmergy: the environment remembers, and so does the body.
##   avoid  the sign of the gradient flipped — flee the strongest scent. Anti-stigmergy:
##          a trail as a record of where you no longer need to go. The ridges never form;
##          the walkers spread and the plot churns evenly.
##   grid   the same following law over the four CARDINAL neighbours only. The lattice
##          stops being a substrate and becomes visible in the result: right-angled
##          ridges, a street plan rather than a delta.
@export_enum("trail", "sniff", "avoid", "grid") var rule: String = "trail"
const RULES: PackedStringArray = ["trail", "sniff", "avoid", "grid"]

## -1 keeps the shipped behaviour EXACTLY: the global unseeded randf()/randi()/randi_range(),
## a different landscape every run. Any value >= 0 pins one. Not an axis — without it four
## rule variants are four different landscapes and a sweep measures the RNG instead of the law.
@export var walk_seed: int = -1

## Steps to run before the first frame is shown, each one decaying by the real step
## interval so the dynamics are the shipped dynamics played fast. 0 is the shipped
## behaviour: nothing has happened when the map opens and the trails grow while you watch.
## Not an axis either — a still photographed 0.35 s after spawn shows a flat white plane
## under every value, which is a fact about the bench and not about the rule.
@export var warmup_steps: int = 0

## The eight compass steps, in the order the shipped `_choose_next_position` built them
## every call. Hoisted to a constant so the candidate set can be narrowed per rule; the
## order is unchanged, which matters because ties fall to the first entry.
const DIRS_8: Array = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
## The first four of those — the cardinal neighbours, same order.
const DIRS_4: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## The same eight in ANGULAR order, so a heading's neighbours are its list neighbours.
const COMPASS: Array = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

@onready var plane_node = $Plane

# Grid data
var x_segments: int
var y_segments: int
var vertex_grid: Array = []
var pheromone_grid: Array = []
var indices: PackedInt32Array

# Walker data
var walkers: Array = []
var mesh_instance: MeshInstance3D
var time_accumulator: float = 0.0

# Seeded stream, used ONLY when walk_seed >= 0. At the shipped -1 every draw still comes
# from the global generator, in the same order and the same count as it always did.
var _rng := RandomNumberGenerator.new()
var _seeded: bool = false

func _ready() -> void:
	_init_rng()
	set_process(false)
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	
	if not plane_node:
		push_error("Pheromoneterrain: No 'Plane' child node found!")
		return
	
	# Find mesh instance
	mesh_instance = _find_mesh_instance(plane_node)
	if not mesh_instance:
		push_error("PheromoneeTerrain: No MeshInstance3D found!")
		return

	# Read dimensions from PlaneMesh before converting
	if mesh_instance.mesh is PlaneMesh:
		var plane_mesh = mesh_instance.mesh as PlaneMesh
		x_segments = plane_mesh.subdivide_width
		y_segments = plane_mesh.subdivide_depth
		# Store size as metadata for later use
		mesh_instance.set_meta("plane_width", plane_mesh.size.x)
		mesh_instance.set_meta("plane_height", plane_mesh.size.y)

	# Convert PrimitiveMesh to ArrayMesh for dynamic modification
	if mesh_instance.mesh is PrimitiveMesh:
		var primitive_mesh = mesh_instance.mesh as PrimitiveMesh
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, primitive_mesh.get_mesh_arrays())
		
		# Create/Ensure material supports vertex colors
		var material = primitive_mesh.material
		if material:
			if material is StandardMaterial3D:
				material.vertex_color_use_as_albedo = true
			array_mesh.surface_set_material(0, material)
		else:
			# Create default material if none exists
			var new_mat = StandardMaterial3D.new()
			new_mat.vertex_color_use_as_albedo = true
			new_mat.albedo_color = Color.WHITE
			array_mesh.surface_set_material(0, new_mat)
			
		mesh_instance.mesh = array_mesh

	_initialize_grids()
	_create_walkers()

	_add_info_label()
	_warmup()
	set_process(true)
	print("PheromoneeTerrain: Initialized with %d walkers on %dx%d grid" % [walker_count, x_segments, y_segments])


func _init_rng() -> void:
	_seeded = walk_seed >= 0
	if _seeded:
		_rng.seed = int(walk_seed)


func _rand_unit() -> float:
	return _rng.randf() if _seeded else randf()


func _rand_index(n: int) -> int:
	return (_rng.randi() % n) if _seeded else (randi() % n)


func _rand_between(a: int, b: int) -> int:
	return _rng.randi_range(a, b) if _seeded else randi_range(a, b)


## Run the simulation forward before anything is shown, decaying by the REAL step
## interval each step so this is the shipped dynamics played fast rather than a
## different process. At the shipped 0 it returns before touching anything.
func _warmup() -> void:
	if warmup_steps <= 0:
		return
	var dt: float = 1.0 / maxf(walk_speed, 0.001)
	for _i in range(warmup_steps):
		_decay_pheromones(dt)
		_walk_step()
	_update_mesh()
	_update_info_label()

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Recursively find MeshInstance3D"""
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

func _initialize_grids() -> void:
	"""Initialize vertex and pheromone grids"""
	# Use dimensions stored as metadata (set during initialization)
	var plane_width: float = mesh_instance.get_meta("plane_width", 20.0)
	var plane_height: float = mesh_instance.get_meta("plane_height", 20.0)

	# x_segments and y_segments are already set in _ready()
	if x_segments == 0:
		x_segments = 100
	if y_segments == 0:
		y_segments = 100
	var half_width = plane_width / 2.0
	var half_height = plane_height / 2.0
	var x_step = plane_width / float(x_segments)
	var y_step = plane_height / float(y_segments)
	
	# Build vertex grid
	vertex_grid.clear()
	pheromone_grid.clear()
	
	for j in range(y_segments + 1):
		var vertex_row = []
		var pheromone_row = []
		for i in range(x_segments + 1):
			var x = -half_width + i * x_step
			var z = half_height - j * y_step
			vertex_row.append(Vector3(x, 0, z))
			pheromone_row.append(0.0)  # Start with no pheromones
		vertex_grid.append(vertex_row)
		pheromone_grid.append(pheromone_row)
	
	# Build indices
	_build_indices()

func _build_indices() -> void:
	"""Build triangle indices"""
	indices.clear()
	for j in range(y_segments):
		for i in range(x_segments):
			var a = j * (x_segments + 1) + i
			var b = a + 1
			var c = (j + 1) * (x_segments + 1) + i
			var d = c + 1
			# CCW winding
			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)

func _create_walkers() -> void:
	"""Create walkers at random positions (inside border)"""
	walkers.clear()
	var min_x = border_size
	var max_x = x_segments - border_size
	var min_y = border_size
	var max_y = y_segments - border_size

	for i in range(walker_count):
		# The two draws, in the shipped order and count. The heading is assigned from the
		# compass by INDEX, deliberately without a draw, so `trail` consumes exactly the
		# random stream it always did and the shipped landscape is unchanged.
		var start_x: int = _rand_between(min_x, max_x)
		var start_y: int = _rand_between(min_y, max_y)
		var head: Vector2i = COMPASS[i % COMPASS.size()]
		walkers.append({
			"x": start_x,
			"y": start_y,
			"active": true,
			"hx": head.x,
			"hy": head.y
		})

func _process(delta: float) -> void:
	if not mesh_instance or vertex_grid.is_empty():
		return
	
	# Decay pheromones
	_decay_pheromones(delta)
	
	# Update walkers at specified speed
	time_accumulator += delta
	var step_interval = 1.0 / maxf(walk_speed, 0.001)
	var steps_to_run := 0
	while time_accumulator >= step_interval and steps_to_run < 32:
		time_accumulator -= step_interval
		steps_to_run += 1

	if steps_to_run > 0:
		for i in range(steps_to_run):
			_walk_step()
		_update_mesh()
		_update_info_label()

func _decay_pheromones(delta: float) -> void:
	"""Decay all pheromones over time"""
	var decay_amount = pheromone_decay_rate * delta
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			if pheromone_grid[j][i] > 0:
				pheromone_grid[j][i] = max(0.0, pheromone_grid[j][i] - decay_amount)

func _walk_step() -> void:
	"""Move walkers based on pheromone attraction"""
	for walker in walkers:
		if not walker.active:
			continue

		# Check if walker is inside the allowed area (not in border)
		if _is_in_border(walker.x, walker.y):
			# Move walker back to allowed area
			walker.x = clamp(walker.x, border_size, x_segments - border_size)
			walker.y = clamp(walker.y, border_size, y_segments - border_size)
			# Turn it round. This branch `continue`s without choosing a direction, so a
			# heading-locked walker (rule = sniff) would keep pushing at the same wall
			# for ever — clamped back, stepping out, clamped back. Reversing the heading
			# here is the only line the border needs. Inert under every other value,
			# which never reads a heading, and it consumes no random draw, so the shipped
			# stream is untouched.
			walker.hx = -int(walker.get("hx", 1))
			walker.hy = -int(walker.get("hy", 0))
			continue

		# Deposit pheromone at current location
		pheromone_grid[walker.y][walker.x] += pheromone_deposit

		# Raise terrain at current location (only if not in border)
		var current_vertex = vertex_grid[walker.y][walker.x]
		if current_vertex.y < max_height:
			current_vertex.y += raise_amount
			vertex_grid[walker.y][walker.x] = current_vertex

		# Decide next move based on pheromones
		var next_pos = _choose_next_position(walker)
		walker.x = next_pos.x
		walker.y = next_pos.y

## The three steps in front of a walker with this heading — straight on, turn left, turn
## right. Used only by `sniff`; a walker that can only see forward cannot reverse into
## its own trail, which is the whole difference between a knot and an arc.
##
## STRAIGHT ON IS FIRST ON PURPOSE. The shipped law breaks ties on the FIRST entry, and
## on ground nobody has walked yet every candidate senses 0.0, so whatever sits at index
## 0 is what a following walker does by default. With a turn there, a sniffing walker
## curls the same way on every blank step and the plot fills with same-handed spirals —
## an artefact of the list order presented as a fact about stigmergy. Straight ahead is
## the honest default for a body with momentum.
func _forward_cone(hx: int, hy: int) -> Array:
	var here := Vector2i(hx, hy)
	var idx: int = COMPASS.find(here)
	if idx < 0:
		idx = 0
	var n: int = COMPASS.size()
	return [COMPASS[idx], COMPASS[(idx + n - 1) % n], COMPASS[(idx + 1) % n]]

func _rule_value() -> String:
	var r: String = String(rule).strip_edges().to_lower()
	return r if RULES.has(r) else "trail"

func _choose_next_position(walker: Dictionary) -> Vector2i:
	"""Choose next position based on pheromone concentration.

	`trail` is the shipped law, line for line: eight compass directions in the order they
	were always built, the seed value best_pheromone = -1.0, a STRICT > so ties fall to
	the first entry, the same bounds test, and the same single randf() before it. The
	other three values change WHICH neighbours are candidates (sniff, grid) or the SIGN
	of the comparison (avoid), and nothing else — same draws, same order, same count.
	"""
	var x: int = int(walker["x"])
	var y: int = int(walker["y"])

	var directions: Array = DIRS_8
	var seek_max: bool = true
	match _rule_value():
		"sniff":
			directions = _forward_cone(int(walker.get("hx", 1)), int(walker.get("hy", 0)))
		"avoid":
			seek_max = false
		"grid":
			directions = DIRS_4
		_:
			pass                      # "trail" — the shipped law

	var chosen: Vector2i = directions[0]
	# Use pheromone attraction vs random choice
	if _rand_unit() < pheromone_attraction:
		# Follow (or flee) pheromones — sense ahead and pick the extreme concentration
		var best_pheromone: float = -1.0 if seek_max else INF

		for dir in directions:
			var d: Vector2i = dir
			var sense_x: int = x + d.x * sensor_distance
			var sense_y: int = y + d.y * sensor_distance

			# Check bounds
			if sense_x < 0 or sense_x > x_segments or sense_y < 0 or sense_y > y_segments:
				continue

			var pheromone_level: float = pheromone_grid[sense_y][sense_x]
			var better: bool = (pheromone_level > best_pheromone) if seek_max else (pheromone_level < best_pheromone)
			if better:
				best_pheromone = pheromone_level
				chosen = d
	else:
		# Random movement
		chosen = directions[_rand_index(directions.size())]

	# The heading a walker leaves with — read back by `sniff` on its next step, inert
	# under every other value.
	walker["hx"] = chosen.x
	walker["hy"] = chosen.y
	return Vector2i(clampi(x + chosen.x, 0, x_segments), clampi(y + chosen.y, 0, y_segments))

func _update_mesh() -> void:
	"""Update mesh with modified vertices, normals, and colors"""
	if not mesh_instance:
		return
	
	# Flatten vertex grid to array
	var new_vertices = PackedVector3Array()
	var new_colors = PackedColorArray()
	
	for j in range(vertex_grid.size()):
		var row = vertex_grid[j]
		var pheromone_row = pheromone_grid[j]
		for i in range(row.size()):
			new_vertices.append(row[i])
			
			# Calculate color based on pheromone intensity
			var intensity = clamp(pheromone_row[i], 0.0, 1.0)
			# Base color (white) mixed with pheromone color
			var color = Color.WHITE.lerp(pheromone_color, intensity)
			new_colors.append(color)
	
	var mesh: ArrayMesh = mesh_instance.mesh

	# Save the material before clearing surfaces
	var saved_material = null
	if mesh.get_surface_count() > 0:
		saved_material = mesh.surface_get_material(0)

	# Use SurfaceTool for proper normal generation
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, indices.size(), 3):
		var idx1 = indices[i]
		var idx2 = indices[i+1]
		var idx3 = indices[i+2]
		
		st.set_color(new_colors[idx1])
		st.add_vertex(new_vertices[idx1])
		
		st.set_color(new_colors[idx2])
		st.add_vertex(new_vertices[idx2])
		
		st.set_color(new_colors[idx3])
		st.add_vertex(new_vertices[idx3])

	st.generate_normals()

	mesh.clear_surfaces()
	st.commit(mesh)

	# Restore the material
	if saved_material:
		mesh.surface_set_material(0, saved_material)

func get_pheromone_at(x: int, y: int) -> float:
	"""Get pheromone level at grid position"""
	if x < 0 or x > x_segments or y < 0 or y > y_segments:
		return 0.0
	return pheromone_grid[y][x]

func reset_terrain() -> void:
	"""Reset terrain and pheromones"""
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			vertex_grid[j][i].y = 0.0
			pheromone_grid[j][i] = 0.0
	_update_mesh()

func _is_in_border(x: int, y: int) -> bool:
	"""Check if position is in the border area"""
	return x < border_size or x > x_segments - border_size or \
		   y < border_size or y > y_segments - border_size

var _info_label: Label3D

func _add_info_label() -> void:
	_info_label = Label3D.new()
	_info_label.font_size = 20
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1.0, 0.5, 1.0, 0.8)
	_info_label.position = Vector3(0, max_height + 2.0, 0)
	add_child(_info_label)

	var title := Label3D.new()
	title.text = "Pheromone Terrain"
	title.font_size = 24
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 0.8)
	title.position = Vector3(0, max_height + 3.5, 0)
	add_child(title)

func _update_info_label() -> void:
	if _info_label:
		var total_phero := 0.0
		for row in pheromone_grid:
			for val in row:
				total_phero += val
		_info_label.text = "walkers: %d  attraction: %.0f%%  pheromone: %.0f" % [
			walker_count, pheromone_attraction * 100, total_phero
		]

## ASSIGNS ONLY — nothing here rebuilds. GridInteractablesComponent reaches this through
## call_deferred, so it lands AFTER _ready has already built the grids and the walkers;
## a rebuild would wipe a terrain the room has been growing since the player walked in,
## which is force_pad's mistake and the reason this is a pure assignment. `rule` is read
## live by _choose_next_position, so it bites from the next step under either ordering.
## walk_seed and warmup_steps only mean anything before _ready — the capture bench sets
## them as properties before add_child, which is where they belong.
##
## All three placements (Random_Pheromone, Room_Random_Pheromone, Corridor_Random_Pheromone)
## carry the bare token with no config keys at all, so not one of these branches is
## reachable from any map that exists today.
func apply_grid_config(config: Dictionary) -> void:
	# An unknown word is ignored rather than assigned, so a typo falls back to the
	# shipped law instead of stalling the walkers.
	if config.has("rule"):
		var want: String = String(config["rule"]).strip_edges().to_lower()
		if RULES.has(want):
			rule = want
	if config.has("walk_seed"):
		walk_seed = int(config["walk_seed"])
		_init_rng()
	if config.has("warmup_steps"): warmup_steps = maxi(0, int(config["warmup_steps"]))
	if config.has("walker_count"): walker_count = maxi(1, int(config["walker_count"]))
	if config.has("walk_speed"): walk_speed = maxf(0.001, float(config["walk_speed"]))
	if config.has("raise_amount"): raise_amount = float(config["raise_amount"])
	if config.has("max_height"): max_height = float(config["max_height"])
	if config.has("pheromone_deposit"): pheromone_deposit = float(config["pheromone_deposit"])
	if config.has("pheromone_decay_rate"): pheromone_decay_rate = maxf(0.0, float(config["pheromone_decay_rate"]))
	if config.has("pheromone_attraction"): pheromone_attraction = clampf(float(config["pheromone_attraction"]), 0.0, 1.0)
	if config.has("sensor_distance"): sensor_distance = maxi(1, int(config["sensor_distance"]))
	if config.has("pheromone_color"):
		pheromone_color = _parse_color(config["pheromone_color"], pheromone_color)


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = String(value).split(",")
		if parts.size() >= 3:
			return Color(float(parts[0]), float(parts[1]), float(parts[2]),
				1.0 if parts.size() < 4 else float(parts[3]))
	return fallback
