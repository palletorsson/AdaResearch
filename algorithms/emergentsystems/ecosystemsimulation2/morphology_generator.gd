# morphology_generator.gd
class_name MorphologyGenerator
extends Node3D

signal morphology_generated(entity, form_data)
signal transformation_completed(entity, old_form, new_form)
signal mutation_occurred(entity, mutation_type, strength)

# Configuration
@export_category("Morphology Parameters")
@export var base_color_palette: Array[Color] = [
	Color(0.8, 0.2, 0.2),  # Red
	Color(0.2, 0.8, 0.2),  # Green
	Color(0.2, 0.2, 0.8),  # Blue
	Color(0.8, 0.8, 0.2),  # Yellow
	Color(0.8, 0.2, 0.8),  # Purple
	Color(0.2, 0.8, 0.8),  # Cyan
	Color(0.9, 0.5, 0.2),  # Orange
	Color(0.5, 0.2, 0.9)   # Violet
]
@export var enable_animations: bool = true
@export var mutation_probability: float = 0.3
@export var entropy_influence: float = 1.0
@export var complexity_range: Vector2 = Vector2(3, 12)  # Min/max number of components in an entity
@export var scale_range: Vector2 = Vector2(0.2, 2.0)    # Min/max overall scale
@export var max_asymmetry: float = 0.8                  # Maximum allowed asymmetry (0=symmetric, 1=total asymmetry)

# State
var current_entropy: float = 0.0
var form_library: Dictionary = {}
var component_library: Dictionary = {}
var generated_forms: Array = []
var mutation_library: Array = []

# Form generation components
var body_types = ["spherical", "cylindrical", "amorphous", "crystalline", "flowing", "segmented", "branching", "nested"]
var appendage_types = ["tentacles", "limbs", "wings", "fronds", "filaments", "spines", "fins", "ribbons"]
var texture_types = ["smooth", "rough", "patterned", "luminous", "transparent", "iridescent", "fluid", "organic"]
var movement_types = ["undulating", "gliding", "pulsing", "rotating", "flowing", "vibrating", "spiraling", "phasing"]
var symmetry_types = ["radial", "bilateral", "asymmetric", "fractal", "nested", "spiral", "tessellated", "fluid"]

# Mutation types
var mutation_types = ["color_shift", "component_growth", "texture_evolution", "symmetry_breaking", "merging", "splitting", "dimensional_shift", "form_inversion"]

func _ready():
	# Initialize libraries
	_initialize_component_library()
	_initialize_mutation_library()
	_initialize_form_library()
	
	print("Morphology Generator initialized")

func _initialize_component_library():
	# Basic shapes
	component_library["shapes"] = {
		"sphere": preload("res://algorithms/emergentsystems/ecosystemsimulation2/components/sphere.tscn") if ResourceLoader.exists("res://algorithms/emergentsystems/ecosystemsimulation2/components/sphere.tscn") else null,
		"cube": preload("res://algorithms/emergentsystems/ecosystemsimulation2/components/cube.tscn") if ResourceLoader.exists("res://algorithms/emergentsystems/ecosystemsimulation2/components/cube.tscn") else null,
		"cylinder": preload("res://algorithms/emergentsystems/ecosystemsimulation2/components/cylinder.tscn") if ResourceLoader.exists("res://algorithms/emergentsystems/ecosystemsimulation2/components/cylinder.tscn") else null,
		"cone": preload("res://algorithms/emergentsystems/ecosystemsimulation2/components/cone.tscn") if ResourceLoader.exists("res://algorithms/emergentsystems/ecosystemsimulation2/components/cone.tscn") else null,
		"torus": preload("res://algorithms/emergentsystems/ecosystemsimulation2/components/torus.tscn") if ResourceLoader.exists("res://algorithms/emergentsystems/ecosystemsimulation2/components/torus.tscn") else null
	}
	
	# If no preloaded assets, set up fallback procedural generation
	if component_library["shapes"]["sphere"] == null:
		print("No preloaded shape assets found. Using procedural generation.")
	
	# Add other component categories
	component_library["textures"] = {}
	component_library["animations"] = {}
	component_library["effects"] = {}

func _initialize_mutation_library():
	mutation_library = [
		{
			"name": "color_shift",
			"probability": 0.4,
			"apply": func(form_data): return _apply_color_shift_mutation(form_data)
		},
		{
			"name": "component_growth",
			"probability": 0.3,
			"apply": func(form_data): return _apply_component_growth_mutation(form_data)
		},
		{
			"name": "texture_evolution",
			"probability": 0.2,
			"apply": func(form_data): return _apply_texture_evolution_mutation(form_data)
		},
		{
			"name": "symmetry_breaking",
			"probability": 0.2,
			"apply": func(form_data): return _apply_symmetry_breaking_mutation(form_data)
		},
		{
			"name": "merging",
			"probability": 0.15,
			"apply": func(form_data): return _apply_merging_mutation(form_data)
		},
		{
			"name": "splitting",
			"probability": 0.15,
			"apply": func(form_data): return _apply_splitting_mutation(form_data)
		},
		{
			"name": "dimensional_shift",
			"probability": 0.1,
			"apply": func(form_data): return _apply_dimensional_shift_mutation(form_data)
		},
		{
			"name": "form_inversion",
			"probability": 0.05,
			"apply": func(form_data): return _apply_form_inversion_mutation(form_data)
		}
	]

