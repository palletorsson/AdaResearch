# SubstrateAnalyzer.gd — Infers substrate vectors from artifact registry data
#
# Scans an artifact's description, tags, category, scene path, interactions,
# and other fields to auto-populate an 8D substrate vector.
#
# Uses keyword matching across all 8 dimensions. Each keyword contributes
# a weight to one or more dimension values. The analyzer accumulates
# evidence from all available fields and produces a confidence score.
#
# Usage:
#   var analyzer := SubstrateAnalyzer.new()
#   var vector := analyzer.infer_vector(artifact_dict)
#   var result := analyzer.classify_artifact(artifact_dict) # {vector, confidence, reasoning}

extends RefCounted
class_name SubstrateAnalyzer

# ── Keyword Maps ─────────────────────────────────────────────
# Each entry: keyword -> [dimension, value, weight]
# Keywords are matched against lowercased text from description, tags, etc.

const GEOMETRY_KEYWORDS := {
	# Primitive meshes
	"spheremesh": ["geometry", "primitive_mesh", 0.8],
	"boxmesh": ["geometry", "primitive_mesh", 0.8],
	"cylindermesh": ["geometry", "primitive_mesh", 0.8],
	"planemesh": ["geometry", "primitive_mesh", 0.7],
	"primitive_mesh": ["geometry", "primitive_mesh", 0.8],
	"primitive": ["geometry", "primitive_mesh", 0.4],
	"cube": ["geometry", "primitive_mesh", 0.5],
	"sphere": ["geometry", "primitive_mesh", 0.4],
	"cylinder": ["geometry", "primitive_mesh", 0.4],
	# CSG
	"csg": ["geometry", "csg", 0.9],
	"csgbox": ["geometry", "csg", 0.8],
	"csgsphere": ["geometry", "csg", 0.8],
	"boolean": ["geometry", "csg", 0.5],
	# Procedural mesh
	"arraymesh": ["geometry", "procedural_mesh", 0.9],
	"procedural_mesh": ["geometry", "procedural_mesh", 0.9],
	"procedural mesh": ["geometry", "procedural_mesh", 0.9],
	"surface_tool": ["geometry", "procedural_mesh", 0.8],
	"surfacetool": ["geometry", "procedural_mesh", 0.8],
	"vertices": ["geometry", "procedural_mesh", 0.5],
	"terrain": ["geometry", "procedural_mesh", 0.6],
	"walkgrid": ["geometry", "procedural_mesh", 0.7],
	"heightmap": ["geometry", "procedural_mesh", 0.6],
	# MultiMesh
	"multimesh": ["geometry", "multimesh", 0.9],
	"multimeshinstance": ["geometry", "multimesh", 0.9],
	"swarm": ["geometry", "multimesh", 0.5],
	"particles": ["geometry", "multimesh", 0.4],
	"instances": ["geometry", "multimesh", 0.3],
	# ImmediateMesh
	"immediatemesh": ["geometry", "immediate_mesh", 0.9],
	"immediate_mesh": ["geometry", "immediate_mesh", 0.9],
	"lines": ["geometry", "immediate_mesh", 0.3],
	"arrows": ["geometry", "immediate_mesh", 0.5],
	"vector arrow": ["geometry", "immediate_mesh", 0.6],
	# Parametric surface
	"parametric": ["geometry", "parametric_surface", 0.7],
	"parametric_surface": ["geometry", "parametric_surface", 0.9],
	"f(u,v)": ["geometry", "parametric_surface", 0.9],
	"helicoid": ["geometry", "parametric_surface", 0.7],
	"helix": ["geometry", "parametric_surface", 0.6],
	"double helix": ["geometry", "parametric_surface", 0.7],
	"dna": ["geometry", "parametric_surface", 0.6],
	"torus": ["geometry", "parametric_surface", 0.6],
	"mobius": ["geometry", "parametric_surface", 0.7],
	"riemann": ["geometry", "parametric_surface", 0.7],
	"klein": ["geometry", "parametric_surface", 0.7],
	# Curve extrusion
	"path3d": ["geometry", "curve_extrusion", 0.8],
	"csgpolygon": ["geometry", "curve_extrusion", 0.7],
	"extrusion": ["geometry", "curve_extrusion", 0.7],
	"cable": ["geometry", "curve_extrusion", 0.6],
	"pipe": ["geometry", "curve_extrusion", 0.5],
	"spline": ["geometry", "curve_extrusion", 0.6],
	"catenary": ["geometry", "curve_extrusion", 0.6],
	# Voxel grid
	"voxel": ["geometry", "voxel_grid", 0.8],
	"voxel_grid": ["geometry", "voxel_grid", 0.9],
	"3d grid": ["geometry", "voxel_grid", 0.5],
}

