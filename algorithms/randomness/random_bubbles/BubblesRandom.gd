# @identity
# essence: random ascent in a contained bowl — bubbles spawn, rise, fade, sometimes carry a soft pink light
# desire: watch petri-dish life: spawn, rise, scale-down, vanish — each bubble a tiny histogram of luck
# critical_parameter: spawn_rate — bubbles per second, the carrier wave of the whole composition
# triggers: bubble_timer accumulates dt; per spawn, a sphere is randomized in size, speed, and position within the dish
# emerges: a soft tower of overlapping translucent spheres rising at random rates, lit by a fraction of pink point-lights
# needs: spawn rate dial [missing]; bubble size range sliders [missing]; light density toggle [missing]
# relationships: sibling of bubble_particles (different parent path, same physics); kin to GaussianPaintSplatter as visible probability density
# truth: Randomness with a ceiling and a floor is still randomness. The dish is the constraint that lets the dispersion be read.

extends Node3D

# Bubble particle properties
@export var spawn_area_size: Vector3 = Vector3(6, 1.0, 6)  # Size of the area where bubbles spawn (matches smaller petri dish)
@export var min_bubble_size: float = 0.2
@export var max_bubble_size: float = 0.8
@export var min_rise_speed: float = 0.5
@export var max_rise_speed: float = 2.0
@export var max_bubble_count: int = 200
@export var spawn_rate: float = 2.0  # Bubbles per second
@export var bubble_lifetime: float = 10.0  # How long bubbles exist before fading out
@export var bubble_fade_time: float = 2.0  # Time it takes for a bubble to fade out
@export var bubble_scale_down_rate: float = 0.05  # How quickly bubbles shrink as they rise

# Bubble light properties
@export var enable_bubble_lights: bool = true
@export var bubble_light_probability: float = 0.35
@export var max_bubble_lights: int = 24
@export var bubble_light_energy: float = 0.22
@export var bubble_light_range: float = 1.8
@export var bubble_light_color: Color = Color(1.0, 0.75, 0.92)

# Petri dish properties
@export var petri_dish_radius: float = 3.5  # Radius of the petri dish (smaller)
@export var petri_dish_height: float = 0.25  # Height of the petri dish walls
@export var petri_dish_thickness: float = 0.04  # Wall thickness
@export var petri_dish_color: Color = Color(1.0, 0.7, 0.9, 0.4)  # Pink glass transparency

# Sound properties
@export var use_synthesized_sounds: bool = true
@export var sound_variations: int = 5  # Number of different bubble sounds to generate
@export var min_pitch_scale: float = 0.8
@export var max_pitch_scale: float = 1.5
@export var min_volume_db: float = -15.0
@export var max_volume_db: float = -5.0
@export var max_concurrent_sounds: int = 4  # Limit number of concurrent sounds
@export var sound_play_chance: float = 0.3  # Chance to play a sound for each bubble (0-1)

# Pre-recorded sounds (alternative to synthesis)
@export var bubble_sounds: Array[AudioStream] = []

## AXIS — WHAT SURROUNDS THE DISH, and so what kind of claim the dish is making. Adopted word
## for word and value for value from the softbody bench family, where seventeen artifacts
## already carry it and where petri_dish_worms — the corpus's other petri dish — joined it on
## 2026-08-05. A private synonym here would have split one question across two vocabularies
## for no gain, and this object's own truth line ("the dish is the constraint that lets the
## dispersion be read") is that question stated from the inside.
##
##   none     the bare 3.5 m dish on nothing: the shipped look, 3 rooms, byte for byte
##   gauge    a graduated post standing off to the left with eight tick bars, a cantilever
##            arm reaching back over the culture and a stylus dropping to just above the
##            glass: the dispersion is no longer watched, it is MEASURED
##   control  a second dish — same glass, same rim, same medium, NO BUBBLES — standing to the
##            right. One dish is something you are watching; two dishes are an experiment you
##            could disagree with, and for a claim about chance that is the sharpest rung
##   chart    a ruled plate standing behind the dish carrying a flat-topped histogram between
##            a marked floor and a marked ceiling: the dish REPORTING, and what it reports is
##            its own thesis — a uniform draw with two bounds
##   vitrine  four glass walls, a lid and a shallow plinth: the culture stops being live work
##            and becomes a thing on display
##
## THE BUBBLES ARE NOT ROUTED THROUGH IT. Every rung spawns the same cloud from the same
## draws in the same order with the same colours; a variant that changed the specimen would
## be changing the answer rather than the showing. The apparatus is added AROUND the dish,
## under a single Node3D appended last, so no legacy child index moves.
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"