func _initialize_form_library():
	# Create some base form templates
	form_library["fluid_sphere"] = {
		"body_type": "spherical",
		"components": [
			{
				"type": "sphere",
				"position": Vector3(0, 0, 0),
				"scale": Vector3(1, 1, 1),
				"color": Color(0.2, 0.6, 0.8),
				"texture": "smooth",
				"animation": "pulsing"
			}
		],
		"symmetry": "radial",
		"movement": "flowing",
		"trait_modifiers": {
			"fluidity": 0.2,
			"adaptability": 0.1
		}
	}
	
	form_library["crystal_cluster"] = {
		"body_type": "crystalline",
		"components": [
			{
				"type": "cube",
				"position": Vector3(0, 0, 0),
				"scale": Vector3(0.8, 0.8, 0.8),
				"color": Color(0.5, 0.2, 0.8),
				"texture": "smooth",
				"animation": "pulsing"
			},
			{
				"type": "cube",
				"position": Vector3(0.5, 0.3, 0.5),
				"scale": Vector3(0.4, 0.7, 0.4),
				"rotation": Vector3(0.3, 0.5, 0.2),
				"color": Color(0.5, 0.2, 0.8),
				"texture": "smooth",
				"animation": "pulsing"
			}
		],
		"symmetry": "asymmetric",
		"movement": "vibrating",
		"trait_modifiers": {
			"stability": 0.2,
			"uniqueness": 0.1
		}
	}
	
	form_library["tentacle_cluster"] = {
		"body_type": "amorphous",
		"components": [
			{
				"type": "sphere",
				"position": Vector3(0, 0, 0),
				"scale": Vector3(0.7, 0.7, 0.7),
				"color": Color(0.8, 0.3, 0.5),
				"texture": "smooth",
				"animation": "pulsing"
			},
			{
				"type": "cylinder",
				"position": Vector3(0.4, 0.4, 0),
				"scale": Vector3(0.2, 0.8, 0.2),
				"rotation": Vector3(0, 0, 1.2),
				"color": Color(0.8, 0.3, 0.5),
				"texture": "smooth",
				"animation": "undulating"
			}
		],
		"symmetry": "asymmetric",
		"movement": "undulating",
		"trait_modifiers": {
			"expressiveness": 0.2,
			"fluidity": 0.1
		}
	}
	
	# Add more base forms as needed

func set_entropy(value: float):
	current_entropy = clamp(value, 0.0, 1.0)

func generate_morphology(entity: Object) -> Dictionary:
	if not entity or not entity.has_method("get_info"):
		return {}
	
	var entity_info = entity.get_info()
	var traits = entity_info["traits"] if entity_info.has("traits") else {}
	
	# Create new form based on traits
	var form_data = _create_form_based_on_traits(traits)
	
	# Generate the visual representation
	_apply_form_to_entity(entity, form_data)
	
	# Record the generated form
	generated_forms.append({
		"entity": entity,
		"form_data": form_data,
		"generation_time": Time.get_ticks_msec()
	})
	
	# Emit signal
	emit_signal("morphology_generated", entity, form_data)
	
	return form_data

func generate_transformation(entity: Object, entropy_level: float) -> Dictionary:
	if not entity or not entity.has_method("get_info"):
		return {}
	
	var entity_info = entity.get_info()
	var traits = entity_info["traits"] if entity_info.has("traits") else {}
	var current_form = entity_info["form"] if entity_info.has("form") else {}
	
	# If no current form, generate a new one
	if current_form.is_empty():
		return generate_morphology(entity)
	
	# Create transformed form
	var new_form = _transform_existing_form(current_form, traits, entropy_level)
	
	# Apply the new form
	_apply_form_to_entity(entity, new_form)
	
	# Emit signal
	emit_signal("transformation_completed", entity, current_form, new_form)
	
	return new_form

func _create_form_based_on_traits(traits: Dictionary) -> Dictionary:
	# Choose a base form template that aligns with traits
	var base_form = _select_base_form_template(traits)
	
	# Customize the base form according to traits
	var form_data = base_form.duplicate(true)
	
	# Adjust body type based on traits
	if traits.has("fluidity") and traits["fluidity"] > 0.7:
		form_data["body_type"] = "flowing"
	elif traits.has("adaptability") and traits["adaptability"] > 0.7:
		form_data["body_type"] = "amorphous"
	
	# Adjust colors based on traits
	if traits.has("expressiveness"):
		form_data = _customize_colors(form_data, traits["expressiveness"])
	
	# Adjust complexity based on traits and entropy
	var complexity_factor = 0.5
	if traits.has("uniqueness"):
		complexity_factor = traits["uniqueness"]
	
	complexity_factor = lerp(complexity_factor, current_entropy, entropy_influence * 0.5)
	form_data = _customize_complexity(form_data, complexity_factor)
	
	# Adjust symmetry based on traits
	if traits.has("boundary_pushing") and traits.has("fluidity"):
		var asymmetry_factor = max(traits["boundary_pushing"], traits["fluidity"]) * max_asymmetry
		form_data = _customize_symmetry(form_data, asymmetry_factor)
	
	# Add movement based on traits
	if traits.has("mobility"):
		form_data = _customize_movement(form_data, traits["mobility"])
	
	# Apply random mutations based on entropy
	if current_entropy > 0.3 and randf() < mutation_probability * current_entropy:
		form_data = _apply_random_mutation(form_data)
	
	return form_data

func _select_base_form_template(traits: Dictionary) -> Dictionary:
	# Select a base form that aligns with the entity's traits
	
	# Calculate similarity scores for each template
	var best_score = -1.0
	var best_template_name = "fluid_sphere"  # Default
	
	for template_name in form_library:
		var template = form_library[template_name]
		var score = 0.0
		
		# Check trait modifiers against entity traits
		if template.has("trait_modifiers"):
			for trait_name in template.trait_modifiers:
				if traits.has(trait_name):
					var modifier = template.trait_modifiers[trait_name]
					var trait_value = traits[trait_name]
					
					# Higher score if trait aligns with modifier direction
					if (modifier > 0 and trait_value > 0.5) or (modifier < 0 and trait_value < 0.5):
						score += abs(modifier) * 0.5
			
			# Bonus for matching body type preference
			if traits.has("morphology") and traits["morphology"].has("organic_geometric"):
				var org_geo = traits["morphology"]["organic_geometric"]
				if template["body_type"] in ["spherical", "amorphous", "flowing"] and org_geo < 0.5:
					score += (1.0 - org_geo) * 0.3
				elif template["body_type"] in ["crystalline", "segmented"] and org_geo > 0.5:
					score += org_geo * 0.3
		
		
		# Add some randomness to prevent always choosing the same template
		score += randf() * 0.2
		
		if score > best_score:
			best_score = score
			best_template_name = template_name
	
	
	return form_library[best_template_name].duplicate(true)

