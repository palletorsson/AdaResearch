@tool
extends Node3D
class_name LivingPaperManager

## Universal living paper substrate.
## Holds a PaperAlgorithm cartridge that draws on a 2D texture.
## Grab the paper → algorithm steps. Drop it → algorithm pauses.
## The paper accumulates its history visually.

## --- Configuration ---

@export var width: int = 128
@export var height: int = 128
@export var interval: float = 0.08
@export var label_text: String = ""

## Algorithm selection
enum Algorithm {
	RANDOM_WALK_SIMPLE, RANDOM_WALK_BROWNIAN, RANDOM_WALK_LEVY,
	RANDOM_WALK_SELF_AVOIDING, RANDOM_WALK_FRACTAL, RANDOM_WALK_FIBONACCI,
	CA_1D_RULE30, CA_1D_RULE110, CA_1D_RULE90,
	CA_2D_LIFE, CA_2D_SEEDS, CA_2D_BRIANS_BRAIN,
	SORTING_BUBBLE, SORTING_INSERTION, SORTING_MERGE, SORTING_QUICK,
	SINE_WAVE, FOURIER_SERIES, LISSAJOUS,
	MANDELBROT, JULIA_SET, SIERPINSKI, KOCH_CURVE,
	LSYSTEM_TREE, LSYSTEM_FERN, LSYSTEM_DRAGON,
	PERLIN_NOISE, NOISE_OCTAVES,
	BFS_FLOOD, DFS_MAZE,
	REACTION_DIFFUSION, DLA_CRYSTAL,
	VORONOI, KMEANS,
	HEAT_DIFFUSION, QUADTREE
}

@export var algorithm: Algorithm = Algorithm.RANDOM_WALK_SIMPLE:
	set(v):
		algorithm = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_setup_algorithm()

## Override colors (leave black to use algorithm defaults)
@export var override_background: Color = Color.BLACK
@export var override_primary: Color = Color.BLACK

## --- Internal ---

var _algorithm: PaperAlgorithm
var _img: Image
var _texture: ImageTexture
var _is_walking: bool = false
var _time_since_last_step: float = 0.0
var _step_index: int = 0

@onready var mesh_instance: MeshInstance3D = $GrabPaper/RandomWalkPlanMesh
@onready var label3d: Label3D = $GrabPaper/id_info_Label3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Robust node lookup — @onready may fail for nodes inside instanced scenes
	if not mesh_instance:
		mesh_instance = find_child("RandomWalkPlanMesh", true, false) as MeshInstance3D
	if not label3d:
		label3d = find_child("id_info_Label3D", true, false) as Label3D

	if not mesh_instance:
		push_error("LivingPaper: RandomWalkPlanMesh not found! Children: %s" % str(_get_child_names()))
	else:
		print("LivingPaper: Found mesh at %s" % mesh_instance.get_path())

	# Auto-detect algorithm from artifact lookup_name (e.g. living_paper_rule30 → rule30)
	_resolve_algorithm_from_lookup_name()
	await get_tree().create_timer(0.5).timeout
	_setup_algorithm()


func _get_child_names() -> Array:
	var names: Array = []
	for child in get_children():
		names.append(child.name)
		for grandchild in child.get_children():
			names.append("%s/%s" % [child.name, grandchild.name])
	return names


## Map artifact lookup_name suffix to algorithm enum
func _resolve_algorithm_from_lookup_name() -> void:
	var lookup = get_meta("artifact_lookup_name", "")
	if lookup == "" or lookup == "living_paper":
		return  # No suffix → use default or grid config

	# Strip "living_paper_" prefix to get the algorithm key
	var key = lookup.replace("living_paper_", "")
	var algo_map = {
		"random_walk": Algorithm.RANDOM_WALK_SIMPLE,
		"brownian": Algorithm.RANDOM_WALK_BROWNIAN,
		"levy": Algorithm.RANDOM_WALK_LEVY,
		"self_avoiding": Algorithm.RANDOM_WALK_SELF_AVOIDING,
		"fractal": Algorithm.RANDOM_WALK_FRACTAL,
		"fibonacci": Algorithm.RANDOM_WALK_FIBONACCI,
		"rule30": Algorithm.CA_1D_RULE30,
		"rule110": Algorithm.CA_1D_RULE110,
		"rule90": Algorithm.CA_1D_RULE90,
		"life": Algorithm.CA_2D_LIFE,
		"seeds": Algorithm.CA_2D_SEEDS,
		"brians_brain": Algorithm.CA_2D_BRIANS_BRAIN,
		"bubble_sort": Algorithm.SORTING_BUBBLE,
		"insertion_sort": Algorithm.SORTING_INSERTION,
		"merge_sort": Algorithm.SORTING_MERGE,
		"quick_sort": Algorithm.SORTING_QUICK,
		"sine": Algorithm.SINE_WAVE,
		"fourier": Algorithm.FOURIER_SERIES,
		"lissajous": Algorithm.LISSAJOUS,
		"mandelbrot": Algorithm.MANDELBROT,
		"julia": Algorithm.JULIA_SET,
		"sierpinski": Algorithm.SIERPINSKI,
		"koch": Algorithm.KOCH_CURVE,
		"tree": Algorithm.LSYSTEM_TREE,
		"fern": Algorithm.LSYSTEM_FERN,
		"dragon": Algorithm.LSYSTEM_DRAGON,
		"perlin": Algorithm.PERLIN_NOISE,
		"noise_octaves": Algorithm.NOISE_OCTAVES,
		"bfs": Algorithm.BFS_FLOOD,
		"dfs_maze": Algorithm.DFS_MAZE,
		"reaction_diffusion": Algorithm.REACTION_DIFFUSION,
		"dla": Algorithm.DLA_CRYSTAL,
		"voronoi": Algorithm.VORONOI,
		"kmeans": Algorithm.KMEANS,
		"heat": Algorithm.HEAT_DIFFUSION,
		"quadtree": Algorithm.QUADTREE,
	}
	if key in algo_map:
		algorithm = algo_map[key]
		print("LivingPaper: Auto-selected algorithm '%s' from lookup_name '%s'" % [key, lookup])


