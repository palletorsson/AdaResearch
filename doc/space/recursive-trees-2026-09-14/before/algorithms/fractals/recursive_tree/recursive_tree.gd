# @identity
# essence: Procedural binary tree — a trunk forks into branches, each branch forks again, recursion depth 3. Box meshes with emission materials create a geometric canopy. Self-similar at every level.
# desire: To grow by halving — generate_branches calls itself with decremented depth, producing sub-branches from each endpoint. The tree is its own blueprint.
# critical_parameter: num_main_branches / max_sub_branches — control branching factor; random_seed — deterministic chaos, same seed same tree
# triggers: _ready → seed + material creation + full tree generation; rebuild_tree → clear all children, regenerate from parameters
# emerges: A geometric sculpture where every subtree is a complete tree — hierarchy from constraint, not command. Each node knows only its children yet the whole structure self-organizes.
# needs: VR branch manipulation [missing], growth animation [missing], parameter sliders [missing]
# relationships: Appears in DataStructures_Trees (binary recursion) and RecursiveEmergence_Tail_Recursion_Memoization (call stack visualization). The tree that teaches both data structure and recursion.
# truth: A tree is a list that learned to decide — left or right, less or greater. Hierarchy emerges not from authority but from the constraint of binary choice repeated.

extends Node3D

# Parameters for tree generation
@export_category("Tree Structure")
@export var num_main_branches := 5
@export var max_sub_branches := 4
@export var branch_length_min := 1.5
@export var branch_length_max := 4.0
@export var branch_width_min := 0.8
@export var branch_width_max := 2.5
@export var branch_height_min := 0.8
@export var branch_height_max := 2.5
@export var trunk_height := 5.0
@export var trunk_width := 1.5
@export var random_seed := 42