func _customize_colors(form_data: Dictionary, expressiveness: float) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Choose a color palette based on expressiveness
	var saturation = lerp(0.3, 1.0, expressiveness)
	var value = lerp(0.5, 1.0, expressiveness)
	
	# Modify component colors
	for i in range(new_form["components"].size()):
		var component = new_form["components"][i]
		
		# Start with base color
		var base_color = component["color"]
		
		# Adjust saturation and value
		var color = Color(base_color.r, base_color.g, base_color.b)
		var h = color.h
		var s = color.s
		var v = color.v

		# For creating a new color:
		# Original:
		# var adjusted_color = Color.from_hsv(hsv.x, hsv.y, hsv.z)
		# Replacement:
		var adjusted_color = Color.from_hsv(h, s, v)
		
		# Apply to component
		component["color"] = adjusted_color
		
		# Add emission for very expressive entities
		if expressiveness > 0.7:
			component["emission"] = adjusted_color
			component["emission_energy"] = expressiveness - 0.5
	
	return new_form

func _customize_complexity(form_data: Dictionary, complexity_factor: float) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Determine target component count based on complexity factor
	var min_components = complexity_range.x
	var max_components = complexity_range.y
	var target_component_count = int(lerp(min_components, max_components, complexity_factor))
	
	# Add or remove components to match target count
	while new_form["components"].size() < target_component_count:
		# Add a new component
		var base_component = new_form["components"][randi() % new_form["components"].size()]
		var new_component = base_component.duplicate(true)
		
		# Modify the new component
		var offset = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		new_component["position"] = base_component["position"] + offset
		
		# Randomize scale
		var scale_factor = randf_range(0.5, 1.0)
		new_component["scale"] = base_component["scale"] * scale_factor
		
		# Slightly vary color
		var color_variation = Color(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1)
		)
		new_component["color"] = Color(
			clamp(base_component["color"].r + color_variation.r, 0, 1),
			clamp(base_component["color"].g + color_variation.g, 0, 1),
			clamp(base_component["color"].b + color_variation.b, 0, 1)
		)
		
		# Add rotation if not present
		if not new_component.has("rotation"):
			new_component["rotation"] = Vector3(
				randf_range(0, TAU),
				randf_range(0, TAU),
				randf_range(0, TAU)
			)
		
		# Add to components array
		new_form["components"].append(new_component)
	
	# Remove excess components if needed
	while new_form["components"].size() > target_component_count:
		var remove_index = randi() % new_form["components"].size()
		new_form["components"].remove_at(remove_index)
	
	return new_form

func _customize_symmetry(form_data: Dictionary, asymmetry_factor: float) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Determine symmetry type based on asymmetry factor
	if asymmetry_factor < 0.2:
		new_form["symmetry"] = "radial"
	elif asymmetry_factor < 0.4:
		new_form["symmetry"] = "bilateral"
	elif asymmetry_factor < 0.6:
		new_form["symmetry"] = "spiral"
	elif asymmetry_factor < 0.8:
		new_form["symmetry"] = "fractal"
	else:
		new_form["symmetry"] = "asymmetric"
	
	# Apply symmetry to components
	if new_form["symmetry"] == "bilateral":
		# Create a bilateral symmetry by mirroring components
		var original_components = new_form["components"].duplicate(true)
		
		for component in original_components:
			if component["position"].x != 0:  # Only mirror components off center
				var mirrored = component.duplicate(true)
				mirrored["position"].x = -component["position"].x
				
				# Mirror rotation as well
				if mirrored.has("rotation"):
					mirrored["rotation"].y = -mirrored["rotation"].y
					mirrored["rotation"].z = -mirrored["rotation"].z
				
				new_form["components"].append(mirrored)
	
	elif new_form["symmetry"] == "radial":
		# Create radial symmetry
		var center_components = []
		var radial_components = []
		
		# Separate center and radial components
		for component in new_form["components"]:
			if component["position"].length() < 0.1:
				center_components.append(component)
			else:
				radial_components.append(component)
		
		# Clear components and re-add centers
		var all_components = []
		all_components.append_array(center_components)
		
		# Create radial copies
		var radial_count = int(randf_range(3, 7))  # 3 to 6 radial elements
		
		for original in radial_components:
			var radius = original["position"].length()
			var base_angle = atan2(original["position"].z, original["position"].x)
			
			for i in range(radial_count):
				var angle = base_angle + TAU * i / radial_count
				var new_comp = original.duplicate(true)
				
				new_comp["position"].x = cos(angle) * radius
				new_comp["position"].z = sin(angle) * radius
				
				# Rotate to face outward
				if new_comp.has("rotation"):
					new_comp["rotation"].y = angle
				
				all_components.append(new_comp)
		
		new_form["components"] = all_components
	
	# Other symmetry types would be implemented here
	
	return new_form

func _customize_movement(form_data: Dictionary, mobility: float) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Set movement type based on mobility and body type
	if mobility < 0.3:
		new_form["movement"] = "pulsing"
	elif mobility < 0.6:
		if new_form["body_type"] == "flowing" or new_form["body_type"] == "amorphous":
			new_form["movement"] = "undulating"
		else:
			new_form["movement"] = "vibrating"
	else:
		if new_form["body_type"] == "flowing":
			new_form["movement"] = "flowing"
		elif new_form["body_type"] == "amorphous":
			new_form["movement"] = "undulating"
		else:
			new_form["movement"] = "gliding"
	
	# Add animation parameters to components
	for component in new_form["components"]:
		component["animation"] = new_form["movement"]
		
		# Add animation parameters based on movement type
		match new_form["movement"]:
			"pulsing":
				component["animation_params"] = {
					"frequency": randf_range(0.5, 2.0),
					"amplitude": randf_range(0.05, 0.15),
					"phase_offset": randf() * TAU
				}
			"undulating":
				component["animation_params"] = {
					"frequency": randf_range(0.5, 1.5),
					"amplitude": randf_range(0.1, 0.3),
					"wave_speed": randf_range(0.5, 2.0),
					"axis": randi() % 3  # 0=x, 1=y, 2=z
				}
			"vibrating":
				component["animation_params"] = {
					"frequency": randf_range(2.0, 4.0),
					"amplitude": randf_range(0.02, 0.08),
					"random_factor": randf_range(0.1, 0.3)
				}
			"gliding", "flowing":
				component["animation_params"] = {
					"speed": randf_range(0.5, 1.5) * mobility,
					"turn_rate": randf_range(0.2, 0.8),
					"height_variation": randf_range(0.1, 0.5)
				}
	
	return new_form

