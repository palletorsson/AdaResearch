extends Node3D

# Beauty of Randomness Visualizer
# This script creates visual demonstrations of different types of randomness
# and explains their beauty and applications

# Parameters for visualization
@export var num_particles: int = 100
@export var display_time: float = 10.0  # Time before switching to next visualization
@export var enable_narration: bool = true
@export var forced_demo: int = -1

## STAGE-2 DNA — AXIS: WHICH KIND OF RANDOMNESS IS ON SHOW.
##
## This artifact is a five-chapter book that reads itself aloud on a ten-second timer. Every
## chapter already exists in full below — its own opening arrangement in `start_demo`, its
## own update rule, its own colour law, its own title and its own paragraph of prose. What
## did not exist was any way to stop on one. `forced_demo` is an int with no names attached,
## the registry declared nothing, and `apply_grid_config` was literally `pass`, so all five
## maps that place this show whichever page the clock happened to be on.
##
##   all         the shipped rotation: open on chaos, turn the page every display_time
##               seconds, forever. Photographed at any instant it IS one of the five.
##   chaos       100 spheres uniform in a 10 m cube, each shoved by an independent random
##               force. Randomness as pure unstructured draw — the null hypothesis.
##   noise       a flat 20 x 5 lattice flowing along a smooth field. Randomness with
##               CORRELATION: neighbouring samples agree, which is what makes it look
##               like nature instead of like static.
##   pattern     a disc, angle by index and radius by draw, wound into a spiral. Randomness
##               under a RULE — the same chance filtered through an equation.
##   emergence   a 2 m ball obeying separation, alignment and cohesion with a small random
##               nudge. Randomness as the LOCAL term whose global effect is order.
##   evolution   a 2 m line that ranks itself against a moving target every frame; the top
##               tenth turn gold and grow, the rest chase a winner and mutate. Randomness
##               under SELECTION.
##
## The five differ in silhouette before they differ in anything else — cube, panel, disc,
## ball, line — which is what makes the axis legible in one still rather than a claim about
## motion. Their prose changes with them, because the labels belong to the chapter.
@export_enum("all", "chaos", "noise", "pattern", "emergence", "evolution") var chapter: String = "all"
## Index-matched to `start_demo`'s existing match block, in its existing order. "all" is
## deliberately absent: it is the value that pins nothing.
const CHAPTER_DEMOS: PackedStringArray = ["chaos", "noise", "pattern", "emergence", "evolution"]

## 0 keeps the shipped `randomize()` — a different cloud every visit, which is what all five
## placements have always shown and what the piece is about. Any other value pins the draw,
## so a sweep's frames differ by `chapter` and by nothing else. Set from the registry's
## dna.fixture, never from a map.
@export var scatter_seed: int = 0

# Visual elements
var particles = []
var current_demo: int = 0
var demo_time: float = 0.0
var labels = []

# Text for explanations
var demo_titles = [
	"Pure Randomness - Chaos and Beauty",
	"Perlin Noise - Natural Randomness",
	"Procedural Patterns - Order from Chaos",
	"Emergent Behavior - Simple Rules, Complex Results",
	"Evolutionary Algorithms - Creative Randomness"
]

var demo_descriptions = [
	"""Pure randomness creates unpredictable beauty.
	
	Each particle follows completely random movements, yet patterns emerge to our eyes.
	This is similar to how we see shapes in clouds or stars.
	
	Random systems are essential in nature, art, music, and even security systems.""",
	
	"""Perlin noise creates structured randomness that mimics nature.
	
	Invented by Ken Perlin for the movie Tron, this algorithm creates natural-looking 
	random textures with smooth transitions.
	
	It's used for terrain generation, clouds, fire, and other organic elements in games.""",
	
	"""Procedural patterns combine randomness with mathematical rules.
	
	By applying constraints to random values, we create beautiful organized systems.
	These systems can generate infinite variations while maintaining coherence.
	
	Games use this for endless unique content generation.""",
	
	"""Emergent behavior arises when simple random elements interact.
	
	Each particle follows basic rules with a touch of randomness, yet together they
	create flocking, swarming, and other complex behaviors.
	
	This is how birds flock, fish school, and complex social systems form.""",
	
	"""Evolutionary algorithms use random mutations guided by selection.
	
	Like natural evolution, randomness explores possibilities while selection preserves
	what works. This combination can solve problems in ways humans wouldn't imagine.
	
	This approach produces novel art, music, designs, and engineering solutions."""
]