@export_category("Tree Appearance")
@export_color_no_alpha var primary_color := Color(0.95, 0.3, 0.3) # Red color from the image
@export_color_no_alpha var secondary_color := Color(0.85, 0.2, 0.2) # Slightly darker red for variation
@export_color_no_alpha var trunk_color := Color(0.8, 0.3, 0.3)
@export var metallic := 0.1
@export var roughness := 0.7
@export var emission_strength := 0.2

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA — axis: aftermath   (shared with branching_growth_algorithm and
# space_colonization_algorithm: three different growth rules, one question)
#
# Growth is a process and a still cannot hold a process. What a still CAN hold is
# what the growing left. This tree's growing is a recursion — a call that forks
# into calls until the depth runs out — so what it leaves is a stack of
# generations and a volume it happened to fill. The axis is how much of that the
# finished sculpture is still willing to show.
#
#   form       the tree alone, in its own three reds. A result, not a record.
#              (DEFAULT — today's picture, unchanged)
#   strata     nothing added: every box repainted by the recursion depth that
#              made it, trunk to canopy, so the call stack is legible as colour.
#              Recursion as history rather than as shape.
#   envelope   the tree plus a wire box on its own bounding volume — the reach
#              the recursion turned out to have, drawn as a claim about extent.
#   apparatus  the envelope plus a mark at the fork the trunk hands off to and
#              at every terminal the recursion could not continue past. The
#              sculpture staged as a demonstration of where the calls stopped.
#
# STRICTLY ADDITIVE and RNG-FREE. _apply_aftermath() runs AFTER generate_tree(),
# reads the built scene graph, and returns immediately at `form`. It draws no
# random number, so the seeded tree is bit-identical at every value.
# ─────────────────────────────────────────────────────────────────────────────
const AFTERMATH_VALUES := ["form", "strata", "envelope", "apparatus"]
@export_enum("form", "strata", "envelope", "apparatus") var aftermath: String = "form"

const AFT_WIRE := Color(0.45, 0.70, 1.0)
const AFT_SHELL := Color(0.40, 0.64, 1.0, 0.14)
const AFT_JOINT := Color(1.0, 0.90, 0.35)
const AFT_TERMINAL := Color(0.30, 1.0, 0.62)
const STRATA_BANDS := [
	Color(0.16, 0.14, 0.38),   # trunk
	Color(0.28, 0.46, 0.86),   # first fork
	Color(0.35, 0.86, 0.72),   # second
	Color(1.0, 0.86, 0.28),    # canopy
]

# Materials
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var trunk_material: StandardMaterial3D

# instance_id -> the material_override the box had at `form`. Only populated
# when `strata` paints over them; empty at the default.
var _original_mats: Dictionary = {}

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Set the random seed
	seed(random_seed)
	
	# Create materials
	create_materials()

	# Generate the tree
	generate_tree()

	# APPENDED LAST, after every randf()/randi() in generate_tree(). Reads the
	# finished scene graph and draws nothing of its own at the default.
	_apply_aftermath()

# Creates materials for the tree
func create_materials() -> void:
	# Primary material (most blocks)
	primary_material = StandardMaterial3D.new()
	primary_material.albedo_color = primary_color
	primary_material.metallic = metallic
	primary_material.roughness = roughness
	primary_material.emission_enabled = true
	primary_material.emission = primary_color
	primary_material.emission_energy_multiplier = emission_strength
	
	# Secondary material (some blocks for variation)
	secondary_material = StandardMaterial3D.new()
	secondary_material.albedo_color = secondary_color
	secondary_material.metallic = metallic
	secondary_material.roughness = roughness
	secondary_material.emission_enabled = true
	secondary_material.emission = secondary_color
	secondary_material.emission_energy_multiplier = emission_strength * 0.7
	
	# Trunk material
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = metallic
	trunk_material.roughness = roughness + 0.1
	trunk_material.emission_enabled = true
	trunk_material.emission = trunk_color
	trunk_material.emission_energy_multiplier = emission_strength * 0.5

# Generates the complete tree structure
func generate_tree() -> void:
	# Create root node for the tree
	var tree_root = Node3D.new()
	tree_root.name = "GeometricTree"
	add_child(tree_root)
	
	# Create trunk
	var trunk = create_trunk()
	tree_root.add_child(trunk)
	
	# Generate main branches
	var branch_origin = Vector3(0, trunk_height - trunk_width/2, 0)
	generate_branches(tree_root, branch_origin, num_main_branches, 0, 3)

# Creates the trunk of the tree
func create_trunk():
	var trunk_node = Node3D.new()
	trunk_node.name = "Trunk"
	
	# Create the main trunk block
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)
	
	var trunk_instance = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = trunk_material
	trunk_instance.position.y = trunk_height / 2
	
	trunk_node.add_child(trunk_instance)
	
	# Maybe add some smaller blocks to the trunk for detail
	var num_details = randi() % 4 + 1
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()
		
		var detail_size = Vector3(
			trunk_width * randf_range(0.3, 0.6),
			trunk_width * randf_range(0.3, 0.6),
			trunk_width * randf_range(0.3, 0.6)
		)
		detail_mesh.size = detail_size
		
		detail.mesh = detail_mesh
		
		# Position somewhere on the trunk
		var height_pos = randf_range(trunk_width, trunk_height - trunk_width)
		var angle = randf_range(0, TAU)
		var radius = trunk_width/2 * 0.9
		
		detail.position = Vector3(
			cos(angle) * radius,
			height_pos,
			sin(angle) * radius
		)
		
		# Randomly choose material
		detail.material_override = primary_material if randf() > 0.3 else secondary_material
		
		trunk_node.add_child(detail)
	
	return trunk_node

