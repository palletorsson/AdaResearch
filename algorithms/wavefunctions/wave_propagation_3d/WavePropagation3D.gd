extends Node3D


# @identity
# essence: height(x,z,t) = sum(A_ring * sin(omega*t - k*distance(x,z,center))) — expanding ring waves
# desire: Watch concentric wave rings propagate across a tile floor, interfering where they meet
# critical_parameter: grid_size — determines the spatial extent of the wave propagation field
# triggers: wave_rings[] spawn at intervals; each ring expands and decays over time
# emerges: interference patterns from overlapping circular waves — constructive and destructive zones appear
# needs: VR interaction to spawn waves [missing], walking on tiles [has]
# relationships: depends on MultiMesh tile height animation; contrasts with sine_space (propagating rings vs standing waves); unlocks wave interference visualization
# truth: Every point in a wave field is the sum of all waves that have reached it — superposition is the law.

@export var grid_size: int = 20  # ~11.6m total span
@export var tile_size: float = 0.5  # Bigger tiles
@export var tile_gutter: float = 0.08
@export var tile_height: float = 0.15  # Taller tiles for more visible height
@export var floor_tilt_degrees: float = -12.0
@export var frequency: float = 0.7
@export var amplitude: float = 1.8  # Bigger wave displacement
@export var wave_speed: float = 0.6
@export var wave_damping: float = 0.06  # Slightly less damping for larger visible area

# ═══════════════════════════════════════════════════════════════════════════
# DNA
#
# Everything above this line is a DIAL — a rate, a size, a tick. Worse, three of
# them (frequency, amplitude, wave_speed) are overwritten every frame by
# animate_controls() from the clock, so the .tscn's frequency = 0.9 survives for
# exactly one frame. A still photograph of this artifact cannot be a photograph
# of any of them.
#
# These two are not dials. They are the two facts about a wave that a single
# frozen frame CAN carry: where the disturbance was born, and what happens to it
# as it gets further from there.
#
#   falloff   the law the spreading obeys. The registry has always claimed this
#             artifact is about "the inverse-square law as entropy increase" and
#             the code has always run exp(-d * wave_damping), which is not the
#             inverse-square law — it is absorption by a lossy medium. The axis
#             is the difference between those claims, laid out as four fields:
#             exponential (shipped, a medium that eats the wave), inverse_square
#             (energy conserved and thinned over a growing sphere), inverse_linear
#             (the same accounting in two dimensions, which is what a tile FLOOR
#             actually is), lossless (nothing thins at all — the wave arrives at
#             the rim as strong as it left). Read per frame in
#             animate_3d_wave_propagation; no rebuild, no node.
#
#   source    where the wave is born, which is what decides whether it is a wave
#             at all or a front. center is the shipped single point at the grid
#             origin; corner puts the same point at one end so the whole floor is
#             one sweeping quadrant; pair gives two points and the tile heights
#             become a genuine SUM, which is what this artifact's own truth line
#             has always claimed and its arithmetic has never done; line is a
#             straight source and the rings become plane waves — the same law,
#             the different geometry, and the reason a ripple tank and a beach
#             look nothing alike.
#
# The two are orthogonal in the code and NOT in the photograph: at `line` the
# distance to the source is a coordinate rather than a radius, so the falloff
# stripes the floor front-to-back instead of ringing it, and inverse_square at
# `corner` puts every visible peak in one corner. That is the interesting part.
@export_enum("exponential", "inverse_square", "inverse_linear", "lossless") var falloff: String = "exponential"
@export_enum("center", "corner", "pair", "line") var source: String = "center"

## Allow-lists. An unknown word from a map token falls back to the shipped field
## rather than leaving a placement with a flat floor.
const FALLOFFS: PackedStringArray = ["exponential", "inverse_square", "inverse_linear", "lossless"]
const SOURCES: PackedStringArray = ["center", "corner", "pair", "line"]

## Where the disturbance is, in tile-plane coordinates. One entry at the origin is
## the shipped state and reproduces `distance = pos2.length()` exactly.
var wave_sources: Array[Vector2] = [Vector2.ZERO]
## `line` measures distance to a STRAIGHT source, so it is a coordinate, not a radius.
var line_source: bool = false
## Extra markers built by pair / line. Empty on the shipped path.
var source_markers: Array[Node3D] = []

