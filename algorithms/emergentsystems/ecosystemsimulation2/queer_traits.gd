# queer_traits.gd
class_name QueerTraits
extends Resource

# Core traits (all on 0.0-1.0 scale)
var fluidity: float = 0.5        # Ability to transform/change
var expressiveness: float = 0.5  # Visual and behavioral expressiveness
var sociality: float = 0.5       # Desire for connection and relationships
var boundary_pushing: float = 0.5 # Tendency to challenge norms/boundaries
var uniqueness: float = 0.5      # Tendency toward unique traits/appearance
var adaptability: float = 0.5    # How quickly entity adapts to changes
var resilience: float = 0.5      # Ability to recover from adversity

# Physical/survival traits
var metabolism: float = 0.5      # Energy consumption rate
var longevity: float = 0.5       # Lifespan multiplier
var mobility: float = 0.5        # Movement speed and agility
var fertility: float = 0.5       # Likelihood of reproduction
var resource_value: float = 0.5  # How much resources entity returns to ecosystem on expiry
var sensory_range: float = 0.5   # How far the entity can sense resources and others

# Spectrum positions (not binary - these are points on continuous spectra)
var spectra: Dictionary = {
	"material_immaterial": 0.5,    # Physical materiality vs ethereal qualities
	"individual_collective": 0.5,  # Individual autonomy vs collective integration
	"order_chaos": 0.5,           # Structured patterns vs entropic tendencies
	"known_unknown": 0.5,         # Familiar traits vs novel emerging properties
	"visible_invisible": 0.5,     # Overt presence vs subtle, hidden influence
	"stable_evolving": 0.5        # Consistent identity vs perpetual becoming
}

# Morphological tendencies
var morphology: Dictionary = {
	"organic_geometric": 0.5,     # Natural/organic forms vs geometric structures  
	"unified_multiple": 0.5,      # Single cohesive form vs multiple components
	"symmetry_asymmetry": 0.5,    # Balanced symmetry vs asymmetrical design
	"solid_permeable": 0.5,       # Defined boundaries vs permeable/fluid boundaries
	"simple_complex": 0.5,        # Minimal structure vs intricate detail
	"stable_ephemeral": 0.5       # Persistent form vs temporary/shifting form
}

# Tendencies that influence interaction and behavior
var tendencies: Dictionary = {
	"giving_receiving": 0.5,      # Tendency to give vs receive resources
	"exploring_nesting": 0.5,     # Tendency to explore vs create stable spaces
	"solo_communal": 0.5,         # Preference for solitude vs group activities
	"consistency_novelty": 0.5,   # Preference for familiar vs new experiences
	"preservation_transformation": 0.5, # Tendency to maintain vs change
	"concrete_abstract": 0.5      # Orientation toward tangible vs conceptual
}

# Color and aesthetic preferences
var aesthetics: Dictionary = {
	"primary_color": Color(1, 1, 1),
	"secondary_color": Color(0.5, 0.5, 0.5),
	"texture_pattern": 0.5,      # Smooth vs textured
	"luminosity": 0.5,           # Dark vs bright
	"translucency": 0.5          # Opaque vs transparent
}

# Memory of past states/forms
var memory_states: Array = []
var form_history: Array = []

# Initialize with random traits
func _init():
	memory_states = []
	form_history = []

# Randomize all traits
func randomize_traits():
	# Core traits
	fluidity = randf()
	expressiveness = randf()
	sociality = randf()
	boundary_pushing = randf()
	uniqueness = randf()
	adaptability = randf()
	resilience = randf()
	
	# Physical/survival traits
	metabolism = randf()
	longevity = randf()
	mobility = randf()
	fertility = randf()
	resource_value = randf()
	sensory_range = randf()
	
	# Randomize all spectra
	for key in spectra.keys():
		spectra[key] = randf()
	
	# Randomize morphology
	for key in morphology.keys():
		morphology[key] = randf()
	
	# Randomize tendencies
	for key in tendencies.keys():
		tendencies[key] = randf()
	
	# Randomize aesthetics
	aesthetics["primary_color"] = Color(randf(), randf(), randf())
	aesthetics["secondary_color"] = Color(randf(), randf(), randf())
	aesthetics["texture_pattern"] = randf()
	aesthetics["luminosity"] = randf()
	aesthetics["translucency"] = randf()