# Initialize
func _ready() -> void:
	_read_grid_config_meta()
	if scatter_seed != 0:
		seed(scatter_seed)
	else:
		randomize()

	# NOTE: Camera3D, DirectionalLight3D, and WorldEnvironment removed —
	# the grid scene (GridSystem) already provides these. Creating duplicates
	# causes rendering conflicts (multiple active cameras, double lighting).

	# Create particles
	create_particles()

	# Create UI elements for explanations
	create_ui()

	# Start first demo
	start_demo(0)
	# CHAPTER gate. `all` with no legacy forced_demo resolves to -1 and falls straight
	# through, leaving the line above as the whole of _ready's staging and display_time at
	# its shipped 10.0 — the rotation, unchanged. A pinned chapter freezes the clock and
	# stages its own opening, exactly as forced_demo always did.
	var idx: int = _chapter_demo_index()
	if idx >= 0:
		display_time = 1_000_000.0
		demo_time = 0.0
		current_demo = idx
		# Chapter 0 is already the one the line above staged, so pinning it is a FREEZE and
		# not a restart. Re-staging would redraw its hundred positions from a fresh stretch
		# of the stream, and `all` and `chaos` — which are the same picture, because a
		# rotating demo photographed at t=0 is its first chapter — would come back as two
		# different scatters and hand the axis a bite it did not earn.
		if idx != 0:
			start_demo(idx)

# Create particles for visualization
func create_particles() -> void:
	# Common material for particles
	var material = StandardMaterial3D.new()
	material.metallic = 0.7
	material.roughness = 0.1
	
	for i in range(num_particles):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.position = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		
		# Give each particle a slightly different color
		var particle_material = material.duplicate()
		particle_material.albedo_color = Color(randf(), randf(), randf())
		particle.material = particle_material
		
		# Store velocity as metadata
		particle.set_meta("velocity", Vector3.ZERO)
		particle.set_meta("original_color", particle_material.albedo_color)
		
		add_child(particle)
		particles.append(particle)

# Create UI elements
func create_ui() -> void:
	# Create title label
	var title_label = Label3D.new()
	title_label.position = Vector3(0, 3.5, 0)
	title_label.text = demo_titles[0]
	title_label.font_size = 64
	title_label.outline_size = 8
	title_label.modulate = Color(1, 1, 1)
	add_child(title_label)
	labels.append(title_label)
	
	# Create description label
	var desc_label = Label3D.new()
	desc_label.position = Vector3(0, -3.5, 0)
	desc_label.text = demo_descriptions[0]
	desc_label.font_size = 32
	desc_label.width = 800
	desc_label.outline_size = 4
	desc_label.modulate = Color(0.9, 0.9, 1.0)
	add_child(desc_label)
	labels.append(desc_label)
	
	# If narration is enabled, we would add audio here
	if enable_narration:
		# In a real implementation, you would load and play audio narration
		# var audio_player = AudioStreamPlayer.new()
		# audio_player.stream = load("res://narrations/demo_0.wav")
		# add_child(audio_player)
		# audio_player.play()
		pass

# Process frame
func _process(delta: float) -> void:
	demo_time += delta
	
	# Switch demos after display_time
	if demo_time > display_time:
		demo_time = 0
		current_demo = (current_demo + 1) % demo_titles.size()
		start_demo(current_demo)
	
	# Update particles based on current demo
	match current_demo:
		0: update_pure_random(delta)
		1: update_perlin_noise(delta)
		2: update_procedural_patterns(delta)
		3: update_emergent_behavior(delta)
		4: update_evolutionary_algorithms(delta)

