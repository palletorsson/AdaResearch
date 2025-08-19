# event_system.gd
class_name EventSystem
extends Node

signal event_triggered(event_type, entities, parameters)
signal celebration_started(location, intensity, participants)
signal challenge_issued(type, difficulty, target_entities)
signal transformation_occurred(entities, catalyst, intensity)

# Configuration
@export_category("Event System Parameters")
@export var random_event_probability: float = 0.02
@export var entropy_influence: float = 1.0
@export var min_time_between_events: float = 60.0  # seconds
@export var enable_narrative_events: bool = true
@export var event_radius: float = 20.0
@export var max_entities_per_event: int = 12

# Event tracking
var active_events: Array = []
var past_events: Array = []
var time_since_last_event: float = 0.0
var current_entropy: float = 0.0
var current_narrative_arc: String = "exploration"
var narrative_progress: float = 0.0

# Event catalogues
var celebration_events = [
	"convergence", "emergence", "flowering", "resonance", "coalescence", 
	"symmetry_breaking", "affinity_surge", "essence_bloom", "harmonic_alignment"
]

var challenge_events = [
	"boundary_test", "entropy_spike", "resource_scarcity", "territory_dispute",
	"identity_crisis", "form_instability", "trait_conflict", "system_perturbation"
]

var transformation_events = [
	"morphic_resonance", "quantum_shift", "collective_evolution", "phase_transition",
	"dimensional_fold", "emergent_pattern", "entropy_cascade", "boundary_dissolution"
]

var narrative_arcs = [
	"exploration", "tension", "convergence", "transformation", "emergence"
]

func _ready():
	randomize()

func trigger_event(event_type: String, affected_entities = null, parameters = null):
	# Basic validation
	if event_type.is_empty():
		return
	
	# Default parameters
	if parameters == null:
		parameters = {}
	
	# Default entities array if not provided
	if affected_entities == null:
		affected_entities = []
	
	# Create event record
	var event = {
		"type": event_type,
		"time": Time.get_ticks_msec(),
		"entities": affected_entities,
		"parameters": parameters,
		"active": true
	}
	
	# Handle different event types
	match event_type:
		"celebration":
			_handle_celebration_event(event)
		"challenge":
			_handle_challenge_event(event)
		"transformation":
			_handle_transformation_event(event)
		"season_change":
			_handle_season_change_event(event)
		"boundary_transcended":
			_handle_boundary_event(event)
		"convergence", "emergence", "resonance":
			_handle_special_event(event)
		_:
			# Generic event handling
			pass
	
	# Add to active events
	active_events.append(event)
	
	# Reset timer for random events
	time_since_last_event = 0.0
	
	# Emit signal
	emit_signal("event_triggered", event_type, affected_entities, parameters)

func consider_random_event(current_day: int, available_entities: Array, environment: Object = null):
	# Check if it's too soon for another random event
	if time_since_last_event < min_time_between_events:
		return
	
	# Base probability adjusted by entropy
	var adjusted_probability = random_event_probability * (1.0 + current_entropy * entropy_influence)
	
	# Random chance to trigger event
	if randf() < adjusted_probability:
		# Determine event type
		var event_type = _determine_random_event_type(current_day)
		
		# Select entities to be affected
		var affected_entities = _select_entities_for_event(event_type, available_entities)
		
		# Determine location and parameters
		var parameters = _generate_event_parameters(event_type, affected_entities, environment)
		
		# Trigger the event
		trigger_event(event_type, affected_entities, parameters)
		
		return true
	
	return false

func update(delta: float):
	# Update time since last event
	time_since_last_event += delta
	
	# Update active events
	for event in active_events.duplicate():  # Duplicate to safely modify during iteration
		# Update event duration if applicable
		if event.has("duration"):
			event.duration -= delta
			
			if event.duration <= 0:
				# Event has ended
				event.active = false
				
				# Move to past events
				active_events.erase(event)
				past_events.append(event)
		
		# Check for event completion if it has a condition
		if event.has("completion_condition") and event.completion_condition.call():
			# Event has been completed
			event.active = false
			event.completed = true
			
			# Move to past events
			active_events.erase(event)
			past_events.append(event)