# Get a single trait by name
func get_trait(trait_name: String) -> float:
	match trait_name:
		"fluidity": return fluidity
		"expressiveness": return expressiveness
		"sociality": return sociality
		"boundary_pushing": return boundary_pushing
		"uniqueness": return uniqueness
		"adaptability": return adaptability
		"resilience": return resilience
		"metabolism": return metabolism
		"longevity": return longevity
		"mobility": return mobility
		"fertility": return fertility
		"resource_value": return resource_value
		"sensory_range": return sensory_range
		_:
			# Check in other dictionaries
			if spectra.has(trait_name):
				return spectra[trait_name]
			elif morphology.has(trait_name):
				return morphology[trait_name]
			elif tendencies.has(trait_name):
				return tendencies[trait_name]
			
			# Default
			return 0.5

# Get all traits as a dictionary
func get_all_traits() -> Dictionary:
	var all_traits = {
		"fluidity": fluidity,
		"expressiveness": expressiveness,
		"sociality": sociality,
		"boundary_pushing": boundary_pushing,
		"uniqueness": uniqueness,
		"adaptability": adaptability,
		"resilience": resilience,
		"metabolism": metabolism,
		"longevity": longevity,
		"mobility": mobility, 
		"fertility": fertility,
		"resource_value": resource_value,
		"sensory_range": sensory_range,
		"spectra": spectra.duplicate(),
		"morphology": morphology.duplicate(),
		"tendencies": tendencies.duplicate(),
		"aesthetics": aesthetics.duplicate()
	}
	
	return all_traits

# Calculate compatibility with another entity's traits
func calculate_compatibility(other_traits: QueerTraits) -> float:
	var compatibility = 0.0
	
	# Core compatibility is a mix of similarities and differences
	# Some traits are more compatible when similar (sociality)
	# Others when different (uniqueness)
	
	# Sociality - more compatible when similar
	var sociality_comp = 1.0 - abs(sociality - other_traits.sociality)
	
	# Uniqueness - more compatible when different
	var uniqueness_comp = abs(uniqueness - other_traits.uniqueness)
	
	# Overall core trait compatibility
	compatibility += sociality_comp * 0.3
	compatibility += uniqueness_comp * 0.2
	compatibility += (1.0 - abs(expressiveness - other_traits.expressiveness)) * 0.2
	compatibility += min(fluidity, other_traits.fluidity) * 0.3
	
	# Some randomness to account for the indefinable qualities of compatibility
	compatibility += randf() * 0.2
	
	return clamp(compatibility, 0.0, 1.0)

# Record the current state in memory
func record_current_state(current_form: Dictionary):
	var state = {
		"fluidity": fluidity,
		"expressiveness": expressiveness,
		"sociality": sociality,
		"boundary_pushing": boundary_pushing,
		"uniqueness": uniqueness,
		"form": current_form.duplicate(true),
		"time": Time.get_ticks_msec()
	}
	
	memory_states.append(state)
	form_history.append(current_form.duplicate(true))
	
	# Limit memory size
	if memory_states.size() > 10:
		memory_states.pop_front()
	
	if form_history.size() > 10:
		form_history.pop_front()

# Slight random drift in traits over time
func slight_random_drift():
	# Core traits drift slightly
	fluidity += _random_drift_amount()
	expressiveness += _random_drift_amount()
	sociality += _random_drift_amount()
	boundary_pushing += _random_drift_amount()
	uniqueness += _random_drift_amount()
	adaptability += _random_drift_amount()
	resilience += _random_drift_amount()
	
	# Clamp core traits
	fluidity = clamp(fluidity, 0.0, 1.0)
	expressiveness = clamp(expressiveness, 0.0, 1.0)
	sociality = clamp(sociality, 0.0, 1.0)
	boundary_pushing = clamp(boundary_pushing, 0.0, 1.0)
	uniqueness = clamp(uniqueness, 0.0, 1.0)
	adaptability = clamp(adaptability, 0.0, 1.0)
	resilience = clamp(resilience, 0.0, 1.0)
	
	# Some spectra also drift
	for key in spectra.keys():
		if randf() < 0.3:  # Only 30% chance to drift each spectrum
			spectra[key] += _random_drift_amount()
			spectra[key] = clamp(spectra[key], 0.0, 1.0)

# Helper function for random drift
func _random_drift_amount() -> float:
	return randf_range(-0.05, 0.05)

