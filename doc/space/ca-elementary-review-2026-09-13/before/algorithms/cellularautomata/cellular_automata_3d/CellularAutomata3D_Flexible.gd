@tool
extends Node3D

# Configurable 3D Cellular Automata
# Supports "Generations" type rules: Survive/Born/States/Neighborhood
# Notation example: "6-8/6-8/3/M"

@export_group("Grid Settings")
@export var grid_size: Vector3i = Vector3i(30, 30, 30)
@export var cell_size: float = 0.2
@export var generation_interval: float = 0.1
@export var run_duration: float = 0.0 # 0.0 means infinite
@export var max_generations: int = 0 # 0 means infinite
@export var paused: bool = false
@export var randomize_on_start: bool = false
@export var center_seed_on_start: bool = true
@export var reset: bool = false:
	set(value):
		if value:
			_initialize_grid()
			generation = 0
			paused = false
			reset = false

@export_group("Debug")
@export var current_generation: int = 0:
	get:
		return generation
	set(value):
		pass # Read only

@export_group("Rule Settings")
@export var rule_string: String = "4-5/5/5/M": # Default to a builder-like rule
	set(value):
		rule_string = value
		_parse_rule(value)

@export_group("Visuals")
@export var mesh_instance: MultiMeshInstance3D
@export var color_alive: Color = Color.WHITE
@export var color_dying: Color = Color.DARK_GRAY
@export var use_gradient: bool = false
@export var gradient_mode: int = 0 # 0: None, 1: Height (Y), 2: Generation
@export var gradient: Gradient

@export_group("Determinism")
## Seed for the initial soup. A slime mould network is nothing but accumulated random
## walks, so an unseeded run makes a DIFFERENT organism every boot — which means any
## sweep of this artifact measures its own noise and reports it as a confident result.
## -1 keeps the old behaviour exactly (randomize, a fresh organism each run); any value
## >= 0 pins the soup so two runs are the same mould and a comparison means something.
@export var growth_seed: int = -1

@export_group("Capture")
## Stand an INVISIBLE box (layers = 0, so it renders nothing and casts nothing) around
## the whole grid volume. Every framing walk in this project — capture_multi_angle and
## capture_config_sweep both — sizes the shot from MeshInstance3D nodes only, and this
## artifact is built entirely of ONE MultiMeshInstance3D. With no MeshInstance3D anywhere
## the walk falls back to a 1 m box at the origin and parks the camera about 5 m from a
## corner of a 6 m cube, looking away from the growth. Default false: not one placement
## changes. A capture harness sets it true via dna.fixture.
@export var capture_anchor: bool = false

@export_group("DNA")
## STAGE-2 DNA, hand promotion 2026-08-03, for the `mold_network` token.
##
## The rule string was the whole argument and it was a constant in the .tscn. A slime
## mould is nothing but a law about how much company a filament needs — survive/born
## decides whether the colony commits to thick reinforced tube or pushes thin
## exploratory strand, and the state count decides how much of everywhere-it-has-been
## is still standing. Both were unreachable: `rule_string` is one opaque field and
## apply_grid_config was `pass`, so no map token could say what kind of mould it meant.
##
## `rule` is the family word, taken from complexity_pattern and lifeform_walker, which
## both declare it for exactly this slot: the transition law. The VALUE LIST cannot be
## shared with them — those are 2D Life-family rules over 8 neighbours, this is a 3D
## Generations rule over 26, a different alphabet — so these three artifacts must NOT be
## compared numerically. Same question, different automaton.
##
## STRUCTURE_GROWTH IS NOT PROMOTED, and the gate will tell you it is. Because these axes
## live on a SHARED script, check_dna_declarations lists `structure_growth: rule, wake`
## under "promoted in code, undeclared in the registry". Do not close that line by copying
## this block into its registry entry. StructureGrowth.tscn authors "6-8/6-8/3/M" — the
## Builder rule, three states — and these four bands are the mould's, derived from the
## mould's seed density. Declaring them there would name values that do not describe that
## artifact, which is precisely the failure the declaration gate exists to catch. If
## structure_growth deserves an axis it needs its own bands, derived from its own code.
##
## NOTHING IS WRITTEN AT DEFAULTS. This script is shared: MoldNetwork.tscn authors
## "4-6/5-7/10/M", StructureGrowth.tscn authors "6-8/6-8/3/M", and
## biome_paint_dispatcher hands per-cell `rule=` overrides in before add_child.
## Composing unconditionally would have overwritten all three. The composition runs only
## when an axis is off its default — and for mold_network the default composition is
## "4-6/5-7/10/M", the byte-identical string the scene already carries.
@export_enum("reinforce", "explore", "compact", "strand") var rule: String = "reinforce"
## How much of the exploratory front the mould keeps. A cell that fails survival does not
## vanish: it walks up the dying states, rendering the whole time and refusing rebirth
## until it reaches zero. So the state count is simultaneously the visible mass of spent
## tissue and the refractory period behind the front.
@export_enum("hold", "fade", "none") var wake: String = "hold"