# Start a new demonstration
func start_demo(demo_index) -> void:
	# Update labels
	labels[0].text = demo_titles[demo_index]
	labels[1].text = demo_descriptions[demo_index]
	
	# Reset particles
	for i in range(particles.size()):
		var particle = particles[i]
		
		# Reset position with some variation between demos
		match demo_index:
			0: # Pure random - scattered
				particle.position = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
			1: # Perlin noise - grid arrangement
				var x = (i % 20) * 0.5 - 5
				var y = ((i / 20) % 20) * 0.5 - 5
				var z = ((i / 400) % 20) * 0.5 - 5
				particle.position = Vector3(x, y, z)
			2: # Procedural patterns - circular arrangement
				var angle = i * 0.1
				var radius = 5.0 * randf()
				particle.position = Vector3(cos(angle) * radius, sin(angle) * radius, randf_range(-2, 2))
			3: # Emergent behavior - central cluster
				particle.position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
			4: # Evolutionary algorithms - line arrangement
				particle.position = Vector3(i * 0.02 - 5, 0, 0)
		
		# Reset velocity
		particle.set_meta("velocity", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
		
		# Reset color
		var material = particle.material as StandardMaterial3D
		material.albedo_color = particle.get_meta("original_color")
		
		# Reset size
		particle.radius = 0.05

# Update functions for different randomness demonstrations

# Demo 1: Pure randomness
func update_pure_random(delta) -> void:
	for particle in particles:
		# Get current velocity
		var velocity = particle.get_meta("velocity")
		
		# Apply random force
		velocity += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * delta
		
		# Apply damping
		velocity *= 0.99
		
		# Update position
		particle.position += velocity * delta
		
		# Contain particles within bounds
		if particle.position.length() > 7:
			particle.position = particle.position.normalized() * 7
			velocity = velocity.bounce(particle.position.normalized()) * 0.8
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
		
		# Slightly change color based on velocity
		var material = particle.material as StandardMaterial3D
		var speed = velocity.length()
		material.emission = Color(speed * 0.2, speed * 0.1, speed * 0.3)
		material.emission_energy = speed * 0.5

# Demo 2: Perlin noise
func update_perlin_noise(delta) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	
	for particle in particles:
		var pos = particle.position
		
		# Use position and time as input to noise function
		var noise_x = noise3(pos.x * 0.1, pos.y * 0.1, time * 0.1)
		var noise_y = noise3(pos.x * 0.1 + 100, pos.y * 0.1 + 100, time * 0.1)
		var noise_z = noise3(pos.x * 0.1 + 200, pos.y * 0.1 + 200, time * 0.1)
		
		# Create a flowing field effect
		var direction = Vector3(noise_x, noise_y, noise_z).normalized()
		
		# Update position
		particle.position += direction * delta
		
		# Contain particles within bounds
		if particle.position.length() > 7:
			particle.position = particle.position.normalized() * 7
		
		# Color based on position
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			(sin(pos.x * 0.5 + time) + 1) * 0.5,
			(sin(pos.y * 0.5 + time * 1.3) + 1) * 0.5,
			(sin(pos.z * 0.5 + time * 0.7) + 1) * 0.5
		)

# Demo 3: Procedural patterns
func update_procedural_patterns(delta) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = particle.position
		
		# Calculate pattern
		var angle = atan2(pos.y, pos.x)
		var distance = Vector2(pos.x, pos.y).length()
		
		# Create spiral movement
		var spiral_force = Vector3(
			-pos.y / (distance + 0.1),
			pos.x / (distance + 0.1),
			sin(distance - time)
		) * delta
		
		# Add some oscillation
		var oscillation = Vector3(
			sin(time + i * 0.1),
			cos(time * 1.3 + i * 0.1),
			sin(time * 0.7 + i * 0.1)
		) * delta * 0.2
		
		# Apply forces
		particle.position += spiral_force + oscillation
		
		# Color based on position in spiral
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			(sin(angle * 3) + 1) * 0.5,
			(sin(distance * 0.5) + 1) * 0.5,
			(sin(time + distance) + 1) * 0.5
		)
		
		# Size based on pattern
		particle.radius = 0.05 + 0.03 * sin(distance * 2 - time * 2)

# Demo 4: Emergent behavior (flocking/swarming)
func update_emergent_behavior(delta) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	
	# First pass: calculate center and average velocity
	var center = Vector3.ZERO
	var avg_velocity = Vector3.ZERO
	
	for particle in particles:
		center += particle.position
		avg_velocity += particle.get_meta("velocity")
	
	center /= particles.size()
	avg_velocity /= particles.size()
	
	# Second pass: update particles
	for particle in particles:
		var pos = particle.position
		var velocity = particle.get_meta("velocity")
		
		# Rule 1: Separation - avoid others
		var separation = Vector3.ZERO
		for other in particles:
			if other == particle:
				continue
			
			var dist = pos.distance_to(other.position)
			if dist < 0.5:
				separation -= (other.position - pos).normalized() / max(dist, 0.1)
		
		# Rule 2: Alignment - move in same direction as neighbors
		var alignment = avg_velocity - velocity
		
		# Rule 3: Cohesion - move toward center
		var cohesion = center - pos
		
		# Rule 4: Random movement
		var random_force = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		)
		
		# Apply forces with weights
		velocity += separation * 0.05
		velocity += alignment * 0.03
		velocity += cohesion * 0.01
		velocity += random_force * 0.01
		
		# Limit speed
		var speed = velocity.length()
		if speed > 2.0:
			velocity = velocity.normalized() * 2.0
		
		# Update position
		particle.position += velocity * delta
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
		
		# Color based on relation to center
		var distance = pos.distance_to(center)
		var material = particle.material as StandardMaterial3D
		material.albedo_color = Color(
			0.5 + 0.5 * sin(distance * 2),
			0.5 + 0.5 * cos(distance * 2),
			0.5 + 0.5 * sin(time + distance)
		)