# Adjust traits after a transformation
func adjust_after_transformation(new_form: Dictionary):
	# Record the previous state before changing
	record_current_state(new_form)
	
	# Transformation increases fluidity slightly
	fluidity = min(fluidity + 0.05, 1.0)
	
	# Other traits may change based on the new form
	if new_form.has("trait_modifiers"):
		for trait_name in new_form.trait_modifiers:
			var modifier = new_form.trait_modifiers[trait_name]
			
			match trait_name:
				"fluidity": fluidity = clamp(fluidity + modifier, 0.0, 1.0)
				"expressiveness": expressiveness = clamp(expressiveness + modifier, 0.0, 1.0)
				"sociality": sociality = clamp(sociality + modifier, 0.0, 1.0)
				"boundary_pushing": boundary_pushing = clamp(boundary_pushing + modifier, 0.0, 1.0)
				"uniqueness": uniqueness = clamp(uniqueness + modifier, 0.0, 1.0)
				"adaptability": adaptability = clamp(adaptability + modifier, 0.0, 1.0)
				"resilience": resilience = clamp(resilience + modifier, 0.0, 1.0)
				_:
					# Check if it's a spectrum or morphology trait
					if spectra.has(trait_name):
						spectra[trait_name] = clamp(spectra[trait_name] + modifier, 0.0, 1.0)
					elif morphology.has(trait_name):
						morphology[trait_name] = clamp(morphology[trait_name] + modifier, 0.0, 1.0)
					elif tendencies.has(trait_name):
						tendencies[trait_name] = clamp(tendencies[trait_name] + modifier, 0.0, 1.0)

# Evolve traits after successfully challenging a boundary
func evolve_after_challenge(boundary_type: String, impact: float):
	# Increase boundary pushing always
	boundary_pushing = min(boundary_pushing + impact * 0.1, 1.0)
	
	# Different boundaries affect different traits
	match boundary_type:
		"physical":
			# Physical boundaries affect material_immaterial spectrum and mobility
			spectra["material_immaterial"] += impact * 0.2
			spectra["material_immaterial"] = clamp(spectra["material_immaterial"], 0.0, 1.0)
			mobility = min(mobility + impact * 0.15, 1.0)
			
		"relational":
			# Relational boundaries affect sociality and tendencies
			sociality = min(sociality + impact * 0.15, 1.0)
			tendencies["solo_communal"] += impact * 0.2
			tendencies["solo_communal"] = clamp(tendencies["solo_communal"], 0.0, 1.0)
			
		"cognitive":
			# Cognitive boundaries affect adaptability and known_unknown spectrum
			adaptability = min(adaptability + impact * 0.15, 1.0)
			spectra["known_unknown"] += impact * 0.2
			spectra["known_unknown"] = clamp(spectra["known_unknown"], 0.0, 1.0)
			
		"expressive":
			# Expressive boundaries affect expressiveness and aesthetics
			expressiveness = min(expressiveness + impact * 0.2, 1.0)
			# Shift colors slightly
			var hue_shift = impact * 0.3
			var primary = aesthetics["primary_color"]
			var h = primary.h + hue_shift
			if h > 1.0: h -= 1.0
			aesthetics["primary_color"] = Color.from_hsv(h, primary.s, primary.v)

# Adapt during crisis events
func crisis_adaptation():
	# Crises increase resilience and adaptability
	resilience = min(resilience + 0.1, 1.0)
	adaptability = min(adaptability + 0.08, 1.0)
	
	# Shift toward more resilient morphology
	morphology["stable_ephemeral"] = clamp(morphology["stable_ephemeral"] - 0.1, 0.0, 1.0)  # More stable
	
	# Record adaptation in memory
	var adaptation = {
		"event": "crisis",
		"time": Time.get_ticks_msec(),
		"resilience_before": resilience - 0.1,
		"resilience_after": resilience,
		"adaptability_before": adaptability - 0.08,
		"adaptability_after": adaptability
	}
	
	if !memory_states.has("adaptations"):
		memory_states.append({"adaptations": []})
		memory_states.back()["adaptations"].append(adaptation)
	else:
		for state in memory_states:
			if state.has("adaptations"):
				state["adaptations"].append(adaptation)
				break