# Recursively generates branches
func generate_branches(parent, origin_point, num_branches, current_depth, max_depth) -> void:
	if current_depth >= max_depth:
		return
	
	for i in range(num_branches):
		# Create a branch node
		var branch = Node3D.new()
		branch.name = "Branch_" + str(current_depth) + "_" + str(i)
		parent.add_child(branch)
		
		# Determine branch size
		var branch_width = randf_range(branch_width_min, branch_width_max) * (1.0 - current_depth * 0.2)
		var branch_height = randf_range(branch_height_min, branch_height_max) * (1.0 - current_depth * 0.2)
		var branch_length = randf_range(branch_length_min, branch_length_max) * (1.0 - current_depth * 0.15)
		
		# Create branch mesh
		var branch_mesh = BoxMesh.new()
		branch_mesh.size = Vector3(branch_width, branch_height, branch_length)
		
		var branch_instance = MeshInstance3D.new()
		branch_instance.mesh = branch_mesh
		
		# Choose material
		branch_instance.material_override = primary_material if randf() > 0.3 else secondary_material
		
		# Set direction, position, and rotation
		var angle
		if num_branches <= 2:
			# For binary branches, space them apart
			angle = TAU * (i / float(num_branches)) + randf_range(-0.3, 0.3)
		else:
			# Random angle for more branches
			angle = randf_range(0, TAU)
		
		# Adjust angle for more natural spreading
		var vertical_tilt = randf_range(0.2, 0.5) # Tilt upward
		
		# Calculate direction with vertical component
		var direction = Vector3(
			cos(angle),
			vertical_tilt,
			sin(angle)
		).normalized()
		
		# Position the branch
		var distance_from_origin = branch_length / 2
		var position = origin_point + direction * distance_from_origin
		branch_instance.position = position
		
		# Rotate to point in the direction
		branch_instance.look_at_from_position(branch_instance.position, position + direction, Vector3.UP)
		
		branch.add_child(branch_instance)
		
		# Maybe add some detail blocks to the branch
		if randf() > 0.4:
			add_detail_blocks(branch, branch_instance, branch_mesh.size)
		
		# Calculate the end point for sub-branches
		var end_point = position + direction * (branch_length / 2)
		
		# Generate sub-branches
		var num_sub = randi() % (max_sub_branches - current_depth) + 1
		if current_depth < 2:  # More branches at lower depths
			num_sub = randi() % max_sub_branches + 2
		
		generate_branches(branch, end_point, num_sub, current_depth + 1, max_depth)

# Adds small detail blocks to a branch
func add_detail_blocks(parent_node, branch_instance, branch_size) -> void:
	var num_details = randi() % 3 + 1
	
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()
		
		# Smaller blocks for details
		var scale_factor = randf_range(0.2, 0.5)
		var detail_size = Vector3(
			branch_size.x * scale_factor,
			branch_size.y * scale_factor,
			branch_size.z * scale_factor
		)
		detail_mesh.size = detail_size
		
		detail.mesh = detail_mesh
		
		# Position on the surface of the branch
		var axis = randi() % 3  # Which axis to project along (x, y, or z)
		var sign_factor = 1 if randf() > 0.5 else -1
		
		var relative_position = Vector3.ZERO
		
		match axis:
			0:  # X-axis
				relative_position.x = sign_factor * (branch_size.x / 2 + detail_size.x / 2 * 0.8)
				relative_position.y = randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = randf_range(-0.4, 0.4) * branch_size.z
			1:  # Y-axis
				relative_position.x = randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = sign_factor * (branch_size.y / 2 + detail_size.y / 2 * 0.8)
				relative_position.z = randf_range(-0.4, 0.4) * branch_size.z
			2:  # Z-axis
				relative_position.x = randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = sign_factor * (branch_size.z / 2 + detail_size.z / 2 * 0.8)
		
		# Apply rotation of parent branch to the relative position
		var global_transform = branch_instance.global_transform
		detail.position = branch_instance.to_local(global_position + global_transform.basis * relative_position)
		
		# Match parent rotation
		detail.rotation = branch_instance.rotation
		
		# Choose material, favor secondary material for details
		detail.material_override = secondary_material if randf() > 0.4 else primary_material
		
		parent_node.add_child(detail)

# Additional function to create more complex geometric tree like in the image
func generate_complex_geometric_tree() -> void:
	# Create root node for the tree
	var tree_root = Node3D.new()
	tree_root.name = "ComplexGeometricTree"
	add_child(tree_root)
	
	# Create base
	var base = create_base()
	tree_root.add_child(base)
	
	# Create "blocks" cluster - the main feature of the image
	create_block_cluster(tree_root, Vector3(0, trunk_height, 0))

# Creates a flat base/ground
func create_base():
	var base_node = Node3D.new()
	base_node.name = "Base"
	
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(20, 0.5, 20)
	
	var base_instance = MeshInstance3D.new()
	base_instance.mesh = base_mesh
	base_instance.position.y = -0.25  # Half the height
	
	# Create a darker material for the base
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.2, 0.2, 0.3)
	base_material.metallic = 0.1
	base_material.roughness = 0.9
	
	base_instance.material_override = base_material
	
	base_node.add_child(base_instance)
	
	return base_node