var time: float = 0.0
var tile_positions: Array[Vector2] = []
var tile_multimesh_instance: MultiMeshInstance3D
var tile_multimesh: MultiMesh
var wave_rings: Array = []
var tile_collision_bodies: Array[StaticBody3D] = []
var soundscape: Node3D

# More distinct color gradient for wave visualization
var base_tile_color := Color(0.15, 0.35, 0.65, 1.0)  # Darker blue base
var peak_tile_color := Color(1.0, 0.9, 0.3, 1.0)  # Brighter yellow peak

func _ready() -> void:
	_read_grid_config_meta()
	create_wave_surface()
	create_wave_rings() # Enable rings for the soundscape
	setup_materials()
	setup_soundscape()
	_normalize_falloff()
	_apply_source()

func setup_soundscape() -> void:
	var WaveSoundscape = load("res://algorithms/wavefunctions/wave_propagation_3d/WaveSoundscapeComponent.gd")
	soundscape = WaveSoundscape.new()
	add_child(soundscape)
	print("WavePropagation: Soundscape component initialized.")

func create_wave_surface() -> void:
	var surface_parent = $WaveSurface
	var instance = MultiMeshInstance3D.new()
	tile_multimesh_instance = instance
	tile_multimesh = MultiMesh.new()
	var tile_mesh = BoxMesh.new()
	tile_mesh.size = Vector3(tile_size, tile_height, tile_size)
	tile_multimesh.mesh = tile_mesh
	tile_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tile_multimesh.use_colors = true
	tile_multimesh.instance_count = grid_size * grid_size
	tile_multimesh_instance.multimesh = tile_multimesh
	surface_parent.add_child(tile_multimesh_instance)
	
	# Create collision bodies for each tile
	_create_tile_collision_bodies(surface_parent)
	
	tile_positions.clear()
	var spacing = tile_size + tile_gutter
	var half = (grid_size - 1) * 0.5
	var index = 0
	for x in range(grid_size):
		for z in range(grid_size):
			var pos2 = Vector2((x - half) * spacing, (z - half) * spacing)
			tile_positions.append(pos2)
			var origin = Vector3(pos2.x, tile_height * 0.5, pos2.y)
			var transform = Transform3D(Basis.IDENTITY, origin)
			tile_multimesh.set_instance_transform(index, transform)
			tile_multimesh.set_instance_color(index, base_tile_color)
			index += 1

func create_wave_rings() -> void:
	var rings_parent = $WaveRings
	wave_rings.clear()
	var ring_count = 4
	for i in range(ring_count):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.2 + float(i) * 0.9
		ring.height = 0.04
		ring.position.y = -0.4
		rings_parent.add_child(ring)
		wave_rings.append(ring)

func setup_materials() -> void:
	var tile_material = StandardMaterial3D.new()
	tile_material.vertex_color_use_as_albedo = true
	tile_material.metallic = 0.0
	tile_material.roughness = 0.4
	tile_material.emission_enabled = true
	tile_material.emission = Color(0.05, 0.08, 0.1, 1.0)
	tile_multimesh_instance.material_override = tile_material
	
	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.75, 0.82, 1.0, 0.35)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.22, 0.22, 0.45, 1.0)
	for ring in wave_rings:
		ring.material_override = ring_material
	
	var source_material = StandardMaterial3D.new()
	source_material.albedo_color = Color(1.0, 0.35, 0.35)
	source_material.emission_enabled = true
	source_material.emission = Color(0.6, 0.1, 0.1)
	$WaveSource.material_override = source_material
	
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.85, 0.35)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.35, 0.22, 0.08)
	$FrequencyControl.material_override = freq_material
	
	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.85, 1.0, 0.35)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.2, 0.32, 0.08)
	$AmplitudeControl.material_override = amp_material

func _process(delta: float) -> void:
	time += delta
	animate_3d_wave_propagation()
	animate_wave_rings()
	animate_controls()
	
	if soundscape:
		soundscape.update_parameters(frequency, amplitude, time, wave_rings)