## survive/born bands. The front advances one cell per generation under EVERY rule here —
## birth needs a live neighbour — so what these change is the texture and density of the
## shell, not its radius, which is why the silhouette stays the same size between values
## and the frames stay comparable.
##
## Derived, not guessed. The seed is a 7^3 block at density 0.5, so a dead cell one step
## outside a face sees Binomial(9, 0.5) live neighbours: P(born) is 0.73 for explore,
## 0.48 for reinforce, 0.25 for compact, 0.41 for strand. All four keep the front moving,
## which is the check that none of them photographs as an empty grid.
const RULE_BANDS := {
	"reinforce": "4-6/5-7",  # shipped: survives with modest company, born only where thick
	"explore": "3-6/4-7",    # commits on little evidence — a broad fuzzy web
	"compact": "5-7/6-8",    # commits only where the mould is already thick — a tight mass
	"strand": "2-4/5-6",     # dies wherever it is crowded — wiry isolated filaments
}
const WAKE_STATES := {
	"hold": 10,  # shipped: eight generations of spent tissue still standing
	"fade": 4,
	"none": 2,   # no lingering at all — the object is only what is alive right now
}
const RULE_KEYS: Array[String] = ["reinforce", "explore", "compact", "strand"]
const WAKE_KEYS: Array[String] = ["hold", "fade", "none"]

# Internal state
## True once _ready has built the grid once. apply_grid_config must not rebuild before
## that: the 27 mold_network placements get their config through a call_deferred from
## GridInteractablesComponent, and a rebuild racing the first build is how a shipped
## room changes.
var _dna_built: bool = false
var current_state: PackedByteArray
var next_state: PackedByteArray
var time_accumulator: float = 0.0
var run_timer: float = 0.0
var generation: int = 0
var total_cells: int = 0
var stride_y: int = 0
var stride_z: int = 0

# Parsed rule
var rule_survive: Array[bool] = [] # Index is neighbor count
var rule_born: Array[bool] = []
var rule_states: int = 2
var rule_neighborhood: String = "M"

# Optimization: Precomputed neighbor offsets
var neighbor_offsets: Array[int] = []