# Creates a complex cluster of blocks like in the reference image
func create_block_cluster(parent, origin_point) -> void:
	# Create a node for the cluster
	var cluster = Node3D.new()
	cluster.name = "BlockCluster"
	parent.add_child(cluster)
	
	# Main large blocks
	create_main_blocks(cluster, origin_point)
	
	# Connecting structures
	create_connecting_structures(cluster, origin_point)
	
	# Small details
	add_cluster_details(cluster, origin_point)

# Creates the main large blocks of the cluster
func create_main_blocks(parent, origin_point) -> void:
	# In the reference image, there are about 3-4 large block clusters
	var num_blocks = 4
	
	for i in range(num_blocks):
		var block_node = Node3D.new()
		block_node.name = "MainBlock_" + str(i)
		parent.add_child(block_node)
		
		# Create a cluster of connected blocks
		var num_sub_blocks = randi() % 4 + 2
		var main_position = Vector3(
			randf_range(-3, 3),
			randf_range(1, 5),
			randf_range(-3, 3)
		) + origin_point
		
		for j in range(num_sub_blocks):
			var block = MeshInstance3D.new()
			var block_mesh = BoxMesh.new()
			
			# Larger sizes for main blocks
			var block_size = Vector3(
				randf_range(2.0, 4.0),
				randf_range(2.0, 4.0),
				randf_range(2.0, 4.0)
			)
			block_mesh.size = block_size
			
			block.mesh = block_mesh
			
			# Position blocks adjacent to each other
			var offset = Vector3(
				randf_range(-1.5, 1.5),
				randf_range(-1.5, 1.5),
				randf_range(-1.5, 1.5)
			)
			
			if j == 0:
				block.position = main_position
			else:
				block.position = main_position + offset
			
			# Use primary material for most blocks
			block.material_override = primary_material
			
			block_node.add_child(block)

# Creates connecting structures between main blocks
func create_connecting_structures(parent, origin_point) -> void:
	# Create a few connector pieces
	var num_connectors = randi() % 5 + 3
	
	for i in range(num_connectors):
		var connector = MeshInstance3D.new()
		connector.name = "Connector_" + str(i)
		
		var connector_mesh
		var type = randi() % 3
		
		match type:
			0:  # Thin box
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(3.0, 6.0)
				)
			1:  # L-shaped (approximated with two boxes)
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(2.0, 4.0)
				)
				
				# Create a second part for the L
				var part2 = MeshInstance3D.new()
				var part2_mesh = BoxMesh.new()
				part2_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(0.5, 1.0),
					randf_range(2.0, 3.0)
				)
				
				part2.mesh = part2_mesh
				part2.position = Vector3(0, 0, connector_mesh.size.z/2 + part2_mesh.size.z/2 - 0.1)
				part2.rotation_degrees.y = 90
				part2.material_override = secondary_material
				
				connector.add_child(part2)
			2:  # Thin vertical column
				connector_mesh = BoxMesh.new()
				connector_mesh.size = Vector3(
					randf_range(0.5, 1.0),
					randf_range(3.0, 6.0),
					randf_range(0.5, 1.0)
				)
		
		connector.mesh = connector_mesh
		
		# Position somewhere in the structure
		connector.position = origin_point + Vector3(
			randf_range(-4, 4),
			randf_range(0, 4),
			randf_range(-4, 4)
		)
		
		# Random rotation
		connector.rotation_degrees.y = randf_range(0, 360)
		
		# Use secondary material for contrast
		connector.material_override = secondary_material
		
		parent.add_child(connector)

# Adds small detail blocks to the cluster
func add_cluster_details(parent, origin_point) -> void:
	var num_details = randi() % 10 + 5
	
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		detail.name = "Detail_" + str(i)
		
		var detail_mesh = BoxMesh.new()
		detail_mesh.size = Vector3(
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8),
			randf_range(0.3, 0.8)
		)
		
		detail.mesh = detail_mesh
		
		# Position details around the structure
		detail.position = origin_point + Vector3(
			randf_range(-5, 5),
			randf_range(0, 6),
			randf_range(-5, 5)
		)
		
		# Random rotation
		detail.rotation_degrees = Vector3(
			randf_range(0, 30),
			randf_range(0, 360),
			randf_range(0, 30)
		)
		
		# Choose material, with higher chance of secondary
		detail.material_override = secondary_material if randf() > 0.3 else primary_material
		
		parent.add_child(detail)