const MATERIAL_KEYWORDS := {
	"opaque": ["material", "opaque_standard", 0.6],
	"standard material": ["material", "opaque_standard", 0.5],
	"albedo": ["material", "opaque_standard", 0.5],
	"metallic": ["material", "opaque_standard", 0.4],
	"wood": ["material", "opaque_standard", 0.5],
	"metal": ["material", "opaque_standard", 0.4],
	"brass": ["material", "opaque_standard", 0.5],
	# Transparent
	"transparent": ["material", "transparent", 0.8],
	"glass": ["material", "transparent", 0.7],
	"translucent": ["material", "transparent", 0.6],
	"alpha": ["material", "transparent", 0.4],
	"see-through": ["material", "transparent", 0.6],
	# Emissive
	"emissive": ["material", "emissive", 0.8],
	"glow": ["material", "emissive", 0.7],
	"glowing": ["material", "emissive", 0.7],
	"neon": ["material", "emissive", 0.6],
	"emission": ["material", "emissive", 0.7],
	"luminous": ["material", "emissive", 0.6],
	# Shader
	"shader": ["material", "shader_driven", 0.7],
	"shadermaterial": ["material", "shader_driven", 0.8],
	"fragment shader": ["material", "shader_driven", 0.8],
	"spatial shader": ["material", "shader_driven", 0.8],
	# Vertex color
	"vertex_color": ["material", "vertex_color", 0.8],
	"vertex color": ["material", "vertex_color", 0.8],
	# Cull disabled
	"double-sided": ["material", "cull_disabled", 0.7],
	"cull_disabled": ["material", "cull_disabled", 0.8],
	"two-sided": ["material", "cull_disabled", 0.6],
}

const PHYSICS_KEYWORDS := {
	"rigidbody": ["physics", "rigid_body", 0.8],
	"rigid_body": ["physics", "rigid_body", 0.8],
	"rigid body": ["physics", "rigid_body", 0.8],
	"throw": ["physics", "rigid_body", 0.5],
	"bounce": ["physics", "rigid_body", 0.5],
	"mass": ["physics", "rigid_body", 0.3],
	"gravity": ["physics", "rigid_body", 0.4],
	"ball": ["physics", "rigid_body", 0.4],
	# Soft body
	"softbody": ["physics", "soft_body", 0.9],
	"soft_body": ["physics", "soft_body", 0.9],
	"soft body": ["physics", "soft_body", 0.9],
	"deformable": ["physics", "soft_body", 0.7],
	"jelly": ["physics", "soft_body", 0.8],
	"squishy": ["physics", "soft_body", 0.8],
	"cloth": ["physics", "soft_body", 0.7],
	"fabric": ["physics", "soft_body", 0.5],
	"wobbly": ["physics", "soft_body", 0.5],
	# Custom integration
	"custom_integration": ["physics", "custom_integration", 0.9],
	"euler": ["physics", "custom_integration", 0.6],
	"verlet": ["physics", "custom_integration", 0.7],
	"_process": ["physics", "custom_integration", 0.3],
	"pendulum": ["physics", "custom_integration", 0.7],
	"spring": ["physics", "custom_integration", 0.6],
	"boids": ["physics", "custom_integration", 0.7],
	"flocking": ["physics", "custom_integration", 0.6],
	"orbital": ["physics", "custom_integration", 0.6],
	# Particle system
	"gpuparticles": ["physics", "particle_system", 0.8],
	"particle_system": ["physics", "particle_system", 0.8],
	"particle system": ["physics", "particle_system", 0.7],
	"particle field": ["physics", "particle_system", 0.7],
	# Collision only
	"staticbody": ["physics", "collision_only", 0.7],
	"collision_only": ["physics", "collision_only", 0.8],
	"walkable": ["physics", "collision_only", 0.6],
	"platform": ["physics", "collision_only", 0.5],
}

