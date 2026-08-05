# @identity
# essence: height(x,z) = one independent draw per vertex — a walkable surface whose ground is white noise, no two neighbours agreeing about anything
# desire: feel the floor breathe; walk a terrain whose elevation is renegotiated every frame
# critical_parameter: law — which distribution the ground is drawn from (uniform | gaussian | poisson | exponential); chaos_level amplifies how far the surface deviates from flat
# triggers: each animation tick re-samples heights according to AnimationType (WAVE/RIPPLE/RANDOM_WALK/CHAOTIC)
# emerges: a VR-walkable random landscape that updates collision at collision_update_interval to keep frame rate
# needs: chaos slider [has]; animation type picker [has]; seed reseed button [missing]
# relationships: subclass of TopologySpace; sibling of SineSpace (deterministic) and NoiseSpace (correlated) among the walkgrid topologies; shares the `law` word with distribution_sampler and force_field_visualizer, which ask the same question of a histogram and of a field
# truth: A floor is a contract; a chaotic floor is a question. Walking it is research — randomness underfoot teaches what stability means.

# RandomSpace.gd - Animated chaos optimized for VR
extends TopologySpace
class_name RandomSpace

## STAGE-2 DNA PROMOTION (2026-08-05). This artifact is the randomness sequence's
## floor: the one substrate whose vertices are INDEPENDENT, against NoiseSpace's
## correlated fractal field next door. It shipped knowing exactly one meaning of
## the word — `rng.randf_range(-chaos_level, chaos_level)`, one hard-coded uniform
## draw per vertex — and none of its eighteen exports was reachable from a map
## token, because TopologySpace has no apply_grid_config and this file had none
## either. The runner refused it as NO TURNABLE KNOBS on that ground.
##
##   law   which distribution the ground is drawn from
##         uniform · gaussian · poisson · exponential
##
## The word and its four values are taken CHARACTER FOR CHARACTER from
## distribution_sampler, which asks the same question of a histogram and whose own
## header says why the word is not a metaphor: in probability the LAW of a random
## variable is literally its distribution. force_field_visualizer uses the same
## word for a field. The default differs from distribution_sampler's — theirs is
## gaussian, ours is uniform — because each artifact's default is its own shipped
## behaviour, not the group's opinion.
##
## THE FOUR LAWS ARE MONOTONE TRANSFORMS OF THE SAME DRAW, which is the property
## that makes them comparable rather than merely different. Every law consumes one
## number per vertex from the same seeded stream, so vertex i receives the same u
## under all four; each law is a non-decreasing function of u, so a vertex that is
## a peak stays a peak. The four surfaces share their layout exactly and differ
## only in how amplitude is distributed over it. Four fields drawn from four
## streams would also have "differed", and the difference would have been the
## streams.
##
##   uniform      flat: every height equally likely, no preferred level. The
##                shipped ground, and maximally rough — the sandpaper floor.
##   gaussian     bell: two thirds of the surface inside a third of the range,
##                with rare deep pits and high spikes. Mostly gentle, punctuated.
##   poisson      counts: five discrete levels at lambda 1.5, so the floor
##                terraces. Randomness that lands on integers, which is what
##                randomness looks like whenever it is counting something.
##   exponential  one-sided: a plain at the floor with about one vertex in twenty
##                at the ceiling. The only asymmetric law of the four — the
##                ground acquires a base level and towers, and the base level is
##                not the middle of the range.
##
## DECLINED, and recorded so the next agent does not reopen them:
##   animation_type (WAVE/RIPPLE/RANDOM_WALK/CHAOTIC) is the obvious enum and it
##   is declined twice over. It is time-domain — a still catches one arbitrary
##   phase — and it is dead in every placement anyway, because the .tscn sets
##   enable_animation = false, so promoting it would mean turning the animation on
##   and changing what all three existing rooms do.
##   chaos_level and height_scale change how MUCH relief there is, not what the
##   relief claims, which is the same reason rhizomatic_maze_space declined its
##   six growth floats. surface_color / emission_tint are "which colour", which is
##   never an argument.
##   `generator` is deliberately NOT taken from noise_space: that word names which
##   correlated basis fills a field, and this artifact's whole position in the
##   sequence is that its vertices are not correlated at all. Taking it would
##   claim the two floors are the same kind of object.
##
## Usage in map_data.json:
##   "random_space#law:exponential"

## THE AXIS — which distribution the ground is drawn from. "uniform" is the
## shipped default and short-circuits to the original expression; see _draw().
@export_enum("uniform", "gaussian", "poisson", "exponential") var law: String = "uniform"

