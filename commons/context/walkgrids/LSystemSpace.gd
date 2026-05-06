# LSystemSpace.gd - L-System branching patterns as walkable terrain
# Lindenmayer systems generate branching structures — rivers, trees,
# blood vessels, road networks. Here they become elevation maps:
# branches are ridges, the spaces between are walkable valleys.
#
# "A grammar that grows. A sentence that branches. A terrain that speaks."

extends TopologySpace
class_name LSystemSpace

@export var axiom: String = "F"
@export var iterations: int = 4
@export var angle_degrees: float = 25.0
@export var step_length: float = 2.0
@export var branch_width: float = 1.5     # How wide the branch ridges are
@export var width_decay: float = 0.7      # Branches get thinner
@export var height_per_branch: float = 0.3  # How tall each branch level is
@export var smooth_passes: int = 3        # Smooth for walkability

# L-System presets
@export var preset: LSystemPreset = LSystemPreset.TREE

enum LSystemPreset {
	TREE,              # Classic branching tree
	KOCH_ISLAND,       # Koch snowflake as terrain
	DRAGON_CURVE,      # Dragon curve as elevation
	SIERPINSKI,        # Sierpinski triangle
	HILBERT_CURVE,     # Space-filling Hilbert curve
	RIVER_DELTA,       # Branching river network
	CUSTOM,            # Use manual axiom/rules
}

# Rules (only used in CUSTOM mode)
@export var rule_f: String = "FF+[+F-F-F]-[-F+F+F]"
@export var rule_g: String = ""

var rules: Dictionary = {}
var grid: Array = []
var grid_size: int = 0

func _ready():
	_apply_preset()
	super._ready()

func _apply_preset():
	match preset:
		LSystemPreset.TREE:
			axiom = "F"
			rule_f = "FF+[+F-F-F]-[-F+F+F]"
			angle_degrees = 22.5
			iterations = 4
		LSystemPreset.KOCH_ISLAND:
			axiom = "F-F-F-F"
			rule_f = "F-F+F+FF-F-F+F"
			angle_degrees = 90.0
			iterations = 3
		LSystemPreset.DRAGON_CURVE:
			axiom = "FX"
			rule_f = ""  # F stays F
			rules["X"] = "X+YF+"
			rules["Y"] = "-FX-Y"
			angle_degrees = 90.0
			iterations = 10
		LSystemPreset.SIERPINSKI:
			axiom = "F-G-G"
			rule_f = "F-G+F+G-F"
			rule_g = "GG"
			angle_degrees = 120.0
			iterations = 5
		LSystemPreset.HILBERT_CURVE:
			axiom = "A"
			rules["A"] = "-BF+AFA+FB-"
			rules["B"] = "+AF-BFB-FA+"
			rule_f = ""
			angle_degrees = 90.0
			iterations = 4
		LSystemPreset.RIVER_DELTA:
			axiom = "F"
			rule_f = "F[+F]F[-F]F"
			angle_degrees = 25.7
			iterations = 4
		LSystemPreset.CUSTOM:
			pass

	# Set rules from rule_f/rule_g
	if preset != LSystemPreset.DRAGON_CURVE and preset != LSystemPreset.HILBERT_CURVE:
		rules.clear()
		if rule_f != "":
			rules["F"] = rule_f
		if rule_g != "":
			rules["G"] = rule_g

func _expand_lsystem() -> String:
	"""Expand the L-system string"""
	var current = axiom
	for _i in range(iterations):
		var next = ""
		for j in range(current.length()):
			var c = current[j]
			if rules.has(c):
				next += rules[c]
			else:
				next += c
		current = next
	return current