const TIME_KEYWORDS := {
	"static": ["time", "static", 0.6],
	"motionless": ["time", "static", 0.7],
	"frozen": ["time", "static", 0.6],
	"doesn't change": ["time", "static", 0.7],
	"constant": ["time", "static", 0.4],
	# Continuous
	"continuous": ["time", "continuous", 0.7],
	"sin(t": ["time", "continuous", 0.7],
	"sin(time": ["time", "continuous", 0.7],
	"smooth animation": ["time", "continuous", 0.6],
	"rotation": ["time", "continuous", 0.4],
	"rotating": ["time", "continuous", 0.5],
	"oscillat": ["time", "continuous", 0.6],
	"oscillation": ["time", "continuous", 0.7],
	"animate": ["time", "continuous", 0.4],
	"animated": ["time", "continuous", 0.5],
	"puls": ["time", "continuous", 0.4],
	"wave": ["time", "continuous", 0.4],
	"swing": ["time", "continuous", 0.5],
	"breathing": ["time", "continuous", 0.5],
	# Discrete step
	"discrete": ["time", "discrete_step", 0.7],
	"generation": ["time", "discrete_step", 0.5],
	"step": ["time", "discrete_step", 0.4],
	"cellular automata": ["time", "discrete_step", 0.7],
	"game of life": ["time", "discrete_step", 0.8],
	# Event driven
	"event_driven": ["time", "event_driven", 0.8],
	"click": ["time", "event_driven", 0.4],
	"on interaction": ["time", "event_driven", 0.6],
	"collapse": ["time", "event_driven", 0.5],
	"observation": ["time", "event_driven", 0.5],
	# Simulation
	"simulation": ["time", "simulation", 0.7],
	"multi-agent": ["time", "simulation", 0.7],
	"predator-prey": ["time", "simulation", 0.7],
	"ecosystem": ["time", "simulation", 0.7],
	"flocking": ["time", "simulation", 0.6],
	# Accumulative
	"accumulative": ["time", "accumulative", 0.8],
	"trail": ["time", "accumulative", 0.6],
	"trace": ["time", "accumulative", 0.5],
	"accumulate": ["time", "accumulative", 0.6],
	"growing": ["time", "accumulative", 0.4],
	"growth": ["time", "accumulative", 0.4],
}