# Create new traits from two parent entities for reproduction
static func create_from_parents(parent1: QueerTraits, parent2: QueerTraits) -> QueerTraits:
	var child_traits = QueerTraits.new()
	
	# Core traits - inherited with random variation
	child_traits.fluidity = _blend_traits(parent1.fluidity, parent2.fluidity)
	child_traits.expressiveness = _blend_traits(parent1.expressiveness, parent2.expressiveness)
	child_traits.sociality = _blend_traits(parent1.sociality, parent2.sociality)
	child_traits.boundary_pushing = _blend_traits(parent1.boundary_pushing, parent2.boundary_pushing)
	child_traits.uniqueness = _blend_traits(parent1.uniqueness, parent2.uniqueness)
	child_traits.adaptability = _blend_traits(parent1.adaptability, parent2.adaptability)
	child_traits.resilience = _blend_traits(parent1.resilience, parent2.resilience)
	
	# Physical/survival traits
	child_traits.metabolism = _blend_traits(parent1.metabolism, parent2.metabolism)
	child_traits.longevity = _blend_traits(parent1.longevity, parent2.longevity)
	child_traits.mobility = _blend_traits(parent1.mobility, parent2.mobility)
	child_traits.fertility = _blend_traits(parent1.fertility, parent2.fertility)
	child_traits.resource_value = _blend_traits(parent1.resource_value, parent2.resource_value)
	child_traits.sensory_range = _blend_traits(parent1.sensory_range, parent2.sensory_range)
	
	# Spectra - blend parents with variation
	for key in parent1.spectra.keys():
		child_traits.spectra[key] = _blend_traits(parent1.spectra[key], parent2.spectra[key])
	
	# Morphology - blend parents with variation
	for key in parent1.morphology.keys():
		child_traits.morphology[key] = _blend_traits(parent1.morphology[key], parent2.morphology[key])
	
	# Tendencies - blend parents with variation
	for key in parent1.tendencies.keys():
		child_traits.tendencies[key] = _blend_traits(parent1.tendencies[key], parent2.tendencies[key])
	
	# Aesthetics - blend colors and properties
	child_traits.aesthetics["primary_color"] = _blend_colors(parent1.aesthetics["primary_color"], parent2.aesthetics["primary_color"])
	child_traits.aesthetics["secondary_color"] = _blend_colors(parent1.aesthetics["secondary_color"], parent2.aesthetics["secondary_color"])
	child_traits.aesthetics["texture_pattern"] = _blend_traits(parent1.aesthetics["texture_pattern"], parent2.aesthetics["texture_pattern"])
	child_traits.aesthetics["luminosity"] = _blend_traits(parent1.aesthetics["luminosity"], parent2.aesthetics["luminosity"])
	child_traits.aesthetics["translucency"] = _blend_traits(parent1.aesthetics["translucency"], parent2.aesthetics["translucency"])
	
	return child_traits

# Helper function to blend two parent traits with some variation
static func _blend_traits(value1: float, value2: float) -> float:
	var inheritance_ratio = randf()  # How much comes from each parent
	var base_value = value1 * inheritance_ratio + value2 * (1.0 - inheritance_ratio)
	
	# Add some variation/mutation
	var mutation = randf_range(-0.1, 0.1)
	
	return clamp(base_value + mutation, 0.0, 1.0)

# Helper function to blend colors
static func _blend_colors(color1: Color, color2: Color) -> Color:
	var inheritance_ratio = randf()
	var mutation = randf_range(-0.1, 0.1)
	
	var r = clamp(color1.r * inheritance_ratio + color2.r * (1.0 - inheritance_ratio) + mutation, 0.0, 1.0)
	var g = clamp(color1.g * inheritance_ratio + color2.g * (1.0 - inheritance_ratio) + mutation, 0.0, 1.0)
	var b = clamp(color1.b * inheritance_ratio + color2.b * (1.0 - inheritance_ratio) + mutation, 0.0, 1.0)
	
	return Color(r, g, b)

# Generate traits that are very different from typical/normative patterns
func generate_divergent_traits():
	# Increase traits that encourage divergence
	fluidity = randf_range(0.7, 1.0)
	uniqueness = randf_range(0.7, 1.0)
	boundary_pushing = randf_range(0.6, 1.0)
	expressiveness = randf_range(0.6, 1.0)
	
	# Create more extreme spectrum positions
	for key in spectra.keys():
		# Push values toward extremes (0.0-0.2 or 0.8-1.0)
		if randf() < 0.5:
			spectra[key] = randf_range(0.0, 0.2)
		else:
			spectra[key] = randf_range(0.8, 1.0)
	
	# Create unusual morphology combinations
	for key in morphology.keys():
		# Create unusual combinations
		if randf() < 0.3:
			morphology[key] = randf_range(0.0, 0.2)
		elif randf() < 0.7:
			morphology[key] = randf_range(0.8, 1.0)
		else:
			morphology[key] = 0.5
	
	# Create vibrant aesthetics
	aesthetics["primary_color"] = Color(randf(), randf(), randf())
	aesthetics["secondary_color"] = Color(randf(), randf(), randf())
	
	# Increase translucency and luminosity
	aesthetics["translucency"] = randf_range(0.6, 1.0)
	aesthetics["luminosity"] = randf_range(0.6, 1.0)