func animate_3d_wave_propagation() -> void:
	if tile_multimesh == null:
		return
	var instance_index = 0
	var tile_half_height = tile_height * 0.5
	var source_count: float = float(max(wave_sources.size(), 1))
	for pos2 in tile_positions:
		# SUPERPOSITION, and at the shipped `center` it is a sum of one term: the
		# loop below evaluates to exactly `amplitude * sin(phase) * exp(-d * damping)`
		# and `sin(phase)`, the two expressions that were here before.
		var displacement: float = 0.0
		var carrier: float = 0.0
		for s: Vector2 in wave_sources:
			var distance: float = _wave_distance(pos2, s)
			var wave_phase: float = distance * frequency - wave_speed * time
			var attenuation: float = _attenuation(distance)
			displacement += amplitude * sin(wave_phase) * attenuation
			carrier += sin(wave_phase)
		carrier /= source_count
		var wave_phase_intensity: float = carrier
		var origin = Vector3(pos2.x, tile_half_height + displacement, pos2.y)
		var transform = Transform3D(Basis.IDENTITY, origin)
		tile_multimesh.set_instance_transform(instance_index, transform)
		var intensity = clamp((wave_phase_intensity + 1.0) * 0.5, 0.0, 1.0)
		var color = base_tile_color.lerp(peak_tile_color, intensity)
		tile_multimesh.set_instance_color(instance_index, color)
		
		# Update collision body position to match visual tile
		if instance_index < tile_collision_bodies.size():
			tile_collision_bodies[instance_index].position = origin
		
		instance_index += 1

func animate_wave_rings() -> void:
	if wave_rings.is_empty():
		return
	var travel_rate = max(wave_speed * 1.8, 0.01)
	var max_radius = 12.0  # Larger radius to match bigger grid
	var cycle_duration = max_radius / travel_rate
	for i in range(wave_rings.size()):
		var ring = wave_rings[i]
		var local_time = time - float(i) * 1.2  # Wider spacing between rings
		if cycle_duration <= 0.0:
			cycle_duration = 1.0
		local_time = fposmod(local_time, cycle_duration)
		var ring_radius = max(0.2, travel_rate * local_time)
		ring.radius = ring_radius
		var fade = clamp(1.0 - local_time * 0.12, 0.0, 1.0)  # Slower fade
		var ring_material = ring.material_override as StandardMaterial3D
		if ring_material:
			ring_material.albedo_color.a = fade * 0.35
			ring_material.emission = Color(0.22 * fade, 0.22 * fade, 0.45 * fade, 1.0)

func animate_controls() -> void:
	var freq_height = frequency * 0.8
	var freq_size = $FrequencyControl.size
	freq_size.y = max(0.2, freq_height)
	$FrequencyControl.size = freq_size
	$FrequencyControl.position.y = -3.0 + freq_size.y * 0.5
	var amp_height = amplitude * 1.6
	var amp_size = $AmplitudeControl.size
	amp_size.y = max(0.2, amp_height)
	$AmplitudeControl.size = amp_size
	$AmplitudeControl.position.y = -3.0 + amp_size.y * 0.5
	frequency = 0.55 + sin(time * 0.12) * 0.25
	amplitude = 0.45 + cos(time * 0.1) * 0.2
	wave_speed = 0.5 + sin(time * 0.09) * 0.18
	$WaveSource.radius = 0.28 + sin(time * frequency * 2.4) * 0.05

func _create_tile_collision_bodies(surface_parent: Node3D) -> void:
	"""Create collision bodies for each tile"""
	tile_collision_bodies.clear()
	
	var spacing = tile_size + tile_gutter
	var half = (grid_size - 1) * 0.5
	
	for x in range(grid_size):
		for z in range(grid_size):
			var pos2 = Vector2((x - half) * spacing, (z - half) * spacing)
			var origin = Vector3(pos2.x, tile_height * 0.5, pos2.y)
			
			# Create StaticBody3D for collision
			var collision_body = StaticBody3D.new()
			collision_body.name = "TileCollision_%d_%d" % [x, z]
			collision_body.position = origin
			
			# Create collision shape
			var collision_shape = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(tile_size, tile_height, tile_size)
			collision_shape.shape = box_shape
			
			collision_body.add_child(collision_shape)
			surface_parent.add_child(collision_body)
			
			# Store reference for animation
			tile_collision_bodies.append(collision_body)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# FALLOFF · SOURCE
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(),
## and the capture harness calls apply_grid_config() before the scene is in the tree.
## Reading the metadata on the way in means the field is built once, correctly.
## Costs nothing when no token is present.
## NEAREST CARRIER WINS, and each key stops on its own. `source` is a common enough
## word that some other artifact's container could plausibly be carrying one; taking
## the closest ancestor's value means a curation_station or a plinth cannot reach past
## the thing it is actually holding. An unknown word is caught downstream anyway.
func _read_grid_config_meta() -> void:
	var node: Node = self
	var got_falloff: bool = false
	var got_source: bool = false
	while node != null:
		if not got_falloff and node.has_meta("config_falloff"):
			falloff = str(node.get_meta("config_falloff"))
			got_falloff = true
		if not got_source and node.has_meta("config_source"):
			source = str(node.get_meta("config_source"))
			got_source = true
		if got_falloff and got_source:
			return
		node = node.get_parent()