func _ready() -> void:
	# DNA axes, before anything reads rule_string. Silent at defaults — see the note on
	# `rule` above: the scenes and the biome dispatcher author their own rule strings and
	# an unconditional compose would overwrite every one of them.
	if rule != "reinforce" or wake != "hold":
		rule_string = _dna_rule_string()

	# robustly find or create mesh instance
	if not mesh_instance:
		for child in get_children():
			if child is MultiMeshInstance3D:
				mesh_instance = child
				break
		
		if not mesh_instance:
			mesh_instance = MultiMeshInstance3D.new()
			mesh_instance.name = "AutomataMesh"
			add_child(mesh_instance)
			
			if Engine.is_editor_hint():
				var root = get_tree().edited_scene_root
				if root:
					mesh_instance.owner = root
	
	# Setup MultiMesh if needed
	if not mesh_instance.multimesh:
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = BoxMesh.new()
		multimesh.mesh.size = Vector3(cell_size, cell_size, cell_size) * 0.9
		mesh_instance.multimesh = multimesh
	
	# Auto-configure gradient based on node name if not set
	if not gradient:
		var n = name.to_lower()
		if "mold" in n:
			gradient = Gradient.new()
			# Overwrite the 2 default points instead of remove+add
			gradient.set_offset(0, 0.0)
			gradient.set_color(0, Color("2e7d32"))   # Dark Green
			gradient.set_offset(1, 1.0)
			gradient.set_color(1, Color("aed581"))   # Light Green
			gradient.add_point(0.5, Color("4db6ac")) # Teal
			use_gradient = true
			gradient_mode = 1 # Height
		elif "structure" in n:
			gradient = Gradient.new()
			# Overwrite the 2 default points instead of remove+add
			gradient.set_offset(0, 0.0)
			gradient.set_color(0, Color("455a64"))   # Blue Grey Dark
			gradient.set_offset(1, 1.0)
			gradient.set_color(1, Color("eceff1"))   # White-ish
			gradient.add_point(0.5, Color("90a4ae")) # Blue Grey Light
			use_gradient = true
			gradient_mode = 1 # Height

	# Ensure material supports vertex colors
	if mesh_instance.multimesh and mesh_instance.multimesh.mesh:
		var mesh = mesh_instance.multimesh.mesh
		if not mesh.material:
			var mat = StandardMaterial3D.new()
			mat.vertex_color_use_as_albedo = true
			mesh.material = mat
		elif mesh.material is StandardMaterial3D:
			mesh.material.vertex_color_use_as_albedo = true

	_calculate_strides()
	_precompute_neighbor_offsets()
	_parse_rule(rule_string)
	_initialize_grid()
	_update_visuals()
	# Appended last, builds nothing unless asked: see the capture_anchor note above.
	if capture_anchor:
		_add_capture_anchor()
	_dna_built = true

func _calculate_strides() -> void:
	stride_y = grid_size.x
	stride_z = grid_size.x * grid_size.y
	total_cells = grid_size.x * grid_size.y * grid_size.z

func _precompute_neighbor_offsets() -> void:
	neighbor_offsets.clear()
	for z in range(-1, 2):
		for y in range(-1, 2):
			for x in range(-1, 2):
				if x == 0 and y == 0 and z == 0:
					continue
				var offset = x + (y * stride_y) + (z * stride_z)
				neighbor_offsets.append(offset)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if paused:
		return
	
	if run_duration > 0.0:
		run_timer += delta
		if run_timer >= run_duration:
			paused = true
			return
	
	if max_generations > 0 and generation >= max_generations:
		paused = true
		return
		
	time_accumulator += delta
	if time_accumulator >= generation_interval:
		time_accumulator = 0.0
		_step()

## `spec`, not `rule`: `rule` is now a member (the DNA axis) and a parameter of that name
## would shadow it.
func _parse_rule(spec: String) -> void:
	var parts = spec.split("/")
	if parts.size() < 2:
		push_error("Invalid rule format. Expected S/B/C/N or S/B")
		return
	
	rule_survive = []
	rule_born = []
	rule_survive.resize(27)
	rule_born.resize(27)
	rule_survive.fill(false)
	rule_born.fill(false)
	
	_parse_range_string(parts[0], rule_survive)
	_parse_range_string(parts[1], rule_born)
	
	if parts.size() > 2:
		rule_states = int(parts[2])
	else:
		rule_states = 2
		
	if parts.size() > 3:
		rule_neighborhood = parts[3]
	else:
		rule_neighborhood = "M"

