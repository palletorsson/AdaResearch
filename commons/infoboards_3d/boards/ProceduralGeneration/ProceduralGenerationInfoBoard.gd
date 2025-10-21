# ProceduralGenerationInfoBoard.gd
# Info board for Procedural Generation algorithms
extends AlgorithmInfoBoardBase

const ProceduralGenerationVis = preload("res://commons/infoboards_3d/boards/ProceduralGeneration/ProceduralGenerationVisualization.gd")

func initialize_content() -> void:
	board_title = "Procedural Generation"
	category_color = Color(0.3, 0.8, 0.5, 1.0)  # Green for generation

	page_content = [
		{
			"title": "Procedural Generation: Introduction",
			"text": [
				"Procedural generation creates content algorithmically rather than manually.",
				"It enables infinite variety, reduces storage needs, and ensures uniqueness.",
				"Common applications: terrain generation, dungeon layouts, plant growth, textures.",
				"Key algorithms: noise functions, L-systems, space partitioning, cellular automata."
			],
			"visualization": "intro"
		},
		{
			"title": "Noise-Based Terrain",
			"text": [
				"Perlin and Simplex noise create natural-looking heightmaps.",
				"Multiple octaves of noise at different scales add detail (fractal noise).",
				"Parameters: seed (randomness), scale (feature size), octaves (detail levels).",
				"Used in: terrain generation, cloud patterns, texture synthesis."
			],
			"visualization": "noise_terrain"
		},
		{
			"title": "L-Systems (Lindenmayer Systems)",
			"text": [
				"L-systems use string rewriting rules to generate fractal patterns.",
				"Start with an axiom, apply production rules recursively.",
				"Turtle graphics interpret the string: F=forward, +=turn left, -=turn right.",
				"Applications: plant modeling, tree generation, organic structures."
			],
			"visualization": "lsystem"
		},
		{
			"title": "Binary Space Partitioning",
			"text": [
				"BSP recursively divides space into smaller regions.",
				"Used for dungeon generation: split room, create sub-rooms, connect with corridors.",
				"Parameters: minimum room size, split ratio, corridor width.",
				"Guarantees connected, non-overlapping spaces."
			],
			"visualization": "dungeon"
		},
		{
			"title": "Advanced Techniques",
			"text": [
				"Wave Function Collapse: constraint-based tile generation.",
				"Voronoi diagrams: natural region boundaries and biome distribution.",
				"Cellular automata: cave systems, erosion simulation.",
				"Combining algorithms: noise for terrain + BSP for structures + L-systems for vegetation."
			],
			"visualization": "advanced"
		}
	]

func create_visualization(vis_type: String) -> Control:
	var vis = Control.new()
	vis.set_script(ProceduralGenerationVis)
	vis.visualization_type = vis_type
	return vis