# Can be called to rebuild the tree with new parameters
func rebuild_tree() -> void:
	# Remove existing tree
	for child in get_children():
		child.queue_free()
	
	# Generate new tree
	generate_tree()
	_apply_aftermath()

# For the specific style in the image - call this instead of generate_tree()
func generate_image_style_tree() -> void:
	# Create base materials
	create_materials()
	
	# Create complex geometric tree like in the image
	generate_complex_geometric_tree()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ─────────────────────────────────────────────────────────────────────────────
# aftermath — everything below is new and nothing above it moved.
# ─────────────────────────────────────────────────────────────────────────────

func _aftermath_key() -> String:
	# Unknown word keeps the default. A typo in a map file should cost you the
	# variant, not the object.
	var key: String = str(aftermath).strip_edges().to_lower()
	if AFTERMATH_VALUES.has(key):
		return key
	return "form"

func _apply_aftermath() -> void:
	var key: String = _aftermath_key()
	if key == "form":
		return

	var boxes: Array = []
	_collect_boxes(self, -1, Transform3D.IDENTITY, boxes)
	if boxes.is_empty():
		return

	var deepest: int = -1
	for b in boxes:
		var d: int = int(b["depth"])
		if d > deepest:
			deepest = d

	match key:
		"strata":
			_paint_strata(boxes, deepest)
		"envelope":
			_draw_wire(_growth_rings(boxes, deepest), [])
		"apparatus":
			var marks: Array = [
				{"at": Vector3(0, trunk_height - trunk_width / 2.0, 0), "r": trunk_width * 0.9,
					"c": AFT_JOINT},
			]
			for tip in boxes:
				if int(tip["depth"]) == deepest:
					var txf: Transform3D = tip["xf"]
					marks.append({"at": txf.origin, "r": 0.55, "c": AFT_TERMINAL})
			_draw_wire(_growth_rings(boxes, deepest), marks)

## One bounding volume per recursion level: what the tree had reached after the
## trunk, after the first fork, after the second, after the third. Nested cages
## rather than a single outer box — one box is 12 hairlines on the silhouette,
## covers under 1% of the frame, and would be reported as decoration. Four
## nested cages with their corners tied together are a lattice, they cross the
## canopy, and they say the thing the value is actually claiming: the reach was
## not given, it accumulated.
func _growth_rings(boxes: Array, deepest: int) -> Array:
	var rings: Array = []
	for d in range(-1, deepest + 1):
		var upto: Array = []
		for b in boxes:
			if int(b["depth"]) <= d:
				upto.append(b)
		if not upto.is_empty():
			rings.append(_bounds_of(upto))
	return rings

## Walks the built tree. `Branch_<depth>_<i>` names its own recursion level, so
## the depth is read off the graph rather than re-derived. Trunk boxes stay at
## -1: the trunk is what the recursion started from, not a generation of it.
func _collect_boxes(node: Node, depth: int, xf: Transform3D, out: Array) -> void:
	for child in node.get_children():
		var cd: int = depth
		var nm: String = String(child.name)
		if nm.begins_with("Branch_"):
			var parts: PackedStringArray = nm.split("_")
			if parts.size() >= 2 and parts[1].is_valid_int():
				cd = int(parts[1])
			else:
				cd = depth + 1
		var cxf: Transform3D = xf
		if child is Node3D:
			cxf = xf * (child as Node3D).transform
		if child is MeshInstance3D and not nm.begins_with("AftermathWire"):
			out.append({"mi": child, "depth": cd, "xf": cxf})
		_collect_boxes(child, cd, cxf, out)

func _bounds_of(boxes: Array) -> AABB:
	var acc := AABB()
	var have: bool = false
	for b in boxes:
		var mi: MeshInstance3D = b["mi"]
		var xf: Transform3D = b["xf"]
		var ab: AABB = xf * mi.get_aabb()
		acc = ab if not have else acc.merge(ab)
		have = true
	return acc