const ALGORITHM_KEYWORDS := {
	# Trig
	"sin": ["algorithm", "trig_functions", 0.5],
	"cos": ["algorithm", "trig_functions", 0.5],
	"sine": ["algorithm", "trig_functions", 0.7],
	"cosine": ["algorithm", "trig_functions", 0.6],
	"trig": ["algorithm", "trig_functions", 0.7],
	"trigonometric": ["algorithm", "trig_functions", 0.8],
	"harmonic": ["algorithm", "trig_functions", 0.6],
	"oscillation": ["algorithm", "trig_functions", 0.5],
	"frequency": ["algorithm", "trig_functions", 0.4],
	"wave": ["algorithm", "trig_functions", 0.3],
	"lissajous": ["algorithm", "trig_functions", 0.7],
	"fourier": ["algorithm", "trig_functions", 0.7],
	# Noise
	"noise": ["algorithm", "noise_sampling", 0.7],
	"perlin": ["algorithm", "noise_sampling", 0.8],
	"simplex": ["algorithm", "noise_sampling", 0.8],
	"fastnoiselite": ["algorithm", "noise_sampling", 0.9],
	"noise_sampling": ["algorithm", "noise_sampling", 0.9],
	"worley": ["algorithm", "noise_sampling", 0.7],
	"voronoi": ["algorithm", "noise_sampling", 0.6],
	# Cellular automata
	"cellular_automata": ["algorithm", "cellular_automata", 0.9],
	"cellular automata": ["algorithm", "cellular_automata", 0.9],
	"game of life": ["algorithm", "cellular_automata", 0.9],
	"conway": ["algorithm", "cellular_automata", 0.8],
	"rule 30": ["algorithm", "cellular_automata", 0.8],
	"rule 110": ["algorithm", "cellular_automata", 0.8],
	"rule30": ["algorithm", "cellular_automata", 0.8],
	"rule110": ["algorithm", "cellular_automata", 0.8],
	"langton": ["algorithm", "cellular_automata", 0.8],
	"wireworld": ["algorithm", "cellular_automata", 0.8],
	"brians brain": ["algorithm", "cellular_automata", 0.8],
	"seeds": ["algorithm", "cellular_automata", 0.5],
	# Flocking
	"flocking": ["algorithm", "flocking_rules", 0.9],
	"boids": ["algorithm", "flocking_rules", 0.9],
	"separation": ["algorithm", "flocking_rules", 0.4],
	"alignment": ["algorithm", "flocking_rules", 0.3],
	"cohesion": ["algorithm", "flocking_rules", 0.4],
	"swarm": ["algorithm", "flocking_rules", 0.6],
	# Fractal
	"fractal": ["algorithm", "fractal_iteration", 0.7],
	"mandelbrot": ["algorithm", "fractal_iteration", 0.9],
	"julia": ["algorithm", "fractal_iteration", 0.8],
	"julia set": ["algorithm", "fractal_iteration", 0.9],
	"sierpinski": ["algorithm", "fractal_iteration", 0.8],
	"koch": ["algorithm", "fractal_iteration", 0.7],
	"z = z": ["algorithm", "fractal_iteration", 0.9],
	"self-similar": ["algorithm", "fractal_iteration", 0.6],
	"recursive": ["algorithm", "fractal_iteration", 0.5],
	# Physics equations
	"physics_equations": ["algorithm", "physics_equations", 0.9],
	"f=ma": ["algorithm", "physics_equations", 0.9],
	"pendulum": ["algorithm", "physics_equations", 0.7],
	"spring": ["algorithm", "physics_equations", 0.6],
	"orbital": ["algorithm", "physics_equations", 0.7],
	"gravity": ["algorithm", "physics_equations", 0.5],
	"force": ["algorithm", "physics_equations", 0.4],
	"acceleration": ["algorithm", "physics_equations", 0.5],
	"damped": ["algorithm", "physics_equations", 0.6],
	"resonance": ["algorithm", "physics_equations", 0.5],
	"coupled": ["algorithm", "physics_equations", 0.5],
	# Vector arithmetic
	"vector_arithmetic": ["algorithm", "vector_arithmetic", 0.9],
	"vector addition": ["algorithm", "vector_arithmetic", 0.8],
	"vector subtraction": ["algorithm", "vector_arithmetic", 0.8],
	"dot product": ["algorithm", "vector_arithmetic", 0.8],
	"cross product": ["algorithm", "vector_arithmetic", 0.8],
	"normalize": ["algorithm", "vector_arithmetic", 0.6],
	"magnitude": ["algorithm", "vector_arithmetic", 0.5],
	"projection": ["algorithm", "vector_arithmetic", 0.6],
	"basis vector": ["algorithm", "vector_arithmetic", 0.7],
	# Reaction diffusion
	"reaction_diffusion": ["algorithm", "reaction_diffusion", 0.9],
	"reaction diffusion": ["algorithm", "reaction_diffusion", 0.9],
	"turing pattern": ["algorithm", "reaction_diffusion", 0.9],
	"gray-scott": ["algorithm", "reaction_diffusion", 0.9],
	"morphogenesis": ["algorithm", "reaction_diffusion", 0.7],
	# L-system
	"lsystem": ["algorithm", "lsystem_expansion", 0.9],
	"l-system": ["algorithm", "lsystem_expansion", 0.9],
	"l_system": ["algorithm", "lsystem_expansion", 0.9],
	"lindenmayer": ["algorithm", "lsystem_expansion", 0.9],
	"rewriting": ["algorithm", "lsystem_expansion", 0.6],
	"turtle": ["algorithm", "lsystem_expansion", 0.5],
	"branching": ["algorithm", "lsystem_expansion", 0.4],
	"tree": ["algorithm", "lsystem_expansion", 0.3],
	# Probability
	"probability": ["algorithm", "probability", 0.7],
	"distribution": ["algorithm", "probability", 0.5],
	"gaussian": ["algorithm", "probability", 0.6],
	"monte carlo": ["algorithm", "probability", 0.8],
	"random walk": ["algorithm", "probability", 0.6],
	"stochastic": ["algorithm", "probability", 0.7],
	"bell curve": ["algorithm", "probability", 0.7],
	"entropy": ["algorithm", "probability", 0.4],
	# Topology
	"topology": ["algorithm", "topology", 0.8],
	"curvature": ["algorithm", "topology", 0.6],
	"geodesic": ["algorithm", "topology", 0.7],
	"hyperbolic": ["algorithm", "topology", 0.7],
	"non-euclidean": ["algorithm", "topology", 0.7],
	"poincare": ["algorithm", "topology", 0.8],
	"mobius": ["algorithm", "topology", 0.7],
	# State machine
	"state_machine": ["algorithm", "state_machine", 0.9],
	"state machine": ["algorithm", "state_machine", 0.8],
	"superposition": ["algorithm", "state_machine", 0.6],
	"collapse": ["algorithm", "state_machine", 0.5],
	"phase transition": ["algorithm", "state_machine", 0.6],
	"regime": ["algorithm", "state_machine", 0.4],
}