func _parse_range_string(s: String, target_array: Array[bool]) -> void:
	var groups = s.split(",")
	for group in groups:
		if "-" in group:
			var range_parts = group.split("-")
			var start = int(range_parts[0])
			var end = int(range_parts[1])
			for i in range(start, end + 1):
				if i < target_array.size():
					target_array[i] = true
		else:
			var val = int(group)
			if val < target_array.size():
				target_array[val] = true

func _initialize_grid() -> void:
	# One generator for the whole soup, so growth_seed pins every draw below. -1
	# randomizes exactly as the bare randf() calls used to.
	var rng := RandomNumberGenerator.new()
	if growth_seed >= 0:
		rng.seed = growth_seed
	else:
		rng.randomize()
	_calculate_strides()
	current_state.resize(total_cells)
	next_state.resize(total_cells)
	current_state.fill(0)
	next_state.fill(0)
	
	if center_seed_on_start:
		var cx = grid_size.x / 2
		var cy = grid_size.y / 2
		var cz = grid_size.z / 2
		var range_ext = 3
		
		for z in range(cz - range_ext, cz + range_ext + 1):
			for y in range(cy - range_ext, cy + range_ext + 1):
				for x in range(cx - range_ext, cx + range_ext + 1):
					if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y and z >= 0 and z < grid_size.z:
						if rng.randf() > 0.5:
							var idx = x + (y * stride_y) + (z * stride_z)
							current_state[idx] = 1
	
	if randomize_on_start:
		for i in range(total_cells):
			if rng.randf() < 0.1:
				current_state[i] = 1

	# Setup MultiMesh capacity
	mesh_instance.multimesh.instance_count = total_cells
	mesh_instance.multimesh.visible_instance_count = 0

func _step() -> void:
	# Optimized step using 1D array and precomputed offsets
	# We avoid boundary checks in the inner loop by iterating only the safe inner volume
	# and handling boundaries separately (or just ignoring them for speed, treating as dead)
	
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	# Safe bounds to avoid boundary checks in the hot loop
	for z in range(1, sz - 1):
		var z_offset = z * stride_z
		for y in range(1, sy - 1):
			var y_offset = y * stride_y
			for x in range(1, sx - 1):
				var idx = x + y_offset + z_offset
				var state = current_state[idx]
				
				# Count neighbors
				var neighbors = 0
				for offset in neighbor_offsets:
					if current_state[idx + offset] == 1:
						neighbors += 1
				
				# Apply Rules
				if state == 0:
					if rule_born[neighbors]:
						next_state[idx] = 1
					else:
						next_state[idx] = 0
				elif state == 1:
					if rule_survive[neighbors]:
						next_state[idx] = 1
					else:
						if rule_states > 2:
							next_state[idx] = 2
						else:
							next_state[idx] = 0
				else:
					if state < rule_states - 1:
						next_state[idx] = state + 1
					else:
						next_state[idx] = 0
	
	# Swap buffers
	var temp = current_state
	current_state = next_state
	next_state = temp
	
	generation += 1
	_update_visuals()

