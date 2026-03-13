# demo_selector.gd - Switch between different mesh generation techniques
extends Node3D
const BASE_PATH := "res://algorithms/proceduralgeneration/procedural_logic/proceduralstrategies/"

enum Strategy {
	MARCHING_CUBES,
	METABALLS,
	DELAUNAY,
	HEIGHTMAP,
	CONVEX_HULL,
	CURVE_EXTRUSION
}

var current_strategy: Strategy = Strategy.MARCHING_CUBES
var current_demo: Node3D = null

@onready var label = $UI/Label

var strategy_scripts = {
	Strategy.MARCHING_CUBES: preload(BASE_PATH + "marching_cubes.gd"),
	Strategy.METABALLS: preload(BASE_PATH + "metaballs.gd"),
	Strategy.DELAUNAY: preload(BASE_PATH + "delaunay.gd"),
	Strategy.HEIGHTMAP: preload(BASE_PATH + "heightmap.gd"),
	Strategy.CONVEX_HULL: preload(BASE_PATH + "convex_hull.gd"),
	Strategy.CURVE_EXTRUSION: preload(BASE_PATH + "curve_extrusion.gd")
}

var strategy_names = {
	Strategy.MARCHING_CUBES: "Marching Cubes (Isosurface)",
	Strategy.METABALLS: "Metaballs (Organic Blobs)",
	Strategy.DELAUNAY: "Delaunay Triangulation",
	Strategy.HEIGHTMAP: "Heightmap Terrain",
	Strategy.CONVEX_HULL: "Convex Hull",
	Strategy.CURVE_EXTRUSION: "Curve Extrusion"
}

func _ready() -> void:
	load_strategy(current_strategy)

func load_strategy(strategy: Strategy) -> void:
	if current_demo:
		current_demo.queue_free()
	
	current_demo = Node3D.new()
	current_demo.set_script(strategy_scripts[strategy])
	add_child(current_demo)
	current_demo.owner = self
	
	update_label()

func update_label() -> void:
	label.text = "[%d/%d] %s\n\nNumber Keys 1-6: Switch strategy\nSPACE: Regenerate\nESC: Quit" % [
		current_strategy + 1,
		strategy_names.size(),
		strategy_names[current_strategy]
	]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_strategy = Strategy.MARCHING_CUBES
				load_strategy(current_strategy)
			KEY_2:
				current_strategy = Strategy.METABALLS
				load_strategy(current_strategy)
			KEY_3:
				current_strategy = Strategy.DELAUNAY
				load_strategy(current_strategy)
			KEY_4:
				current_strategy = Strategy.HEIGHTMAP
				load_strategy(current_strategy)
			KEY_5:
				current_strategy = Strategy.CONVEX_HULL
				load_strategy(current_strategy)
			KEY_6:
				current_strategy = Strategy.CURVE_EXTRUSION
				load_strategy(current_strategy)
			KEY_LEFT:
				current_strategy = (current_strategy - 1 + strategy_names.size()) % strategy_names.size()
				load_strategy(current_strategy)
			KEY_RIGHT:
				current_strategy = (current_strategy + 1) % strategy_names.size()
				load_strategy(current_strategy)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