const INTERACTION_KEYWORDS := {
	# Grab
	"grab": ["interaction", "grab", 0.8],
	"grabbable": ["interaction", "grab", 0.8],
	"pickable": ["interaction", "grab", 0.7],
	"drag": ["interaction", "grab", 0.6],
	"xr grab": ["interaction", "grab", 0.8],
	# Slider
	"slider": ["interaction", "slider", 0.8],
	"knob": ["interaction", "slider", 0.7],
	"dial": ["interaction", "slider", 0.6],
	"adjust": ["interaction", "slider", 0.4],
	"parameter control": ["interaction", "slider", 0.6],
	"grab_slide": ["interaction", "slider", 0.8],
	# Button
	"button": ["interaction", "button", 0.7],
	"click": ["interaction", "button", 0.5],
	"toggle": ["interaction", "button", 0.5],
	"preset": ["interaction", "button", 0.4],
	# Touch surface
	"touch": ["interaction", "touch_surface", 0.6],
	"paint": ["interaction", "touch_surface", 0.6],
	"draw": ["interaction", "touch_surface", 0.5],
	"touch_surface": ["interaction", "touch_surface", 0.8],
	# Spatial presence
	"proximity": ["interaction", "spatial_presence", 0.7],
	"spatial_presence": ["interaction", "spatial_presence", 0.8],
	"walk through": ["interaction", "spatial_presence", 0.6],
	"walkable": ["interaction", "spatial_presence", 0.5],
	"walk_through": ["interaction", "spatial_presence", 0.7],
	"embodied": ["interaction", "spatial_presence", 0.5],
}