func _setup_algorithm() -> void:
	_algorithm = _create_algorithm(algorithm)
	_step_index = 0

	var bg = override_background if override_background != Color.BLACK else _algorithm.get_background_color()
	_img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	_img.fill(bg)

	_algorithm.initialize(_img, width, height)

	# Pre-draw some steps so the paper isn't blank
	var initial = _algorithm.get_initial_steps()
	for i in range(initial):
		_algorithm.step(_img, _step_index)
		_step_index += 1

	_texture = ImageTexture.create_from_image(_img)

	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = _texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.emission_enabled = true
		mat.emission_texture = _texture
		mat.emission_energy_multiplier = 0.3
		mesh_instance.material_override = mat

	if label3d:
		var display_name = label_text if label_text != "" else _algorithm.get_name()
		label3d.text = display_name


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_walking or not _algorithm:
		return

	_time_since_last_step += delta
	if _time_since_last_step >= interval:
		var still_running = _algorithm.step(_img, _step_index)
		_step_index += 1
		_texture.set_image(_img)
		_time_since_last_step = 0.0

		if not still_running:
			_is_walking = false


func _on_grab_paper_grabbed(_pickable: Variant, _by: Variant) -> void:
	_is_walking = true
	_time_since_last_step = 0.0


func _on_grab_paper_dropped(_pickable: Variant) -> void:
	_is_walking = false


## --- Algorithm factory ---

func _create_algorithm(algo: Algorithm) -> PaperAlgorithm:
	match algo:
		# Random walks
		Algorithm.RANDOM_WALK_SIMPLE:
			return _make_walk(PaperRandomWalk.WalkMode.SIMPLE)
		Algorithm.RANDOM_WALK_BROWNIAN:
			return _make_walk(PaperRandomWalk.WalkMode.BROWNIAN)
		Algorithm.RANDOM_WALK_LEVY:
			return _make_walk(PaperRandomWalk.WalkMode.LEVY_FLIGHT)
		Algorithm.RANDOM_WALK_SELF_AVOIDING:
			return _make_walk(PaperRandomWalk.WalkMode.SELF_AVOIDING)
		Algorithm.RANDOM_WALK_FRACTAL:
			return _make_walk(PaperRandomWalk.WalkMode.FRACTAL)
		Algorithm.RANDOM_WALK_FIBONACCI:
			return _make_walk(PaperRandomWalk.WalkMode.FIBONACCI_SPIRAL)
		# CA 1D
		Algorithm.CA_1D_RULE30:
			return PaperCA1D.new(30)
		Algorithm.CA_1D_RULE110:
			return PaperCA1D.new(110)
		Algorithm.CA_1D_RULE90:
			return PaperCA1D.new(90)
		# CA 2D
		Algorithm.CA_2D_LIFE:
			return PaperCA2D.new(PaperCA2D.Ruleset.LIFE)
		Algorithm.CA_2D_SEEDS:
			return PaperCA2D.new(PaperCA2D.Ruleset.SEEDS)
		Algorithm.CA_2D_BRIANS_BRAIN:
			return PaperCA2D.new(PaperCA2D.Ruleset.BRIANS_BRAIN)
		# Sorting
		Algorithm.SORTING_BUBBLE:
			return PaperSorting.new(PaperSorting.SortMode.BUBBLE)
		Algorithm.SORTING_INSERTION:
			return PaperSorting.new(PaperSorting.SortMode.INSERTION)
		Algorithm.SORTING_MERGE:
			return PaperSorting.new(PaperSorting.SortMode.MERGE)
		Algorithm.SORTING_QUICK:
			return PaperSorting.new(PaperSorting.SortMode.QUICK)
		# Waves
		Algorithm.SINE_WAVE:
			return PaperSineWave.new()
		Algorithm.FOURIER_SERIES:
			return PaperFourier.new()
		Algorithm.LISSAJOUS:
			return PaperLissajous.new()
		# Fractals
		Algorithm.MANDELBROT:
			return PaperMandelbrot.new()
		Algorithm.JULIA_SET:
			return PaperJuliaSet.new()
		Algorithm.SIERPINSKI:
			return PaperSierpinski.new()
		Algorithm.KOCH_CURVE:
			return PaperKochCurve.new()
		# L-systems
		Algorithm.LSYSTEM_TREE:
			return PaperLSystem.new(PaperLSystem.Preset.TREE)
		Algorithm.LSYSTEM_FERN:
			return PaperLSystem.new(PaperLSystem.Preset.FERN)
		Algorithm.LSYSTEM_DRAGON:
			return PaperLSystem.new(PaperLSystem.Preset.DRAGON)
		# Noise
		Algorithm.PERLIN_NOISE:
			return PaperPerlinNoise.new()
		Algorithm.NOISE_OCTAVES:
			return PaperNoiseOctaves.new()
		# Search
		Algorithm.BFS_FLOOD:
			return PaperBFS.new()
		Algorithm.DFS_MAZE:
			return PaperDFSMaze.new()
		# Pattern generation
		Algorithm.REACTION_DIFFUSION:
			return PaperReactionDiffusion.new()
		Algorithm.DLA_CRYSTAL:
			return PaperDLA.new()
		# Computational geometry
		Algorithm.VORONOI:
			return PaperVoronoi.new()
		# ML
		Algorithm.KMEANS:
			return PaperKMeans.new()
		# Physics
		Algorithm.HEAT_DIFFUSION:
			return PaperHeatDiffusion.new()
		# Data structures
		Algorithm.QUADTREE:
			return PaperQuadtree.new()

	# Fallback
	return PaperRandomWalk.new()