# Create a hybrid with another set of traits
func create_hybrid_with(other_traits: QueerTraits) -> QueerTraits:
	var hybrid = QueerTraits.new()
	
	# Take most fluid and expressive traits
	hybrid.fluidity = max(fluidity, other_traits.fluidity) + randf_range(0.0, 0.1)
	hybrid.expressiveness = max(expressiveness, other_traits.expressiveness) + randf_range(0.0, 0.1)
	
	# Clamp to valid range
	hybrid.fluidity = min(hybrid.fluidity, 1.0)
	hybrid.expressiveness = min(hybrid.expressiveness, 1.0)
	
	# For other core traits, take a blend with some extra uniqueness
	hybrid.sociality = _blend_traits(sociality, other_traits.sociality)
	hybrid.boundary_pushing = _blend_traits(boundary_pushing, other_traits.boundary_pushing) + randf_range(0.0, 0.1)
	hybrid.boundary_pushing = min(hybrid.boundary_pushing, 1.0)
	hybrid.uniqueness = _blend_traits(uniqueness, other_traits.uniqueness) + 0.1
	hybrid.uniqueness = min(hybrid.uniqueness, 1.0)
	hybrid.adaptability = _blend_traits(adaptability, other_traits.adaptability) + randf_range(0.0, 0.1)
	hybrid.adaptability = min(hybrid.adaptability, 1.0)
	hybrid.resilience = _blend_traits(resilience, other_traits.resilience)
	
	# For spectra, combine the most extreme values from both parents
	for key in spectra.keys():
		var parent1_distance_from_center = abs(spectra[key] - 0.5)
		var parent2_distance_from_center = abs(other_traits.spectra[key] - 0.5)
		
		if parent1_distance_from_center > parent2_distance_from_center:
			hybrid.spectra[key] = spectra[key]
		else:
			hybrid.spectra[key] = other_traits.spectra[key]
		
		# Add slight variation
		hybrid.spectra[key] += randf_range(-0.1, 0.1)
		hybrid.spectra[key] = clamp(hybrid.spectra[key], 0.0, 1.0)
	
	# For morphology, create novel combinations
	for key in morphology.keys():
		# 20% chance to invert the trait from the stronger parent
		if randf() < 0.2:
			var parent_value
			if morphology[key] > other_traits.morphology[key]:
				parent_value = morphology[key]
			else:
				parent_value = other_traits.morphology[key]
			
			hybrid.morphology[key] = 1.0 - parent_value
		else:
			hybrid.morphology[key] = _blend_traits(morphology[key], other_traits.morphology[key])
	
	# For tendencies, take most pronounced from either parent
	for key in tendencies.keys():
		if abs(tendencies[key] - 0.5) > abs(other_traits.tendencies[key] - 0.5):
			hybrid.tendencies[key] = tendencies[key]
		else:
			hybrid.tendencies[key] = other_traits.tendencies[key]
	
	# For aesthetics, blend colors with possible vibrancy boost
	hybrid.aesthetics["primary_color"] = _blend_colors(aesthetics["primary_color"], other_traits.aesthetics["primary_color"])
	hybrid.aesthetics["secondary_color"] = _blend_colors(aesthetics["secondary_color"], other_traits.aesthetics["secondary_color"])
	
	# Chance to increase color vibrancy
	if randf() < 0.3:
		var primary = hybrid.aesthetics["primary_color"]
		var secondary = hybrid.aesthetics["secondary_color"]
		
		# Increase saturation
		hybrid.aesthetics["primary_color"] = Color.from_hsv(primary.h, min(primary.s + 0.2, 1.0), primary.v)
		hybrid.aesthetics["secondary_color"] = Color.from_hsv(secondary.h, min(secondary.s + 0.2, 1.0), secondary.v)
	
	# Other aesthetic properties
	hybrid.aesthetics["texture_pattern"] = _blend_traits(aesthetics["texture_pattern"], other_traits.aesthetics["texture_pattern"])
	hybrid.aesthetics["luminosity"] = _blend_traits(aesthetics["luminosity"], other_traits.aesthetics["luminosity"])
	hybrid.aesthetics["translucency"] = _blend_traits(aesthetics["translucency"], other_traits.aesthetics["translucency"])
	
	# Physical traits tend to average between parents with some variation
	hybrid.metabolism = _blend_traits(metabolism, other_traits.metabolism)
	hybrid.longevity = _blend_traits(longevity, other_traits.longevity)
	hybrid.mobility = _blend_traits(mobility, other_traits.mobility)
	hybrid.fertility = _blend_traits(fertility, other_traits.fertility) * 0.8  # Hybrids tend to be less fertile
	hybrid.resource_value = _blend_traits(resource_value, other_traits.resource_value)
	hybrid.sensory_range = _blend_traits(sensory_range, other_traits.sensory_range)
	
	return hybrid