## Allow-list. An unrecognised token falls back to the bare dish rather than half an apparatus.
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for the bubble draws. -1 (the default) falls straight through to the global randf /
## randf_range this artifact has always called, in the same order and the same count, so a
## shipped dish is unchanged.
##
## NOT AN AXIS. It exists because every bubble costs TEN unseeded numbers — three for its
## position, one for its size, one for its rise speed, two for its wobble, two for its
## horizontal drift, one for whether it gets a light — and the dish spawns ten a second.
## Without it, five sweep frames are five different clouds and the critic reads that noise as
## a confident BITE on whatever axis happened to be varying. Set it non-negative and the same
## cloud comes back every time, which is the precondition for `assay` being measurable.
@export var bubble_seed: int = -1
var _rng: RandomNumberGenerator = null

# Assay apparatus. Null on the legacy default — the node is not even created.
var _assay_root: Node3D = null

## Set at the end of _ready. apply_grid_config refuses to tear anything down before it is
## true, so a caller that hands the dict over by hand cannot rebuild on top of a half-built
## dish.
var _built: bool = false

# Internal properties
var bubble_timer: float = 0.0
var active_bubbles = []
var active_audio_players = []
var audio_player_pool = []
var synthesized_sounds: Array = []
var petri_dish_container: Node3D
var active_bubble_light_count: int = 0
#var sound_synthesizer: BubbleSoundSynthesizer

# Bubble class to track properties of each bubble
class Bubble:
	var mesh_instance: MeshInstance3D
	var rise_speed: float
	var age: float = 0.0
	var initial_scale: float
	var horizontal_drift: Vector2
	var wobble_amount: float
	var wobble_speed: float
	var material: StandardMaterial3D
	var light: OmniLight3D = null
	
	## p_drift used to be drawn HERE with two bare randf_range calls. An inner class cannot see
	## the outer node's generator, so the two draws moved out to spawn_bubble — to the exact
	## point in the sequence they were made from before, immediately after wobble_speed and
	## before the light's randf, so the global stream at bubble_seed = -1 is consumed in the
	## same order and the same count as it always was.
	func _init(p_mesh_instance, p_rise_speed, p_initial_scale, p_wobble_amount, p_wobble_speed, p_drift: Vector2) -> void:
		mesh_instance = p_mesh_instance
		rise_speed = p_rise_speed
		initial_scale = p_initial_scale
		wobble_amount = p_wobble_amount
		wobble_speed = p_wobble_speed
		horizontal_drift = p_drift

		# Set up the transparent material
		material = StandardMaterial3D.new()
		material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.7, 0.9, 0.3)  # Light pink, transparent
		material.emission = Color(0.8, 0.3, 0.5, 0.1)  # Slight pink glow
		material.roughness = 0.1
		material.metallic = 0.2
		material.metallic_specular = 1.0
		mesh_instance.set_surface_override_material(0, material)

func _ready() -> void:
	_read_dna()

	# Create the petri dish
	create_petri_dish()

	# Appended LAST so every legacy child index and position above it is untouched, and so a
	# rung that wants to enclose the dish can see the finished dish.
	_build_assay()
	_built = true

	# Create the sound synthesizer
	#if use_synthesized_sounds:
		#sound_synthesizer = BubbleSoundSynthesizer.new()
		#add_child(sound_synthesizer)
		
		# Generate a set of bubble sounds with different properties
		#synthesized_sounds = sound_synthesizer.generate_bubble_sound_set(sound_variations)
	
	# Pre-create a pool of audio players
	#for i in range(max_concurrent_sounds):
		#var audio_player = AudioStreamPlayer3D.new()
		#audio_player.max_distance = 20.0
		#audio_player.unit_size = 2.0
		#audio_player.finished.connect(_on_audio_finished.bind(audio_player))
		#add_child(audio_player)
		#audio_player_pool.append(audio_player)

