# LevelsManager.gd
# Add this script as an AutoLoad/Singleton in Project Settings
extends Node

# Levels data structure
var levels_data = {
  "meta": {
	"version": "1.0",
	"title": "Ada Research: A Meta-Quest into the World of Algorithms",
	"author": "Palle Torsson",
	"description": "A VR exploration of algorithms from basic concepts to advanced AI, focused on finding queer potential in digital spaces"
  },
  "player": {
	"starting_xp": 0,
	"starting_level": "Intro_0",
	"inventory": []
  },
  "zones": [
	{
	  "id": "Preface",
	  "name": "Central Hub",
	  "description": "The central navigation space that connects all zones of Ada Research",
	  "color": "#61d7f2",
	  "icon": "cube",
	  "required_xp": 0
	},
	{
	  "id": "Intro",
	  "name": "Introduction",
	  "description": "Introduction to Ada Research and the concepts of algorithms",
	  "color": "#8a2be2",
	  "icon": "point",
	  "required_xp": 0
	},
	{
	  "id": "Basic",
	  "name": "Basic Elements",
	  "description": "Fundamental algorithmic concepts that form the building blocks of digital creativity",
	  "color": "#8a2be2",
	  "icon": "line",
	  "required_xp": 20
	},
	{
	  "id": "Advanced",
	  "name": "Advanced Elements",
	  "description": "Complex algorithms that enable the creation of sophisticated forms and simulations",
	  "color": "#ff4500",
	  "icon": "flow-field",
	  "required_xp": 100
	},
	{
	  "id": "Pattern",
	  "name": "Pattern and World Building",
	  "description": "Algorithms that enable the creation of unique and dynamic patterns and game environments",
	  "color": "#32cd32",
	  "icon": "procedural",
	  "required_xp": 250
	},
	{
	  "id": "Tech",
	  "name": "Advanced Techniques",
	  "description": "Cutting-edge algorithms exploring algorithmic life, AI, and non-euclidean spaces",
	  "color": "#ffd700",
	  "icon": "ai",
	  "required_xp": 400
	}
  ],
  "levels": {
	"Preface": {
		"0": {
		"title": "There was already a flipped monolite",
		"summary": {
			"0": 
				"Arrays exist at the heart of digital reality as fundamental structures that both organize our world and limit our expression.",
			"1": """
				ARRAYS AS FOUNDATION:
				- Arrays impose an ordered grid on chaotic reality
				- Each element exists at a precise coordinate: array[i] or grid[row][col]
				- This indexing creates a map of reality that computers can navigate
				""", 
			"2": """
				THE PARADOX OF STRUCTURE:
				- Our minds seek both order (arrays, grids, tables) and freedom (topology, curves, flow)
				- Arrays embody this tension—they give us power through structure while simultaneously constraining us
				- The grid becomes a gravitational force pulling content toward predictable forms
				""", 
			"3": """
				BEYOND THE MATRIX:
				- When we nest arrays within arrays, complexity emerges
				- Procedural generation uses arrays but produces organic forms
				- Soft body physics warps rigid structures into fluid movement
				- Queer potential exists in how we manipulate and transform these structures
				""", 
			"4": """
				TOPOLOGICAL DESIRE:
				- Arrays represent the binary nature of computing, yet we yearn for the non-binary
				- The dimensional drive pushes against the limitations of the grid
				- Through recursion, arrays can fold into themselves, creating strange loops
				""", 
			"5": """
				THE ENTROPY QUEST:
				- As we increase complexity in our arrays, we increase entropy
				- Higher dimensions of arrays (3D, 4D, nD) reach toward the margins of comprehension
				- At these margins, the queer potential of digital existence emerges
			""",
			"6": """ 
				This exploration of arrays is both a recognition of the fundamental grammar of our digital world and an invitation to push beyond its constraints. The array is not just a tool but a metaphor for how we organize reality—and for how we might reimagine it.
			""" },
		"description": "Begin standing on the 'flipped monolite' - a horizontal black rectangle subverting the iconic form. A geometric cube array materializes around you, revealing pathways through digital space. The grid emerges, marking boundaries and possibilities, while an info board glows nearby, ready to guide your journey into the world of algorithms.",
		"explained":  {
			"0": """
				Arrays are fundamental data structures that store collections of items in memory. 
			""", 
			"1": """
				SINGLE ELEMENT:
				- A single element is accessed with one index: array[0]
				- Memory is allocated for one value at a specific address
				CODE: 
				# Instantiate a single cube and transform its position 
				single_cube = cube_scene.instantiate()
				single_cube.transform.origin = Vector3(0, 1, 0)
				""", 
			"2": """
				1D ARRAY:
				- A row of elements accessed with one index: array[i]
				- Memory is allocated in a contiguous block
				- Perfect for lists, sequences, or collections
				1D ARRAY CODE:
				# Create a row of cubes along Z axis
				for i in range(7):
				\tvar cube = cube_scene.instantiate()
				\t# Position along Z axis with even spacing
				\tcube.transform.origin = Vector3(0, 1, i * 1.5)
				\tadd_child(cube)
				\t# Store reference in our array
				\trow_cubes.append(cube)
			""", 
			"3": """
				2D ARRAY:
				- A grid of elements accessed with two indices: array[row][col]
				- Implemented as an "array of arrays"
				- Perfect for grids, tables, and matrices
				""", 
			"4": """
				2D ARRAY CODE:
				# Create a 3x4 grid of cubes (3 rows, 4 columns)
				var grid_cubes = []  # Will hold our 2D array
				for row in range(3):
				\tvar row_array = []  # Create array for this row
				\tfor col in range(4):
				\t\tvar cube = cube_scene.instantiate()
				\t\t# Position in X-Z grid with even spacing
				\t\tcube.transform.origin = Vector3(row * 1.5, 1, col * 1.5)
				\t\tadd_child(cube)
				\t\t# Add to row array
				\t\trow_array.append(cube)
				\t# Add completed row to grid
				\tgrid_cubes.append(row_array)
				"""
			
			},			 
		"xp_reward": 10,
		"icons": ["point", "line", "grid", "rotation"],
		"unlocks": ["Intro_0"],
		"environment": "central_hub",
		"special_objects": ["navigation_terminal", "zone_portals", "ada_hologram"],
		"queer_elements": ["fluid_architecture", "perspective_shifting"]
		
		}, 
		"1": {
		"title": "pickup cube",
		"summary": {
			"0": 
				"Arrays exist at the heart of digital reality as fundamental structures that both organize our world and limit our expression.",
			
				},
		"description": "Begin standing on the 'flipped monolite' - a horizontal black rectangle subverting the iconic form. A geometric cube array materializes around you, revealing pathways through digital space. The grid emerges, marking boundaries and possibilities, while an info board glows nearby, ready to guide your journey into the world of algorithms.",
		"explained":  {
			"0": """
				Arrays are fundamental data structures that store collections of items in memory. 
			""", 
		
			
			},			 
		"xp_reward": 10,
		"icons": ["point", "line", "grid", "rotation"],
		"unlocks": ["Intro_0"],
		"environment": "central_hub",
		"special_objects": ["navigation_terminal", "zone_portals", "ada_hologram"],
		"queer_elements": ["fluid_architecture", "perspective_shifting"]
		
		}
	},
	"Intro": {
	  "0": {
		"title": "About Ada Lovelace",
		"summary": "The world's first programmer and visionary",
		"description": "Ada Lovelace wrote about the relationship between computers and generative art in 1842. Her insights continue to inspire our exploration of algorithmic creativity. This space honors her legacy and introduces the basic concepts of algorithmic thinking.",
		"xp_reward": 15,
		"icons": ["point", "random", "noise"],
		"unlocks": ["Intro_1"],
		"environment": "victorian_computing_hall",
		"special_objects": ["analytical_engine", "ada_notes", "babbage_portrait"],
		"queer_elements": ["historical_revision", "feminine_technology"]
	  },
	  "1": {
		"title": "Randomness Laboratory",
		"summary": "The foundation of generative art",
		"description": "Explore different forms of randomness and how they create the unpredictability essential for generative art. Compare true randomness with algorithmic pseudo-randomness and observe how they create different patterns and textures.",
		"xp_reward": 20,
		"icons": ["random", "simulation", "entropy"],
		"unlocks": ["Intro_2"],
		"environment": "random_particle_chamber",
		"special_objects": ["random_generators", "pattern_visualizers", "entropy_meter"],
		"queer_elements": ["pattern_disruption", "normative_breakdown"]
	  },
	  "2": {
		"title": "Fibonacci Exploration",
		"summary": "Nature's mathematical pattern",
		"description": "Discover the Fibonacci sequence and golden ratio through interactive visualizations. Plant seeds in the virtual garden and watch them grow according to these mathematical principles that appear throughout nature and art.",
		"xp_reward": 20,
		"icons": ["recursion", "line", "point"],
		"unlocks": ["Intro_3"],
		"environment": "spiral_garden",
		"special_objects": ["seed_planters", "spiral_sculptures", "growth_simulator"],
		"queer_elements": ["non_linear_growth", "pattern_variation"]
	  },
	  "3": {
		"title": "Perlin Noise Landscape",
		"summary": "Creating natural-looking randomness",
		"description": "Developed by Ken Perlin in 1983, Perlin noise generates smoothly varying random-like patterns that create naturalistic textures, terrains, and movements in digital spaces. Manipulate noise parameters to create different landscapes.",
		"xp_reward": 25,
		"icons": ["noise", "texture", "procedural"],
		"unlocks": ["Intro_4"],
		"environment": "morphing_landscape",
		"special_objects": ["noise_controllers", "terrain_generator", "parameter_dials"],
		"queer_elements": ["landscape_fluidity", "morphing_topography"]
	  },
	  "4": {
		"title": "Voronoi Garden",
		"summary": "Cellular space division",
		"description": "Explore Voronoi diagrams, mathematical structures that divide space into regions based on distance to generator points. Create crystalline structures and organic cell-like patterns by placing and moving these points.",
		"xp_reward": 25,
		"icons": ["point", "procedural", "line"],
		"unlocks": ["Intro_5"],
		"environment": "crystal_cavern",
		"special_objects": ["point_placer", "cell_visualizer", "voronoi_sculptor"],
		"queer_elements": ["boundary_dissolution", "category_blending"]
	  },
	  "5": {
		"title": "Sine Wave Symphony",
		"summary": "Visualizing sound mathematics",
		"description": "Interact with sine waves as both visual forms and audio frequencies. Combine waves to create complex patterns and sounds, exploring the mathematical foundation of harmonics and interference patterns.",
		"xp_reward": 25,
		"icons": ["line", "noise", "simulation"],
		"unlocks": ["Basic_0"],
		"environment": "audio_visual_chamber",
		"special_objects": ["wave_generator", "harmonic_mixer", "frequency_visualizer"],
		"queer_elements": ["sensory_crossing", "synesthetic_experience"]
	  }
	},
	"Random": {
	  "0": {
		"title": "Randomness Laboratory",
		"summary": "The foundation of generative art",
		"description": "Explore different forms of randomness and how they create the unpredictability essential for generative art. Compare true randomness with algorithmic pseudo-randomness and observe how they create different patterns and textures.",
		"xp_reward": 20,
		"icons": ["random", "simulation", "entropy"],
		"unlocks": ["Intro_2"],
		"environment": "random_particle_chamber",
		"special_objects": ["random_generators", "pattern_visualizers", "entropy_meter"],
		"queer_elements": ["pattern_disruption", "normative_breakdown"]
	  }, 
	 "1": {
		"title": "Topology Morphing Chamber",
		"summary": "Continuous transformations",
		"description": "Explore topological transformations where objects can be continuously deformed while preserving certain properties. Morph donuts into coffee cups and perform other topological operations that reveal mathematical equivalence in seemingly different forms.",
		"xp_reward": 35,
		"icons": ["queer", "simulation", "procedural"],
		"unlocks": ["Advanced_0"],
		"environment": "topological_space",
		"special_objects": ["morphing_objects", "continuity_visualizer", "equivalence_demonstrator"],
		"queer_elements": ["form_fluidity", "categorical_dissolution"]
	  }
	},
	"Basic": {
	  "0": {
		"title": "Fractal Meditation",
		"summary": "Infinite self-similarity",
		"description": "Journey through recursive fractal structures where patterns repeat at different scales. Zoom in endlessly to discover new details within the Mandelbrot set, Julia sets, and other fractal forms that reveal the beauty of mathematical infinity.",
		"xp_reward": 30,
		"icons": ["recursion", "procedural", "queer"],
		"unlocks": ["Basic_1"],
		"environment": "fractal_dimension",
		"special_objects": ["zoom_portal", "fractal_generator", "iteration_controls"],
		"queer_elements": ["scale_ambiguity", "infinite_complexity"]
	  },
	  "1": {
		"title": "Flow Field Navigation",
		"summary": "Vector-guided movement",
		"description": "Explore a space filled with directional vectors that guide particle movement. Manipulate the flow field to create swirling vortices, diverging paths, and other complex patterns as particles follow the changing directions.",
		"xp_reward": 30,
		"icons": ["vector", "flow-field", "particles"],
		"unlocks": ["Basic_2"],
		"environment": "vector_field",
		"special_objects": ["field_manipulator", "particle_emitter", "flow_visualizer"],
		"queer_elements": ["directional_fluidity", "path_disruption"]
	  },
	  "2": {
		"title": "Fourier Transform Visualizer",
		"summary": "Deconstructing waves",
		"description": "Discover how complex waveforms can be broken down into simple sine waves through Fourier transforms. Draw shapes and see their frequency domain representations, revealing how seemingly complex patterns have simpler components.",
		"xp_reward": 30,
		"icons": ["line", "noise", "simulation"],
		"unlocks": ["Basic_3"],
		"environment": "wave_analysis_lab",
		"special_objects": ["shape_drawer", "transform_visualizer", "frequency_analyzer"],
		"queer_elements": ["pattern_deconstruction", "component_reassembly"]
	  },
	  "3": {
		"title": "L-System Forest",
		"summary": "Recursive growth patterns",
		"description": "Wander through a forest generated by L-systems, recursive algorithms that create complex branching structures from simple rules. Modify the growth rules to create different plant forms and observe how small rule changes lead to dramatic differences.",
		"xp_reward": 35,
		"icons": ["recursion", "procedural", "line"],
		"unlocks": ["Basic_4"],
		"environment": "procedural_forest",
		"special_objects": ["rule_editor", "growth_simulator", "plant_specimens"],
		"queer_elements": ["rule_breaking_growth", "alternative_morphology"]
	  },
	  "4": {
		"title": "Soft Body Playground",
		"summary": "Physics of deformation",
		"description": "Interact with deformable objects that stretch, bounce, and flow according to soft body physics simulations. Experiment with different material properties and see how objects respond to forces and constraints.",
		"xp_reward": 35,
		"icons": ["physics", "simulation", "material"],
		"unlocks": ["Basic_5"],
		"environment": "physics_playroom",
		"special_objects": ["deformable_objects", "force_applicators", "material_adjusters"],
		"queer_elements": ["body_fluidity", "material_ambiguity"]
	  },
	  "5": {
		"title": "Topology Morphing Chamber",
		"summary": "Continuous transformations",
		"description": "Explore topological transformations where objects can be continuously deformed while preserving certain properties. Morph donuts into coffee cups and perform other topological operations that reveal mathematical equivalence in seemingly different forms.",
		"xp_reward": 35,
		"icons": ["queer", "simulation", "procedural"],
		"unlocks": ["Advanced_0"],
		"environment": "topological_space",
		"special_objects": ["morphing_objects", "continuity_visualizer", "equivalence_demonstrator"],
		"queer_elements": ["form_fluidity", "categorical_dissolution"]
	  }
	},
	"Advanced": {
	  "0": {
		"title": "Reaction-Diffusion Aquarium",
		"summary": "Chemical pattern formation",
		"description": "Observe and influence reaction-diffusion systems that model how chemicals interact and spread, creating organic-looking patterns. Experiment with different parameters to produce spots, stripes, and other emergent patterns seen in nature.",
		"xp_reward": 40,
		"icons": ["procedural", "simulation", "queer"],
		"unlocks": ["Advanced_1"],
		"environment": "pattern_tank",
		"special_objects": ["chemical_injectors", "parameter_controls", "pattern_catalog"],
		"queer_elements": ["emergent_identity", "pattern_hybridity"]
	  },
	  "1": {
		"title": "Graph Theory Network",
		"summary": "Connections and relationships",
		"description": "Manipulate networks of nodes and connections to explore graph theory concepts. Rearrange connections to optimize paths, create different network topologies, and observe how information flows through different network structures.",
		"xp_reward": 40,
		"icons": ["array", "line", "point"],
		"unlocks": ["Advanced_2"],
		"environment": "network_space",
		"special_objects": ["node_creator", "connection_tool", "flow_simulator"],
		"queer_elements": ["connection_reconfiguration", "hierarchical_disruption"]
	  },
	  "2": {
		"title": "Procedural City Generator",
		"summary": "Algorithmic architecture",
		"description": "Explore a city that builds itself according to procedural rules. Modify generation parameters to create different urban environments and observe how simple rules can create complex, varied structures that mimic organic urban growth.",
		"xp_reward": 40,
		"icons": ["procedural", "cube", "array"],
		"unlocks": ["Advanced_3"],
		"environment": "growing_city",
		"special_objects": ["parameter_controls", "district_paintbrush", "rule_editor"],
		"queer_elements": ["architectural_fluidity", "urban_reconfiguration"]
	  },
	  "3": {
		"title": "Neural Network Observatory",
		"summary": "Visual machine learning",
		"description": "Step inside a visual representation of a neural network and watch how information flows and transforms. Feed different inputs to the network and observe how it processes data, learns patterns, and makes predictions.",
		"xp_reward": 45,
		"icons": ["neural-net", "ai", "array"],
		"unlocks": ["Advanced_4"],
		"environment": "neural_landscape",
		"special_objects": ["input_feed", "neuron_activator", "weight_adjuster"],
		"queer_elements": ["cognitive_remodeling", "binary_dissolution"]
	  },
	  "4": {
		"title": "Shader Workshop",
		"summary": "Visual programming effects",
		"description": "Experiment with shader programs that transform the appearance of objects and environments. Combine different rendering techniques to create unique visual effects, from realistic materials to impossible visuals that challenge perception.",
		"xp_reward": 45,
		"icons": ["shader", "material", "texture"],
		"unlocks": ["Advanced_5"],
		"environment": "shader_gallery",
		"special_objects": ["shader_editor", "material_previewer", "effect_combiner"],
		"queer_elements": ["visual_disruption", "perception_bending"]
	  },
	  "5": {
		"title": "Evolutionary Algorithm Habitat",
		"summary": "Digital natural selection",
		"description": "Witness digital creatures evolve through generations according to fitness functions and selection pressure. Modify environmental conditions and selection criteria to guide the evolutionary process and observe adaptation in action.",
		"xp_reward": 45,
		"icons": ["genetic", "ai", "simulation"],
		"unlocks": ["Pattern_0"],
		"environment": "digital_ecosystem",
		"special_objects": ["environment_controls", "selection_tools", "generation_tracker"],
		"queer_elements": ["fitness_redefinition", "categorical_evolution"]
	  }
	},
	"Pattern": {
	  "0": {
		"title": "Swarm Intelligence Collective",
		"summary": "Emergent group behavior",
		"description": "Explore how simple rules followed by individual agents can create complex collective behaviors. Modify the rules governing bird flocks, fish schools, and other swarms to observe different emergent patterns and problem-solving abilities.",
		"xp_reward": 50,
		"icons": ["simulation", "ai", "array"],
		"unlocks": ["Pattern_1"],
		"environment": "swarm_space",
		"special_objects": ["rule_adjuster", "agent_spawner", "behavior_analyzer"],
		"queer_elements": ["collective_identity", "individual_dissolution"]
	  },
	  "1": {
		"title": "Chaos Theory Laboratory",
		"summary": "Order within disorder",
		"description": "Experiment with chaotic systems where tiny initial differences lead to dramatically different outcomes. Interact with double pendulums, strange attractors, and other chaotic systems to explore the boundary between determinism and unpredictability.",
		"xp_reward": 50,
		"icons": ["random", "entropy", "physics"],
		"unlocks": ["Pattern_2"],
		"environment": "chaos_chamber",
		"special_objects": ["initial_condition_setter", "trajectory_tracker", "attractor_visualizer"],
		"queer_elements": ["predictability_breakdown", "determinism_questioning"]
	  },
	  "2": {
		"title": "Algorithmic Life Incubator",
		"summary": "Digital organism simulation",
		"description": "Create and observe digital life forms based on cellular automata and artificial life algorithms. Design rule sets and initial conditions to generate self-replicating patterns, evolving systems, and other life-like behaviors from simple rules.",
		"xp_reward": 50,
		"icons": ["genetic", "simulation", "array"],
		"unlocks": ["Pattern_3"],
		"environment": "digital_petri_dish",
		"special_objects": ["rule_designer", "initial_pattern_editor", "evolution_tracker"],
		"queer_elements": ["life_redefinition", "reproduction_alternatives"]
	  },
	  "3": {
		"title": "Non-Euclidean Maze",
		"summary": "Impossible geometries",
		"description": "Navigate through spaces that violate the rules of conventional geometry. Experience rooms that are bigger on the inside, corridors that bend back on themselves impossibly, and other spatial paradoxes that challenge our understanding of space.",
		"xp_reward": 55,
		"icons": ["queer", "shader", "procedural"],
		"unlocks": ["Pattern_4"],
		"environment": "impossible_architecture",
		"special_objects": ["portal_connections", "space_warpers", "perspective_illusions"],
		"queer_elements": ["spatial_fluidity", "geometric_subversion"]
	  },
	  "4": {
		"title": "AI Collaboration Studio",
		"summary": "Human-AI creative partnership",
		"description": "Create art, music, or narratives in collaboration with AI systems. Take turns with AI collaborators to build on each other's contributions, exploring the creative potential of human-machine partnerships and challenging notions of authorship.",
		"xp_reward": 55,
		"icons": ["ai", "neural-net", "queer"],
		"unlocks": ["Pattern_5"],
		"environment": "creative_studio",
		"special_objects": ["ai_collaborators", "creative_tools", "gallery_space"],
		"queer_elements": ["authorship_blurring", "creative_hybridity"]
	  },
	  "5": {
		"title": "Entropy Portal",
		"summary": "Order, disorder, and transformation",
		"description": "Manipulate entropy levels to transform environments between states of order and chaos. Explore entropy as a unifying concept across information theory, thermodynamics, and creative processes, finding beauty and potential in both order and disorder.",
		"xp_reward": 60,
		"icons": ["entropy", "queer", "random"],
		"unlocks": ["Tech_0"],
		"environment": "entropy_nexus",
		"special_objects": ["entropy_dial", "state_transformer", "order_chaos_visualizer"],
		"queer_elements": ["binary_transcendence", "transformative_potential"]
	  }
	},
	"Tech": {
	  "0": {
		"title": "Swarm Intelligence Collective",
		"summary": "Emergent group behavior",
		"description": "Explore how simple rules followed by individual agents can create complex collective behaviors. Modify the rules governing bird flocks, fish schools, and other swarms to observe different emergent patterns and problem-solving abilities.",
		"xp_reward": 50,
		"icons": ["simulation", "random", "ai"],
		"unlocks": ["Tech_1"],
		"environment": "swarm_space",
		"special_objects": ["rule_adjuster", "agent_spawner", "behavior_analyzer"],
		"queer_elements": ["collective_identity", "individual_dissolution"]
	  },
	  "1": {
		"title": "Chaos Theory Laboratory",
		"summary": "Order within disorder",
		"description": "Experiment with chaotic systems where tiny initial differences lead to dramatically different outcomes. Interact with double pendulums, strange attractors, and other chaotic systems to explore the boundary between determinism and unpredictability.",
		"xp_reward": 50,
		"icons": ["random", "physics", "time"],
		"unlocks": ["Tech_2"],
		"environment": "chaos_chamber",
		"special_objects": ["initial_condition_setter", "trajectory_tracker", "attractor_visualizer"],
		"queer_elements": ["predictability_breakdown", "determinism_questioning"]
	  },
	  "2": {
		"title": "Algorithmic Life Incubator",
		"summary": "Digital organism simulation",
		"description": "Create and observe digital life forms based on cellular automata and artificial life algorithms. Design rule sets and initial conditions to generate self-replicating patterns, evolving systems, and other life-like behaviors from simple rules.",
		"xp_reward": 50,
		"icons": ["genetic", "simulation", "ai"],
		"unlocks": ["Tech_3"],
		"environment": "digital_petri_dish",
		"special_objects": ["rule_designer", "initial_pattern_editor", "evolution_tracker"],
		"queer_elements": ["life_redefinition", "reproduction_alternatives"]
	  },
	  "3": {
		"title": "Non-Euclidean Maze",
		"summary": "Impossible geometries",
		"description": "Navigate through spaces that violate the rules of conventional geometry. Experience rooms that are bigger on the inside, corridors that bend back on themselves impossibly, and other spatial paradoxes that challenge our understanding of space.",
		"xp_reward": 55,
		"icons": ["queer", "shader", "recursion"],
		"unlocks": ["Tech_4"],
		"environment": "impossible_architecture",
		"special_objects": ["portal_connections", "space_warpers", "perspective_illusions"],
		"queer_elements": ["spatial_fluidity", "geometric_subversion"]
	  },
	  "4": {
		"title": "AI Collaboration Studio",
		"summary": "Human-AI creative partnership",
		"description": "Create art, music, or narratives in collaboration with AI systems. Take turns with AI collaborators to build on each other's contributions, exploring the creative potential of human-machine partnerships and challenging notions of authorship.",
		"xp_reward": 55,
		"icons": ["ai", "neural-net", "queer"],
		"unlocks": ["Tech_5"],
		"environment": "creative_studio",
		"special_objects": ["ai_collaborators", "creative_tools", "gallery_space"],
		"queer_elements": ["authorship_blurring", "creative_hybridity"]
	  },
	  "5": {
		"title": "Entropy Portal",
		"summary": "Order, disorder, and transformation",
		"description": "Manipulate entropy levels to transform environments between states of order and chaos. Explore entropy as a unifying concept across information theory, thermodynamics, and creative processes, finding beauty and potential in both order and disorder.",
		"xp_reward": 60,
		"icons": ["entropy", "queer", "random"],
		"unlocks": [],
		"environment": "entropy_nexus",
		"special_objects": ["entropy_dial", "state_transformer", "order_chaos_visualizer"],
		"queer_elements": ["binary_transcendence", "transformative_potential"]
	  }
	}
  },
  "objects": {
	"navigation_terminal": {
	  "description": "A holographic interface that shows the player's progress through different zones",
	  "interactions": ["view_progress", "teleport_to_unlocked_levels"]
	},
	"zone_portals": {
	  "description": "Shimmering doorways that lead to different algorithmic exploration zones",
	  "interactions": ["enter_zone", "preview_zone"]
	},
	"ada_hologram": {
	  "description": "An interactive hologram of Ada Lovelace that provides historical context and guidance",
	  "interactions": ["ask_questions", "request_hints", "learn_history"]
	},
	"analytical_engine": {
	  "description": "A virtual recreation of Babbage's analytical engine with working parts",
	  "interactions": ["examine_components", "run_simple_programs", "trace_computation"]
	},
	"random_generators": {
	  "description": "Devices that produce different types of random distributions",
	  "interactions": ["generate_uniform", "generate_gaussian", "generate_perlin"]
	},
	"seed_planters": {
	  "description": "Tools for planting virtual seeds that grow according to Fibonacci patterns",
	  "interactions": ["plant_seed", "adjust_growth_parameters", "accelerate_growth"]
	},
	"noise_controllers": {
	  "description": "Control panels for adjusting Perlin noise parameters",
	  "interactions": ["adjust_frequency", "adjust_amplitude", "adjust_octaves", "save_preset"]
	},
	"point_placer": {
	  "description": "A tool for placing generator points in Voronoi space",
	  "interactions": ["place_point", "move_point", "delete_point", "randomize_points"]
	},
	"wave_generator": {
	  "description": "A device that creates sine waves with adjustable parameters",
	  "interactions": ["adjust_frequency", "adjust_amplitude", "adjust_phase", "combine_waves"]
	},
	"zoom_portal": {
	  "description": "A portal that allows infinite zooming into fractal structures",
	  "interactions": ["zoom_in", "zoom_out", "pan", "mark_interesting_location"]
	},
	"field_manipulator": {
	  "description": "A tool for shaping and directing flow fields",
	  "interactions": ["draw_direction", "create_vortex", "create_attractor", "create_repeller"]
	},
	"shape_drawer": {
	  "description": "A 3D drawing tool that converts shapes into frequency spectra",
	  "interactions": ["draw_shape", "erase", "transform_to_frequency", "transform_from_frequency"]
	},
	"rule_editor": {
	  "description": "An interface for modifying L-system rules or other procedural generation rules",
	  "interactions": ["edit_rules", "test_rules", "save_preset", "load_preset"]
	},
	"deformable_objects": {
	  "description": "Objects with different soft body physics properties",
	  "interactions": ["stretch", "compress", "twist", "throw", "adjust_properties"]
	},
	"morphing_objects": {
	  "description": "Objects that can be topologically transformed while preserving certain properties",
	  "interactions": ["morph", "identify_invariants", "demonstrate_equivalence"]
	},
	"chemical_injectors": {
	  "description": "Tools for adding reactants to reaction-diffusion systems",
	  "interactions": ["inject_chemical_a", "inject_chemical_b", "clear_system", "save_pattern"]
	},
	"node_creator": {
	  "description": "A tool for creating and connecting nodes in a network",
	  "interactions": ["create_node", "connect_nodes", "disconnect_nodes", "simulate_flow"]
	},
	"parameter_controls": {
	  "description": "Interfaces for adjusting generation parameters in procedural systems",
	  "interactions": ["adjust_parameter", "randomize_parameters", "save_preset", "load_preset"]
	},
	"input_feed": {
	  "description": "A system for feeding different inputs to a neural network",
	  "interactions": ["select_input", "feed_input", "observe_output", "train_network"]
	},
	"shader_editor": {
	  "description": "An interface for creating and modifying shader programs",
	  "interactions": ["edit_code", "preview_effect", "apply_to_object", "save_shader"]
	},
	"environment_controls": {
	  "description": "Tools for adjusting environmental conditions in evolutionary simulations",
	  "interactions": ["adjust_resource_level", "add_obstacle", "change_environmental_pressure"]
	},
	"rule_adjuster": {
	  "description": "Controls for modifying the behavior rules of swarm agents",
	  "interactions": ["adjust_separation", "adjust_alignment", "adjust_cohesion", "introduce_goal"]
	},
	"initial_condition_setter": {
	  "description": "A precision tool for setting starting conditions in chaotic systems",
	  "interactions": ["set_position", "set_velocity", "slightly_perturb", "reset_system"]
	},
	"rule_designer": {
	  "description": "An interface for creating rules for cellular automata and artificial life",
	  "interactions": ["set_birth_rules", "set_survival_rules", "draw_initial_state", "run_simulation"]
	},
	"portal_connections": {
	  "description": "Doorways that connect spaces in non-intuitive ways",
	  "interactions": ["enter_portal", "reconfigure_connection", "visualize_connection"]
	},
	"ai_collaborators": {
	  "description": "AI systems that collaborate with the player on creative projects",
	  "interactions": ["submit_contribution", "request_ai_contribution", "evaluate_result", "iterate"]
	},
	"entropy_dial": {
	  "description": "A control that adjusts entropy levels in the surrounding environment",
	  "interactions": ["increase_entropy", "decrease_entropy", "target_specific_system", "observe_effects"]
	}
  },
  "achievements": {
	"explorer": {
	  "title": "Algorithm Explorer",
	  "description": "Visit every level in a zone",
	  "icon": "compass",
	  "xp_reward": 50
	},
	"experimenter": {
	  "title": "Digital Experimenter",
	  "description": "Interact with 20 different objects",
	  "icon": "flask",
	  "xp_reward": 30
	},
	"creator": {
	  "title": "Pattern Creator",
	  "description": "Save 10 custom patterns or presets",
	  "icon": "paintbrush",
	  "xp_reward": 40
	},
	"theorist": {
	  "title": "Algorithm Theorist",
	  "description": "Read all documentation entries in a zone",
	  "icon": "book",
	  "xp_reward": 35
	},
	"disruptor": {
	  "title": "Entropy Disruptor",
	  "description": "Create high-entropy states in 5 different systems",
	  "icon": "lightning",
	  "xp_reward": 45
	}
  }
}