## Config from map_data.json tokens: #falloff:inverse_square · #source:pair
##
## GUARDED ON CHANGE. A placement carrying any other token arrives here with neither
## key, and the grid reaches this twice for one placement; rebuilding the markers on
## both of those would tear down and re-raise geometry for nothing. `falloff` never
## rebuilds anything at all — it is read per frame.
func apply_grid_config(config: Dictionary) -> void:
	var was_falloff: String = falloff
	var was_source: String = source

	if config.has("falloff"):
		falloff = str(config["falloff"])
	if config.has("source"):
		source = str(config["source"])

	if falloff == was_falloff and source == was_source:
		return

	_normalize_falloff()

	# Before _ready() the floor does not exist yet and _ready() will do this itself.
	if tile_multimesh == null:
		return

	if source != was_source:
		_apply_source()


func _normalize_falloff() -> void:
	var want: String = String(falloff).strip_edges().to_lower()
	if not FALLOFFS.has(want):
		want = "exponential"                 # an unknown word keeps the shipped medium
	falloff = want


## How much of the wave survives the trip out to `distance`.
##
## The default branch is the shipped expression, unchanged and unreachable by
## rounding: at falloff = "exponential" this function IS exp(-d * wave_damping).
func _attenuation(distance: float) -> float:
	match falloff:
		"inverse_square":
			# Energy conserved, spread over a sphere of radius d. The rim goes quiet
			# fast; every visible peak collapses toward the source.
			return 1.0 / ((1.0 + distance) * (1.0 + distance))
		"inverse_linear":
			# The same accounting one dimension down — a circular front on a FLOOR,
			# which is what these tiles actually are.
			return 1.0 / (1.0 + distance)
		"lossless":
			# Nothing thins. The far rim moves exactly as hard as the source.
			return 1.0
	return exp(-distance * wave_damping)


## Distance from a tile to the disturbance. A point source measures a radius; a line
## source measures a coordinate, which is the whole difference between a ripple and
## a swell.
func _wave_distance(pos2: Vector2, s: Vector2) -> float:
	if line_source:
		return absf(pos2.y - s.y)
	return (pos2 - s).length()


## Where the wave is born. Rebuilds only the MARKERS — the tile field is unchanged
## geometry and re-reads the source list every frame.
func _apply_source() -> void:
	var want: String = String(source).strip_edges().to_lower()
	if not SOURCES.has(want):
		want = "center"                      # an unknown word keeps the shipped field
	source = want

	for marker in source_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	source_markers.clear()

	var span: float = (tile_size + tile_gutter) * float(grid_size - 1) * 0.5
	var points: Array[Vector2] = []
	line_source = false
	match want:
		"corner":
			points.append(Vector2(-span, -span))
		"pair":
			points.append(Vector2(-span * 0.45, 0.0))
			points.append(Vector2(span * 0.45, 0.0))
		"line":
			line_source = true
			points.append(Vector2(0.0, -span))
		_:
			points.append(Vector2.ZERO)
	wave_sources = points

	var primary: Vector2 = wave_sources[0]
	var source_node: CSGSphere3D = $WaveSource
	source_node.position = Vector3(primary.x, source_node.position.y, primary.y)

	# The concentric rings are a second drawing of a POINT source. They follow it,
	# and a straight source has none to follow.
	var rings: Node3D = $WaveRings
	rings.position = Vector3(primary.x, rings.position.y, primary.y)
	rings.visible = not line_source

	if want == "pair":
		var second := CSGSphere3D.new()
		second.radius = 0.3
		second.position = Vector3(wave_sources[1].x, source_node.position.y, wave_sources[1].y)
		second.material_override = source_node.material_override
		add_child(second)
		source_markers.append(second)
	elif want == "line":
		var bar := CSGBox3D.new()
		bar.size = Vector3(span * 2.0 + tile_size, 0.12, 0.24)
		bar.position = Vector3(0.0, source_node.position.y, primary.y)
		bar.material_override = source_node.material_override
		add_child(bar)
		source_markers.append(bar)