func generate_space():
	grid_size = resolution + 1
	grid.clear()
	grid.resize(grid_size * grid_size)
	for i in range(grid.size()):
		grid[i] = 0.0

	# Expand L-system
	var lstring = _expand_lsystem()

	# Trace the turtle, painting into the grid
	_trace_turtle(lstring)

	# Smooth for walkability
	for _p in range(smooth_passes):
		grid = _smooth_grid(grid)

	# Scale heights
	var heights: Array = []
	for i in range(grid.size()):
		heights.append(grid[i] * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _trace_turtle(lstring: String):
	"""Trace turtle graphics, painting branch paths into the height grid"""
	var pos = Vector2(space_size.x / 2.0, space_size.y / 2.0)  # Start center
	var heading = -PI / 2.0  # Start pointing up
	var width = branch_width
	var depth = 0
	var stack: Array = []
	var angle_rad = deg_to_rad(angle_degrees)

	# First pass: find bounding box
	var min_pos = pos
	var max_pos = pos
	var trace_positions: Array = []
	var trace_stack: Array = []

	for i in range(lstring.length()):
		var c = lstring[i]
		match c:
			"F", "G":
				var next_pos = pos + Vector2(cos(heading), sin(heading)) * step_length
				trace_positions.append({"from": pos, "to": next_pos, "width": width, "depth": depth})
				pos = next_pos
				min_pos = Vector2(minf(min_pos.x, pos.x), minf(min_pos.y, pos.y))
				max_pos = Vector2(maxf(max_pos.x, pos.x), maxf(max_pos.y, pos.y))
			"+":
				heading += angle_rad
			"-":
				heading -= angle_rad
			"[":
				trace_stack.append({"pos": pos, "heading": heading, "width": width, "depth": depth})
				depth += 1
				width *= width_decay
			"]":
				if trace_stack.size() > 0:
					var state = trace_stack.pop_back()
					pos = state["pos"]
					heading = state["heading"]
					width = state["width"]
					depth = state["depth"]

	# Second pass: paint into grid with proper scaling
	var extent = max_pos - min_pos
	if extent.x < 0.001: extent.x = 1.0
	if extent.y < 0.001: extent.y = 1.0
	var scale_factor = Vector2(space_size.x / extent.x, space_size.y / extent.y) * 0.8
	var offset = -min_pos * scale_factor + Vector2(space_size.x, space_size.y) * 0.1

	for segment in trace_positions:
		var from: Vector2 = segment["from"] * scale_factor + offset
		var to: Vector2 = segment["to"] * scale_factor + offset
		var w: float = segment["width"]
		var d: int = segment["depth"]
		var h = height_per_branch * (1.0 + d * 0.5)
		_paint_line(from, to, w * scale_factor.x * 0.1, h)

func _paint_line(from: Vector2, to: Vector2, width: float, height: float):
	"""Paint a line into the height grid"""
	var steps = int(from.distance_to(to) * 2.0) + 1
	for i in range(steps):
		var t = float(i) / float(steps)
		var p = from.lerp(to, t)

		# Map to grid coordinates
		var gx = int((p.x / space_size.x) * float(grid_size))
		var gz = int((p.y / space_size.y) * float(grid_size))

		# Paint with gaussian falloff around the line
		var radius = int(width) + 1
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var nx = gx + dx
				var nz = gz + dz
				if nx >= 0 and nx < grid_size and nz >= 0 and nz < grid_size:
					var dist = sqrt(float(dx * dx + dz * dz))
					if dist <= width:
						var falloff = exp(-dist * dist / (width * 0.5 + 0.01))
						var idx = nz * grid_size + nx
						grid[idx] = maxf(grid[idx], height * falloff)

func _smooth_grid(g: Array) -> Array:
	var smoothed = g.duplicate()
	for z in range(1, grid_size - 1):
		for x in range(1, grid_size - 1):
			var idx = z * grid_size + x
			smoothed[idx] = (
				g[idx] * 0.5 +
				(g[idx-1] + g[idx+1] + g[idx-grid_size] + g[idx+grid_size]) * 0.125
			)
	return smoothed

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.45, 0.3)  # Forest green
	material.roughness = 0.8
	material.metallic = 0.05
	material.emission_enabled = true
	material.emission = Color(0.2, 0.3, 0.15) * 0.2
	mesh_instance.material_override = material

# Public API
func set_preset(p: LSystemPreset):
	preset = p
	_apply_preset()
	generate_space()

func regenerate():
	generate_space()
