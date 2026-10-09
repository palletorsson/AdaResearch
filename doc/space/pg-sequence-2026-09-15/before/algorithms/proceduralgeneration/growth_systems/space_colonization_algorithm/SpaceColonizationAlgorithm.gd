@tool
extends Node3D

# @identity
# essence: assign each target to its nearest eligible site, sum unit directions, add a segment; tips or persistent-site policy
# desire: compare a strand with a branching tree by changing which sites can respond again
# critical_parameter: kill_distance — the radius at which an attractor is consumed; too small and branches overshoot, too large and the tree is sparse
# triggers: regenerate rebuilds entirely; step_growth advances one iteration; toggle_animation switches between instant and animated growth
# emerges: parent/child records define a tree; NETWORK can fork at older sites, TIPS replaces each influenced leaf with one successor
# needs: attraction point display [has]; cube guide [has]; step/animate toggle [has]; VR attractor placement [missing]
# relationships: follows GeneticProgramming (criterion vs spatial requests); contrasts with branching_growth_algorithm (summed directions vs nearest target)
# truth: the target field, eligible sites and stopping rules participate in the generated form

@export_group("Target Shape")
@export var cube_size: Vector3 = Vector3(4, 4, 4)
@export var attraction_points_count: int = 500
@export var distribution_thickness: float = 2.0
@export_enum("Shell", "Volume", "Surface", "Corners") var distribution_type: int = 0

@export_group("Growth Settings")
@export var segment_length: float = 0.2
@export var influence_distance: float = 2.0
@export var kill_distance: float = 0.3
@export var max_iterations: int = 1000
@export var branch_thickness: float = 0.15
@export var thickness_decay: float = 0.9

@export_group("Starting Point")
@export var growth_origin: Vector3 = Vector3(0, -6, 0)
@export_enum("Single", "Multiple", "Ring", "Base") var origin_type: int = 0