func _update_visuals() -> void:
	var mm = mesh_instance.multimesh
	var active_count = 0
	
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	# Optimization: Skip the outer boundary layer (always dead)
	# This matches the logic in _step() and saves iterations
	for z in range(1, sz - 1):
		var z_offset = z * stride_z
		for y in range(1, sy - 1):
			var y_offset = y * stride_y
			for x in range(1, sx - 1):
				var idx = x + y_offset + z_offset
				var state = current_state[idx]
				
				if state > 0:
					# Optimization: Occlusion Culling (Shell Rendering)
					# Only render if at least one neighbor is empty (or transparent)
					# This drastically reduces instance count for dense structures
					var is_visible = false
					
					# Check 6 direct neighbors
					# We can use the precomputed offsets, but we need to be careful about the 26 vs 6 neighbors
					# Let's just check the 6 cardinal neighbors manually for speed and correctness of "shell"
					
					# x+1
					if current_state[idx + 1] == 0: is_visible = true
					# x-1
					elif current_state[idx - 1] == 0: is_visible = true
					# y+1
					elif current_state[idx + stride_y] == 0: is_visible = true
					# y-1
					elif current_state[idx - stride_y] == 0: is_visible = true
					# z+1
					elif current_state[idx + stride_z] == 0: is_visible = true
					# z-1
					elif current_state[idx - stride_z] == 0: is_visible = true
					
					if is_visible:
						var t = Transform3D()
						t.origin = Vector3(x, y, z) * cell_size
						
						var color = color_alive
						
						if use_gradient and gradient:
							var t_grad = 0.0
							if gradient_mode == 1: # Height (Y)
								t_grad = float(y) / float(sy)
							elif gradient_mode == 2: # Generation (approximate or just Z?)
								t_grad = float(y) / float(sy)
							
							color = gradient.sample(t_grad)
						elif state > 1:
							var t_life = float(state - 1) / float(rule_states - 2) if rule_states > 2 else 0.0
							color = color_alive.lerp(color_dying, t_life)
						
						mm.set_instance_transform(active_count, t)
						mm.set_instance_color(active_count, color)
						active_count += 1
	
	mm.visible_instance_count = active_count

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## The two DNA axes, reachable from a map token. Everything else stays as it was: this
## used to be `pass`, so no key any map passed did anything, and no shipped placement is
## sending `rule` or `wake` today.
##
## Guarded twice over. A value only counts if it is one the code can actually build
## (_pick_axis falls back to the current value, never to an invalid string), and the
## regrow only happens when a value CHANGED and the first build has already finished —
## GridInteractablesComponent calls this deferred, so an unguarded rebuild here would
## restart the automaton in all 27 existing rooms.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("rule"):
		var r: String = _pick_axis(String(config["rule"]), RULE_KEYS, rule)
		if r != rule:
			rule = r
			changed = true
	if config.has("wake"):
		var w: String = _pick_axis(String(config["wake"]), WAKE_KEYS, wake)
		if w != wake:
			wake = w
			changed = true
	if not changed or not _dna_built:
		return
	rule_string = _dna_rule_string()   # the setter re-parses
	generation = 0
	time_accumulator = 0.0
	run_timer = 0.0
	paused = false
	_initialize_grid()
	_update_visuals()


func _dna_rule_string() -> String:
	var bands: String = String(RULE_BANDS.get(rule, RULE_BANDS["reinforce"]))
	var states: int = int(WAKE_STATES.get(wake, WAKE_STATES["hold"]))
	# Moore is the only neighbourhood this file implements — _precompute_neighbor_offsets
	# always builds the 26 offsets and _step never reads rule_neighborhood — so writing
	# anything else in the fourth slot would be a claim the code does not honour.
	return "%s/%d/M" % [bands, states]


## An unrecognised value keeps the current one rather than silently becoming an invalid
## rule string. That matters here: `_parse_rule` on nonsense pushes an error and leaves
## the previous bands in place, which would look like a working axis producing identical
## frames — the exact failure the declaration gate exists to catch.
func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


## An invisible box the size of the simulated volume, so a framing walk that only knows
## how to measure MeshInstance3D can still find out how big this thing is.
##
## layers = 0 and NOT visible = false: Godot visibility is hierarchical, so hiding a node
## hides everything under it, while the render layer mask is per-instance and leaves the
## mesh, the material and the bounds exactly where they are — which is the whole point,
## because the bounds are what the camera is being told about.
func _add_capture_anchor() -> void:
	var span: Vector3 = Vector3(grid_size) * cell_size
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = span
	anchor.mesh = bm
	# Cells are placed at Vector3(x, y, z) * cell_size from the node origin, so the
	# volume runs 0 .. span and its centre is half a span out on every axis.
	anchor.position = span * 0.5
	anchor.layers = 0
	add_child(anchor)
	if Engine.is_editor_hint():
		var root = get_tree().edited_scene_root
		if root:
			anchor.owner = root
