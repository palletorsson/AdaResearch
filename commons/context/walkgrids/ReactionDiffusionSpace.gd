# ReactionDiffusionSpace.gd - Turing patterns as walkable terrain
# Gray-Scott model: two chemical species whose interaction creates
# spots, stripes, spirals — the mathematics of animal coats,
# coral growth, and self-organization from homogeneity.
#
# "Order from nothing. Pattern from uniformity. Life from chemistry."

extends TopologySpace
class_name ReactionDiffusionSpace

@export var feed_rate: float = 0.055       # F — how fast chemical A is supplied
@export var kill_rate: float = 0.062       # k — how fast chemical B decays
@export var diffusion_a: float = 1.0       # How fast A spreads
@export var diffusion_b: float = 0.5       # How fast B spreads (slower = patterns)
@export var sim_resolution: int = 64        # Simulation grid size (independent of mesh resolution)
@export var iterations: int = 2000         # Simulation steps
@export var dt: float = 1.0                # Time step
@export var seed_count: int = 5            # Initial disturbance seeds
@export var seed_radius: int = 3           # Size of initial seeds
@export var seed_value: int = 42

# Presets for different pattern types
@export var pattern_preset: PatternPreset = PatternPreset.SPOTS

enum PatternPreset {
	SPOTS,         # F=0.055, k=0.062 — mitosis-like spots
	STRIPES,       # F=0.035, k=0.065 — zebrafish stripes
	SPIRALS,       # F=0.014, k=0.054 — rotating spirals
	CORAL,         # F=0.060, k=0.062 — branching coral
	HOLES,         # F=0.039, k=0.058 — soliton holes
	WORMS,         # F=0.078, k=0.061 — wormy patterns
	CUSTOM         # Use manual F/k values
}

# Animation
@export var enable_animation: bool = false
@export var animation_speed: float = 0.5
@export var continue_simulation: bool = false  # Keep evolving after initial gen

var grid_a: Array = []  # Chemical A concentration
var grid_b: Array = []  # Chemical B concentration
var grid_size: int = 0
var rng: RandomNumberGenerator
var animation_time: float = 0.0
var base_heights: Array = []

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_apply_preset()
	super._ready()

func _apply_preset():
	match pattern_preset:
		PatternPreset.SPOTS:
			feed_rate = 0.055; kill_rate = 0.062
		PatternPreset.STRIPES:
			feed_rate = 0.035; kill_rate = 0.065
		PatternPreset.SPIRALS:
			feed_rate = 0.014; kill_rate = 0.054
		PatternPreset.CORAL:
			feed_rate = 0.060; kill_rate = 0.062
		PatternPreset.HOLES:
			feed_rate = 0.039; kill_rate = 0.058
		PatternPreset.WORMS:
			feed_rate = 0.078; kill_rate = 0.061
		PatternPreset.CUSTOM:
			pass  # Use exported values

func generate_space():
	grid_size = sim_resolution
	_initialize_grid()
	_seed_disturbances()
	_run_simulation()
	_build_mesh()

func _initialize_grid():
	grid_a.clear()
	grid_b.clear()
	var total = grid_size * grid_size
	grid_a.resize(total)
	grid_b.resize(total)
	for i in range(total):
		grid_a[i] = 1.0  # Uniform A
		grid_b[i] = 0.0  # No B

func _seed_disturbances():
	"""Drop seeds of chemical B to start pattern formation"""
	for _s in range(seed_count):
		var cx = rng.randi_range(seed_radius + 2, grid_size - seed_radius - 2)
		var cz = rng.randi_range(seed_radius + 2, grid_size - seed_radius - 2)
		for dz in range(-seed_radius, seed_radius + 1):
			for dx in range(-seed_radius, seed_radius + 1):
				var idx = (cz + dz) * grid_size + (cx + dx)
				if idx >= 0 and idx < grid_a.size():
					grid_b[idx] = 1.0