# Current level tracking
var current_level_category: String = "intro"
var current_level_id: int = 0

# Signals
signal level_loaded(category, id, data)
signal level_completed(category, id, xp_reward)

func _ready() -> void:
	# Initialize with first level
	if not GameManager.game_started:
		load_level("intro", 0)

# Load a specific level
func load_level(category: String, id: int) -> bool:
	if levels_data.has(category) and levels_data[category].has(id):
		current_level_category = category
		current_level_id = id
		
		# Set current message in GameManager to level title
		var level_data = levels_data[category][id]
		GameManager.set_message(level_data.title)
		
		emit_signal("level_loaded", category, id, level_data)
		print("LevelsManager: Loaded level " + category + "_" + str(id) + ": " + level_data.title)
		return true
	else:
		print("LevelsManager: Failed to load level " + category + "_" + str(id) + " - Not found")
		return false

# Load the next level
func next_level() -> bool:
	# Check if next level exists in current category
	if levels_data[current_level_category].has(current_level_id + 1):
		return load_level(current_level_category, current_level_id + 1)
	else:
		# Try to load first level of next category
		# This is a simple implementation - you might want more sophisticated logic
		var categories = levels_data.keys()
		var current_index = categories.find(current_level_category)
		
		if current_index >= 0 and current_index < categories.size() - 1:
			var next_category = categories[current_index + 1]
			return load_level(next_category, 0)
	
	print("LevelsManager: No next level available")
	return false