@export_group("Visual Settings")
@export var show_attraction_points: bool = true
@export var show_cube_guide: bool = true
@export var show_growth_animation: bool = false
@export var branch_color: Color = Color(0.6, 0.4, 0.2)
@export var attraction_color: Color = Color(1, 0.3, 0.3, 0.5)

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA — axis: aftermath   (shared with branching_growth_algorithm and
# recursive_tree: three different growth rules, one question)
#
# Growth is a process and a still cannot hold a process. What a still CAN hold is
# what the growing left: the branches, the demand they were answering, the volume
# they were allowed to fill. The axis is how much of the growing the finished
# thing is still willing to show.
#
#   apparatus  demand and boundary and structure all at once — the growth staged
#              as an experiment.  (DEFAULT, and it is what this artifact has
#              always drawn: show_cube_guide and show_attraction_points both
#              ship true, so today's frame IS the apparatus frame.)
#   form       branches only. A result. The rig struck, the auxin cloud gone.
#   field      branches plus the attraction points — the demand without the
#              target volume that framed it.
#   envelope   branches plus the target volume drawn SOLID and translucent —
#              the permitted region without the demand inside it. A boundary
#              and what filled it.
#   strata     branches only, repainted by generation instead of by distance
#              from the root, so every segment carries its date.
#
# STRICTLY ADDITIVE. `apparatus` puts both gates back to plain `true` and takes
# the early return in _aftermath_tint(), so the default frame is the pre-DNA one.
# The value is read AFTER growth and never enters the RNG path.
# ─────────────────────────────────────────────────────────────────────────────
const AFTERMATH_VALUES := ["apparatus", "form", "field", "envelope", "strata"]
@export_enum("apparatus", "form", "field", "envelope", "strata") var aftermath: String = "apparatus"

## Pins the attraction cloud so a sweep renders the SAME network five times.
## -1 keeps the pre-DNA behaviour exactly: no seed() call, every run differs.
@export var growth_seed: int = -1

@export_group("Actions")
@export var regenerate: bool = false:
	set(value):
		if value:
			generate_structure()
			regenerate = false
@export var step_growth: bool = false:
	set(value):
		if value and is_growing:
			grow_iteration()
			step_growth = false
@export var toggle_animation: bool = false:
	set(value):
		if value:
			is_growing = !is_growing
			toggle_animation = false

class GrowthNode:
	var position: Vector3
	var parent: GrowthNode = null
	var children: Array[GrowthNode] = []
	var thickness: float = 1.0
	var growth_direction: Vector3 = Vector3.ZERO
	var influenced_by: int = 0
	# Generation, stamped once at creation. `strata` needs the age of every
	# segment; walking parents per node per redraw would be O(n·depth) inside a
	# function the animated path already calls every iteration.
	var depth: int = 0

	func _init(pos: Vector3, par: GrowthNode = null, thick: float = 1.0) -> void:
		position = pos
		parent = par
		thickness = thick

var attraction_points: Array[Vector3] = []
var active_attraction_points: Array[Vector3] = []
var root_nodes: Array[GrowthNode] = []
var leaf_nodes: Array[GrowthNode] = []
var all_nodes: Array[GrowthNode] = []

var is_growing: bool = false
var current_iteration: int = 0
var growth_timer: float = 0.0
var _aft: String = "apparatus"   # aftermath key, normalised once per redraw

func _ready() -> void:
	generate_structure()

func _process(delta: float) -> void:
	if show_growth_animation and is_growing:
		growth_timer += delta * 5.0
		if growth_timer >= 0.05:
			growth_timer = 0.0
			if not grow_iteration():
				is_growing = false

func generate_structure() -> void:
	# FIRST statement, ahead of generate_attraction_points()'s randf()/randi().
	# At the default -1 no seed() runs and the stream is the pre-DNA one.
	if growth_seed >= 0:
		seed(growth_seed)
	clear_structure()
	current_iteration = 0
	
	# Generate attraction points around cube
	generate_attraction_points()
	
	# Create initial growth nodes
	create_root_nodes()
	
	if not show_growth_animation:
		# Generate entire structure
		while grow_iteration() and current_iteration < max_iterations:
			pass
	else:
		is_growing = true
	
	visualize_structure()

func generate_attraction_points() -> void:
	attraction_points.clear()
	active_attraction_points.clear()
	
	match distribution_type:
		0: # Shell - points around cube surface
			generate_shell_distribution()
		1: # Volume - points throughout volume around cube
			generate_volume_distribution()
		2: # Surface - points on cube surface
			generate_surface_distribution()
		3: # Corners - concentrated at corners
			generate_corner_distribution()
	
	active_attraction_points = attraction_points.duplicate()

func generate_shell_distribution() -> void:
	for i in range(attraction_points_count):
		# Random point on cube surface
		var face = randi() % 6
		var u = randf() * cube_size.x - cube_size.x / 2
		var v = randf() * cube_size.y - cube_size.y / 2
		
		var point: Vector3
		match face:
			0: point = Vector3(cube_size.x / 2, u, v)
			1: point = Vector3(-cube_size.x / 2, u, v)
			2: point = Vector3(u, cube_size.y / 2, v)
			3: point = Vector3(u, -cube_size.y / 2, v)
			4: point = Vector3(u, v, cube_size.z / 2)
			5: point = Vector3(u, v, -cube_size.z / 2)
		
		# Add random offset outward
		var normal = point.normalized()
		point += normal * randf_range(0, distribution_thickness)
		
		attraction_points.append(point)

func generate_volume_distribution() -> void:
	for i in range(attraction_points_count):
		var point = Vector3(
			randf() * (cube_size.x + distribution_thickness * 2) - (cube_size.x / 2 + distribution_thickness),
			randf() * (cube_size.y + distribution_thickness * 2) - (cube_size.y / 2 + distribution_thickness),
			randf() * (cube_size.z + distribution_thickness * 2) - (cube_size.z / 2 + distribution_thickness)
		)
		
		# Check if point is outside cube but within shell
		var inside_outer = (abs(point.x) <= cube_size.x / 2 + distribution_thickness and
						   abs(point.y) <= cube_size.y / 2 + distribution_thickness and
						   abs(point.z) <= cube_size.z / 2 + distribution_thickness)
		
		var inside_inner = (abs(point.x) <= cube_size.x / 2 and
						   abs(point.y) <= cube_size.y / 2 and
						   abs(point.z) <= cube_size.z / 2)
		
		if inside_outer and not inside_inner:
			attraction_points.append(point)

func generate_surface_distribution() -> void:
	for i in range(attraction_points_count):
		var face = randi() % 6
		var u = randf() * cube_size.x - cube_size.x / 2
		var v = randf() * cube_size.y - cube_size.y / 2
		
		var point: Vector3
		match face:
			0: point = Vector3(cube_size.x / 2, u, v)
			1: point = Vector3(-cube_size.x / 2, u, v)
			2: point = Vector3(u, cube_size.y / 2, v)
			3: point = Vector3(u, -cube_size.y / 2, v)
			4: point = Vector3(u, v, cube_size.z / 2)
			5: point = Vector3(u, v, -cube_size.z / 2)
		
		attraction_points.append(point)

func generate_corner_distribution() -> void:
	var corners = [
		Vector3(1, 1, 1), Vector3(-1, 1, 1),
		Vector3(1, -1, 1), Vector3(-1, -1, 1),
		Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(1, -1, -1), Vector3(-1, -1, -1)
	]
	
	for i in range(attraction_points_count):
		var corner = corners[randi() % corners.size()]
		var base_pos = corner * cube_size / 2
		
		# Add random offset around corner
		var offset = Vector3(
			randf_range(-distribution_thickness, distribution_thickness),
			randf_range(-distribution_thickness, distribution_thickness),
			randf_range(-distribution_thickness, distribution_thickness)
		)
		
		attraction_points.append(base_pos + offset)

func create_root_nodes() -> void:
	root_nodes.clear()
	leaf_nodes.clear()
	all_nodes.clear()
	
	match origin_type:
		0: # Single origin
			var root = GrowthNode.new(growth_origin, null, branch_thickness)
			root_nodes.append(root)
			leaf_nodes.append(root)
			all_nodes.append(root)
		
		1: # Multiple origins
			for i in range(4):
				var angle = float(i) / 4.0 * TAU
				var offset = Vector3(cos(angle), 0, sin(angle)) * 2.0
				var root = GrowthNode.new(growth_origin + offset, null, branch_thickness)
				root_nodes.append(root)
				leaf_nodes.append(root)
				all_nodes.append(root)
		
		2: # Ring origin
			for i in range(8):
				var angle = float(i) / 8.0 * TAU
				var offset = Vector3(cos(angle), 0, sin(angle)) * 1.5
				var root = GrowthNode.new(growth_origin + offset, null, branch_thickness * 0.8)
				root_nodes.append(root)
				leaf_nodes.append(root)
				all_nodes.append(root)
		
		3: # Base platform
			for x in range(-2, 3):
				for z in range(-2, 3):
					var offset = Vector3(x * 0.5, 0, z * 0.5)
					var root = GrowthNode.new(growth_origin + offset, null, branch_thickness * 0.6)
					root_nodes.append(root)
					leaf_nodes.append(root)
					all_nodes.append(root)

@export_enum("tips", "network") var growth_policy: String = "tips"
@export var node_budget: int = 0 # Zero preserves the ordinary artifact's iteration-only limit.
var last_decision: Dictionary = {}
var stop_reason := ""

func grow_iteration() -> bool:
	if current_iteration >= max_iterations or (node_budget > 0 and all_nodes.size() >= node_budget):
		stop_reason = "budget"
		return false
	last_decision = decision_snapshot()
	if growth_policy == "network":
		return _grow_network_iteration()
	var grew: bool = _grow_tips_iteration()
	stop_reason = "" if grew else ("targets reached" if active_attraction_points.is_empty() else "no eligible direction")
	return grew

func decision_snapshot() -> Dictionary:
	var sites: Array = all_nodes if growth_policy == "network" else leaf_nodes
	var result := {"sites": [], "assignments": [], "remove": []}
	for node in sites:
		result.sites.append({"index": all_nodes.find(node), "position": node.position, "sum": Vector3.ZERO, "count": 0})
	for i in active_attraction_points.size():
		var point: Vector3 = active_attraction_points[i]
		var nearest := -1
		var distance := influence_distance
		for j in sites.size():
			var d: float = point.distance_to(sites[j].position)
			if d < distance:
				distance = d
				nearest = j
		if nearest < 0: continue
		if distance <= kill_distance:
			result.remove.append(i)
		else:
			var direction: Vector3 = (point - sites[nearest].position).normalized()
			result.sites[nearest].sum += direction
			result.sites[nearest].count += 1
			result.assignments.append({"point": point, "site": sites[nearest].position, "direction": direction, "index": all_nodes.find(sites[nearest])})
	return result

func _grow_network_iteration() -> bool:
	# Read all assignments from one unchanged generation. Earlier sites remain eligible.
	for i in range(last_decision.remove.size() - 1, -1, -1):
		active_attraction_points.remove_at(last_decision.remove[i])
	var additions: Array[GrowthNode] = []
	for choice in last_decision.sites:
		if choice.count == 0 or choice.sum.length_squared() < 0.00000001: continue
		var node: GrowthNode = all_nodes[choice.index]
		var direction: Vector3 = choice.sum.normalized()
		var next_position := node.position + direction * segment_length
		var duplicate := false
		for existing in all_nodes:
			if existing.position.distance_squared_to(next_position) < 0.00000001:
				duplicate = true
		for existing in additions:
			if existing.position.distance_squared_to(next_position) < 0.00000001:
				duplicate = true
		if duplicate: continue
		if node_budget > 0 and all_nodes.size() + additions.size() >= node_budget: break
		var child := GrowthNode.new(next_position, node, node.thickness * thickness_decay)
		child.depth = node.depth + 1
		node.children.append(child)
		additions.append(child)
	all_nodes.append_array(additions)
	leaf_nodes.clear()
	for node in all_nodes:
		if node.children.is_empty(): leaf_nodes.append(node)
	current_iteration += 1
	stop_reason = "" if not additions.is_empty() else ("targets reached" if active_attraction_points.is_empty() else "no new direction")
	if show_growth_animation: visualize_structure()
	return not additions.is_empty()

func _grow_tips_iteration() -> bool:
	if active_attraction_points.size() == 0:
		return false
	
	# Reset influence counters
	for node in leaf_nodes:
		node.growth_direction = Vector3.ZERO
		node.influenced_by = 0
	
	# Find closest nodes for each attraction point
	var points_to_remove: Array[int] = []
	
	for i in range(active_attraction_points.size()):
		var attr_point = active_attraction_points[i]
		var closest_node: GrowthNode = null
		var closest_distance = INF
		
		# Find closest leaf node
		for node in leaf_nodes:
			var distance = node.position.distance_to(attr_point)
			
			if distance < influence_distance and distance < closest_distance:
				closest_distance = distance
				closest_node = node
		
		# If point is close enough, influence the node
		if closest_node != null:
			if closest_distance <= kill_distance:
				points_to_remove.append(i)
			else:
				var direction = (attr_point - closest_node.position).normalized()
				closest_node.growth_direction += direction
				closest_node.influenced_by += 1
	
	# Remove colonized points
	for i in range(points_to_remove.size() - 1, -1, -1):
		active_attraction_points.remove_at(points_to_remove[i])
	
	# Generate new nodes
	var new_leaf_nodes: Array[GrowthNode] = []
	var grew = false
	
	for node in leaf_nodes:
		if node.influenced_by > 0:
			# Normalize growth direction
			var growth_dir = node.growth_direction.normalized()
			
			# Create new node
			var new_position = node.position + growth_dir * segment_length
			var new_thickness = node.thickness * thickness_decay
			var new_node = GrowthNode.new(new_position, node, new_thickness)
			new_node.depth = node.depth + 1
			
			node.children.append(new_node)
			new_leaf_nodes.append(new_node)
			all_nodes.append(new_node)
			grew = true
		else:
			# Keep node as leaf if not influenced
			new_leaf_nodes.append(node)
	
	leaf_nodes = new_leaf_nodes
	current_iteration += 1
	
	if show_growth_animation:
		visualize_structure()
	
	return grew

func visualize_structure() -> void:
	clear_visualization()

	# Both gates below pick up ONE extra term, and both extra terms are true at
	# `apparatus` — so at the default the pair reduces to the pre-DNA `if show_*:`
	# and the frame is unchanged. Every other value subtracts from it.
	_aft = _aftermath_key()

	# Draw cube guide
	if show_cube_guide and _aft == "apparatus":
		create_cube_guide()

	# `envelope` gets a SOLID translucent target volume rather than the shipped
	# wire guide. The guide is twelve hairlines at alpha 0.2 — under 1% of the
	# frame and below the critic's own subject threshold, so an envelope built
	# from it would be indistinguishable from an axis that does nothing. The
	# claim is a volume; draw a volume.
	if _aft == "envelope":
		_add_target_shell()

	# Draw attraction points
	if show_attraction_points and (_aft == "apparatus" or _aft == "field"):
		draw_attraction_points()

	# Draw growth structure
	draw_branches()

	# The bounding hull of the target volume + the growth origin, on layers 0 so
	# it draws nothing. It exists so `form` and `apparatus` report the SAME AABB:
	# otherwise the capture rig refits per variant, the camera moves, every pixel
	# changes, and the bite number is a picture of a zoom rather than of an axis.
	_add_field_anchor()

func create_cube_guide() -> void:
	var cube_mesh = MeshInstance3D.new()
	add_child(cube_mesh)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var half = cube_size / 2
	var corners = [
		Vector3(-half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z)
	]
	
	var edges = [
		[0,1], [1,2], [2,3], [3,0],
		[4,5], [5,6], [6,7], [7,4],
		[0,4], [1,5], [2,6], [3,7]
	]
	
	for edge in edges:
		surface_tool.add_vertex(corners[edge[0]])
		surface_tool.add_vertex(corners[edge[1]])
	
	cube_mesh.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_mesh.material_override = material

func draw_attraction_points() -> void:
	# Draw active points
	for point in active_attraction_points:
		var sphere = MeshInstance3D.new()
		add_child(sphere)
		
		var mesh = SphereMesh.new()
		mesh.radius = 0.05
		mesh.height = mesh.radius
		sphere.mesh = mesh
		sphere.position = point
		
		var material = StandardMaterial3D.new()
		material.albedo_color = attraction_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere.material_override = material
	
	# Draw colonized points (darker)
	var colonized_count = attraction_points.size() - active_attraction_points.size()
	if colonized_count > 0:
		var sample_size = min(colonized_count, 50)
		for i in range(sample_size):
			var idx = randi() % attraction_points.size()
			if attraction_points[idx] not in active_attraction_points:
				var sphere = MeshInstance3D.new()
				add_child(sphere)
				
				var mesh = SphereMesh.new()
				mesh.radius = 0.03
				mesh.height = mesh.radius
				sphere.mesh = mesh
				sphere.position = attraction_points[idx]
				
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(0.2, 0.2, 0.2, 0.3)
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				sphere.material_override = material

func draw_branches() -> void:
	for node in all_nodes:
		if node.parent != null:
			create_branch_segment(node)

func create_branch_segment(node: GrowthNode) -> void:
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var mesh = create_cylinder_between(
		node.parent.position,
		node.position,
		node.parent.thickness * 0.1,
		node.thickness * 0.1
	)
	
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	# Color based on depth/distance from root
	var depth_factor = clamp(node.position.distance_to(growth_origin) / 10.0, 0.0, 1.0)
	material.albedo_color = branch_color.lerp(Color(0.3, 0.6, 0.3), depth_factor)
	# Last word on colour, and a pass-through at every value but `strata`. The
	# line above colours by DISTANCE from the root; strata colours by GENERATION,
	# which is a different claim — how far is not the same as how long ago.
	material.albedo_color = _aftermath_tint(node, material.albedo_color)
	material.roughness = 0.8
	mesh_instance.material_override = material

func create_cylinder_between(start: Vector3, end: Vector3, start_radius: float, end_radius: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	var segments = 6
	
	# Create perpendicular vectors
	var tangent = Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right = direction.cross(tangent).normalized()
	var up = right.cross(direction).normalized()
	
	# Create cylinder
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		var perpendicular = right * cos(angle) + up * sin(angle)
		
		var start_point = start + perpendicular * start_radius
		var end_point = end + perpendicular * end_radius
		
		if i < segments:
			var next_angle = float(i + 1) / segments * TAU
			var next_perp = right * cos(next_angle) + up * sin(next_angle)
			
			var start_next = start + next_perp * start_radius
			var end_next = end + next_perp * end_radius
			
			# Create quad
			surface_tool.add_vertex(start_point)
			surface_tool.add_vertex(end_point)
			surface_tool.add_vertex(start_next)
			
			surface_tool.add_vertex(start_next)
			surface_tool.add_vertex(end_point)
			surface_tool.add_vertex(end_next)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func clear_structure() -> void:
	last_decision.clear();stop_reason = ""
	# Break the parent/child reference cycle before discarding a generation.
	for node in all_nodes:
		node.children.clear();node.parent = null
	attraction_points.clear()
	active_attraction_points.clear()
	root_nodes.clear()
	leaf_nodes.clear()
	all_nodes.clear()
	clear_visualization()

func clear_visualization() -> void:
	for child in get_children():
		child.queue_free()

func _exit_tree() -> void:
	for node in all_nodes:
		node.children.clear();node.parent = null
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ─────────────────────────────────────────────────────────────────────────────
# aftermath — everything below is new and nothing above it moved.
# ─────────────────────────────────────────────────────────────────────────────

const STRATA_ROOT := Color(0.10, 0.13, 0.42)
const STRATA_TIP := Color(1.0, 0.93, 0.30)
const SHELL_COLOR := Color(0.40, 0.64, 1.0, 0.16)

func _add_target_shell() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "TargetShell"
	var box := BoxMesh.new()
	box.size = cube_size
	shell.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = SHELL_COLOR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shell)

func _aftermath_key() -> String:
	# Unknown word keeps the default. A typo in a map file should cost you the
	# variant, not the object.
	var key: String = str(aftermath).strip_edges().to_lower()
	if AFTERMATH_VALUES.has(key):
		return key
	return "apparatus"

func _aftermath_tint(node: GrowthNode, base: Color) -> Color:
	if _aft != "strata":
		return base
	var span: float = maxf(1.0, float(current_iteration))
	var t: float = clampf(float(node.depth) / span, 0.0, 1.0)
	return STRATA_ROOT.lerp(STRATA_TIP, t)

func _add_field_anchor() -> void:
	# layers = 0, NOT visible = false: hiding a node hides its children too. A
	# zero-layer VisualInstance3D is in no camera's cull mask and draws nothing,
	# but it still reports an AABB, which is what holds the framing steady.
	var half: Vector3 = cube_size * 0.5 + Vector3.ONE * distribution_thickness
	var lo: Vector3 = Vector3(
		minf(-half.x, growth_origin.x), minf(-half.y, growth_origin.y), minf(-half.z, growth_origin.z))
	var hi: Vector3 = Vector3(
		maxf(half.x, growth_origin.x), maxf(half.y, growth_origin.y), maxf(half.z, growth_origin.z))
	var anchor := MeshInstance3D.new()
	anchor.name = "FieldAnchor"
	var box := BoxMesh.new()
	box.size = hi - lo
	anchor.mesh = box
	anchor.position = (lo + hi) * 0.5
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anchor)

func apply_grid_config(config: Dictionary) -> void:
	# Additive: a config without these keys leaves the artifact exactly as it was.
	var touched: bool = false
	if config.has("aftermath"):
		var key: String = str(config["aftermath"]).strip_edges().to_lower()
		if AFTERMATH_VALUES.has(key):
			aftermath = key
			touched = true
	if config.has("growth_seed"):
		growth_seed = int(config["growth_seed"])
	# Redraw, never regrow: regenerating would re-roll an unseeded cloud and hand
	# the caller a different network than the one it just asked to restyle.
	if touched and not all_nodes.is_empty():
		visualize_structure()