func set_entropy(value: float):
	current_entropy = clamp(value, 0.0, 1.0)

func _determine_random_event_type(current_day: int) -> String:
	# Event probabilities adjusted by entropy and narrative arc
	var celebration_chance = 0.4 - current_entropy * 0.2
	var challenge_chance = 0.3 + current_entropy * 0.2
	var transformation_chance = 0.2 + current_entropy * 0.3
	
	# Adjust based on narrative arc
	match current_narrative_arc:
		"exploration":
			celebration_chance *= 1.5
			challenge_chance *= 0.7
		"tension":
			celebration_chance *= 0.7
			challenge_chance *= 1.5
		"convergence":
			celebration_chance *= 1.2
			transformation_chance *= 1.2
		"transformation":
			transformation_chance *= 2.0
		"emergence":
			transformation_chance *= 1.5
			celebration_chance *= 1.2
	
	# Normalize probabilities
	var total = celebration_chance + challenge_chance + transformation_chance
	celebration_chance /= total
	challenge_chance /= total
	transformation_chance /= total
	
	# Choose event category
	var roll = randf()
	var event_category: String
	
	if roll < celebration_chance:
		event_category = "celebration"
	elif roll < celebration_chance + challenge_chance:
		event_category = "challenge"
	else:
		event_category = "transformation"
	
	# Choose specific event from category
	var specific_event: String
	
	match event_category:
		"celebration":
			specific_event = celebration_events[randi() % celebration_events.size()]
		"challenge":
			specific_event = challenge_events[randi() % challenge_events.size()]
		"transformation":
			specific_event = transformation_events[randi() % transformation_events.size()]
	
	return specific_event

func _select_entities_for_event(event_type: String, available_entities: Array) -> Array:
	# Ensure we have entities to work with
	if available_entities.size() == 0:
		return []
	
	# Sort entities by suitability for this event type
	var sorted_entities = available_entities.duplicate()
	
	# Apply sorting based on event type
	# In a full implementation, this would evaluate entity traits
	# For this simplified version, we'll just randomize
	sorted_entities.shuffle()
	
	# Different event types affect different numbers of entities
	var count = 1
	
	match event_type:
		# Celebrations often involve multiple entities
		"convergence", "resonance", "harmonic_alignment":
			count = int(max(3, min(available_entities.size() * 0.3, max_entities_per_event)))
		
		# Transformations can be individual or small groups
		"morphic_resonance", "quantum_shift", "phase_transition":
			count = int(max(1, min(available_entities.size() * 0.2, 5)))
		
		# Challenges can target individuals or larger groups
		"boundary_test", "identity_crisis":
			count = int(max(1, min(available_entities.size() * 0.15, 3)))
		
		"entropy_spike", "resource_scarcity":
			count = int(max(2, min(available_entities.size() * 0.4, max_entities_per_event)))
		
		# Default to small group
		_:
			count = int(max(1, min(available_entities.size() * 0.2, 4)))
	
	# Return the selected entities
	return sorted_entities.slice(0, count)

func _generate_event_parameters(event_type: String, affected_entities: Array, environment: Object) -> Dictionary:
	var parameters = {}
	
	# Basic parameters common to all events
	parameters.intensity = randf_range(0.3, 0.8) + current_entropy * 0.2
	parameters.duration = randf_range(20, 60)  # seconds
	
	# Determine event location
	var location = Vector3.ZERO
	
	if affected_entities.size() > 0:
		# Center location on average position of affected entities
		for entity in affected_entities:
			location += entity.global_position
		
		location /= affected_entities.size()
	elif environment:
		# Random location within environment
		var env_size = environment.get_environment_size()
		location = Vector3(
			randf_range(-env_size.x/2, env_size.x/2),
			randf_range(1, 5),
			randf_range(-env_size.z/2, env_size.z/2)
		)
	
	parameters.location = location
	
	# Event-specific parameters
	match event_type:
		# Celebration events
		"convergence", "resonance", "coalescence":
			parameters.radius = event_radius * (0.8 + current_entropy * 0.4)
			parameters.energy_boost = 0.2 + current_entropy * 0.1
			parameters.connection_strength = 0.5 + current_entropy * 0.3
		
		# Challenge events
		"boundary_test", "entropy_spike", "resource_scarcity":
			parameters.difficulty = 0.4 + current_entropy * 0.3
			parameters.reward_factor = 0.5 + parameters.difficulty * 0.5
			parameters.adaptation_requirement = 0.3 + current_entropy * 0.4
		
		# Transformation events
		"morphic_resonance", "quantum_shift", "phase_transition":
			parameters.transformation_magnitude = 0.4 + current_entropy * 0.5
			parameters.stability_factor = max(0.2, 0.8 - current_entropy * 0.6)
			parameters.trait_influence = 0.3 + current_entropy * 0.4
	
	return parameters