func _paint_strata(boxes: Array, deepest: int) -> void:
	var bands: Array = []
	var span: int = maxi(1, deepest + 2)
	for i in range(span):
		var t: float = float(i) / float(maxi(1, span - 1)) * float(STRATA_BANDS.size() - 1)
		var lo: int = clampi(int(floor(t)), 0, STRATA_BANDS.size() - 1)
		var hi: int = clampi(lo + 1, 0, STRATA_BANDS.size() - 1)
		var a: Color = STRATA_BANDS[lo]
		var c: Color = a.lerp(STRATA_BANDS[hi], t - float(lo))
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.metallic = metallic
		m.roughness = roughness
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission_strength
		bands.append(m)
	for b in boxes:
		var idx: int = clampi(int(b["depth"]) + 1, 0, bands.size() - 1)
		var mi: MeshInstance3D = b["mi"]
		# Remember what `form` looked like. Which boxes drew primary and which
		# drew secondary was decided by a randf() at build time and cannot be
		# re-derived, so switching back has to be a restore, not a rebuild.
		if not _original_mats.has(mi.get_instance_id()):
			_original_mats[mi.get_instance_id()] = mi.material_override
		mi.material_override = bands[idx]

func _corners_of(bounds: AABB) -> Array[Vector3]:
	var lo: Vector3 = bounds.position
	var hi: Vector3 = bounds.position + bounds.size
	var out: Array[Vector3] = [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
		Vector3(hi.x, hi.y, lo.z), Vector3(lo.x, hi.y, lo.z),
		Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z),
		Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	]
	return out

func _draw_wire(cages: Array, marks: Array) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]
	var prev_corners: Array[Vector3] = []
	for cg in cages:
		var bounds: AABB = cg
		var corner: Array[Vector3] = _corners_of(bounds)
		for e in edges:
			im.surface_set_color(AFT_WIRE)
			im.surface_add_vertex(corner[int(e[0])])
			im.surface_set_color(AFT_WIRE)
			im.surface_add_vertex(corner[int(e[1])])
		# Tie each ring to the one before it, so the cages read as one expanding
		# lattice rather than as four unrelated boxes.
		if prev_corners.size() == 8:
			for k in range(8):
				im.surface_set_color(AFT_WIRE)
				im.surface_add_vertex(prev_corners[k])
				im.surface_set_color(AFT_WIRE)
				im.surface_add_vertex(corner[k])
		prev_corners = corner
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for mk in marks:
		var at: Vector3 = mk["at"]
		var r: float = float(mk["r"])
		var c: Color = mk["c"]
		for ax in axes:
			im.surface_set_color(c)
			im.surface_add_vertex(at - ax * r)
			im.surface_set_color(c)
			im.surface_add_vertex(at + ax * r)
	im.surface_end()

	var wire := MeshInstance3D.new()
	wire.name = "AftermathWire"
	wire.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	wire.material_override = mat
	wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wire)

	# The outermost ring as a SOLID translucent block, under the lattice. Sixty
	# hairlines are still only ~1% of the frame; the reach the recursion had is
	# a volume, so it is drawn as one and the critic can see it.
	if not cages.is_empty():
		var outer: AABB = cages[cages.size() - 1]
		var shell := MeshInstance3D.new()
		shell.name = "AftermathWire"   # same name so _restyle() sweeps both
		var box := BoxMesh.new()
		box.size = outer.size
		shell.mesh = box
		shell.position = outer.get_center()
		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.albedo_color = AFT_SHELL
		smat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shell.material_override = smat
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shell)

## Puts the tree back to `form` — wire removed, materials restored — so the axis
## can be changed on a standing tree without regrowing it. rebuild_tree() would
## reshuffle every randf() and hand the caller a different tree than the one it
## asked to restyle, which is a change of subject, not a change of staging.
func _restyle() -> void:
	# begins_with, not ==: Godot renames a second child sharing a name, so the
	# translucent shell lands as "AftermathWire2" and an exact match leaks it.
	for child in get_children():
		if String(child.name).begins_with("AftermathWire"):
			remove_child(child)
			child.free()
	for id in _original_mats.keys():
		var mi = instance_from_id(int(id))
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).material_override = _original_mats[id]
	_original_mats.clear()
	_apply_aftermath()

func apply_grid_config(config: Dictionary) -> void:
	# Additive: a config without these keys leaves the artifact exactly as it was.
	if config.has("aftermath"):
		var key: String = str(config["aftermath"]).strip_edges().to_lower()
		if AFTERMATH_VALUES.has(key) and key != aftermath:
			aftermath = key
			if is_inside_tree() and get_child_count() > 0:
				_restyle()
	if config.has("random_seed"):
		random_seed = int(config["random_seed"])
