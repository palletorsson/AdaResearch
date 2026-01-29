extends Node

# Tutorial content file
var text = '''
[center][b]Procedural Generation Atlas[/b][/center]
[center][i]Mapping the living examples inside [code]res://algorithms/proceduralgeneration/[/code][/i][/center]

Every folder under that root is a playable laboratory: each couples a .tscn rig, a focused GDScript, and a README that explains the knobs. Use this map beside the clipboard tutorial stack so you can jump from BinarySpacePartitioning.tscn to WFC3DGenerator.tscn knowing why each scene exists and which data it emits.

[hr]
[b]Macro Layout Sculptors[/b]
res://algorithms/proceduralgeneration/binary_space_partitioning/BinarySpacePartitioning.tscn demonstrates BSP-driven dungeon carving--recursive AABB splits stored in BinarySpacePartitioning.gd's all_cells become candidate rooms you can colorize, weight, or reserve for boss arenas. res://algorithms/proceduralgeneration/mazegeneration/maze_generator.tscn animates recursive-backtracker corridors with walls, floor mesh, and collision toggles so the maze is immediately traversable. Organic complements live in res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_cave.tscn (signed-distance meshing, live material palette) and res://algorithms/proceduralgeneration/caverandomwalk/caverandomwalk.tscn (biased walkers carving caverns), letting you stitch rooms to caves without leaving the editor.

[i]Concepts: BSP trees, recursive maze carving, marching cubes, random walk tunneling, hybrid topology blending[/i]
[i]Decide the gross anatomy first; the later passes can pour detail into those empty cells.[/i]

[hr]
[b]Constraint Weavers & Tile Grammars[/b]
res://algorithms/proceduralgeneration/wave_function_collapse/WaveFunctionCollapse.tscn, WFCCave.tscn, and modelsynthesis.tscn walk through entropy-based collapse, adjacency dictionaries, and backtracking metrics. res://algorithms/proceduralgeneration/wfcRooms/wfc_rooms.tscn plus tile_template_examples.gd document how to author tiles, sockets, and metadata before solving, while res://algorithms/proceduralgeneration/WFC3DGenerator/WFC3DGenerator.tscn and WFCSculptureGenerator/WFCSculptureGenerator.tscn lift the technique into voxels and gallery sculptures. Use these once your macro layout exists: feed each solver tile sets derived from BSP leaves or maze corridors so constraints lock everything together.

[i]Concepts: entropy ordering, adjacency matrices, tile tagging, constraint satisfaction, failure recovery[/i]
[i]Constraints are the grammar rules that keep infinite rearrangements coherent.[/i]

[hr]
[b]Sampling, Fields, and Distance-Driven Geometry[/b]
res://algorithms/proceduralgeneration/poisson_disk_sampling_3d/PoissonDiskSampling3D.tscn (and PoissonDiskSamplingApplications.gd) exposes Bridson sampling sliders, boundary falloff modes, and radial statistics. Feed that point cloud to res://algorithms/proceduralgeneration/voronoi_diagrams/voronoi_diagrams.tscn, res://algorithms/proceduralgeneration/voronoi_diagram_3d/VoronoiDiagram3D.tscn, or res://algorithms/proceduralgeneration/delaunay_triangulation_3d_cell/DelaunayTriangulation3DCell.tscn to study adjacency graphs, neighbors, and mesh extraction. When you need implicit surfaces, res://algorithms/proceduralgeneration/metaballs/nakama_metaballs.tscn, res://algorithms/proceduralgeneration/metaballgenerator/metaballworld.tscn, res://algorithms/proceduralgeneration/marchingsquares/marching_squares_scene.tscn, and the res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_* variants show how distance fields become clay, while res://algorithms/proceduralgeneration/wireframe/fatwireframe.tscn and res://algorithms/proceduralgeneration/layeredmembrane/layered_membrane.tscn visualize gradients and layer accumulation.

[i]Concepts: Poisson disk sampling, Voronoi/Laguerre cells, Delaunay triangulation, signed-distance fields, iso-surface meshing[/i]
[i]Structured randomness gives you the scaffolds that surfaces, textures, and populations can inhabit.[/i]

[hr]
[b]Growth Algorithms & Emergent Biology[/b]
res://algorithms/l_systems/Growth/AnimatedTree.tscn decodes rewriting rules into branching meshes. res://algorithms/proceduralgeneration/branchinggrowthalgorithm/BranchingGrowthAlgorithm.tscn (and the continued study in branchinggrowthalgorithmcontinued) layers heuristics like tropism, pruning, and bud memory; res://algorithms/proceduralgeneration/space_colonization_algorithm/SpaceColonizationAlgorithm.tscn adds attraction volumes and thickness decay to steer branches around a cube, ring, or shell. Agent-based examples such as res://algorithms/proceduralgeneration/slimemold/slime.tscn, res://algorithms/proceduralgeneration/reactiondiffusion/2d_in_3d_turing_pattern_reaction_diffusion.tscn, res://algorithms/proceduralgeneration/percolationnetwork_ca/percolationnetwork_ca.tscn, res://algorithms/proceduralgeneration/crackpropagation_ca/crackpropagation_ca.tscn, and res://algorithms/proceduralgeneration/mirroredcellularautomata/mirrored_cellular_automata.tscn show how local diffusion, percolation thresholds, and mirrored rule tables yield vascular maps, Turing skins, or fracture webs.

[i]Concepts: L-systems, space colonization, branching heuristics, agent swarms, reaction-diffusion fields[/i]
[i]Let simple local incentives run long enough and complexity negotiates itself.[/i]

[hr]
[b]Design Studies & Hybrid Strategies[/b]
res://algorithms/proceduralgeneration/modernistchairs/ModernistChairGallery.tscn composes parametric furniture families; each chair script (Barcelona, Bauhaus, GridWire, etc.) exposes sliders that demonstrate how procedural rules encode typologies. res://algorithms/proceduralgeneration/berninicolumns/MeltingBerniniScene.tscn, res://algorithms/proceduralgeneration/dewcoveredfoliage/dewcoveredfoliage.tscn, and res://algorithms/proceduralgeneration/tilepatterns/tilepattern.tscn mix art direction with algorithmic tessellation, noise, and shader animation. res://algorithms/proceduralgeneration/proceduralstrategies/demo_scene.tscn functions as a sampler platter--convex hulls, curve extrusions, marching cubes, metaballs--while folders like layeredmembrane, wireframe, and modernistmaterials reveal how the same algorithms double as material studies.

[i]Concepts: parametric product families, ornamental systems, hybrid procedural + art direction workflows[/i]
[i]Procedural rules are also a design language, not just a content factory.[/i]

[hr]
[b]From Layout to Detail: Example Pipeline[/b]
Use several of these scenes together: harvest spatial cells from BSP, seed points with Poisson disk, then drive tile collapse and growth passes.

[color=yellow]Code[/color]
[code]
var bsp := BinarySpacePartitioning.new()
bsp.space_size = Vector3(24, 10, 24)
bsp.max_depth = 5
bsp.min_cell_size = 3.0
bsp.generate_bsp()

var sampler := PoissonDiskSampling3D.new()
sampler.sample_region = bsp.space_size
sampler.min_distance = 1.5
sampler.generate_samples()

var wfc := preload("res://algorithms/proceduralgeneration/wave_function_collapse/WaveFunctionCollapse.gd").new()
wfc.grid_size = 24
wfc.adjacency_rules = {
    "empty": ["empty", "wall"],
    "floor": ["floor", "wall"],
    "wall": ["empty", "floor", "wall"]
}

var colonizer := preload("res://algorithms/proceduralgeneration/space_colonization_algorithm/SpaceColonizationAlgorithm.gd").new()
colonizer.attraction_points_count = sampler.sample_points.size()
colonizer.distribution_type = 1
colonizer.segment_length = 0.25

add_child(bsp)
add_child(sampler)
add_child(wfc)
add_child(colonizer)

for cell in bsp.all_cells:
    if cell.is_leaf:
        var center := cell.bounds.position + cell.bounds.size * 0.5
        # Use center + sampler.sample_points to bias where WaveFunctionCollapse collapses next
        # and to seed custom attraction point sets for the colonizer tree.
[/code]

[i]Concepts: cross-algorithm pipelines, data reuse, authored constraints steering stochastic processes[/i]
[i]Chain the labs: partition -> sample -> collapse -> grow to get coherent worlds fast.[/i]
'''
