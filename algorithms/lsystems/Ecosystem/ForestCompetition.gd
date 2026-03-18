# ===========================================================================
# ForestCompetition - L-System Ecosystem Simulation
# Implementation: AI-assisted GDScript, 2025
#
# Multiple L-System trees competing for space in a shared environment
# License: CC BY-NC-SA 3.0
# ===========================================================================

extends Node3D

## Forest Competition Ecosystem
## Demonstrates multiple L-System organisms competing for space and resources
## Chapter: L-Systems (Ecosystem & Interaction)

@export var num_trees: int = 5
@export var tree_generations: int = 4
@export var forest_radius: float = 3.0
@export var growth_speed: float = 2.0
@export var show_growth_animation: bool = true
@export var competition_enabled: bool = true
@export var tree_step_length: float = 0.25
@export var tree_thickness: float = 0.06

# Tree types with different strategies
enum TreeStrategy {
	TALL_SPARSE,      # Grows tall with sparse branches
	WIDE_DENSE,       # Grows wide with dense branches
	BALANCED,         # Balanced growth
	AGGRESSIVE,       # Fast expansion
	CONSERVATIVE      # Slow, stable growth
}

# Tree data structure
class LSystemTree:
	var position: Vector3
	var turtle: Turtle3D
	var lsystem
	var strategy: int
	var growth_rate: float
	var current_generation: int = 0
	var health: float = 1.0
	var color: Color

	func _init(pos: Vector3, strat: int, col: Color) -> void:
		position = pos
		strategy = strat
		color = col
		growth_rate = 1.0

var trees: Array[LSystemTree] = []
var growth_timer: float = 0.0
var is_growing: bool = false
var current_tree_index: int = 0

# UI
var info_label: Label3D
var stats_label: Label3D

func _ready() -> void:
	setup_forest()
	create_ui()

	if show_growth_animation:
		is_growing = true
	else:
		grow_all_trees()

	update_info_label()
	print("ForestCompetition: %d trees initialized" % num_trees)

func setup_forest() -> void:
	"""Initialize the forest ecosystem"""
	randomize()

	for i in range(num_trees):
		var tree = create_tree(i)
		trees.append(tree)
		add_child(tree.turtle)

func create_tree(index: int) -> LSystemTree:
	"""Create a single tree with random position and strategy"""
	# Position trees in a circle
	var angle = (TAU / num_trees) * index
	var distance = randf_range(0.5, forest_radius)
	var pos = Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)

	# Assign strategy (cycle through strategies)
	var strategy = index % 5

	# Assign unique color based on strategy
	var color = get_strategy_color(strategy)

	var tree = LSystemTree.new(pos, strategy, color)

	# Setup turtle with better visual parameters
	tree.turtle = Turtle3D.new()
	tree.turtle.position = pos
	tree.turtle.branch_thickness = tree_thickness
	tree.turtle.use_pink_palette = false
	tree.turtle.set_colors(color, color.lightened(0.3))

	# Setup L-System based on strategy
	tree.lsystem = create_lsystem_for_strategy(strategy)

	# Adjust growth rate based on strategy
	match strategy:
		TreeStrategy.AGGRESSIVE:
			tree.growth_rate = 1.5
		TreeStrategy.CONSERVATIVE:
			tree.growth_rate = 0.7
		_:
			tree.growth_rate = 1.0

	return tree

func get_strategy_color(strategy: int) -> Color:
	"""Get color based on tree strategy"""
	match strategy:
		TreeStrategy.TALL_SPARSE:
			return Color(0.2, 0.6, 0.3)  # Dark green
		TreeStrategy.WIDE_DENSE:
			return Color(0.4, 0.8, 0.5)  # Bright green
		TreeStrategy.BALANCED:
			return Color(0.3, 0.7, 0.4)  # Medium green
		TreeStrategy.AGGRESSIVE:
			return Color(0.8, 0.4, 0.3)  # Reddish (fast growing)
		TreeStrategy.CONSERVATIVE:
			return Color(0.5, 0.6, 0.7)  # Blue-green (slow)
		_:
			return Color(0.3, 0.7, 0.4)

func create_lsystem_for_strategy(strategy: int):
	"""Create L-System based on tree strategy"""
	var LSystemClass = load("res://utils/lsystem.gd")
	var lsys

	match strategy:
		TreeStrategy.TALL_SPARSE:
			# Tall with few branches
			lsys = LSystemClass.new("X")
			lsys.add_rule("X", "F[+X]F[-X]+X")
			lsys.add_rule("F", "FF")

		TreeStrategy.WIDE_DENSE:
			# Wide spreading with many branches
			lsys = LSystemClass.new("F")
			lsys.add_rule("F", "F[+F]F[-F][F]")

		TreeStrategy.BALANCED:
			# Balanced tree (fractal plant)
			lsys = LSystemClass.create_fractal_plant()

		TreeStrategy.AGGRESSIVE:
			# Fast expanding bush
			lsys = LSystemClass.create_bush()

		TreeStrategy.CONSERVATIVE:
			# Simple binary tree
			lsys = LSystemClass.create_tree()

		_:
			lsys = LSystemClass.create_plant()

	return lsys