func _process(delta: float) -> void:
	# Spawn new bubbles
	bubble_timer += delta
	if bubble_timer >= 1.0 / spawn_rate and active_bubbles.size() < max_bubble_count:
		spawn_bubble()
		bubble_timer = 0.0
	
	# Update existing bubbles
	var i = 0
	while i < active_bubbles.size():
		var bubble = active_bubbles[i]
		bubble.age += delta
		
		if bubble.age >= bubble_lifetime:
			# Remove and free the bubble
			if bubble.light:
				active_bubble_light_count = maxi(0, active_bubble_light_count - 1)
			bubble.mesh_instance.queue_free()
			active_bubbles.remove_at(i)
			continue
		
		# Move the bubble upward
		var pos = bubble.mesh_instance.position
		pos.y += bubble.rise_speed * delta
		
		# Add horizontal drift
		pos.x += bubble.horizontal_drift.x * delta
		pos.z += bubble.horizontal_drift.y * delta
		
		# Add wobble motion
		var wobble_x = sin(bubble.age * bubble.wobble_speed) * bubble.wobble_amount
		var wobble_z = cos(bubble.age * bubble.wobble_speed * 0.7) * bubble.wobble_amount
		pos.x += wobble_x * delta
		pos.z += wobble_z * delta
		
		bubble.mesh_instance.position = pos
		
		# Scale down as the bubble rises
		var current_scale = bubble.initial_scale * (1.0 - (bubble.age / bubble_lifetime) * bubble_scale_down_rate)
		bubble.mesh_instance.scale = Vector3(current_scale, current_scale, current_scale)
		
		# Fade out when near the end of lifetime
		if bubble.age > (bubble_lifetime - bubble_fade_time):
			var alpha = 0.3 * (1.0 - (bubble.age - (bubble_lifetime - bubble_fade_time)) / bubble_fade_time)
			bubble.material.albedo_color.a = alpha
		
		if bubble.light:
			var life_ratio = clampf(1.0 - (bubble.age / bubble_lifetime), 0.0, 1.0)
			bubble.light.light_energy = bubble_light_energy * life_ratio
		
		i += 1

func create_petri_dish() -> void:
	"""Create a realistic petri dish with glass-like appearance"""
	petri_dish_container = Node3D.new()
	petri_dish_container.name = "PetriDish"
	add_child(petri_dish_container)
	
	# Create glass material for the petri dish
	var glass_material = StandardMaterial3D.new()
	glass_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = petri_dish_color
	glass_material.roughness = 0.05  # Very smooth for glass
	glass_material.metallic = 0.0
	glass_material.refraction_enabled = true
	glass_material.refraction_scale = 0.05
	glass_material.rim_enabled = true
	glass_material.rim = 0.9
	glass_material.rim_color = Color(1.0, 0.8, 0.95, 0.7)  # Pink-tinted rim
	
	# Create the bottom plate (main circular base)
	var bottom_cylinder = CylinderMesh.new()
	bottom_cylinder.top_radius = petri_dish_radius
	bottom_cylinder.bottom_radius = petri_dish_radius
	bottom_cylinder.height = petri_dish_thickness
	
	var bottom_instance = MeshInstance3D.new()
	bottom_instance.mesh = bottom_cylinder
	bottom_instance.set_surface_override_material(0, glass_material)
	bottom_instance.position = Vector3(0, -petri_dish_thickness/2, 0)
	bottom_instance.name = "PetriDishBottom"
	petri_dish_container.add_child(bottom_instance)
	
	# Create the side walls (outer ring)
	var wall_cylinder = CylinderMesh.new()
	wall_cylinder.top_radius = petri_dish_radius
	wall_cylinder.bottom_radius = petri_dish_radius
	wall_cylinder.height = petri_dish_height
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_cylinder
	wall_instance.set_surface_override_material(0, glass_material)
	wall_instance.position = Vector3(0, petri_dish_height/2, 0)
	wall_instance.name = "PetriDishWalls"
	petri_dish_container.add_child(wall_instance)
	
	# Create inner walls (to make it look hollow)
	var inner_wall_cylinder = CylinderMesh.new()
	inner_wall_cylinder.top_radius = petri_dish_radius - petri_dish_thickness
	inner_wall_cylinder.bottom_radius = petri_dish_radius - petri_dish_thickness
	inner_wall_cylinder.height = petri_dish_height - petri_dish_thickness
	
	var inner_wall_instance = MeshInstance3D.new()
	inner_wall_instance.mesh = inner_wall_cylinder
	# Create inverted material for inner walls
	var inner_material = glass_material.duplicate()
	inner_material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render from inside
	inner_wall_instance.set_surface_override_material(0, inner_material)
	inner_wall_instance.position = Vector3(0, (petri_dish_height - petri_dish_thickness)/2, 0)
	inner_wall_instance.name = "PetriDishInnerWalls"
	petri_dish_container.add_child(inner_wall_instance)
	
	# Add some subtle lighting enhancement around the dish
	var area_light = OmniLight3D.new()
	area_light.light_energy = 0.4
	area_light.light_color = Color(1.0, 0.85, 0.95)  # Pink-tinted light
	area_light.omni_range = petri_dish_radius * 2.5
	area_light.position = Vector3(0, petri_dish_height + 0.8, 0)
	area_light.name = "PetriDishLight"
	petri_dish_container.add_child(area_light)
	
	print("BubblesRandom: Created petri dish with radius %.1f and height %.1f" % [petri_dish_radius, petri_dish_height])