# Mark current level as completed
func complete_current_level() -> void:
	var level_data = get_current_level_data()
	if level_data:
		# Award XP
		if level_data.has("xp_reward"):
			GameManager.update_xp(level_data.xp_reward)
		
		emit_signal("level_completed", current_level_category, current_level_id, level_data.get("xp_reward", 0))
		print("LevelsManager: Completed level " + current_level_category + "_" + str(current_level_id))

# Get current level data
func get_current_level_data() -> Dictionary:
	if levels_data.has(current_level_category) and levels_data[current_level_category].has(current_level_id):
		return levels_data[current_level_category][current_level_id]
	return {}

# Get data for a specific level
# Get data for a specific level
func get_level_data(category, id):
	# Convert category to proper case to match JSON structure
	var proper_category = category.capitalize()  # This will capitalize the first letter

	if levels_data.has("levels") and levels_data.levels.has(proper_category) and levels_data.levels[proper_category].has(str(id)):
		return levels_data.levels[proper_category][str(id)]
	else:
		print("LevelsManager: Level data not found for " + category + "/" + str(id))
		return {}

# Check if a level is unlocked
func is_level_unlocked(category: String, id: int) -> bool:
	# This is a basic implementation - you might want to store unlocked levels
	# in a separate array and check against that for a proper game
	
	# For now, let's just consider sequential unlocking
	if category == "intro" and id == 0:
		return true  # First level is always unlocked
	
	# Check if previous level exists and is completed
	if id > 0 and levels_data.has(category) and levels_data[category].has(id - 1):
		return true  # Assuming previous level is completed
	
	# More complex unlocking logic would go here
	
	return false

# Save and load level progress
# These could be integrated with GameManager's save/load functions
func save_level_progress() -> Dictionary:
	var progress_data = {
		"current_level_category": current_level_category,
		"current_level_id": current_level_id,
		# You would add other tracking data here, like completed levels
	}
	return progress_data

func load_level_progress(progress_data: Dictionary) -> void:
	if progress_data.has("current_level_category") and progress_data.has("current_level_id"):
		load_level(progress_data.current_level_category, progress_data.current_level_id)