const CONTAINMENT_KEYWORDS := {
	"glass jar": ["containment", "glass_jar", 0.8],
	"glass_jar": ["containment", "glass_jar", 0.8],
	"jar": ["containment", "glass_jar", 0.6],
	"specimen": ["containment", "glass_jar", 0.5],
	"vial": ["containment", "glass_jar", 0.5],
	# Glass tank
	"glass tank": ["containment", "glass_tank", 0.8],
	"glass_tank": ["containment", "glass_tank", 0.8],
	"aquarium": ["containment", "glass_tank", 0.8],
	"tank": ["containment", "glass_tank", 0.5],
	"container": ["containment", "glass_tank", 0.3],
	# Petri dish
	"petri": ["containment", "petri_dish", 0.8],
	"petri_dish": ["containment", "petri_dish", 0.9],
	"dish": ["containment", "petri_dish", 0.4],
	"plate": ["containment", "petri_dish", 0.3],
	# Table
	"table": ["containment", "table", 0.5],
	"desk": ["containment", "table", 0.5],
	"workbench": ["containment", "table", 0.5],
	# Pedestal
	"pedestal": ["containment", "pedestal", 0.8],
	"display stand": ["containment", "pedestal", 0.7],
	"plinth": ["containment", "pedestal", 0.7],
	"stand": ["containment", "pedestal", 0.4],
	# Frame
	"frame": ["containment", "frame", 0.6],
	"monitor": ["containment", "frame", 0.5],
	"display": ["containment", "frame", 0.3],
	"screen": ["containment", "frame", 0.4],
	"canvas": ["containment", "frame", 0.5],
	# Box
	"box": ["containment", "box", 0.5],
	"enclosed": ["containment", "box", 0.5],
	"opaque container": ["containment", "box", 0.7],
	"display case": ["containment", "glass_jar", 0.6],
	"museum case": ["containment", "glass_jar", 0.6],
	"kiosk": ["containment", "pedestal", 0.5],
}

const INFORMATION_KEYWORDS := {
	"label3d": ["information", "label_3d", 0.8],
	"label_3d": ["information", "label_3d", 0.8],
	"label": ["information", "label_3d", 0.4],
	"text": ["information", "label_3d", 0.3],
	"plaque": ["information", "label_3d", 0.6],
	"infoboard": ["information", "label_3d", 0.6],
	# Formula
	"formula": ["information", "formula_display", 0.7],
	"equation": ["information", "formula_display", 0.6],
	"notation": ["information", "formula_display", 0.5],
	"a + b = c": ["information", "formula_display", 0.8],
	"math notation": ["information", "formula_display", 0.7],
	# Data viz
	"chart": ["information", "data_visualization", 0.7],
	"graph": ["information", "data_visualization", 0.5],
	"histogram": ["information", "data_visualization", 0.7],
	"spectrum": ["information", "data_visualization", 0.6],
	"waveform": ["information", "data_visualization", 0.6],
	"meter": ["information", "data_visualization", 0.5],
	"gauge": ["information", "data_visualization", 0.5],
	"oscilloscope": ["information", "data_visualization", 0.7],
	"analyzer": ["information", "data_visualization", 0.5],
	# Color encoding
	"color_encoding": ["information", "color_encoding", 0.8],
	"color encoding": ["information", "color_encoding", 0.8],
	"palette": ["information", "color_encoding", 0.5],
	"color mapping": ["information", "color_encoding", 0.7],
	"hue": ["information", "color_encoding", 0.4],
	"colored": ["information", "color_encoding", 0.3],
	# Spatial encoding
	"spatial_encoding": ["information", "spatial_encoding", 0.8],
	"spatial encoding": ["information", "spatial_encoding", 0.8],
	"height map": ["information", "spatial_encoding", 0.6],
	"position encodes": ["information", "spatial_encoding", 0.7],
	"3d visualization": ["information", "spatial_encoding", 0.5],
}

# All keyword maps in one array for scanning
var _all_keyword_maps: Array[Dictionary] = [
	GEOMETRY_KEYWORDS, MATERIAL_KEYWORDS, PHYSICS_KEYWORDS,
	TIME_KEYWORDS, ALGORITHM_KEYWORDS, INTERACTION_KEYWORDS,
	CONTAINMENT_KEYWORDS, INFORMATION_KEYWORDS,
]

# Category → default substrate hints
const CATEGORY_HINTS := {
	"physics": {"physics": {"custom_integration": 0.4}, "time": {"continuous": 0.3}},
	"waves": {"algorithm": {"trig_functions": 0.3}, "time": {"continuous": 0.3}},
	"emergence": {"time": {"discrete_step": 0.3}, "algorithm": {"cellular_automata": 0.3}},
	"mathematics": {"information": {"formula_display": 0.3}},
	"philosophy": {"information": {"label_3d": 0.3}},
	"procedural": {"algorithm": {"noise_sampling": 0.2}},
	"qfep": {"interaction": {"slider": 0.2}, "information": {"data_visualization": 0.2}},
	"transforms": {"algorithm": {"vector_arithmetic": 0.2}},
	"audio": {"algorithm": {"trig_functions": 0.3}, "information": {"data_visualization": 0.2}},
}