func _handle_celebration_event(event: Dictionary):
	# Special handling for celebration events
	var intensity = event.parameters.intensity
	var location = event.parameters.location
	var entities = event.entities
	
	# Emit celebration signal
	emit_signal("celebration_started", location, intensity, entities)
	
	# In a full implementation, this would create visual effects,
	# gameplay changes, etc.

func _handle_challenge_event(event: Dictionary):
	# Special handling for challenge events
	var difficulty = event.parameters.difficulty
	var event_type = event.type
	var entities = event.entities
	
	# Emit challenge signal
	emit_signal("challenge_issued", event_type, difficulty, entities)
	
	# In a full implementation, this would create challenges for
	# the affected entities to overcome

func _handle_transformation_event(event: Dictionary):
	# Special handling for transformation events
	var magnitude = event.parameters.transformation_magnitude
	var entities = event.entities
	
	# Emit transformation signal
	emit_signal("transformation_occurred", entities, event.type, magnitude)
	
	# In a full implementation, this would trigger actual changes
	# to the affected entities

func _handle_season_change_event(event: Dictionary):
	# Special handling for season change
	var season = event.parameters.season if event.parameters.has("season") else 0
	
	# Different effects based on season
	match season:
		0:  # Spring
			# Rebirth and growth
			event.parameters.growth_factor = 1.5
			event.parameters.energy_boost = 0.3
		1:  # Summer
			# Abundance and activity
			event.parameters.energy_boost = 0.5
			event.parameters.connection_strength = 0.3
		2:  # Autumn
			# Change and preparation
			event.parameters.adaptation_bonus = 0.3
			event.parameters.resource_efficiency = 0.2
		3:  # Winter
			# Conservation and reflection
			event.parameters.stability_factor = 0.4
			event.parameters.energy_conservation = 0.3

func _handle_boundary_event(event: Dictionary):
	# Handle an entity transcending a boundary
	var entity = event.entities[0] if event.entities.size() > 0 else null
	var boundary_type = event.parameters.boundary_type if event.parameters.has("boundary_type") else "unknown"
	
	if entity == null:
		return
	
	# Apply effects based on boundary type
	match boundary_type:
		"physical":
			event.parameters.mobility_boost = 0.2
			event.parameters.transformation_chance = 0.4
		"relational":
			event.parameters.connection_boost = 0.3
			event.parameters.social_radius = 2.0
		"cognitive":
			event.parameters.adaptation_boost = 0.25
			event.parameters.entropy_tolerance = 0.2
		"expressive":
			event.parameters.expressiveness_boost = 0.3
			event.parameters.uniqueness_boost = 0.2

func _handle_special_event(event: Dictionary):
	# Handle special one-off events
	
	# In a full implementation, this would have unique logic for
	# each special event type
	
	# For now, just add a special flag
	event.parameters.is_special = true

func advance_narrative_arc():
	# Move to the next narrative arc
	var current_index = narrative_arcs.find(current_narrative_arc)
	current_index = (current_index + 1) % narrative_arcs.size()
	current_narrative_arc = narrative_arcs[current_index]
	narrative_progress = 0.0
	
	print("Narrative arc advanced to: " + current_narrative_arc)

func get_active_events() -> Array:
	return active_events.duplicate()

func get_past_events(count: int = -1) -> Array:
	if count <= 0 or count > past_events.size():
		return past_events.duplicate()
	else:
		# Return most recent events
		return past_events.slice(past_events.size() - count, past_events.size())

func is_entity_in_active_event(entity: Object) -> bool:
	for event in active_events:
		if event.entities.has(entity):
			return true
	return false