func _apply_random_mutation(form_data: Dictionary) -> Dictionary:
	# Choose a random mutation based on probabilities
	var mutation = _choose_random_mutation()
	
	# Apply the mutation
	var mutated_form = mutation.apply.call(form_data.duplicate(true))
	
	# Emit signal with mutation info
	emit_signal("mutation_occurred", null, mutation.name, 1.0)
	
	return mutated_form

func _choose_random_mutation():
	var total_prob = 0.0
	
	# Sum probabilities and scale by entropy
	for mutation in mutation_library:
		total_prob += mutation.probability * (1.0 + current_entropy)
	
	# Choose a mutation
	var roll = randf() * total_prob
	var cumulative_prob = 0.0
	
	for mutation in mutation_library:
		cumulative_prob += mutation.probability * (1.0 + current_entropy)
		if roll <= cumulative_prob:
			return mutation
	
	# Default to first mutation if somehow we got here
	return mutation_library[0]

# Mutation application functions
func _apply_color_shift_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Shift the hue of all components
	var hue_shift = randf_range(0.1, 0.3)  # 10-30% hue shift
	if randf() < 0.5:
		hue_shift = -hue_shift  # 50% chance of shifting in either direction
	
	for component in new_form["components"]:
		var color = Color(component["color"].r, component["color"].g, component["color"].b)
		var h = color.h
		var s = color.s
		var v = color.v

		# When you need to adjust HSV and create a new color:
		# Example:
		h = fmod(h + hue_shift, 1.0)  # Shift hue and wrap around
		var new_color = Color.from_hsv(h, s, v)
		
		# Update emission if present
		if component.has("emission"):
			component["emission"] = new_color
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["expressiveness"] = 0.05
	
	return new_form

func _apply_component_growth_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Randomly select a component to grow
	var component_index = randi() % new_form["components"].size()
	var component = new_form["components"][component_index]
	
	# Increase the scale
	var growth_factor = randf_range(1.2, 1.8)
	component["scale"] = component["scale"] * growth_factor
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["boundary_pushing"] = 0.05
	
	return new_form

func _apply_texture_evolution_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Change textures for all components
	var possible_textures = ["smooth", "rough", "patterned", "luminous", "transparent", "iridescent"]
	var new_texture = possible_textures[randi() % possible_textures.size()]
	
	for component in new_form["components"]:
		component["texture"] = new_texture
		
		# Add special properties based on texture
		match new_texture:
			"luminous":
				component["emission"] = component["color"]
				component["emission_energy"] = randf_range(0.5, 1.5)
			"transparent":
				var color = component["color"]
				color.a = randf_range(0.3, 0.7)
				component["color"] = color
			"iridescent":
				component["iridescence"] = randf_range(0.5, 1.0)
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["uniqueness"] = 0.05
	
	return new_form

func _apply_symmetry_breaking_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Only apply if not already asymmetric
	if new_form["symmetry"] == "asymmetric":
		return new_form
	
	# Change symmetry type to a more complex or broken form
	var current_symmetry = new_form["symmetry"]
	var new_symmetry = ""
	
	match current_symmetry:
		"radial":
			new_symmetry = "bilateral"
		"bilateral":
			new_symmetry = "asymmetric"
		"fractal":
			new_symmetry = "asymmetric"
		_:
			new_symmetry = "asymmetric"
	
	new_form["symmetry"] = new_symmetry
	
	# Break symmetry by modifying some components
	for i in range(new_form["components"].size()):
		if randf() < 0.3:  # 30% chance to modify each component
			var component = new_form["components"][i]
			
			# Add random offset
			var pos_offset = Vector3(
				randf_range(-0.2, 0.2),
				randf_range(-0.2, 0.2),
				randf_range(-0.2, 0.2)
			)
			component["position"] += pos_offset
			
			# Modify scale
			var scale_mod = Vector3(
				randf_range(0.8, 1.2),
				randf_range(0.8, 1.2),
				randf_range(0.8, 1.2)
			)
			component["scale"] = Vector3(
				component["scale"].x * scale_mod.x,
				component["scale"].y * scale_mod.y,
				component["scale"].z * scale_mod.z
			)
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["boundary_pushing"] = 0.1
	new_form["trait_modifiers"]["uniqueness"] = 0.1
	
	return new_form

func _apply_merging_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Need at least 2 components to merge
	if new_form["components"].size() < 2:
		return new_form
	
	# Choose two components to merge
	var idx1 = randi() % new_form["components"].size()
	var idx2 = idx1
	while idx2 == idx1:
		idx2 = randi() % new_form["components"].size()
	
	var comp1 = new_form["components"][idx1]
	var comp2 = new_form["components"][idx2]
	
	# Create merged component
	var merged = {}
	
	# Average position
	merged["position"] = (comp1["position"] + comp2["position"]) / 2.0
	
	# Combine scale (slightly larger than either component)
	merged["scale"] = (comp1["scale"] + comp2["scale"]) * 0.6
	
	# Blend colors
	merged["color"] = Color(
		(comp1["color"].r + comp2["color"].r) / 2.0,
		(comp1["color"].g + comp2["color"].g) / 2.0,
		(comp1["color"].b + comp2["color"].b) / 2.0
	)
	
	# Choose type based on larger component
	if comp1["scale"].length() > comp2["scale"].length():
		merged["type"] = comp1["type"]
	else:
		merged["type"] = comp2["type"]
	
	# Merge other properties
	merged["texture"] = comp1["texture"] if randf() < 0.5 else comp2["texture"]
	merged["animation"] = comp1["animation"] if randf() < 0.5 else comp2["animation"]
	
	# Handle rotation (average if both have it)
	if comp1.has("rotation") and comp2.has("rotation"):
		merged["rotation"] = (comp1["rotation"] + comp2["rotation"]) / 2.0
	elif comp1.has("rotation"):
		merged["rotation"] = comp1["rotation"]
	elif comp2.has("rotation"):
		merged["rotation"] = comp2["rotation"]
	
	# Remove original components
	new_form["components"].remove_at(max(idx1, idx2))
	new_form["components"].remove_at(min(idx1, idx2))
	
	# Add merged component
	new_form["components"].append(merged)
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["fluidity"] = 0.1
	
	return new_form