func _run_simulation():
	"""Run Gray-Scott reaction-diffusion"""
	var new_a = grid_a.duplicate()
	var new_b = grid_b.duplicate()

	for _step in range(iterations):
		for z in range(1, grid_size - 1):
			for x in range(1, grid_size - 1):
				var idx = z * grid_size + x
				var a = grid_a[idx]
				var b = grid_b[idx]

				# Laplacian (5-point stencil)
				var lap_a = (
					grid_a[idx - 1] + grid_a[idx + 1] +
					grid_a[idx - grid_size] + grid_a[idx + grid_size] -
					4.0 * a
				)
				var lap_b = (
					grid_b[idx - 1] + grid_b[idx + 1] +
					grid_b[idx - grid_size] + grid_b[idx + grid_size] -
					4.0 * b
				)

				var abb = a * b * b
				new_a[idx] = a + (diffusion_a * lap_a - abb + feed_rate * (1.0 - a)) * dt
				new_b[idx] = b + (diffusion_b * lap_b + abb - (kill_rate + feed_rate) * b) * dt

				new_a[idx] = clampf(new_a[idx], 0.0, 1.0)
				new_b[idx] = clampf(new_b[idx], 0.0, 1.0)

		# Swap buffers
		var tmp_a = grid_a
		var tmp_b = grid_b
		grid_a = new_a
		grid_b = new_b
		new_a = tmp_a
		new_b = tmp_b

func _build_mesh():
	"""Convert chemical B concentration to walkable terrain, upsampling from sim grid"""
	var gs = resolution + 1
	var heights: Array = []
	
	for z in range(gs):
		for x in range(gs):
			# Bilinear sample from simulation grid
			var sx = (x / float(resolution)) * float(grid_size - 1)
			var sz = (z / float(resolution)) * float(grid_size - 1)
			var ix = int(sx)
			var iz = int(sz)
			var fx = sx - ix
			var fz = sz - iz
			
			var ix1 = mini(ix + 1, grid_size - 1)
			var iz1 = mini(iz + 1, grid_size - 1)
			
			var v00 = grid_b[iz * grid_size + ix]
			var v10 = grid_b[iz * grid_size + ix1]
			var v01 = grid_b[iz1 * grid_size + ix]
			var v11 = grid_b[iz1 * grid_size + ix1]
			
			var h = lerpf(lerpf(v00, v10, fx), lerpf(v01, v11, fx), fz)
			heights.append(h * height_scale)

	base_heights = heights.duplicate()

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.85, 0.7)  # Warm organic
	material.roughness = 0.75
	material.metallic = 0.1
	material.emission_enabled = true
	material.emission = Color(0.4, 0.25, 0.15) * 0.3
	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return
	if continue_simulation:
		# Run a few more simulation steps per frame
		_run_simulation_steps(5)
		_build_mesh()
	else:
		animation_time += delta * animation_speed
		_update_animated_mesh()

func _run_simulation_steps(steps: int):
	"""Run a few more RD steps for live evolution"""
	var new_a = grid_a.duplicate()
	var new_b = grid_b.duplicate()
	for _step in range(steps):
		for z in range(1, grid_size - 1):
			for x in range(1, grid_size - 1):
				var idx = z * grid_size + x
				var a = grid_a[idx]
				var b = grid_b[idx]
				var lap_a = grid_a[idx-1] + grid_a[idx+1] + grid_a[idx-grid_size] + grid_a[idx+grid_size] - 4.0*a
				var lap_b = grid_b[idx-1] + grid_b[idx+1] + grid_b[idx-grid_size] + grid_b[idx+grid_size] - 4.0*b
				var abb = a * b * b
				new_a[idx] = clampf(a + (diffusion_a*lap_a - abb + feed_rate*(1.0-a))*dt, 0.0, 1.0)
				new_b[idx] = clampf(b + (diffusion_b*lap_b + abb - (kill_rate+feed_rate)*b)*dt, 0.0, 1.0)
		var ta = grid_a; var tb = grid_b
		grid_a = new_a; grid_b = new_b
		new_a = ta; new_b = tb

func _update_animated_mesh():
	if base_heights.is_empty():
		return
	var gs = resolution + 1
	var animated = []
	for i in range(base_heights.size()):
		var x = i % gs
		var z = i / gs
		var wave = sin(animation_time + x * 0.08 + z * 0.08) * 0.15
		animated.append(base_heights[i] + wave)
	mesh_instance.mesh = create_mesh_from_heights(animated)

# Public API
func set_preset(preset: PatternPreset):
	pattern_preset = preset
	_apply_preset()
	generate_space()

func regenerate():
	rng.seed = randi()
	generate_space()