## The allow-list, same spelling and same order as the @export_enum above and as
## distribution_sampler's LAW_TYPES.
const LAWS: PackedStringArray = ["uniform", "gaussian", "poisson", "exponential"]

## poisson's rate, and the cap that turns an unbounded count into five levels.
## 1.5 puts 22%/34%/25%/13% of the surface on the first four terraces and 7% on
## the fifth, so every level is populated and none of them dominates.
const POISSON_LAMBDA: float = 1.5
const POISSON_CAP: int = 4

## exponential's rate, in units of the half-range. At 3.0 the median vertex sits
## at 0.23 of the range above the floor and exp(-3) = 5% of vertices saturate at
## the ceiling: a plain with towers.
const EXPONENTIAL_RATE: float = 3.0

## True once _ready has built the surface. apply_grid_config must not regenerate
## before it — config can arrive before _ready, because the grid stamps it on the
## node it is about to add.
var _built: bool = false

@export var chaos_level: float = 2.0
@export var seed_value: int = 12345

# Animation properties
@export var enable_animation: bool = true
@export var animation_speed: float = 1.0
@export var animation_amplitude: float = 0.5
@export var animation_frequency: float = 0.1
@export var animation_type: AnimationType = AnimationType.WAVE

# VR Performance optimization
@export var update_frequency: float = 30.0  # Updates per second
@export var collision_update_interval: float = 0.5  # Collision update interval in seconds
@export var enable_lod: bool = true
@export var lod_distance: float = 50.0
@export var use_trimesh_collision: bool = true

# Visual tuning
@export var surface_color: Color = Color(0.78, 0.88, 1.0, 1.0)
@export var emission_tint: Color = Color(0.72, 0.84, 1.0, 1.0)
@export var emission_strength: float = 0.42
@export var surface_metallic: float = 0.06
@export var surface_roughness: float = 0.62
@export var rim_strength: float = 0.28

enum AnimationType {
	WAVE,
	RIPPLE,
	RANDOM_WALK,
	CHAOTIC
}

# Internal variables
var base_heights: Array = []
var current_heights: Array = []
var animation_time: float = 0.0
var update_timer: float = 0.0
var collision_timer: float = 0.0
var rng: RandomNumberGenerator
var player_node: Node3D
var last_player_distance: float = 0.0

func _ready():
	super._ready()
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_find_player()
	_generate_base_heights()
	_built = true

func _find_player():
	# Find player for LOD calculations
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		player_node = get_tree().get_first_node_in_group("vr_player")

func _generate_base_heights():
	"""Generate the base height map that will be animated"""
	# Ensure RNG is initialized
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.seed = seed_value
	
	base_heights.clear()
	current_heights.clear()

	var chosen: String = _law_name()
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			# Pure randomness - mathematical anarchy
			var height: float = _draw(chosen)
			base_heights.append(height * height_scale)
			current_heights.append(height * height_scale)


## One vertex, drawn under one law, in the half-open range [-chaos_level,
## chaos_level].
##
## SHORT-CIRCUIT AT THE DEFAULT, deliberately, and not a recomputation of the
## same number. At `uniform` this is the shipped expression itself — the same
## call, the same argument order, one draw from the same stream — rather than a
## re-derivation through randf() that would be equal today and hostage tomorrow
## to how the engine happens to implement randf_range.
##
## The other three take one randf() each, so every law consumes exactly one
## number per vertex and vertex i receives the same u under all four — which is
## what makes the four surfaces comparable rather than merely different. That
## alignment does rest on randf_range being one linear randf, which it is in
## Godot 4; the DEFAULT rests on nothing of the kind, because at `uniform` this
## branch never runs.
func _draw(chosen: String) -> float:
	if chosen == "uniform":
		return rng.randf_range(-chaos_level, chaos_level)
	var u: float = rng.randf()
	match chosen:
		"gaussian":
			# The normal quantile, clipped at three sigma and mapped onto the
			# range so the law is compared at the same amplitude as the others
			# — the axis is the SHAPE of the distribution, not how loud it is.
			return clampf(_inverse_normal(u) / 3.0, -1.0, 1.0) * chaos_level
		"poisson":
			var k: int = _poisson_quantile(u)
			return (float(k) / (float(POISSON_CAP) * 0.5) - 1.0) * chaos_level
		"exponential":
			var e: float = -log(maxf(1.0 - u, 1e-9)) / EXPONENTIAL_RATE
			return (2.0 * minf(e, 1.0) - 1.0) * chaos_level
	return rng.randf_range(-chaos_level, chaos_level)