## The grid writes config_<key> onto the artifact ROOT before add_child and only calls
## apply_grid_config deferred, i.e. AFTER _ready. Reading the metadata here means a token that
## asks for an apparatus builds it once, instead of building the bare dish and tearing it down
## a frame later. A bare token sets no metadata and reaches nothing.
func _read_dna() -> void:
	if has_meta("config_bubble_seed"):
		bubble_seed = int(str(get_meta("config_bubble_seed")))
	if has_meta("config_assay"):
		var word: String = str(get_meta("config_assay")).strip_edges().to_lower()
		if ASSAYS.has(word):
			assay = word


## The two kinds of draw this artifact makes. At bubble_seed = -1 both fall straight through
## to the global functions it has always called.
func _rf() -> float:
	if bubble_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = bubble_seed
	return _rng.randf()


func _rf_range(from_v: float, to_v: float) -> float:
	if bubble_seed < 0:
		return randf_range(from_v, to_v)
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = bubble_seed
	return _rng.randf_range(from_v, to_v)


func spawn_bubble() -> void:
	# Create a random position within the spawn area
	var pos = Vector3(
		_rf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
		_rf_range(-spawn_area_size.y/2, spawn_area_size.y/2),
		_rf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
	)
	
	# Create a sphere mesh (optimized for many bubbles)
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8  # Reduced polygon count for better performance
	sphere.rings = 4           # Reduced polygon count for better performance
	
	# Create mesh instance and add to scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	mesh_instance.position = pos
	
	# Random properties
	var initial_scale = _rf_range(min_bubble_size, max_bubble_size)
	mesh_instance.scale = Vector3(initial_scale, initial_scale, initial_scale)

	var rise_speed = _rf_range(min_rise_speed, max_rise_speed)
	var wobble_amount = _rf_range(0.05, 0.25)
	var wobble_speed = _rf_range(1.0, 3.0)

	# The two drift draws, made here rather than inside Bubble._init but at the same point in
	# the sequence, with the same bounds, so the stream is consumed exactly as before.
	var drift: Vector2 = Vector2(_rf_range(-0.2, 0.2), _rf_range(-0.2, 0.2))

	# Create and track the bubble
	var bubble = Bubble.new(mesh_instance, rise_speed, initial_scale, wobble_amount, wobble_speed, drift)

	if enable_bubble_lights and active_bubble_light_count < max_bubble_lights and _rf() <= bubble_light_probability:
		var bubble_light = OmniLight3D.new()
		bubble_light.name = "BubbleLight"
		bubble_light.shadow_enabled = false
		bubble_light.light_energy = bubble_light_energy
		bubble_light.light_color = bubble_light_color
		bubble_light.omni_range = bubble_light_range * clampf(initial_scale, 0.5, 1.4)
		mesh_instance.add_child(bubble_light)
		bubble.light = bubble_light
		active_bubble_light_count += 1

	active_bubbles.append(bubble)
	
	# Play bubble sound effect
	play_bubble_sound(pos, initial_scale)