# ── Inference ────────────────────────────────────────────────

func infer_vector(artifact_dict: Dictionary) -> SubstrateVector:
	var result := classify_artifact(artifact_dict)
	return result["vector"]


func classify_artifact(artifact_dict: Dictionary) -> Dictionary:
	var weights: Dictionary = {}  # {dim: {value: weight}}
	var reasoning: Array[String] = []
	var match_count := 0

	# Gather all searchable text
	var texts: Array[String] = []
	var desc: String = artifact_dict.get("description", "")
	if desc != "":
		texts.append(desc.to_lower())

	var name_str: String = artifact_dict.get("name", "")
	if name_str != "":
		texts.append(name_str.to_lower())

	var lookup: String = artifact_dict.get("lookup_name", "")
	if lookup != "":
		texts.append(lookup.to_lower())

	var scene: String = artifact_dict.get("scene", "")
	if scene != "":
		texts.append(scene.to_lower())

	# Tags
	var tags: Array = artifact_dict.get("tags", [])
	for tag in tags:
		texts.append(str(tag).to_lower())

	# Dev themes
	var themes: Array = artifact_dict.get("dev_themes", [])
	for theme in themes:
		texts.append(str(theme).to_lower())

	# Interactions
	var interactions = artifact_dict.get("interactions", [])
	if interactions is Array:
		for inter in interactions:
			texts.append(str(inter).to_lower())
	elif interactions is String:
		texts.append(interactions.to_lower())

	# Interaction field (single string)
	var interaction_field: String = artifact_dict.get("interaction", "")
	if interaction_field != "":
		texts.append(interaction_field.to_lower())

	var combined_text := " ".join(texts)

	# Scan all keyword maps
	for kw_map in _all_keyword_maps:
		for keyword in kw_map:
			if combined_text.contains(keyword):
				var entry: Array = kw_map[keyword]
				var dim_name: String = entry[0]
				var val_name: String = entry[1]
				var weight: float = entry[2]
				if not weights.has(dim_name):
					weights[dim_name] = {}
				# Take max weight per value
				var current: float = weights[dim_name].get(val_name, 0.0)
				if weight > current:
					weights[dim_name][val_name] = weight
					if weight >= 0.5:
						reasoning.append("'%s' → %s.%s (%.1f)" % [keyword, dim_name, val_name, weight])
					match_count += 1

	# Apply category hints
	var category: String = artifact_dict.get("category", "")
	if CATEGORY_HINTS.has(category):
		var hints: Dictionary = CATEGORY_HINTS[category]
		for dim_name in hints:
			if not weights.has(dim_name):
				weights[dim_name] = {}
			for val_name in hints[dim_name]:
				var hint_w: float = hints[dim_name][val_name]
				var current: float = weights[dim_name].get(val_name, 0.0)
				if hint_w > current:
					weights[dim_name][val_name] = hint_w
		reasoning.append("category '%s' applied defaults" % category)

	# Default: most artifacts have label_3d info and primitive geometry
	if not weights.has("information"):
		weights["information"] = {"label_3d": 0.3}
	if not weights.has("geometry"):
		weights["geometry"] = {"primitive_mesh": 0.3}
	if not weights.has("interaction"):
		weights["interaction"] = {"none": 0.3}

	# Build the vector
	var sv := SubstrateVector.create(weights)

	# Confidence: based on how many dimensions have strong (>0.5) evidence
	var strong_dims := 0
	for dim_name in weights:
		for val_name in weights[dim_name]:
			if weights[dim_name][val_name] >= 0.5:
				strong_dims += 1
				break

	var confidence: float = clampf(float(strong_dims) / 6.0, 0.1, 1.0)

	return {
		"vector": sv,
		"confidence": confidence,
		"reasoning": reasoning,
	}
