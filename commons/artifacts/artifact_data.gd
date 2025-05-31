extends Node3D


const ARTIFACTS_JSON := [
	{
		"artifact_name": "start menu",
		"lookup_name": "start_menu",
		"description": "A tabel with the cube rotating box in queer void. Pick it up to start the game. To exit now touch the pass through sphere.",
		"scene": "res://adaresearch/Common/Scenes/Menu/StartMenu/StartMenu.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Menu/StartMenu/README.md"
 	},
	{
		"artifact_name": "The Cube and the Exit",
		"lookup_name": "cube_one_exit",
		"description": "Remember a world where there was a box and an exit",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/CubeOneWithAndExit/CubeOneWithAndExit.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Cubes/CubeOneWithNExit/README.md"
 	},
	
	{
		"artifact_name": "menu",
		"lookup_name": "menu",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Maps/menu.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Maps/README.md"
 	},
	{
		"artifact_name": "First There Was Code",
		"lookup_name": "first_code",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/FirstThereWasCode/first_there_was_code.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/FirstThereWasCode/README.md"
 	},
	{
		"artifact_name": "Init Grid",
		"lookup_name": "init_grid",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/cube_sequence_array.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Cubes/README.md"
 	},
	{
		"artifact_name": "line_shader",
		"lookup_name": "line_shader",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/Grids/line_shader.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Grids/README.md"
 	},
	{
		"artifact_name": "gridshaders",
		"lookup_name": "gridshaders",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/Grids/gridshaders.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Grids/README.md"
 	},
	
	{
		"artifact_name": "cube_patterns_array",
		"lookup_name": "cube_patterns_array",
		"description": "cube_patterns_array",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/cube_patterns_array.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Cubes/README.md"
 	},
	{
		"artifact_name": "grabable_xyz",
		"lookup_name": "grabable_xyz",
		"description": "grabable_xyz",
		"scene": "res://adaresearch/Common/Scenes/Context/pickableXYZ/grabable_xyz.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/pickableXYZ/README.md"
 	},
	{
		"artifact_name": "cameraFeedBack",
		"lookup_name": "cameraFeedBack",
		"description": "cameraFeedBack",
		"scene": "res://adaresearch/Common/Scenes/Context/CameraFeedBack/cameraFeedBack.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CameraFeedBack/README.md"
 	},
	{
		"artifact_name": "Grid array",
		"lookup_name": "grid_array",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/cube_sequence_array_explained.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Cubes/README.md"
 	},
	{
		"artifact_name": "Mondrian 2d",
		"lookup_name": "mondrian_2d",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/CombineGrids/Mondrian2d/mondrian_2d.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CombineGrids/Mondrian2d/README.md"
 	},
		{
		"artifact_name": "grabable_mondrian",
		"lookup_name": "grabable_mondrian",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/CombineGrids/Mondrian2d/grabable_mondrian.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CombineGrids/Mondrian2d/README.md"
 	},
	{
		"artifact_name": "grabable_agnes",
		"lookup_name": "grabable_agnes",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/CombineGrids/Agnes_Matrin_Grid/agnes_grid_3d.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CombineGrids/Agnes_Matrin_Grid/README.md"
 	},
	{
		"artifact_name": "zelda_tiles_3d",
		"lookup_name": "zelda_tiles_3d",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/CombineGrids/ZeldaTilemap/zelda_tiles_3d.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CombineGrids/ZeldaTilemap/README.md"
 	},

	{
		"artifact_name": "Zelda Tilemap",
		"lookup_name": "zelda_tilemap",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/CombineGrids/ZeldaTilemap/zelda_tilemap.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/CombineGrids/ZeldaTilemap/README.md"
 	},
		{
		"artifact_name": "Pick Up Cube",
		"lookup_name": "pick_up_cube",
		"description": "First There Was Code transforms a featureless void into a fully interactive VR world through a gradual, animated unveiling of digital structures and interfaces.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/cube_sequence_pickup.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/Cubes/README.md"
 	},

	{
		"artifact_name": "Moving Panels",
		"lookup_name": "moving_panels",
		"description": "These panels embody a paradoxical dance of attraction and repulsion—drawn to face the player with magnetic fascination yet recoiling with delicate apprehension when approached too closely, creating an ever-shifting field of responsive entities that mirror human social dynamics.",
		"scene": "res://adaresearch/Common/Scenes/Context/MovingPanels/moving_panels.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/MovingPanels/README.md"
	},
	{
		"artifact_name": "Random Wood Boxes",
		"lookup_name": "random_wood_boxes",
		"description": "continuously creates wooden cube objects at a fixed position until reaching a maximum limit, after which it replaces random existing cubes with new ones",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/random_object_spawner.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/README.md"
	},
	{
		"artifact_name": "Random Walk Collection",
		"lookup_name": "random_walk_collection",
		"description": "continuously creates wooden cube objects at a fixed position until reaching a maximum limit, after which idynamically generated visualization of various random walk patterns that evolve when the object is picked up and stops when dropped",
		"scene": "res://adaresearch/Algorithms/Randomness/RandomWalk/Scenes/random_walk_collection.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/RandomWalk/Scenes/README.md"
	},
	{
		"artifact_name": "resonance_frequencies_visualizer",
		"lookup_name": "resonance_frequencies_visualizer",
		"description": "resonance_frequencies_visualizer",
		"scene": "res://adaresearch/Algorithms/SineAndSound/ResonanceFrequencies/resonance_frequencies_visualizer_setup.tscn",
		"readme_link": "res://adaresearch/Algorithms/SineAndSound/ResonanceFrequencies/README.md"
	},
	{
		"artifact_name": "random sort panel",
		"lookup_name": "sort_L_panels",
		"description": "random sort panel",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/RandomSortPanel/random_sort_panel.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/RandomSortPanel/README.md"
	},
	{
		"artifact_name": "random_number_book_page_collection",
		"lookup_name": "random_number_book_page_collection",
		"description": "random_number_book_page_collection",
		"scene": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/random_number_book_page_collection.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/README.md"
	},
	{
		"artifact_name": "random_color_book_page_collection",
		"lookup_name": "random_color_book_page_collection",
		"description": "random_color_book_page_collection",
		"scene": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/random_color_book_page_collection.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/README.md"
	},
	{
		"artifact_name": "random_object_spawner",
		"lookup_name": "random_object_spawner",
		"description": "random_object_spawner",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/random_object_spawner.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/README.md"
	},
	{
		"artifact_name": "spawn_randomcubes",
		"lookup_name": "spawn_randomcubes",
		"description": "spawn_randomcubes",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/ObjectTransforms/Scenes/spawn_randomcubes.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/ObjectTransforms/Scenes/README.md"
	},
	
	{
		"artifact_name": "random_edge_profile_collection",
		"lookup_name": "random_edge_profile_collection",
		"description": "random_edge_profile_collection",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/random_edge_profile_collection.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/README.md"
	},
		{
		"artifact_name": "TorusBlaster",
		"lookup_name": "TorusBlaster",
		"description": "TorusBlaster",
		"scene": "res://adaresearch/Common/Scenes/Player/Weapons/TorusBlaster/TorusBlaster.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Player/Weapons/TorusBlaster/README.md"
	},
	
	{
		"artifact_name": "butterflies",
		"lookup_name": "butterflies",
		"description": "butterflies",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/RandomButterFlies/butterflies.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/RandomButterFlies/README.md"
	},
	{
		"artifact_name": "vertical_block_animator_collection",
		"lookup_name": "vertical_block_animator_collection",
		"description": "vertical_block_animator_collection",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/VerticalBlockAnimator/vertical_block_animator_collection.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/VerticalBlockAnimator/README.md"
	},
		{
		"artifact_name": "bubble_particles",
		"lookup_name": "bubble_particles",
		"description": "bubble_particles",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/BubbleParticles/bubble_particles.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/BubbleParticles/README.md"
	},
		{
		"artifact_name": "random_wall",
		"lookup_name": "random_wall",
		"description": "random_wall",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/RandomWall/random_wall.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/RandomWall/README.md"
	},
		{
		"artifact_name": "random_increase_wall",
		"lookup_name": "random_increase_wall",
		"description": "random_increase_wall",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/IncreaseRandomnessWall/random_increase_wall.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/Scenes/IncreaseRandomnessWall/README.md"
	},
	{
		"artifact_name": "ProbabilityDistributions3D",
		"lookup_name": "ProbabilityDistributions3D",
		"description": "ProbabilityDistributions3D",
		"scene": "res://adaresearch/Algorithms/Randomness/Distributions/ProbabilityDistributions3D.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Distributions/README.md"
	},
	{
		"artifact_name": "RandomGaussianTexture",
		"lookup_name": "RandomGaussianTexture",
		"description": "RandomGaussianTexture",
		"scene": "res://adaresearch/Algorithms/Randomness/Distributions/Gaussian/Scenes/RandomGaussianTexture.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Distributions/Gaussian/Scenes/README.md"
	},
	
	{
		"artifact_name": "pollock_3d",
		"lookup_name": "pollock_3d",
		"description": "pollock_3d",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/pollock_3D/pollock_3d.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/pollock_3D/README.md"
	},
	{
		"artifact_name": "paint_dripping_2d",
		"lookup_name": "paint_dripping_2d",
		"description": "paint_dripping_2d",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/Pollock_2D/PollockPaintingIn3d.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/MovementBased/Scenes/Pollock_2D/README.md"
	},
	{
		"artifact_name": "ten_print_maze_3d",
		"lookup_name": "ten_print_maze_3d",
		"description": "ten_print_maze_3d",
		"scene": "res://adaresearch/Algorithms/Randomness/Generative/TenPrintAntMaze/ten_print_maze_3d.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Generative/TenPrintAntMaze/README.md"
	},
		{
		"artifact_name": "Particle randomness",
		"lookup_name": "particle_randomness",
		"description": "Particle randomness",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/ParticleRandomness/extrem_randomness.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/ParticleRandomness/README.md"
	},
{
		"artifact_name": "radiolaria",
		"lookup_name": "radiolaria",
		"description": "radiolaria",
		"scene": "res://adaresearch/Algorithms/ComputationalBiology/Radiolaria/radiolaria.tscn",
		"readme_link": "res://adaresearch/Algorithms/ComputationalBiology/Radiolaria/README.md"
	},
	{
		"artifact_name": "omoss",
		"lookup_name": "omoss",
		"description": "omoss",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/omoss/omoss.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/omoss/README.md"
	},
	{
		"artifact_name": "mc_clould_packing",
		"lookup_name": "mc_clould_packing",
		"description": "mc_clould_packing",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/McCluld/mc_clould.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/McCluld/README.md"
	},
		{
		"artifact_name": "kusama_sine",
		"lookup_name": "kusama_sine",
		"description": "kusama_sine",
		"scene": "res://adaresearch/Algorithms/SineAndSound/KusamaSine/kusama_sine.tscn",
		"readme_link": "res://adaresearch/Algorithms/SineAndSound/KusamaSine/README.md"
	},
	{
		"artifact_name": "caveSystem",
		"lookup_name": "caveSystem",
		"description": "caveSystem",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/caveSystem/caveSystem.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/caveSystem/README.md"
	},
	{
		"artifact_name": "liquid_simulation",
		"lookup_name": "liquid_simulation",
		"description": "liquid_simulation",
		"scene": "res://adaresearch/Algorithms/ProceduralGeneration/ParticleBasedSimulation/LiquidSimulation/liquid_simulation.tscn",
		"readme_link": "res://adaresearch/Algorithms/ProceduralGeneration/ParticleBasedSimulation/LiquidSimulation/README.md"
	},
	{
		"artifact_name": "LyapunovExponents_2d_in_3d",
		"lookup_name": "LyapunovExponents_2d_in_3d",
		"description": "LyapunovExponents_2d_in_3d",
		"scene": "res://adaresearch/Algorithms/Chaos/LyapunovExponents/LyapunovExponents_2d_in_3d.tscn",
		"readme_link": "res://adaresearch/Algorithms/Chaos/LyapunovExponents/README.md"
	},
	{
		"artifact_name": "layered_membrane",
		"lookup_name": "layered_membrane",
		"description": "layered_membrane",
		"scene": "res://adaresearch/Algorithms/ProceduralGeneration/LayeredMembrane/layered_membrane.tscn",
		"readme_link": "res://adaresearch/Algorithms/ProceduralGeneration/LayeredMembrane/README.md"
	},
	{
		"artifact_name": "cellular_automata_grabable",
		"lookup_name": "cellular_automata_grabable",
		"description": "cellular_automata_grabable",
		"scene": "res://adaresearch/Algorithms/ProceduralGeneration/CellularAutomata/Scenes/cellular_automata_grabable.tscn",
		"readme_link": "res://adaresearch/Algorithms/ProceduralGeneration/CellularAutomata/Scenes/README.md"
	},
	{
		"artifact_name": "self_organization_principle",
		"lookup_name": "self_organization_principle",
		"description": "self_organization_principle",
		"scene": "res://adaresearch/Algorithms/EmergentSystems/Self-OrganizingPatterns/self_organization_principles.tscn",
		"readme_link": "res://adaresearch/Algorithms/EmergentSystems/Self-OrganizingPatterns/README.md"
	},
	
	{
		"artifact_name": "NeonWaveGrid",
		"lookup_name": "NeonWaveGrid",
		"description": "NeonWaveGrid",
		"scene": "res://adaresearch/Algorithms/Randomness/Noise/PerlinNoise/Scenes/NeonWaveGrid.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Noise/PerlinNoise/Scenes/README.md"
	},
		{
		"artifact_name": "cellshader",
		"lookup_name": "cellshader",
		"description": "cellshader",
		"scene": "res://adaresearch/Algorithms/Randomness/Noise/CellularNoise/Scenes/cellshader.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Noise/CellularNoise/Scenes/README.md"
	},
	{
		"artifact_name": "pool_hole_noise",
		"lookup_name": "pool_hole_noise_terrain",
		"description": "pool_hole_noise",
		"scene": "res://adaresearch/Algorithms/Randomness/Noise/CellularNoise/Scenes/pool_hole_noise.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Noise/CellularNoise/Scenes/README.md"
	},
	{
		"artifact_name": "MonteCarloProteinChainSimulation",
		"lookup_name": "MonteCarloProteinChainSimulation",
		"description": "MonteCarloProteinChainSimulation",
		"scene": "res://adaresearch/Algorithms/ComputationalBiology/MonteCarloProteinChainSimulation/monte_carl_methods_protein.tscn",
		"readme_link": "res://adaresearch/Algorithms/ComputationalBiology/MonteCarloProteinChainSimulation/README.md"
	},
	{
		"artifact_name": "bucket_of_tulips",
		"lookup_name": "bucket_of_tulips",
		"description": "bucket_of_tulips",
		"scene": "res://adaresearch/Algorithms/ComputationalBiology/BucketOfTulips/bucket_of_tulips.tscn",
		"readme_link": "res://adaresearch/Algorithms/ComputationalBiology/BucketOfTulips/README.md"
	},
	
	{
		"artifact_name": "metaballs",
		"lookup_name": "metaballs",
		"description": "metaballs",
		"scene": "res://adaresearch/Algorithms/ProceduralGeneration/ImplicitSurfaceModeling/metaballs/metaballs.tscn",
		"readme_link": "res://adaresearch/Algorithms/ProceduralGeneration/ImplicitSurfaceModeling/metaballs/README.md"
	},
		{
		"artifact_name": "boids",
		"lookup_name": "boids",
		"description": "boids",
		"scene": "res://adaresearch/Algorithms/EmergentSystems/BoidFlocking/boid_manager.tscn",
		"readme_link": "res://adaresearch/Algorithms/EmergentSystems/BoidFlocking/README.md"
	},
	{
		"artifact_name": "Strange Attractors",
		"lookup_name": "strange_attractors",
		"description": "Interactive visualization of chaotic dynamical systems including Lorenz, Rössler, and queer-theoretical attractors with real-time parameter control and chaos analysis.",
		"scene": "res://adaresearch/Algorithms/StrangeAttractors/StrangeAttractorScene.tscn",
		"readme_link": "res://adaresearch/Algorithms/StrangeAttractors/README.md"
	},
	{
		"artifact_name": "Hyperbolic Space",
		"lookup_name": "hyperbolic_space",
		"description": "Explore hyperbolic geometry through interactive VR environments that demonstrate non-Euclidean spatial relationships and curved space-time visualization.",
		"scene": "res://adaresearch/Algorithms/AlternativeGeometries/HyperbolicSpace/HyperbolicScene.tscn",
		"readme_link": "res://adaresearch/Algorithms/AlternativeGeometries/HyperbolicSpace/README.md"
	},
	{
		"artifact_name": "Rhizomatic Structures",
		"lookup_name": "rhizomatic_structures",
		"description": "Experience rhizomatic thinking through non-hierarchical network structures that challenge traditional tree-based organizational models with fluid, interconnected pathways.",
		"scene": "res://adaresearch/Algorithms/AlternativeGeometries/RhizomaticStructures/RhizomaticInteriorScene.tscn",
		"readme_link": "res://adaresearch/Algorithms/AlternativeGeometries/RhizomaticStructures/README.md"
	},
	{
		"artifact_name": "Mobius Walk",
		"lookup_name": "mobius_walk",
		"description": "Navigate the paradoxical surface of a Möbius strip where inside becomes outside, demonstrating topological continuity and non-orientable surfaces.",
		"scene": "res://adaresearch/Algorithms/AlternativeGeometries/MobiusWalk/MobiusWalkScene.tscn",
		"readme_link": "res://adaresearch/Algorithms/AlternativeGeometries/MobiusWalk/README.md"
	},
	{
		"artifact_name": "Reaction Diffusion Systems",
		"lookup_name": "reaction_diffusion_system",
		"description": "Interactive simulation of pattern formation through chemical reactions and diffusion processes, creating biological-like structures and textures.",
		"scene": "res://adaresearch/Algorithms/NonlinearSystems/ReactionDiffusion/ReactionDiffusionScene.tscn",
		"readme_link": "res://adaresearch/Algorithms/NonlinearSystems/ReactionDiffusion/README.md"
	},
	{
		"artifact_name": "L-System Tree Generation",
		"lookup_name": "l_system_tree",
		"description": "Procedural generation of tree-like structures using Lindenmayer systems, demonstrating recursive growth patterns found in nature.",
		"scene": "res://adaresearch/Algorithms/ProceduralGeneration/LSystem/Scenes/tree_l_system.tscn",
		"readme_link": "res://adaresearch/Algorithms/ProceduralGeneration/LSystem/README.md"
	},
	{
		"artifact_name": "Random Decay Objects",
		"lookup_name": "random_decay_objects",
		"description": "Simulation of random decay processes in objects, visualizing probabilistic degradation over time with interactive controls.",
		"scene": "res://adaresearch/Algorithms/Randomness/RandomDecay/Scenes/random_decay_objects.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/RandomDecay/README.md"
	},
	{
		"artifact_name": "Random Plants Generation",
		"lookup_name": "random_plants",
		"description": "Procedural generation of plant-like structures using randomness and geometric growth algorithms for organic forms.",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/RandomPlants/random_plants.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/RandomPlants/README.md"
	},
	{
		"artifact_name": "McClould Packing 2",
		"lookup_name": "mc_clould_packing_2",
		"description": "Advanced circle packing algorithms with enhanced visualization and interaction capabilities for spatial optimization.",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/McCluld/mc_clould_2.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/McCluld/README.md"
	},
	
	{
		"artifact_name": "test1",
		"lookup_name": "test1",
		"description": "test1",
		"scene": "res://adaresearch/Common/Scenes/Context/infoBoards/Vectors/2d_in_3d_vectors_vis.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/infoBoards/Vectors/README.md"
	},
		
	{
		"artifact_name": "test2",
		"lookup_name": "test2",
		"description": "test2",
		"scene": "res://adaresearch/Common/Scenes/Context/infoBoards/Arrays/2d_in_3d_array_vis.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/infoBoards/Arrays/README.md"
	},
		
	{
		"artifact_name": "test3",
		"lookup_name": "test3",
		"description": "test3",
		"scene": "res://adaresearch/Common/Scenes/Context/infoBoards/Forces/2d_in_3d_forces_vis.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/infoBoards/Forces/README.md"
	},
	
	{
		"artifact_name": "kitbashing",
		"lookup_name": "kitbashing",
		"description": "kitbashing",
		"scene": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/kitbashing/kitbashing.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/ProceduralRandomness/GeometryBased/kitbashing/README.md"
	},
	
	{
		"artifact_name": "Tune the radio",
		"lookup_name": "tune_radio",
		"description": "Tune the frequencies, Find the hidden message or some nice music.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Arrange sticker notes",
		"lookup_name": "arrange_stickers",
		"description": "Organize the sticker notes by color",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Explore research images",
		"lookup_name": "explore_images",
		"description": "Look closely at the research images",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Draw a Circle",
		"lookup_name": "draw_circle",
		"description": "Create a perfect circle on the canvas",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	}, 
	{
		"artifact_name": "See the Queer Eye",
		"lookup_name": "see_queer_eye",
		"description": "Discover the queer perspective through the lens",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	}, 
	{
		"artifact_name": "Queer Edge of Entropy",
		"lookup_name": "queer_edge_entropy",
		"description": "Explore the boundaries of order and chaos to discover new edges in a queer world.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Randomness and Its Limits",
		"lookup_name": "randomness_limits",
		"description": "Investigate the limits and frameworks surrounding randomness in time and space.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Small Change in Scale and Rotation",
		"lookup_name": "scale_rotation_change",
		"description": "Use minor adjustments in scale and rotation to mimic organic growth.",
		"scene": "res://adaresearch/Common/Scenes/Context/Cubes/basic_cube.tscn",
		"readme_link": "res://adaresearch/Common/Scenes/Context/GridControl/README.md"
	},
	{
		"artifact_name": "Recursive Self Observer",
		"lookup_name": "recursive_self_observer",
		"description": "Explores identity formation through recursive loops of observation, where the act of observing alters the observed.",
		"scene": "res://adaresearch/Algorithms/RecursiveObserver/Scenes/self_observer_system.tscn",
		"readme_link": "res://adaresearch/Algorithms/RecursiveObserver/README.md"
	},
	{
		"artifact_name": "Non-Euclidean Space",
		"lookup_name": "non_euclidean_space",
		"description": "Experience spatial paradoxes and impossible geometry through non-Euclidean space principles that challenge conventional perceptions of 3D environments.",
		"scene": "res://adaresearch/Algorithms/AlternativeGeometries/Non-EuclideanSpace/non_euclidean_space.tscn",
		"readme_link": "res://adaresearch/Algorithms/AlternativeGeometries/Non-EuclideanSpace/README.md"
	},
	{
		"artifact_name": "Quantum Identity Superposition",
		"lookup_name": "quantum_identity_superposition",
		"description": "Explores the quantum principle of superposition applied to identity formation, where multiple identity states coexist until observation collapses possibilities.",
		"scene": "res://adaresearch/Algorithms/QuantumAlgorithms/Scenes/quantum_identity_superposition.tscn",
		"readme_link": "res://adaresearch/Algorithms/QuantumAlgorithms/README.md"
	},
	{
		"artifact_name": "Boundary Dissolution",
		"lookup_name": "boundary_dissolution",
		"description": "Visualizes the process of dissolving boundaries between defined categories, representing the fluid nature of identity and categorization systems.",
		"scene": "res://adaresearch/Algorithms/EmergentSystems/BoundaryDissolution/boundary_dissolution_visualizer.tscn",
		"readme_link": "res://adaresearch/Algorithms/EmergentSystems/BoundaryDissolution/README.md"
	},
	{
		"artifact_name": "Fluid Gaussian",
		"lookup_name": "fluid_gaussian",
		"description": "Demonstrates Gaussian distribution patterns in fluid dynamics, showing how randomness follows predictable statistical patterns even in complex systems.",
		"scene": "res://adaresearch/Algorithms/Randomness/Distributions/Scenes/fluid_gaussian.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/Distributions/Scenes/README.md"
	},
	{
		"artifact_name": "Visual Poetry",
		"lookup_name": "visual_poetry",
		"description": "Transforms random number sequences into visual poetry, revealing aesthetic patterns emerging from randomness.",
		"scene": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/visual_poetry.tscn",
		"readme_link": "res://adaresearch/Algorithms/Randomness/RandomNumberGeneration/Scenes/README.md"
	},
	{
		"artifact_name": "Fluid Identity Flock",
		"lookup_name": "fluid_identity_flock",
		"description": "Explores how individual identities can maintain uniqueness while participating in collective movement and shared purpose through flocking algorithms.",
		"scene": "res://adaresearch/Algorithms/EmergentSystems/BoidFlocking/Scenes/fluid_identity_flock.tscn",
		"readme_link": "res://adaresearch/Algorithms/EmergentSystems/BoidFlocking/README.md"
	},
	{
		"artifact_name": "Fluid Identity Lab",
		"lookup_name": "fluid_identity_lab",
		"description": "An integrated environment for exploring fluid identity concepts through multiple algorithmic lenses, allowing for interaction between different simulations.",
		"scene": "res://adaresearch/Integration/Scenes/fluid_identity_lab.tscn",
		"readme_link": "res://adaresearch/Integration/README.md"
	},
	{
		"artifact_name": "Wave Function Collapse",
		"lookup_name": "wave_function_collapse",
		"description": "Demonstrates the quantum-inspired algorithm that procedurally generates patterns with local constraints, creating complex structures from simple rules.",
		"scene": "res://adaresearch/Tests/Scenes/wave_function_collapse/wave_function_collapse.tscn",
		"readme_link": "res://adaresearch/Tests/Scenes/wave_function_collapse/README.md"
	},
	{
		"artifact_name": "Reaction Diffusion Systems",
		"lookup_name": "reaction_diffusion_systems",
		"description": "Visualizes patterns formed by chemical reactions where substances transform and spread across space, creating emergent biological-like structures.",
		"scene": "res://adaresearch/Tests/Scenes/reaction_diffusion_systems/reaction_diffusion_systems.tscn",
		"readme_link": "res://adaresearch/Tests/Scenes/reaction_diffusion_systems/README.md"
	},
	{
		"artifact_name": "Bifurcation Diagrams",
		"lookup_name": "bifurcation_diagrams",
		"description": "Illustrates how simple systems can produce increasingly complex behavior as parameters change, revealing the boundary between order and chaos.",
		"scene": "res://adaresearch/Tests/Scenes/bifurcation_diagrams.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Lyapunov Exponents",
		"lookup_name": "lyapunov_exponents",
		"description": "Visualizes how sensitive systems are to initial conditions, a core concept in chaos theory showing predictability horizons in complex systems.",
		"scene": "res://adaresearch/Tests/Scenes/lyapunov_exponents.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Evolutionary Biology",
		"lookup_name": "evolutionary_biology",
		"description": "Simulates evolutionary processes and genetic algorithms, showing how complex structures and behaviors can emerge from simple selection rules.",
		"scene": "res://adaresearch/Tests/Scenes/evolutionary_biology.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Marching Cubes",
		"lookup_name": "marching_cubes",
		"description": "Demonstrates a computational geometry algorithm that extracts a polygonal mesh from an implicit function, creating smooth surfaces from voxel data.",
		"scene": "res://adaresearch/Tests/Scenes/marching_cubes.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Multi-Layer Grid",
		"lookup_name": "multi_layer_grid",
		"description": "Explores the interplay between multiple grids at different scales, creating emergent patterns through their interactions and intersections.",
		"scene": "res://adaresearch/Tests/Scenes/multi_layer_grid.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Bridget Riley Sine Wave",
		"lookup_name": "bridget_riley_sine",
		"description": "Digital recreation of op-art techniques using sine wave mathematics to create perceptually challenging visual effects with dynamic distortion.",
		"scene": "res://adaresearch/Tests/Scenes/bridget_riley_sine.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Algorithm Tree",
		"lookup_name": "algorithm_tree",
		"description": "Visual representation of algorithmic relationships, mapping how different computational approaches connect and branch from common mathematical roots.",
		"scene": "res://adaresearch/Tests/Scenes/algorithm_tree.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Calder Simulation",
		"lookup_name": "calder_simulation",
		"description": "Physics-based simulation inspired by Alexander Calder's kinetic sculptures, demonstrating principles of balance, movement, and emergent complexity.",
		"scene": "res://adaresearch/Tests/Scenes/calder_simulation.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	},
	{
		"artifact_name": "Graham Condenser",
		"lookup_name": "graham_condenser",
		"description": "Explores concepts of data condensation and pattern extraction, distilling complex information into simplified but meaningful visual representations.",
		"scene": "res://adaresearch/Tests/Scenes/graham_condenser.tscn",
		"readme_link": "res://adaresearch/Tests/README.md"
	}
]