func _apply_splitting_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# Choose a component to split
	if new_form["components"].size() == 0:
		return new_form
		
	var idx = randi() % new_form["components"].size()
	var comp = new_form["components"][idx]
	
	# Create two new components from the original
	var comp1 = comp.duplicate(true)
	var comp2 = comp.duplicate(true)
	
	# Modify positions to separate them
	var split_vector = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * 0.3
	comp1["position"] += split_vector
	comp2["position"] -= split_vector
	
	# Modify scales to make them smaller
	comp1["scale"] *= randf_range(0.6, 0.8)
	comp2["scale"] *= randf_range(0.6, 0.8)
	
	# Slightly vary properties
	# Colors
	var color_shift1 = Color(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
	var color_shift2 = Color(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
	
	comp1["color"] = Color(
		clamp(comp["color"].r + color_shift1.r, 0, 1),
		clamp(comp["color"].g + color_shift1.g, 0, 1),
		clamp(comp["color"].b + color_shift1.b, 0, 1)
	)
	
	comp2["color"] = Color(
		clamp(comp["color"].r + color_shift2.r, 0, 1),
		clamp(comp["color"].g + color_shift2.g, 0, 1),
		clamp(comp["color"].b + color_shift2.b, 0, 1)
	)
	
	# Rotations
	if comp.has("rotation"):
		var rot_shift1 = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		var rot_shift2 = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		
		comp1["rotation"] = comp["rotation"] + rot_shift1
		comp2["rotation"] = comp["rotation"] + rot_shift2
	
	# Remove original component
	new_form["components"].remove_at(idx)
	
	# Add new components
	new_form["components"].append(comp1)
	new_form["components"].append(comp2)
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["expressiveness"] = 0.1
	
	return new_form

func _apply_dimensional_shift_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# This mutation distorts space around components
	# Randomly choose to stretch along an axis or bend space
	var shift_type = randi() % 3
	
	match shift_type:
		0:  # Stretch along an axis
			var stretch_axis = randi() % 3  # 0=x, 1=y, 2=z
			var stretch_factor = randf_range(1.5, 2.5)
			
			for component in new_form["components"]:
				match stretch_axis:
					0:  # X axis
						component["position"].x *= stretch_factor
						component["scale"].x *= 1.0 / sqrt(stretch_factor)  # Compensate scale
					1:  # Y axis
						component["position"].y *= stretch_factor
						component["scale"].y *= 1.0 / sqrt(stretch_factor)
					2:  # Z axis
						component["position"].z *= stretch_factor
						component["scale"].z *= 1.0 / sqrt(stretch_factor)
		
		1:  # Bend space (move components along a curve)
			var bend_axis = randi() % 3  # Axis perpendicular to bend
			var bend_strength = randf_range(0.2, 0.5)
			
			for component in new_form["components"]:
				var pos = component["position"]
				
				match bend_axis:
					0:  # Bend in YZ plane (around X)
						var dist = sqrt(pos.y * pos.y + pos.z * pos.z)
						var angle = atan2(pos.z, pos.y)
						angle += bend_strength * pos.x
						pos.y = cos(angle) * dist
						pos.z = sin(angle) * dist
					1:  # Bend in XZ plane (around Y)
						var dist = sqrt(pos.x * pos.x + pos.z * pos.z)
						var angle = atan2(pos.z, pos.x)
						angle += bend_strength * pos.y
						pos.x = cos(angle) * dist
						pos.z = sin(angle) * dist
					2:  # Bend in XY plane (around Z)
						var dist = sqrt(pos.x * pos.x + pos.y * pos.y)
						var angle = atan2(pos.y, pos.x)
						angle += bend_strength * pos.z
						pos.x = cos(angle) * dist
						pos.y = sin(angle) * dist
				
				component["position"] = pos
				
				# Add rotation to align with bend
				if not component.has("rotation"):
					component["rotation"] = Vector3.ZERO
					
				match bend_axis:
					0: component["rotation"].x += bend_strength * pos.x  # Rotate around X
					1: component["rotation"].y += bend_strength * pos.y  # Rotate around Y
					2: component["rotation"].z += bend_strength * pos.z  # Rotate around Z
		
		2:  # Fold space (mirror or invert part of the form)
			var fold_axis = randi() % 3  # 0=x, 1=y, 2=z
			var fold_position = randf_range(-0.5, 0.5)  # Position of fold along the axis
			
			for component in new_form["components"]:
				var pos = component["position"]
				
				match fold_axis:
					0:  # Fold along YZ plane
						if pos.x > fold_position:
							pos.x = fold_position - (pos.x - fold_position)
							# Flip rotations
							if component.has("rotation"):
								component["rotation"].y = -component["rotation"].y
								component["rotation"].z = -component["rotation"].z
					1:  # Fold along XZ plane
						if pos.y > fold_position:
							pos.y = fold_position - (pos.y - fold_position)
							# Flip rotations
							if component.has("rotation"):
								component["rotation"].x = -component["rotation"].x
								component["rotation"].z = -component["rotation"].z
					2:  # Fold along XY plane
						if pos.z > fold_position:
							pos.z = fold_position - (pos.z - fold_position)
							# Flip rotations
							if component.has("rotation"):
								component["rotation"].x = -component["rotation"].x
								component["rotation"].y = -component["rotation"].y
				
				component["position"] = pos
	
	# Update body type to reflect dimensional shift
	new_form["body_type"] = "dimensional"
	
	# Add trait modifiers
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["boundary_pushing"] = 0.2
	new_form["trait_modifiers"]["uniqueness"] = 0.2
	
	return new_form

func _apply_form_inversion_mutation(form_data: Dictionary) -> Dictionary:
	var new_form = form_data.duplicate(true)
	
	# This is the most radical mutation - a complete inversion of the form
	# Invert inside/outside, solid/void, etc.
	
	# Invert positions - turn the form inside out
	for component in new_form["components"]:
		var pos = component["position"]
		
		# Skip components at exact center
		if pos.length() < 0.01:
			continue
		
		# Invert position - distant components become close, close become distant
		var inv_factor = 1.0 / (pos.length_squared() + 0.5)
		component["position"] = pos.normalized() * inv_factor * 2.0
		
		# Invert scales - small becomes large, large becomes small
		component["scale"] = Vector3(1.0, 1.0, 1.0) / component["scale"]
		
		# Invert colors
		component["color"] = Color(
			1.0 - component["color"].r,
			1.0 - component["color"].g,
			1.0 - component["color"].b
		)
	
	# Invert other form properties
	match new_form["body_type"]:
		"flowing": new_form["body_type"] = "crystalline"
		"crystalline": new_form["body_type"] = "flowing"
		"amorphous": new_form["body_type"] = "segmented"
		"segmented": new_form["body_type"] = "amorphous"
		"spherical": new_form["body_type"] = "branching"
		"branching": new_form["body_type"] = "spherical"
	
	match new_form["symmetry"]:
		"radial": new_form["symmetry"] = "asymmetric"
		"bilateral": new_form["symmetry"] = "fractal"
		"asymmetric": new_form["symmetry"] = "radial"
		"fractal": new_form["symmetry"] = "bilateral"
	
	match new_form["movement"]:
		"pulsing": new_form["movement"] = "gliding"
		"gliding": new_form["movement"] = "pulsing"
		"undulating": new_form["movement"] = "rotating"
		"rotating": new_form["movement"] = "undulating"
		"flowing": new_form["movement"] = "vibrating"
		"vibrating": new_form["movement"] = "flowing"
	
	# Add trait modifiers - this is a major transformation
	if not new_form.has("trait_modifiers"):
		new_form["trait_modifiers"] = {}
	
	new_form["trait_modifiers"]["fluidity"] = 0.3
	new_form["trait_modifiers"]["boundary_pushing"] = 0.3
	new_form["trait_modifiers"]["uniqueness"] = 0.3
	
	return new_form

func _transform_existing_form(current_form: Dictionary, traits: Dictionary, entropy_level: float) -> Dictionary:
	# Create a transformation based on current form, traits, and entropy
	var new_form = current_form.duplicate(true)
	
	# Apply mutations based on fluidity and entropy
	var fluidity = traits.get("fluidity", 0.5)
	var mutation_chance = fluidity * 0.5 + entropy_level * 0.5
	
	if randf() < mutation_chance:
		# Apply 1-3 mutations
		var mutation_count = 1
		if randf() < mutation_chance * 0.7:
			mutation_count += 1
		if randf() < mutation_chance * 0.4:
			mutation_count += 1
		
		for i in range(mutation_count):
			new_form = _apply_random_mutation(new_form)
	
	# Ensure the form doesn't become too complex
	if new_form["components"].size() > complexity_range.y:
		# Merge components to reduce complexity
		while new_form["components"].size() > complexity_range.y:
			new_form = _apply_merging_mutation(new_form)
	
	# Ensure the form doesn't become too simple
	if new_form["components"].size() < complexity_range.x:
		# Split components to increase complexity
		while new_form["components"].size() < complexity_range.x:
			new_form = _apply_splitting_mutation(new_form)
	
	return new_form

func _apply_form_to_entity(entity: Object, form_data: Dictionary):
	# Clear existing visual representation
	var visual_node = entity.get_node_or_null("VisualForm")
	if visual_node:
		# Remove current visualization
		for child in visual_node.get_children():
			child.queue_free()
	else:
		# Create visual node if it doesn't exist
		visual_node = Node3D.new()
		visual_node.name = "VisualForm"
		entity.add_child(visual_node)
	
	# Apply new visual representation
	for component_data in form_data["components"]:
		var component = _create_component(component_data)
		if component:
			visual_node.add_child(component)
	
	# Apply animations if enabled
	if enable_animations and form_data.has("movement"):
		_setup_animations(visual_node, form_data)

func _create_component(component_data: Dictionary) -> Node3D:
	var component: Node3D
	
	# Check if we have a preloaded component
	if component_data.has("type") and component_library["shapes"].has(component_data["type"]) and component_library["shapes"][component_data["type"]] != null:
		component = component_library["shapes"][component_data["type"]].instantiate()
	else:
		# Create procedurally
		component = _create_procedural_component(component_data)
	
	if not component:
		return null
	
	# Apply transform
	if component_data.has("position"):
		component.position = component_data["position"]
	
	if component_data.has("rotation"):
		component.rotation = component_data["rotation"]
	
	if component_data.has("scale"):
		component.scale = component_data["scale"]
	
	# Apply material
	_apply_component_material(component, component_data)
	
	return component

func _create_procedural_component(component_data: Dictionary) -> Node3D:
	var component = MeshInstance3D.new()
	
	# Create mesh based on type
	var mesh: Mesh
	
	match component_data["type"]:
		"sphere":
			mesh = SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
		"cube":
			mesh = BoxMesh.new()
			mesh.size = Vector3(1, 1, 1)
		"cylinder":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.5
			mesh.bottom_radius = 0.5
			mesh.height = 1.0
		"cone":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.0
			mesh.bottom_radius = 0.5
			mesh.height = 1.0
		"torus":
			mesh = TorusMesh.new()
			mesh.inner_radius = 0.3
			mesh.outer_radius = 0.5
		_:
			# Default to sphere
			mesh = SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
	
	component.mesh = mesh
	return component

func _apply_component_material(component: Node3D, component_data: Dictionary):
	# Find the mesh instance to apply material to
	var mesh_instance: MeshInstance3D
	
	if component is MeshInstance3D:
		mesh_instance = component
	else:
		# Look for a MeshInstance3D child
		for child in component.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if not mesh_instance:
		return
	
	# Create material
	var material = StandardMaterial3D.new()
	
	# Base color
	if component_data.has("color"):
		material.albedo_color = component_data["color"]
	else:
		material.albedo_color = Color(1, 1, 1)
	
	# Texture
	if component_data.has("texture"):
		match component_data["texture"]:
			"rough":
				material.roughness = 0.9
				material.metallic = 0.1
			"smooth":
				material.roughness = 0.1
				material.metallic = 0.8
			"patterned":
				material.roughness = 0.5
				material.metallic = 0.3
				# Would add texture maps in a full implementation
			"luminous":
				material.emission_enabled = true
				material.emission = component_data["color"]
				material.emission_energy = 1.0
			"transparent":
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.albedo_color.a = 0.7
			"iridescent":
				material.metallic = 1.0
				material.roughness = 0.1
				material.anisotropy_enabled = true
				material.anisotropy = 0.8
	
	# Emission
	if component_data.has("emission"):
		material.emission_enabled = true
		material.emission = component_data["emission"]
		
		if component_data.has("emission_energy"):
			material.emission_energy = component_data["emission_energy"]
		else:
			material.emission_energy = 1.0
	
	# Apply material
	mesh_instance.material_override = material

func _setup_animations(visual_node: Node3D, form_data: Dictionary):
	# Add animation player if needed
	var anim_player = visual_node.get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		visual_node.add_child(anim_player)
	
	# Create animation based on movement type
	var anim = Animation.new()
	var movement_type = form_data["movement"]
	
	match movement_type:
		"pulsing":
			_create_pulsing_animation(anim, visual_node, form_data)
		"undulating":
			_create_undulating_animation(anim, visual_node, form_data)
		"vibrating":
			_create_vibrating_animation(anim, visual_node, form_data)
		"gliding", "flowing":
			_create_gliding_animation(anim, visual_node, form_data)
		"rotating":
			_create_rotating_animation(anim, visual_node, form_data)
	
	# Add animation to player
	var anim_name = "morph_anim"
	var lib: AnimationLibrary = anim_player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)
	anim_player.play(anim_name)

func _create_pulsing_animation(anim: Animation, visual_node: Node3D, form_data: Dictionary):
	# Create a pulsing animation where components scale up and down
	
	# Set up animation
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Add tracks for scale of each component
	for i in range(visual_node.get_child_count()):
		var component = visual_node.get_child(i)
		if not component is MeshInstance3D:
			continue
		
		var component_data = form_data["components"][i] if i < form_data["components"].size() else null
		if not component_data or not component_data.has("animation_params"):
			continue
		
		var params = component_data["animation_params"]
		var frequency = params.get("frequency", 1.0)
		var amplitude = params.get("amplitude", 0.1)
		var phase_offset = params.get("phase_offset", 0.0)
		
		# Add track for scale
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(str(component.get_path()) + ":scale"))
		
		# Add keyframes
		var base_scale = component.scale
		var frames = 10  # Number of keyframes in the animation
		
		for f in range(frames + 1):
			var t = float(f) / frames * anim.length
			var scale_factor = 1.0 + amplitude * sin(TAU * frequency * t + phase_offset)
			var new_scale = base_scale * scale_factor
			
			anim.track_insert_key(track_idx, t, new_scale)

