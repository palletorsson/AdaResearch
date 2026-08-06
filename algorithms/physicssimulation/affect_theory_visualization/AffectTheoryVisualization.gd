extends Node3D

# Affect Theory Visualization
# Emotional response to digital touch and affective transmission

var time := 0.0
var affect_timer := 0.0

# Affect theory concepts
var emotional_bodies := []
var affective_flows := []
var intensity_levels := {}
var touch_responses := []

# ═══════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — individuation × locus (promoted 2026-08-06)
# ═══════════════════════════════════════════════════════════════════════
#
# THIS FILE HAD NO EXPORTS AT ALL. Everything it argues was a constant, and the
# thing it argues hardest was invisible: the six names in the `affects` table
# below — joy, fear, anger, sadness, surprise, disgust — never reach the eye.
# They pick a colour and a motion rule and then stay in the source. What a
# viewer meets is coloured blobs, a bar field and some ripples. Whether that
# reads as a claim about feeling or as a physics demo written with emotional
# variable names is the artifact's own open question, and until now there was no
# way to ask it, because there was only ever one answer on the floor.
#
#   individuation  WHAT AN AFFECT IS TAKEN TO BE, decided at the one place the
#                  six names ever become visible: their colour.
#                    named      six affects, six hues — feeling arrives already
#                               sorted into kinds. Ekman's basic emotions, which
#                               is the picture affect theory exists to argue
#                               with, and it is the picture this file shipped.
#                    intensive  one hue for everything, brightness carrying
#                               intensity alone. Affect as pre-personal
#                               intensity: how much, never which.
#                    valence    two poles, warm and cool, brightness by strength.
#                               The circumplex — feeling reduced to good-or-bad
#                               times how much of it.
#                    unmarked   no colour distinction at all. The renaming
#                               withdrawn, and the simulation left running
#                               underneath it. The deformations still differ,
#                               because the MOTION rule is named too, so this
#                               value asks precisely: without the colour key, is
#                               there anything here you would call an affect?
#
#   locus          WHERE THE PIECE PUTS FEELING. The scene has four displays —
#                  bodies, transmission, an intensity field, touch — parked 8 m
#                  apart on four axes, all drawn at once. They are four
#                  incompatible answers to "where does affect live": in the
#                  subject, between subjects, in an impersonal field, in the
#                  event of contact. Drawn together they are co-asserted and
#                  none of them is argued. Drawn one at a time they are claims.
#
# DEFAULTS ARE THE SHIPPED PIECE. named returns each affect's own Color literal
# untouched, so every material is built from the same three floats as before;
# dispersed draws all four displays exactly as _process always did. THE
# SIMULATION IS NEVER GATED at any value — bodies move, affect transmits, touches
# land and influence their neighbours identically at all twenty combinations.
# Only what is drawn changes.
@export_enum("named", "intensive", "valence", "unmarked") var individuation: String = "named"
@export_enum("dispersed", "bodies", "between", "field", "touch") var locus: String = "dispersed"

const INDIVIDUATIONS: PackedStringArray = ["named", "intensive", "valence", "unmarked"]
const LOCI: PackedStringArray = ["dispersed", "bodies", "between", "field", "touch"]

## The single hue `intensive` paints everything. Arbitrary ON PURPOSE: the whole
## claim of that value is that nothing here is distinguished by kind, so no hue
## can be the right one for any particular affect.
const INTENSIVE_HUE: Color = Color(0.95, 0.55, 0.35)
const VALENCE_WARM: Color = Color(1.0, 0.72, 0.25)
const VALENCE_COOL: Color = Color(0.30, 0.50, 0.90)
const UNMARKED_GREY: Color = Color(0.72, 0.72, 0.74)
## Which of the six a valence reading calls positive. Kept OUT of the affects
## table on purpose — the table is this artifact's own six, and valence is a
## reading imposed on them from outside, so it is written down separately.
const POSITIVE_AFFECTS: PackedStringArray = ["joy", "surprise"]