func _process(delta: float) -> void:
	if not is_growing:
		return

	growth_timer += delta

	if growth_timer >= growth_speed:
		growth_timer = 0.0
		grow_next_generation()

func grow_next_generation() -> void:
	"""Grow one generation for the current tree"""
	if current_tree_index >= trees.size():
		# All trees have grown this generation
		current_tree_index = 0

		# Check if we should continue to next generation
		var any_can_grow = false
		for tree in trees:
			if tree.current_generation < tree_generations and tree.health > 0.1:
				any_can_grow = true
				break

		if not any_can_grow:
			is_growing = false
			print("Forest growth complete!")
			update_info_label()
			return

	var tree = trees[current_tree_index]

	# Check if this tree can still grow
	if tree.current_generation < tree_generations and tree.health > 0.1:
		# Apply competition if enabled
		if competition_enabled:
			apply_competition(tree)

		# Grow one generation
		tree.lsystem.generate()
		tree.current_generation += 1

		# Redraw tree with better visual parameters
		var step_length = tree_step_length * tree.health  # Health affects size
		var turn_angle = 25.0
		tree.turtle.interpret_lsystem(tree.lsystem.get_sentence(), step_length, turn_angle)

		update_info_label()

	current_tree_index += 1

func apply_competition(tree: LSystemTree) -> void:
	"""Apply competition pressure based on neighboring trees"""
	var crowding = 0.0

	# Check proximity to other trees
	for other in trees:
		if other == tree:
			continue

		var distance = (tree.position as Vector3).distance_to(other.position as Vector3)
		if distance < 1.5:  # Competition radius
			# More advanced trees create more competition
			var competition_strength = other.current_generation * 0.05
			crowding += competition_strength / max(distance, 0.5)

	# Reduce health based on crowding
	tree.health = max(0.1, tree.health - crowding * 0.1)

	# Update visual based on health
	var health_color = tree.color.lerp(Color(0.4, 0.3, 0.2), 1.0 - tree.health)
	tree.turtle.set_colors(health_color, health_color.lightened(0.3))

func grow_all_trees() -> void:
	"""Grow all trees to full generations immediately"""
	for tree in trees:
		tree.lsystem.generate_n(tree_generations)
		tree.current_generation = tree_generations

		if competition_enabled:
			for _gen in range(tree_generations):
				apply_competition(tree)

		var step_length = tree_step_length * tree.health
		var turn_angle = 25.0
		tree.turtle.interpret_lsystem(tree.lsystem.get_sentence(), step_length, turn_angle)

	update_info_label()

func create_ui() -> void:
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(0.3, 0.9, 0.4)
	info_label.position = Vector3(0, 2.5, 0)
	add_child(info_label)

	stats_label = Label3D.new()
	stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stats_label.font_size = 20
	stats_label.modulate = Color(0.7, 0.85, 0.6)
	stats_label.position = Vector3(0, 2.0, 0)
	stats_label.width = 800.0
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(stats_label)

func update_info_label() -> void:
	"""Update info display"""
	if info_label:
		var total_branches = 0
		var avg_health = 0.0

		for tree in trees:
			total_branches += tree.turtle.branches.size()
			avg_health += tree.health

		avg_health /= max(1, trees.size())

		info_label.text = "Forest Ecosystem\nTrees: %d | Branches: %d" % [trees.size(), total_branches]

	if stats_label:
		var status = "Growing..." if is_growing else "Stable"
		var competition_status = "ON" if competition_enabled else "OFF"
		stats_label.text = "Status: %s | Competition: %s\nAvg Health: %.0f%%" % [
			status,
			competition_status,
			get_average_health() * 100.0
		]

func get_average_health() -> float:
	"""Calculate average health of all trees"""
	var total = 0.0
	for tree in trees:
		total += tree.health
	return total / max(1, trees.size())

func get_strategy_name(strategy: int) -> String:
	"""Get strategy name for display"""
	match strategy:
		TreeStrategy.TALL_SPARSE: return "Tall & Sparse"
		TreeStrategy.WIDE_DENSE: return "Wide & Dense"
		TreeStrategy.BALANCED: return "Balanced"
		TreeStrategy.AGGRESSIVE: return "Aggressive"
		TreeStrategy.CONSERVATIVE: return "Conservative"
		_: return "Unknown"

func reset_forest() -> void:
	"""Reset and regenerate the forest"""
	for tree in trees:
		tree.turtle.queue_free()
	trees.clear()

	growth_timer = 0.0
	current_tree_index = 0

	setup_forest()

	if show_growth_animation:
		is_growing = true
	else:
		grow_all_trees()

	update_info_label()

func toggle_competition() -> void:
	"""Toggle competition mode"""
	competition_enabled = !competition_enabled
	reset_forest()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