func _create_undulating_animation(anim: Animation, visual_node: Node3D, form_data: Dictionary):
	# Create a wave-like animation where components move in sinusoidal patterns
	
	# Set up animation
	anim.length = 3.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Add tracks for position of each component
	for i in range(visual_node.get_child_count()):
		var component = visual_node.get_child(i)
		if not component is MeshInstance3D:
			continue
		
		var component_data = form_data["components"][i] if i < form_data["components"].size() else null
		if not component_data or not component_data.has("animation_params"):
			continue
		
		var params = component_data["animation_params"]
		var frequency = params.get("frequency", 1.0)
		var amplitude = params.get("amplitude", 0.2)
		var wave_speed = params.get("wave_speed", 1.0)
		var axis = params.get("axis", 1)  # Default to Y
		
		# Add track for position
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(str(component.get_path()) + ":position"))
		
		# Add keyframes
		var base_pos = component.position
		var frames = 15  # Number of keyframes
		
		for f in range(frames + 1):
			var t = float(f) / frames * anim.length
			var offset = Vector3.ZERO
			
			# Apply different wave pattern based on position
			var wave_value = sin(TAU * frequency * t + base_pos.length() * wave_speed)
			
			match axis:
				0: offset.x = amplitude * wave_value
				1: offset.y = amplitude * wave_value
				2: offset.z = amplitude * wave_value
			
			var new_pos = base_pos + offset
			anim.track_insert_key(track_idx, t, new_pos)