## Bench knobs, NOT axes. 0 leaves the RNG alone, which is the shipped file:
## initialize_emotional_bodies picks six positions, six sizes, six
## responsivenesses and six permeabilities with randf_range, so unseeded variants
## are six different crowds and any difference measured between them is the RNG.
@export var rng_seed: int = 0
## See _build_capture_anchor. OFF by default: the shipped scene has no
## MeshInstance3D in it anywhere and this adds one.
@export var capture_anchor: bool = false

## Derived from the scene, not guessed. Bodies hang off the $EmotionalBodies
## container at (-8,0,0) with positions clamped to x,z in [-5,5] and y in
## [0.5,8]; $AffectiveTransmission at (8,0,0) draws between those same
## coordinates; the pillar grid under $IntensityFlows at (0,8,0) spans [-5,4]
## with pillars up to 4 m tall; $DigitalTouch at (0,-8,0) starts ripples inside
## [-4,4] and grows them a 6 m radius.
const ANCHOR_CENTRE: Vector3 = Vector3(0.0, 2.0, 0.0)
const ANCHOR_SIZE: Vector3 = Vector3(26.0, 20.0, 20.0)

# Emotional states based on affect theory
var affects = [
	{"name": "joy", "intensity": 0.5, "transmission": 0.8, "color": Color(1.0, 0.8, 0.2)},
	{"name": "fear", "intensity": 0.3, "transmission": 0.6, "color": Color(0.8, 0.2, 0.8)},
	{"name": "anger", "intensity": 0.7, "transmission": 0.9, "color": Color(1.0, 0.2, 0.2)},
	{"name": "sadness", "intensity": 0.4, "transmission": 0.3, "color": Color(0.2, 0.4, 0.8)},
	{"name": "surprise", "intensity": 0.9, "transmission": 0.7, "color": Color(0.9, 0.9, 0.2)},
	{"name": "disgust", "intensity": 0.6, "transmission": 0.4, "color": Color(0.4, 0.8, 0.2)}
]

class EmotionalBody:
	var position: Vector3
	var velocity: Vector3
	var current_affect: Dictionary
	var affect_history: Array
	var responsiveness: float
	var boundary_permeability: float
	var size: float

class AffectiveFlow:
	var source: Vector3
	var target: Vector3
	var intensity: float
	var affect_type: String
	var flow_speed: float
	var particles: Array

class TouchResponse:
	var position: Vector3
	var affect_type: String
	var intensity: float
	var ripple_radius: float
	var age: float

func _ready() -> void:
	# 0 is the shipped file and never touches the RNG.
	if rng_seed != 0:
		seed(rng_seed)
	initialize_emotional_bodies()
	initialize_affective_system()
	if capture_anchor:
		_build_capture_anchor()


## `individuation` — the one function where the six names become something you
## can see. `named` returns each affect's own Color literal untouched, so every
## material downstream is built from exactly the floats it was built from before.
func _affect_color(affect: Dictionary) -> Color:
	var base: Color = affect.get("color", Color.WHITE)
	match individuation:
		"intensive":
			var lit: float = 0.35 + 0.65 * clamp(float(affect.get("intensity", 0.5)), 0.0, 1.0)
			# Alpha is rebuilt at 1.0 rather than scaled: three of the five callers
			# hand this straight to albedo_color with no transparency flag set, and
			# a fourth overwrites the alpha anyway. Scaling it would be a value
			# nothing reads today and a bug the first time something does.
			return Color(INTENSIVE_HUE.r * lit, INTENSIVE_HUE.g * lit, INTENSIVE_HUE.b * lit, 1.0)
		"valence":
			var pole: Color = VALENCE_COOL
			if POSITIVE_AFFECTS.has(str(affect.get("name", ""))):
				pole = VALENCE_WARM
			var strength: float = 0.40 + 0.60 * clamp(float(affect.get("intensity", 0.5)), 0.0, 1.0)
			return Color(pole.r * strength, pole.g * strength, pole.b * strength, 1.0)
		"unmarked":
			return UNMARKED_GREY
	return base