## Abramowitz & Stegun 26.2.23 — the rational approximation to the inverse normal
## CDF, absolute error below 4.5e-4, which is four orders of magnitude finer than
## a vertex of this mesh can show. Monotone in u by construction, which is the
## property the axis depends on: a vertex that is a peak under one law is a peak
## under all of them.
func _inverse_normal(u: float) -> float:
	var p: float = clampf(u, 1e-6, 1.0 - 1e-6)
	var q: float = minf(p, 1.0 - p)
	var t: float = sqrt(-2.0 * log(q))
	var num: float = 2.515517 + t * (0.802853 + t * 0.010328)
	var den: float = 1.0 + t * (1.432788 + t * (0.189269 + t * 0.001308))
	var z: float = t - num / den
	if p < 0.5:
		return -z
	return z


## The Poisson quantile by direct accumulation of the pmf. At lambda 1.5 this
## loops five times at most, so there is no reason to be clever about it. Capped
## rather than unbounded, because five terraces are legible on a floor and a
## twelve-count outlier would just be a spike.
func _poisson_quantile(u: float) -> int:
	var p: float = exp(-POISSON_LAMBDA)
	var cumulative: float = p
	var k: int = 0
	while u > cumulative and k < POISSON_CAP:
		k += 1
		p = p * POISSON_LAMBDA / float(k)
		cumulative += p
	return k


func _law_name() -> String:
	var v: String = law.strip_edges().to_lower()
	if LAWS.has(v):
		return v
	return "uniform"

func generate_space():
	"""Generate the initial space"""
	_generate_base_heights()
	_update_mesh()
	_update_collision()
	_setup_material()

func _setup_material():
	"""Setup the material for the space"""
	var material = StandardMaterial3D.new()
	material.albedo_color = surface_color
	material.roughness = surface_roughness
	material.metallic = surface_metallic
	material.rim_enabled = true
	material.rim = rim_strength
	material.rim_tint = 0.7
	material.clearcoat_enabled = true
	material.clearcoat = 0.18
	material.clearcoat_gloss = 0.72
	material.emission_enabled = true
	material.emission = emission_tint
	material.emission_energy_multiplier = emission_strength
	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return
	
	animation_time += delta * animation_speed
	update_timer += delta
	collision_timer += delta
	
	# Update mesh at specified frequency for performance
	if update_timer >= 1.0 / update_frequency:
		_update_mesh()
		update_timer = 0.0
	
	# Update collision less frequently to reduce CPU load
	if collision_timer >= collision_update_interval:
		_update_collision()
		collision_timer = 0.0

func _update_mesh():
	"""Update the mesh with animated heights"""
	if base_heights.is_empty():
		return
	
	if enable_animation:
		# Calculate LOD factor if enabled
		var lod_factor = 1.0
		if enable_lod and player_node:
			var distance = global_position.distance_to(player_node.global_position)
			lod_factor = clamp(1.0 - (distance / lod_distance), 0.1, 1.0)
		
		# Update heights based on animation type
		_animate_heights(lod_factor)
	else:
		# Keep a pure static random field for walkable mode.
		current_heights = base_heights.duplicate()
	
	# Create and apply new mesh
	var mesh = create_mesh_from_heights(current_heights)
	mesh_instance.mesh = mesh

func _animate_heights(lod_factor: float = 1.0):
	"""Animate the heights based on the selected animation type"""
	var effective_amplitude = animation_amplitude * lod_factor
	
	match animation_type:
		AnimationType.WAVE:
			_animate_wave(effective_amplitude)
		AnimationType.RIPPLE:
			_animate_ripple(effective_amplitude)
		AnimationType.RANDOM_WALK:
			_animate_random_walk(effective_amplitude)
		AnimationType.CHAOTIC:
			_animate_chaotic(effective_amplitude)

func _animate_wave(amplitude: float):
	"""Wave animation - smooth waves across the surface"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var wave_x = sin(animation_time * animation_frequency + x * 0.1) * amplitude
			var wave_z = cos(animation_time * animation_frequency + z * 0.1) * amplitude
			current_heights[index] = base_heights[index] + (wave_x + wave_z) * 0.5

func _animate_ripple(amplitude: float):
	"""Ripple animation - expanding ripples from center"""
	var center_x = resolution / 2.0
	var center_z = resolution / 2.0
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var distance = sqrt(pow(x - center_x, 2) + pow(z - center_z, 2))
			var ripple = sin(distance * 0.5 - animation_time * animation_frequency * 2.0) * amplitude
			current_heights[index] = base_heights[index] + ripple

func _animate_random_walk(amplitude: float):
	"""Random walk animation - chaotic but smooth movement"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var val_x = sin(animation_time * animation_frequency + x * 0.3) * 0.5
			var val_z = cos(animation_time * animation_frequency + z * 0.3) * 0.5
			var walk = (val_x + val_z) * amplitude
			current_heights[index] = base_heights[index] + walk