func play_bubble_sound(position: Vector3, bubble_size: float) -> void:
	# Determine normalized bubble size (0-1)
	var size_factor = (bubble_size - min_bubble_size) / (max_bubble_size - min_bubble_size)
	
	# Only play sound occasionally to avoid too many sound effects.
	# Routed through _rf for COUNT, not for sound: audio_player_pool is permanently empty
	# (the synthesizer and its pool are commented out above), so this line always returns and
	# no bubble has ever made a noise. It still consumes one draw per bubble, and a seeded
	# stream that skipped it would not be the same stream.
	if _rf() > sound_play_chance or audio_player_pool.size() == 0:
		return
	
	# Check if we have any sounds to play
	var available_sounds = use_synthesized_sounds if  synthesized_sounds else bubble_sounds
	if available_sounds:
		return
		
	# Get an available audio player from the pool
	var audio_player = audio_player_pool.pop_back()
	active_audio_players.append(audio_player)
	
	# Set the audio player's position to match the bubble
	audio_player.position = position
	
	# Choose a sound based on bubble size
	var sound_index
	if use_synthesized_sounds:
		# For synthesized sounds, we have a range from small to large
		sound_index = int(size_factor * (available_sounds.size() - 1))
	else:
		# For pre-recorded sounds, choose randomly
		sound_index = randi() % available_sounds.size()
	
	# Apply a small random variation to index to add variety
	sound_index = clamp(sound_index + randi() % 3 - 1, 0, available_sounds.size() - 1)
	audio_player.stream = available_sounds[sound_index]
	
	# Scale pitch and volume based on bubble size
	# Smaller bubbles = higher pitch, quieter
	audio_player.pitch_scale = lerp(max_pitch_scale, min_pitch_scale, size_factor)
	audio_player.volume_db = lerp(min_volume_db, max_volume_db, size_factor)
	
	# Add a slight randomization to pitch for variety
	audio_player.pitch_scale *= randf_range(0.95, 1.05)
	
	# Play the sound
	audio_player.play()

func _on_audio_finished(audio_player) -> void:
	# Return the audio player to the pool when finished
	if active_audio_players.has(audio_player):
		active_audio_players.erase(audio_player)
		audio_player_pool.append(audio_player)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GUARDED. This used to be `pass`, so every key a map could send was silently discarded; it
## now reads exactly two, and it returns before touching anything unless the key is PRESENT,
## names a legal value, and that value DIFFERS from the one already standing. Restating the
## value the dish already holds must not throw the apparatus away and build it again, and
## nothing may be torn down before _ready has built once.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty() or not _built:
		return

	if config_data.has("bubble_seed"):
		var s: int = int(str(config_data["bubble_seed"]))
		if s != bubble_seed:
			bubble_seed = s
			_rng = null

	if config_data.has("assay"):
		var word: String = str(config_data["assay"]).strip_edges().to_lower()
		if ASSAYS.has(word) and word != assay:
			assay = word
			_rebuild_assay()


func _rebuild_assay() -> void:
	if is_instance_valid(_assay_root):
		remove_child(_assay_root)
		_assay_root.queue_free()
	_assay_root = null
	_build_assay()


# ─── ASSAY apparatus ──────────────────────────────────────────────────────────────────────
# Every dimension below is petri_dish_worms.gd's absolute value divided by its AS_DISH_R of
# 0.16, then multiplied by this dish's own radius. The two petri dishes carry the SAME
# apparatus at their own sizes, rather than one carrying a scale model of the other's — which
# is what "the siblings measure alike" has to mean when the objects are 22x apart.
const AS_POST_X := -1.875           # gauge post centre, 0.30 / 0.16
const AS_CONTROL_X := 2.5           # control dish centre, 0.40 / 0.16
const AS_CHART_Z := -1.875          # chart plate standoff behind the dish, 0.30 / 0.16


func _build_assay() -> void:
	var r: float = maxf(petri_dish_radius, 0.05)
	match assay:
		"gauge":
			_assay_root_node()
			_assay_gauge(r)
		"control":
			_assay_root_node()
			_assay_control(r)
		"chart":
			_assay_root_node()
			_assay_chart(r)
		"vitrine":
			_assay_root_node()
			_assay_vitrine(r)
		_:
			pass                                  # "none" — the legacy lineage, nothing added