## `locus` — which claim about where affect lives is on show. Drawing only: every
## caller of this still runs its simulation first, so the bodies move, the flows
## advance and the touches influence their neighbours at every value.
func _shows(part: String) -> bool:
	return locus == "dispersed" or locus == part


## A capture bench cannot see this artifact at all, and that is a fact about the
## BENCH rather than the work: every body, particle, pillar and ripple here is a
## CSGShape3D, and the AABB pass counts MeshInstance3D and MultiMeshInstance3D
## only. Finding neither it falls back to a 1 m box at the origin — and there is
## nothing at the origin, because all four displays are parked 8 m out. It would
## photograph empty air and score the axis dead.
##
## So: one BoxMesh on layers = 0, rendered by no camera, measured by the walk,
## sized from the container offsets and the clamps in apply_emotional_physics.
## OFF by default, because a 26 m mesh would also change what the grid's
## auto-grounding measures for the 3 existing placements.
func _build_capture_anchor() -> void:
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var box := BoxMesh.new()
	box.size = ANCHOR_SIZE
	anchor.mesh = box
	anchor.layers = 0
	anchor.position = ANCHOR_CENTRE
	add_child(anchor)

func _process(delta: float) -> void:
	time += delta
	affect_timer += delta
	
	update_emotional_states()
	simulate_emotional_bodies()
	visualize_affective_transmission()
	demonstrate_intensity_flows()
	show_digital_touch_responses()

func initialize_emotional_bodies() -> void:
	# Create emotional bodies with different affective capacities
	for i in range(6):
		var body = EmotionalBody.new()
		body.position = Vector3(
			randf_range(-3, 3),
			randf_range(1, 5),
			randf_range(-3, 3)
		)
		body.velocity = Vector3.ZERO
		body.current_affect = affects[i % affects.size()].duplicate()
		body.affect_history = []
		body.responsiveness = randf_range(0.3, 1.0)
		body.boundary_permeability = randf_range(0.4, 0.9)
		body.size = randf_range(0.8, 1.5)
		
		emotional_bodies.append(body)

func initialize_affective_system() -> void:
	# Initialize intensity tracking for different affects
	for affect in affects:
		intensity_levels[affect.name] = {"current": affect.intensity, "target": affect.intensity}

func update_emotional_states() -> void:
	# Update affect intensities over time
	for affect_name in intensity_levels:
		var level = intensity_levels[affect_name]
		
		# Add some temporal variation
		level.target = clamp(
			level.target + sin(time * 0.5 + affects.find(func(a): return a.name == affect_name)) * 0.1,
			0.0, 1.0
		)
		
		# Smooth interpolation towards target
		level.current = lerp(level.current, level.target, 0.1)

func simulate_emotional_bodies() -> void:
	var container = $EmotionalBodies
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	for i in range(emotional_bodies.size()):
		var body = emotional_bodies[i]
		
		# Update emotional state based on proximity to other bodies
		update_affective_influence(body, i)
		
		# Apply soft body physics with emotional modulation
		apply_emotional_physics(body)

		# Visualize emotional body — the only gated line. The two calls above are
		# the simulation and run at every value of `locus`.
		if _shows("bodies"):
			create_emotional_body_visualization(container, body, i)

func update_affective_influence(body: EmotionalBody, body_index: int) -> void:
	# Affect transmission between bodies
	for j in range(emotional_bodies.size()):
		if j == body_index:
			continue
		
		var other_body = emotional_bodies[j]
		var distance = body.position.distance_to(other_body.position)
		
		if distance < 4.0:
			# Calculate affective influence
			var influence_strength = (4.0 - distance) / 4.0
			influence_strength *= other_body.current_affect.transmission
			influence_strength *= body.boundary_permeability
			
			# Transmit affect
			var intensity_change = influence_strength * 0.1
			body.current_affect.intensity = lerp(
				body.current_affect.intensity,
				other_body.current_affect.intensity,
				intensity_change
			)
			
			# Create affective flow
			if randf() < 0.05:
				create_affective_flow(other_body.position, body.position, other_body.current_affect.name)