# Demo 5: Evolutionary algorithms
func update_evolutionary_algorithms(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	# Fitness function (in this case, proximity to a moving target)
	var target = Vector3(
		3 * sin(time * 0.5),
		2 * cos(time * 0.7),
		sin(time)
	)
	
	# Sort particles by fitness (distance to target)
	particles.sort_custom(func(a, b):
		var dist_a = a.position.distance_to(target)
		var dist_b = b.position.distance_to(target)
		return dist_a < dist_b
	)
	
	# Top 10% are "winners" that influence others
	var winner_count = int(particles.size() * 0.1)
	
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = particle.position
		var velocity = particle.get_meta("velocity")
		
		if i < winner_count:
			# Winners: move directly toward target with slight randomness
			velocity = (target - pos).normalized() * 2.0
			velocity += Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			
			# Winners get a special color
			var material = particle.material as StandardMaterial3D
			material.albedo_color = Color(1.0, 0.8, 0.2)
			material.emission = Color(1.0, 0.8, 0.2)
			material.emission_energy = 0.5
			
			# Winners are slightly bigger
			particle.radius = 0.08
		else:
			# Others: choose a random winner to follow + random mutation
			var winner_idx = randi() % winner_count
			var winner = particles[winner_idx]
			
			# Move toward winner position with randomness (mutation)
			velocity = velocity * 0.9 + (winner.position - pos).normalized() * 0.5
			velocity += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.3
			
			# Color based on how close to being a winner
			var rank_ratio = float(i) / particles.size()
			var material = particle.material as StandardMaterial3D
			material.albedo_color = Color(
				0.2 + 0.8 * (1.0 - rank_ratio),
				0.2 + 0.6 * (1.0 - rank_ratio),
				0.5
			)
			material.emission_energy = 0
			
			# Size based on rank
			particle.radius = 0.05 - 0.02 * rank_ratio
		
		# Apply velocity
		particle.position += velocity * delta
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)
	
	# Visualize the target
	# In a real implementation, you would create a visible target object
	pass

# Utility function to simulate 3D Perlin noise
# (Godot 4 has built-in noise functions, but this is provided as an example)
func noise3(x, y, z):
	return sin(x * 7 + z * 3) * cos(y * 5 + x * 2) * sin(z * 11 + y * 7)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ── CHAPTER ──────────────────────────────────────────────────────────────────────────────
# Appended LAST. Nothing here touches a demo's arrangement, its update rule, its colour law
# or its prose — only which of the five is on the table, and whether the clock runs.

## Which demo index the axis asks for, or -1 for "keep turning the pages".
##
## The legacy `forced_demo` export still wins where a map or scene set it, so nothing that
## already used it changes; `chapter` is the named door onto the same room.
func _chapter_demo_index() -> int:
	var c: String = str(chapter).strip_edges().to_lower()
	var i: int = CHAPTER_DEMOS.find(c)
	if i >= 0:
		return i
	if forced_demo >= 0 and forced_demo < demo_titles.size():
		return forced_demo
	return -1


## The grid sets config_<key> metadata on the instantiated root BEFORE it calls
## apply_grid_config(), so reading it here means the chapter is staged once rather than
## staged as `all` and then restaged. All five existing placements carry no such meta and
## fall straight through.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_chapter"):
			chapter = str(node.get_meta("config_chapter"))
		if node.has_meta("config_scatter_seed"):
			scatter_seed = int(node.get_meta("config_scatter_seed"))
		node = node.get_parent()


## Config from map_data.json tokens:  extreme_randomness#chapter:emergence
##
## GUARDED ON CHANGE. All five existing placements arrive here with no keys at all, and the
## grid reaches this twice for one placement; restaging unguarded would redraw a hundred
## particle positions on both of those, for nothing. Before _ready has run there is nothing
## staged, so the value is only recorded — which is also the path the capture harness takes
## when it sets the export directly.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("scatter_seed"):
		scatter_seed = int(config["scatter_seed"])
	if not config.has("chapter"):
		return
	var want: String = str(config["chapter"]).strip_edges().to_lower()
	if want != "all" and CHAPTER_DEMOS.find(want) < 0:
		return
	if want == chapter:
		return
	chapter = want
	if particles.is_empty():
		return
	var idx: int = _chapter_demo_index()
	if idx < 0:
		display_time = 10.0
		demo_time = 0.0
		current_demo = 0
		start_demo(0)
		return
	display_time = 1_000_000.0
	demo_time = 0.0
	current_demo = idx
	start_demo(idx)