## One wrapper node for the whole apparatus. A plain Node3D, which is also why the grid's
## auto-grounding walk cannot see any of it: that walk types only the root's DIRECT children,
## and a Node3D is not one of the types it measures.
func _assay_root_node() -> void:
	_assay_root = Node3D.new()
	_assay_root.name = "Assay"
	add_child(_assay_root)


func _as_metal(tint: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = 0.55
	mat.roughness = 0.42
	return mat


func _as_glass() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _as_box(size: Vector3, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	return _as_box_under(_assay_root, size, at, mat)


## Same box, parented somewhere other than the assay root — the chart hangs its rules and its
## bars off the tilted plate so they tilt with it instead of floating in front of it.
func _as_box_under(parent: Node3D, size: Vector3, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _as_cylinder(top_r: float, bot_r: float, h: float, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = h
	cyl.radial_segments = 32
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = cyl
	mi.position = at
	mi.material_override = mat
	_assay_root.add_child(mi)
	return mi


## GAUGE — the dish stops being watched and starts being measured. A graduated post, a
## cantilever reaching back over the culture, and a stylus hanging above the glass.
func _assay_gauge(r: float) -> void:
	var steel: StandardMaterial3D = _as_metal(Color(0.62, 0.64, 0.68))
	var brass: StandardMaterial3D = _as_metal(Color(0.85, 0.68, 0.30))
	var px: float = AS_POST_X * r
	_as_box(Vector3(0.3125 * r, 0.075 * r, 0.5625 * r), Vector3(px, 0.0375 * r, 0.0), steel)
	_as_box(Vector3(0.1375 * r, 1.375 * r, 0.1375 * r), Vector3(px, 0.6875 * r, 0.0), steel)
	for i in range(8):
		var y: float = (0.219 + 0.15 * float(i)) * r
		var long_tick: bool = (i % 2) == 0
		var w: float = (0.25 * r) if long_tick else (0.1625 * r)
		_as_box(Vector3(w, 0.0219 * r, 0.0375 * r),
			Vector3(px + w * 0.5 + 0.06875 * r, y, 0.075 * r), brass)
	# Cantilever arm reaching from the post back over the centre of the dish, and the stylus.
	var reach: float = absf(px) + 0.125 * r
	_as_box(Vector3(reach, 0.0875 * r, 0.1125 * r), Vector3(px + reach * 0.5, 1.25 * r, 0.0), steel)
	_as_box(Vector3(0.05 * r, 1.0 * r, 0.05 * r), Vector3(-0.125 * r, 0.75 * r, 0.0), brass)
	_as_cylinder(0.0, 0.04375 * r, 0.1125 * r,
		Vector3(-0.125 * r, petri_dish_height + 0.175 * r, 0.0), brass)


## CONTROL — the rung that turns an observation into an experiment. Same glass, same rim, same
## medium, standing 2.5 radii away. No bubbles: nothing spawns into it, and that absence is the
## whole content of this rung. For an artifact whose entire subject is chance it is the
## sharpest of the five — an empty dish is the only thing in the room that can disagree.
func _assay_control(r: float) -> void:
	var glass: StandardMaterial3D = _as_glass()
	var medium: StandardMaterial3D = StandardMaterial3D.new()
	medium.albedo_color = petri_dish_color
	medium.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var c: Vector3 = Vector3(AS_CONTROL_X * r, 0.0, 0.0)
	_as_cylinder(r, 0.9375 * r, 0.15625 * r, c + Vector3(0, 0.078 * r, 0), glass)
	_as_cylinder(1.03 * r, r, 0.05 * r, c + Vector3(0, 0.18 * r, 0), glass)
	_as_cylinder(0.875 * r, 0.875 * r, 0.09375 * r, c + Vector3(0, 0.05 * r, 0), medium)
	var tag: Label3D = Label3D.new()
	tag.text = "CONTROL\nno bubbles"
	tag.pixel_size = 0.008 * r
	tag.font_size = 10
	tag.outline_size = 2
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.modulate = Color(0.6, 0.7, 0.8, 0.8)
	tag.position = c + Vector3(0, -0.0625 * r, 1.125 * r)
	_assay_root.add_child(tag)


## CHART — the dish reporting. A ruled plate standing behind the culture. The sibling plots a
## logistic because a worm population grows; a bubble dish has no growth curve, so what stands
## here is this artifact's OWN thesis drawn as a picture: a flat-topped histogram between a
## marked floor and a marked ceiling, which is the truth line ("randomness with a ceiling and
## a floor is still randomness") made visible. FIXED, not sampled — a rung that rolled dice
## would make every capture a different picture and the axis unmeasurable.
func _assay_chart(r: float) -> void:
	var w: float = 2.625 * r
	var h: float = 1.625 * r
	var board: StandardMaterial3D = _as_metal(Color(0.10, 0.11, 0.13))
	board.metallic = 0.15
	board.roughness = 0.85
	var plate: MeshInstance3D = _as_box(Vector3(w, h, 0.0625 * r),
		Vector3(0.0, h * 0.5 + 0.125 * r, AS_CHART_Z * r), board)
	plate.rotation_degrees = Vector3(-8, 0, 0)

	var rule: StandardMaterial3D = _as_metal(Color(0.38, 0.42, 0.46))
	rule.metallic = 0.0
	for i in range(5):
		var gy: float = -h * 0.5 + h * (float(i) + 0.5) / 5.0
		_as_box_under(plate, Vector3(w * 0.88, 0.014 * r, 0.025 * r), Vector3(0, gy, 0.044 * r), rule)

	# The flat top: fourteen equal bars over the admitted band, and nothing outside it.
	var ink: StandardMaterial3D = _as_metal(Color(0.95, 0.55, 0.80))
	ink.metallic = 0.0
	ink.emission_enabled = true
	ink.emission = Color(0.95, 0.55, 0.80)
	ink.emission_energy_multiplier = 1.4
	var bars: int = 14
	var band: float = w * 0.60
	var bar_w: float = band / float(bars) * 0.72
	var bar_h: float = h * 0.52
	for i in range(bars):
		var bx: float = -band * 0.5 + band * (float(i) + 0.5) / float(bars)
		_as_box_under(plate, Vector3(bar_w, bar_h, 0.030 * r),
			Vector3(bx, -h * 0.40 + bar_h * 0.5, 0.056 * r), ink)

	# The floor and the ceiling: two uprights at the band's edges, which is the whole claim.
	var bound: StandardMaterial3D = _as_metal(Color(0.98, 0.86, 0.35))
	bound.metallic = 0.0
	bound.emission_enabled = true
	bound.emission = Color(0.98, 0.86, 0.35)
	bound.emission_energy_multiplier = 1.2
	for s in [-1.0, 1.0]:
		var o: float = float(s) * band * 0.5
		_as_box_under(plate, Vector3(0.030 * r, h * 0.80, 0.030 * r),
			Vector3(o, -h * 0.05, 0.062 * r), bound)


## VITRINE — the culture stops being live work. Four walls, a lid and a shallow plinth: the
## dish is now a thing on display, which is a different claim about what you are looking at.
func _assay_vitrine(r: float) -> void:
	var glass: StandardMaterial3D = _as_glass()
	var plinth: StandardMaterial3D = _as_metal(Color(0.16, 0.17, 0.20))
	plinth.metallic = 0.25
	plinth.roughness = 0.8
	var half: float = 1.3125 * r
	var top: float = 1.875 * r
	var t: float = 0.0375 * r
	_as_box(Vector3(half * 2.0 + 0.25 * r, 0.075 * r, half * 2.0 + 0.25 * r),
		Vector3(0, -0.0375 * r, 0), plinth)
	_as_box(Vector3(half * 2.0, t, half * 2.0), Vector3(0, top, 0), glass)
	_as_box(Vector3(half * 2.0, top, t), Vector3(0, top * 0.5, -half), glass)
	_as_box(Vector3(half * 2.0, top, t), Vector3(0, top * 0.5, half), glass)
	_as_box(Vector3(t, top, half * 2.0), Vector3(-half, top * 0.5, 0), glass)
	_as_box(Vector3(t, top, half * 2.0), Vector3(half, top * 0.5, 0), glass)
	# Corner posts, so the case reads as a case and not as four floating panes.
	var post: StandardMaterial3D = _as_metal(Color(0.55, 0.57, 0.60))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_as_box(Vector3(0.0625 * r, top, 0.0625 * r),
				Vector3(half * float(sx), top * 0.5, half * float(sz)), post)