func apply_emotional_physics(body: EmotionalBody) -> void:
	# Emotional state affects physical behavior
	var emotional_force = Vector3.ZERO
	
	# Different affects create different movement patterns
	match body.current_affect.name:
		"joy":
			emotional_force += Vector3(0, sin(time * 3) * 2.0, 0)  # Bouncy movement
		"fear":
			emotional_force += Vector3(
				cos(time * 5) * 1.5,
				0,
				sin(time * 5) * 1.5
			)  # Erratic movement
		"anger":
			emotional_force += Vector3(
				sin(time * 2) * 3.0,
				0,
				cos(time * 2) * 3.0
			)  # Aggressive movement
		"sadness":
			emotional_force += Vector3(0, -1.0, 0)  # Downward tendency
		"surprise":
			if fmod(time, 3.0) < 0.1:
				emotional_force += Vector3(
					randf_range(-5, 5),
					randf_range(0, 5),
					randf_range(-5, 5)
				)  # Sudden bursts
		"disgust":
			# Avoidance behavior - move away from others
			for other_body in emotional_bodies:
				if other_body != body:
					var distance_vec = body.position - other_body.position
					var distance = distance_vec.length()
					if distance < 3.0:
						emotional_force += distance_vec.normalized() * (3.0 - distance)
	
	# Apply emotional modulation
	emotional_force *= body.current_affect.intensity * body.responsiveness
	
	# Update physics
	body.velocity += emotional_force * get_process_delta_time() * 0.1
	body.velocity *= 0.95  # Damping
	body.position += body.velocity * get_process_delta_time()
	
	# Boundary constraints
	body.position.x = clamp(body.position.x, -5, 5)
	body.position.y = clamp(body.position.y, 0.5, 8)
	body.position.z = clamp(body.position.z, -5, 5)

func create_affective_flow(source: Vector3, target: Vector3, affect_type: String) -> void:
	var flow = AffectiveFlow.new()
	flow.source = source
	flow.target = target
	flow.affect_type = affect_type
	flow.intensity = randf_range(0.3, 1.0)
	flow.flow_speed = randf_range(1.0, 3.0)
	flow.particles = []
	
	# Create flow particles
	for i in range(8):
		flow.particles.append({
			"position": source,
			"progress": float(i) / 8.0,
			"size": randf_range(0.1, 0.3)
		})
	
	affective_flows.append(flow)

func create_emotional_body_visualization(container: Node3D, body: EmotionalBody, index: int) -> void:
	# Create soft, deformable emotional body
	var body_sphere = CSGSphere3D.new()
	
	# Size affected by emotional intensity
	var size_modulation = 1.0 + body.current_affect.intensity * 0.5
	body_sphere.radius = body.size * size_modulation
	body_sphere.position = body.position

	# Apply emotional deformation. NOT gated by `individuation`: the motion rule
	# is named too, and `unmarked` is the question "is the behaviour alone legible
	# as affect", which is only a question if the behaviour survives.
	var deformation = get_emotional_deformation(body.current_affect.name, index)
	body_sphere.scale = deformation

	var col: Color = _affect_color(body.current_affect)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(col.r, col.g, col.b, 0.7)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = col * body.current_affect.intensity * 0.6
	material.metallic = 0.1
	material.roughness = 0.8
	body_sphere.material_override = material

	container.add_child(body_sphere)

	# Add affect label (small indicator)
	var affect_indicator = CSGBox3D.new()
	affect_indicator.size = Vector3(0.2, 0.2, 0.2)
	affect_indicator.position = body.position + Vector3(0, body.size + 0.5, 0)

	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = col
	indicator_material.emission_enabled = true
	indicator_material.emission = col * 0.8
	affect_indicator.material_override = indicator_material
	
	container.add_child(affect_indicator)