func _create_vibrating_animation(anim: Animation, visual_node: Node3D, form_data: Dictionary):
	# Create rapid, small movements in random directions
	
	# Set up animation
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Add tracks for position of each component
	for i in range(visual_node.get_child_count()):
		var component = visual_node.get_child(i)
		if not component is MeshInstance3D:
			continue
		
		var component_data = form_data["components"][i] if i < form_data["components"].size() else null
		if not component_data or not component_data.has("animation_params"):
			continue
		
		var params = component_data["animation_params"]
		var frequency = params.get("frequency", 3.0)
		var amplitude = params.get("amplitude", 0.05)
		var random_factor = params.get("random_factor", 0.2)
		
		# Add track for position
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(str(component.get_path()) + ":position"))
		
		# Add keyframes
		var base_pos = component.position
		var frames = 20  # More frames for smoother vibration
		
		for f in range(frames + 1):
			var t = float(f) / frames * anim.length
			
			# Create vibration with some randomness
			var offset = Vector3(
				amplitude * sin(TAU * frequency * t) + randf_range(-random_factor, random_factor) * amplitude,
				amplitude * cos(TAU * frequency * t * 1.3) + randf_range(-random_factor, random_factor) * amplitude,
				amplitude * sin(TAU * frequency * t * 0.7) + randf_range(-random_factor, random_factor) * amplitude
			)
			
			var new_pos = base_pos + offset
			anim.track_insert_key(track_idx, t, new_pos)