func _make_walk(mode: PaperRandomWalk.WalkMode) -> PaperRandomWalk:
	var walk = PaperRandomWalk.new()
	walk.walk_mode = mode
	return walk


## --- Config from grid system ---

func apply_grid_config(config: Dictionary) -> void:
	if config.has("algorithm"):
		var algo_name = str(config["algorithm"]).to_lower()
		var algo_map = {
			"random_walk": Algorithm.RANDOM_WALK_SIMPLE,
			"brownian": Algorithm.RANDOM_WALK_BROWNIAN,
			"levy": Algorithm.RANDOM_WALK_LEVY,
			"self_avoiding": Algorithm.RANDOM_WALK_SELF_AVOIDING,
			"rule30": Algorithm.CA_1D_RULE30,
			"rule110": Algorithm.CA_1D_RULE110,
			"life": Algorithm.CA_2D_LIFE,
			"seeds": Algorithm.CA_2D_SEEDS,
			"brians_brain": Algorithm.CA_2D_BRIANS_BRAIN,
			"bubble_sort": Algorithm.SORTING_BUBBLE,
			"insertion_sort": Algorithm.SORTING_INSERTION,
			"merge_sort": Algorithm.SORTING_MERGE,
			"quick_sort": Algorithm.SORTING_QUICK,
			"sine": Algorithm.SINE_WAVE,
			"fourier": Algorithm.FOURIER_SERIES,
			"lissajous": Algorithm.LISSAJOUS,
			"mandelbrot": Algorithm.MANDELBROT,
			"julia": Algorithm.JULIA_SET,
			"sierpinski": Algorithm.SIERPINSKI,
			"koch": Algorithm.KOCH_CURVE,
			"tree": Algorithm.LSYSTEM_TREE,
			"fern": Algorithm.LSYSTEM_FERN,
			"dragon": Algorithm.LSYSTEM_DRAGON,
			"perlin": Algorithm.PERLIN_NOISE,
			"noise_octaves": Algorithm.NOISE_OCTAVES,
			"bfs": Algorithm.BFS_FLOOD,
			"dfs_maze": Algorithm.DFS_MAZE,
			"reaction_diffusion": Algorithm.REACTION_DIFFUSION,
			"dla": Algorithm.DLA_CRYSTAL,
			"voronoi": Algorithm.VORONOI,
			"kmeans": Algorithm.KMEANS,
			"heat": Algorithm.HEAT_DIFFUSION,
			"quadtree": Algorithm.QUADTREE,
		}
		if algo_name in algo_map:
			algorithm = algo_map[algo_name]
	if config.has("interval"):
		interval = float(config["interval"])
	if config.has("width"):
		width = int(config["width"])
	if config.has("height"):
		height = int(config["height"])