func get_emotional_deformation(affect_name: String, index: int) -> Vector3:
	# Different affects create different body deformations
	var base_scale = Vector3.ONE
	
	match affect_name:
		"joy":
			return base_scale + Vector3(
				sin(time * 4 + index) * 0.2,
				cos(time * 3 + index) * 0.3,
				sin(time * 5 + index) * 0.2
			)
		"fear":
			return base_scale + Vector3(
				sin(time * 8 + index) * 0.4,
				sin(time * 10 + index) * 0.3,
				sin(time * 6 + index) * 0.4
			)
		"anger":
			return base_scale + Vector3(
				1.0 + sin(time * 2 + index) * 0.5,
				0.8,
				1.0 + cos(time * 2 + index) * 0.5
			)
		"sadness":
			return Vector3(1.2, 0.6 + sin(time * 1 + index) * 0.2, 1.2)
		"surprise":
			var burst_factor = 1.0
			if fmod(time + index, 2.0) < 0.2:
				burst_factor = 1.5
			return base_scale * burst_factor
		"disgust":
			return Vector3(
				0.8 + sin(time * 3 + index) * 0.1,
				1.0,
				0.8 + cos(time * 3 + index) * 0.1
			)
		_:
			return base_scale

func visualize_affective_transmission() -> void:
	var container = $AffectiveTransmission
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update and visualize affective flows
	var i = 0
	while i < affective_flows.size():
		var flow = affective_flows[i]
		
		# Update flow particles
		var all_particles_reached = true
		for particle in flow.particles:
			particle.progress += flow.flow_speed * get_process_delta_time() * 0.5
			if particle.progress < 1.0:
				all_particles_reached = false
			
			particle.position = flow.source.lerp(flow.target, particle.progress)
			
			# Visualize particle. The progress integration above is the simulation
			# and is never gated; only this drawing is.
			if particle.progress < 1.0 and _shows("between"):
				var particle_sphere = CSGSphere3D.new()
				particle_sphere.radius = particle.size
				particle_sphere.position = particle.position

				var affect_data = affects.filter(func(a): return a.name == flow.affect_type)[0]
				var col: Color = _affect_color(affect_data)
				var material = StandardMaterial3D.new()
				material.albedo_color = col
				material.emission_enabled = true
				material.emission = col * flow.intensity
				particle_sphere.material_override = material

				container.add_child(particle_sphere)
		
		# Remove completed flows
		if all_particles_reached:
			affective_flows.remove_at(i)
		else:
			i += 1

func demonstrate_intensity_flows() -> void:
	var container = $IntensityFlows
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()

	# The clear above still runs at every value, so switching `locus` away from
	# the field leaves no stale pillars standing.
	if not _shows("field"):
		return

	# Create intensity field visualization
	var grid_size = 10
	for i in range(grid_size):
		for j in range(grid_size):
			var pos = Vector3(
				i - grid_size * 0.5,
				0,
				j - grid_size * 0.5
			)
			
			# Calculate combined intensity at this position
			var total_intensity = 0.0
			var dominant_affect = affects[0]
			
			for body in emotional_bodies:
				var distance = pos.distance_to(Vector3(body.position.x, 0, body.position.z))
				var influence = body.current_affect.intensity / (distance + 1.0)
				
				if influence > total_intensity:
					total_intensity = influence
					dominant_affect = body.current_affect
			
			total_intensity = clamp(total_intensity, 0.0, 1.0)
			
			if total_intensity > 0.1:
				var intensity_pillar = CSGBox3D.new()
				intensity_pillar.size = Vector3(0.4, total_intensity * 4.0, 0.4)
				intensity_pillar.position = pos + Vector3(0, intensity_pillar.size.y * 0.5, 0)
				
				var pillar_col: Color = _affect_color(dominant_affect)
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(
					pillar_col.r,
					pillar_col.g,
					pillar_col.b,
					0.6
				)
				material.flags_transparent = true
				material.emission_enabled = true
				material.emission = pillar_col * total_intensity * 0.4
				intensity_pillar.material_override = material
				
				container.add_child(intensity_pillar)