func _create_gliding_animation(anim: Animation, visual_node: Node3D, form_data: Dictionary):
	# Create a smooth, flowing movement animation
	
	# Set up animation
	anim.length = 4.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Create global movement for the whole entity
	var root_track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(root_track_idx, NodePath(str(visual_node.get_path()) + ":position"))
	
	# Get parameters from first component with animation params
	var params = null
	for component_data in form_data["components"]:
		if component_data.has("animation_params"):
			params = component_data["animation_params"]
			break
	
	if not params:
		params = {
			"speed": 0.5,
			"turn_rate": 0.5,
			"height_variation": 0.2
		}
	
	var speed = params.get("speed", 0.5)
	var turn_rate = params.get("turn_rate", 0.5)
	var height_variation = params.get("height_variation", 0.2)
	
	# Create a meandering path
	var frames = 20
	var base_pos = visual_node.position
	var direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	
	for f in range(frames + 1):
		var t = float(f) / frames * anim.length
		
		# Update direction with gentle turns
		var turn = Vector3(
			randf_range(-turn_rate, turn_rate),
			0,
			randf_range(-turn_rate, turn_rate)
		)
		direction = (direction + turn).normalized()
		
		# Calculate new position
		var movement = direction * speed * t
		var height_offset = sin(t * TAU * 0.5) * height_variation
		var new_pos = base_pos + movement + Vector3(0, height_offset, 0)
		
		# Add keyframe
		anim.track_insert_key(root_track_idx, t, new_pos)
	
	# Also add gentle rotation to the entity
	var rotation_track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rotation_track_idx, NodePath(str(visual_node.get_path()) + ":rotation"))
	
	var base_rot = visual_node.rotation
	for f in range(frames + 1):
		var t = float(f) / frames * anim.length
		var rot_offset = Vector3(
			sin(t * TAU * 0.3) * 0.1,
			sin(t * TAU * 0.2) * 0.2,
			sin(t * TAU * 0.4) * 0.1
		)
		anim.track_insert_key(rotation_track_idx, t, base_rot + rot_offset)

func _create_rotating_animation(anim: Animation, visual_node: Node3D, form_data: Dictionary):
	# Create rotation animations for components
	
	# Set up animation
	anim.length = 5.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Add rotation tracks for each component
	for i in range(visual_node.get_child_count()):
		var component = visual_node.get_child(i)
		if not component is MeshInstance3D:
			continue
		
		# Add track for rotation
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(str(component.get_path()) + ":rotation"))
		
		# Base rotation
		var base_rot = component.rotation
		
		# Rotation speed varies per component
		var rotation_speed = Vector3(
			randf_range(0.1, 0.5),
			randf_range(0.1, 0.5),
			randf_range(0.1, 0.5)
		)
		
		# Add keyframes
		var frames = 10
		for f in range(frames + 1):
			var t = float(f) / frames * anim.length
			
			var rot_offset = Vector3(
				rotation_speed.x * t * TAU,
				rotation_speed.y * t * TAU,
				rotation_speed.z * t * TAU
			)
			
			anim.track_insert_key(track_idx, t, base_rot + rot_offset)

# Additional helper functions

func get_generated_form_for_entity(entity: Object) -> Dictionary:
	# Find the stored form data for an entity
	for record in generated_forms:
		if record.entity == entity:
			return record.form_data
	
	return {}
	
func get_current_entropy() -> float:
	return current_entropy

func mutate_entity_form(entity: Object, mutation_type: String = "") -> Dictionary:
	# Apply a specific mutation to an entity
	var entity_info = entity.get_info() if entity.has_method("get_info") else {}
	var current_form = entity_info.get("form", {})
	
	if current_form.is_empty():
		return {}
	
	# Apply either specific mutation or random one
	var mutated_form
	
	if mutation_type != "":
		# Find the specific mutation
		for mutation in mutation_library:
			if mutation.name == mutation_type:
				mutated_form = mutation.apply.call(current_form.duplicate(true))
				break
		
		# Fall back to random if not found
		if mutated_form == null:
			mutated_form = _apply_random_mutation(current_form)
	else:
		# Apply random mutation
		mutated_form = _apply_random_mutation(current_form)
	
	# Apply to entity
	_apply_form_to_entity(entity, mutated_form)
	
	# Emit signal
	emit_signal("mutation_occurred", entity, mutation_type if mutation_type != "" else "random", 1.0)
	
	return mutated_form

func generate_hybrid_form(entity1: Object, entity2: Object) -> Dictionary:
	# Create a hybrid form combining aspects of two entities
	var info1 = entity1.get_info() if entity1.has_method("get_info") else {}
	var info2 = entity2.get_info() if entity2.has_method("get_info") else {}
	
	var form1 = info1.get("form", {})
	var form2 = info2.get("form", {})
	
	if form1.is_empty() or form2.is_empty():
		return {}
	
	# Create hybrid form
	var hybrid_form = {
		"body_type": form1.get("body_type") if randf() < 0.5 else form2.get("body_type"),
		"symmetry": form1.get("symmetry") if randf() < 0.5 else form2.get("symmetry"),
		"movement": form1.get("movement") if randf() < 0.5 else form2.get("movement"),
		"components": [],
		"trait_modifiers": {}
	}
	
	# Combine components from both forms
	var comp1 = form1.get("components", [])
	var comp2 = form2.get("components", [])
	
	# Take some components from each parent
	var comp1_count = min(comp1.size(), int(ceil(comp1.size() * 0.6)))
	var comp2_count = min(comp2.size(), int(ceil(comp2.size() * 0.6)))
	
	# Randomly select components from each parent
	comp1.shuffle()
	comp2.shuffle()
	
	for i in range(comp1_count):
		if i < comp1.size():
			hybrid_form.components.append(comp1[i].duplicate(true))
	
	for i in range(comp2_count):
		if i < comp2.size():
			hybrid_form.components.append(comp2[i].duplicate(true))
	
	# Combine trait modifiers
	if form1.has("trait_modifiers"):
		for key in form1.trait_modifiers:
			hybrid_form.trait_modifiers[key] = form1.trait_modifiers[key]
	
	if form2.has("trait_modifiers"):
		for key in form2.trait_modifiers:
			if hybrid_form.trait_modifiers.has(key):
				hybrid_form.trait_modifiers[key] = (hybrid_form.trait_modifiers[key] + form2.trait_modifiers[key]) * 0.6
			else:
				hybrid_form.trait_modifiers[key] = form2.trait_modifiers[key]
	
	# Add unique trait bonus for hybrids
	hybrid_form.trait_modifiers["uniqueness"] = (hybrid_form.trait_modifiers.get("uniqueness", 0.0) + 0.2)
	hybrid_form.trait_modifiers["fluidity"] = (hybrid_form.trait_modifiers.get("fluidity", 0.0) + 0.1)
	
	return hybrid_form