func _animate_chaotic(amplitude: float):
	"""Chaotic animation - pure mathematical chaos"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var chaos_x = sin(animation_time * animation_frequency * 3.0 + x * 0.2) * 0.5
			var chaos_z = cos(animation_time * animation_frequency * 2.0 + z * 0.2) * 0.5
			var chaos_combined = sin(chaos_x + chaos_z + animation_time) * amplitude
			current_heights[index] = base_heights[index] + chaos_combined

func _update_collision():
	"""Update collision shape - called less frequently for performance"""
	if mesh_instance.mesh:
		if use_trimesh_collision:
			# Matches SineSpace behavior for reliable walkability.
			create_collision_from_mesh(mesh_instance.mesh)
		else:
			# Faster fallback.
			create_collision_single_convex(mesh_instance.mesh)

# Public API for external control
func set_animation_type(new_type: AnimationType):
	animation_type = new_type
	print("RandomSpace: Animation type set to ", AnimationType.keys()[new_type])

func set_animation_speed(speed: float):
	animation_speed = speed
	print("RandomSpace: Animation speed set to ", speed)

func set_animation_amplitude(amp: float):
	animation_amplitude = amp
	print("RandomSpace: Animation amplitude set to ", amp)

func toggle_animation():
	enable_animation = !enable_animation
	print("RandomSpace: Animation ", "enabled" if enable_animation else "disabled")

func reset_animation():
	"""Reset animation to base state"""
	animation_time = 0.0
	current_heights = base_heights.duplicate()
	_update_mesh()
	_update_collision()
	print("RandomSpace: Animation reset")

func get_animation_info() -> Dictionary:
	"""Get current animation state information"""
	return {
		"enabled": enable_animation,
		"type": AnimationType.keys()[animation_type],
		"speed": animation_speed,
		"amplitude": animation_amplitude,
		"frequency": animation_frequency,
		"time": animation_time,
		"update_frequency": update_frequency,
		"collision_interval": collision_update_interval,
		"lod_enabled": enable_lod
	}


## GUARDED, and the first one this class has ever had — TopologySpace declares no
## apply_grid_config, so before this every export on every walkgrid was
## editor-only and a map could not say anything at all about its floor.
##
## Config can arrive before _ready (the grid stamps it on the node it is about to
## add) or after. Before the first build, assignment is enough: _ready reads the
## new values on its way through. After it, only a value that actually MOVED may
## pay for a 2,601-vertex regenerate and a fresh trimesh collider — the force_pad
## fault was tearing down and rebuilding on ANY call, including calls naming
## nothing it owns. None of the 3 mentions of this token in map_data passes any
## of these keys, so none of them rebuilds anything.
##
## THE RESEED IS LOAD-BEARING, and for a reason worth writing down. This class
## draws its field TWICE on boot: super._ready() runs generate_space() (which
## builds the mesh from the first draw) and then _ready() calls
## _generate_base_heights() a second time, leaving base_heights holding a field
## that is never displayed while enable_animation is false — which it is in the
## .tscn, hence in all three placements. Reseeding here before regenerating means
## the rebuilt surface is the FIRST draw again, i.e. the field the room has always
## shown, rather than wherever the stream happened to have got to. A regenerate
## that changes only the law therefore changes only the law.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var field_changed: bool = false

	if config.has("law"):
		var want: String = str(config["law"]).strip_edges().to_lower()
		if not LAWS.has(want):
			push_warning("random_space: unknown law '%s' — keeping '%s'" % [want, law])
		elif want != _law_name():
			law = want
			field_changed = true
	if config.has("seed_value"):
		var s: int = int(config["seed_value"])
		if s != seed_value:
			seed_value = s
			field_changed = true
	if config.has("chaos_level"):
		var c: float = float(config["chaos_level"])
		if not is_equal_approx(c, chaos_level):
			chaos_level = c
			field_changed = true

	if not _built:
		return
	if field_changed:
		if not rng:
			rng = RandomNumberGenerator.new()
		rng.seed = seed_value
		generate_space()