func show_digital_touch_responses() -> void:
	var container = $DigitalTouch
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Generate touch events
	if affect_timer > 0.5:
		affect_timer = 0.0
		create_touch_response()
	
	# Update and visualize touch responses
	var i = 0
	while i < touch_responses.size():
		var response = touch_responses[i]
		response.age += get_process_delta_time()
		response.ripple_radius += 2.0 * get_process_delta_time()
		
		if response.age > 3.0:
			touch_responses.remove_at(i)
			continue

		# The ageing above is the simulation and runs at every value of `locus`;
		# only the ripple and the haptic sphere below are gated.
		if not _shows("touch"):
			i += 1
			continue
		
		# Create ripple effect
		var ripple = CSGCylinder3D.new()
		ripple.radius = response.ripple_radius + 0.3
		ripple.height = 0.1
		ripple.position = response.position
		
		var affect_data = affects.filter(func(a): return a.name == response.affect_type)[0]
		var touch_col: Color = _affect_color(affect_data)
		var material = StandardMaterial3D.new()
		var alpha = (1.0 - response.age / 3.0) * response.intensity
		material.albedo_color = Color(
			touch_col.r,
			touch_col.g,
			touch_col.b,
			alpha * 0.4
		)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = touch_col * alpha * 0.6
		ripple.material_override = material
		
		container.add_child(ripple)
		
		# Create haptic feedback visualization
		var haptic_sphere = CSGSphere3D.new()
		haptic_sphere.radius = 0.3 * response.intensity * (1.0 - response.age / 3.0)
		haptic_sphere.position = response.position + Vector3(0, sin(response.age * 5) * 0.5, 0)
		
		var haptic_material = StandardMaterial3D.new()
		haptic_material.albedo_color = touch_col
		haptic_material.emission_enabled = true
		haptic_material.emission = touch_col * alpha
		haptic_sphere.material_override = haptic_material
		
		container.add_child(haptic_sphere)
		
		i += 1

func create_touch_response() -> void:
	var response = TouchResponse.new()
	response.position = Vector3(
		randf_range(-4, 4),
		1,
		randf_range(-4, 4)
	)
	response.affect_type = affects[randi() % affects.size()].name
	response.intensity = randf_range(0.3, 1.0)
	response.ripple_radius = 0.1
	response.age = 0.0
	
	touch_responses.append(response)
	
	# Influence nearby emotional bodies
	for body in emotional_bodies:
		var distance = response.position.distance_to(body.position)
		if distance < 2.0:
			var influence = (2.0 - distance) / 2.0 * response.intensity
			body.current_affect.intensity = clamp(
				body.current_affect.intensity + influence * 0.2,
				0.0, 1.0
			)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map tokens: "affect_theory_visualization#individuation:unmarked",
## "affect_theory_visualization#locus:field".
##
## THERE IS NOTHING TO REBUILD HERE, and that is not laziness. _process frees
## every child of all four containers and builds them again from scratch on every
## single frame, so a value set at any moment is on screen at the next one. The
## trap this loop has fallen into before — force_pad tearing down eight
## placements on a call that named nothing it owned — cannot arise, because there
## is no teardown to schedule. A word the code cannot build is refused rather
## than accepted and silently rendered as the default.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("individuation"):
		var want: String = str(config["individuation"]).strip_edges().to_lower()
		if INDIVIDUATIONS.has(want):
			individuation = want
		elif want != "":
			push_warning("affect_theory_visualization: unknown individuation '%s' — keeping '%s'"
				% [want, individuation])

	if config.has("locus"):
		var want_locus: String = str(config["locus"]).strip_edges().to_lower()
		if LOCI.has(want_locus):
			locus = want_locus
		elif want_locus != "":
			push_warning("affect_theory_visualization: unknown locus '%s' — keeping '%s'"
				% [want_locus, locus])

	if config.has("rng_seed"):
		rng_seed = int(config["rng_seed"])
