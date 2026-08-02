# @identity
# essence: Procedural kitbash environment — 30 modules (surrealist/mechanical/organic) placed randomly in 3D space, connected by pipes, beams, and floating bridges. Modular composition through randomized assembly.
# desire: To be regenerated endlessly — connects to regenerate_emitters, clears all geometry, and rebuilds from scratch. Every instantiation is a unique surrealist landscape.
# critical_parameter: generation_rules — "surrealist" spawns exquisite-corpse creatures and nonsensical machines, "mechanical" spawns joints and pipe systems, "organic" spawns coral and fluid vessels; disclosure — how much the finished world admits about the draw that made it (oracle | tally | ledger | works | origin)
# triggers: regenerate_requested signal → full scene rebuild; _ready → initial generation with random color theme selection
# emerges: A different world every time — the same code produces industrial cathedrals, alien nurseries, or surrealist galleries depending on the random seed and theme; at disclosure:origin the seed that chose this one stands in the world as thirty-two lamps
# needs: VR interaction [missing], module selection UI [missing], generation preview [missing]
# relationships: The default environment artifact across data structures and geometry sequences — a procedural backdrop that gives each map a unique visual identity; shares the disclosure ladder with prng_crank_machine, coin_toss and trng_vs_prng
# truth: Randomness is not absence of structure — it is structure deferred to the moment of instantiation, where every possible world gets exactly one chance to exist.

extends Node3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02). The randomness family's ONE axis, adopted:
#
#   disclosure   oracle  <  tally  <  ledger  <  works  <  origin
#
# defined in prng_crank_machine.gd, already shared with coin_toss,
# random_number_book_page_1955 and trng_vs_prng. This is the most-placed untouched
# artifact in the registry — 43 rooms — and it is made ENTIRELY of draws: thirty
# positions, thirty rotations, thirty scales, fifteen connections, a colour theme,
# five spotlights, a hundred motes. It shows you the result of all of that and not
# one thing about it. So the family word lands here harder than anywhere: this
# world's default rung is the BOTTOM one.
#
#   oracle  A world arrives. Modules, pipes, beams, lights, motes. Nothing says it
#           was drawn rather than built, nothing says how many of what, nothing
#           says where the boundary of the possible was. THE LEGACY ENVIRONMENT,
#           byte for byte — this is the default, and all 43 placements keep it.
#   tally   + the census: a bar chart at world scale standing inside the field,
#           one column per module RECIPE, height proportional to how many of that
#           kind the draw produced. How much of each was made. Never which.
#   ledger  + the record: a rod dropped from every placed module to the floor
#           plane, one per entry, so the scatter that the draw actually produced
#           becomes a legible field of stems instead of an impression of clutter.
#   works   + the mechanism: the sampling domain itself, drawn as a wireframe cage
#           of exactly space_size with graduated ticks along one edge of each
#           axis. The generator is "uniform inside this box", and at this rung the
#           box is a thing you can walk to the corner of.
#   origin  + the substrate: the seed, as thirty-two lamps along the south edge,
#           MSB left — the number this entire world unrolls from. When no seed was
#           pinned the sockets stand EMPTY and struck through, because randomize()
#           cannot be read back: that world had an origin and nobody wrote it down,
#           and it can never be visited again. The lamps are the honest report
#           either way.
#
# NOT PROMOTED: generation_rules. It is a real fork in what gets built, but it is
# the artifact's SUBJECT, not its argument about itself — and it is already an
# export nothing reads (see apply_grid_config, which was `pass`). module_count and
# space_size are quantities, not claims. The colour themes are "which colour",
# which the promotion rules exclude by name.
#
# NOT TOUCHED: the generator. Every rung draws the same modules in the same places
# from the same stream — the disclosure rig is built LAST, from recorded data,
# with no randomness of its own, so a fixed kitbash_seed gives byte-identical
# worlds at all five rungs and only the account over them changes.
#
# WHY THE RIG IS MULTIMESH: the DNA capturer fits its camera to the union of the
# MeshInstance3D nodes it finds. Every piece of this account is drawn as MultiMesh
# instead, so adding it cannot move the camera — the five variants are photographed
# from exactly the same place and the sweep measures the axis rather than its own
# framing.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once in prng_crank_machine. Preloaded rather than
## reached through class_name — class_name lookups are not reliable headless and
## every frame of the evidence loop is rendered headless.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

# Parameters for modular kitbashing generation
@export var module_count: int = 30
@export var space_size: Vector3 = Vector3(30, 15, 30)
@export_dir var modules_path: String = "res://modules/"
@export var generation_rules: String = "surrealist" # surrealist, mechanical, organic

## THE AXIS — how much the finished world admits about the draw that made it. Same
## five rungs, same order, same spellings as prng_crank_machine and coin_toss.
## `oracle` is the legacy environment: it admits nothing, which is precisely what
## the bottom rung of this ladder means.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "oracle"

## The allow-list, in ladder order — the same five words the @export_enum declares.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## PIN. -1 (the default) is today's behaviour exactly: _ready calls randomize() and
## every one of the several hundred draws below comes out different on every
## instantiation, in every one of the 43 rooms this stands in. That is the artifact
## working as designed and it makes it UNMEASURABLE — a disclosure sweep would
## render five completely different worlds and report a confident bite that was
## entirely the kitbash.
##
## Any value >= 0 seeds the global generator instead, so the same number rebuilds
## the same world. The DNA fixture must set it, and `origin` has something to show
## only when it is set.
@export var kitbash_seed: int = -1

# Color themes inspired by the reference images
@export var color_themes = [
	# Ben Nicholas blue/yellow theme
	{
		"primary": Color(0.1, 0.5, 0.8),
		"secondary": Color(0.9, 0.7, 0.1),
		"accent": Color(0.7, 0.1, 0.3),
		"metal": Color(0.7, 0.7, 0.75)
	},
	# Vitaly Bulgarov industrial theme
	{
		"primary": Color(0.2, 0.2, 0.25),
		"secondary": Color(0.5, 0.5, 0.55),
		"accent": Color(0.9, 0.1, 0.1),
		"metal": Color(0.8, 0.8, 0.9)
	},
	# Katie Torn vibrant theme
	{
		"primary": Color(0.9, 0.3, 0.7),
		"secondary": Color(0.2, 0.8, 0.7),
		"accent": Color(0.95, 0.95, 0.2),
		"metal": Color(0.6, 0.8, 1.0)
	}
]

var modules = []
var placed_modules = []
var color_theme = null

## THE RECORD the disclosure rig is built from. Filled as the world is generated,
## never read by the generator itself — so at `oracle` these arrays are written and
## then nothing looks at them, which costs three appends per module and keeps the
## account and the process completely separate.
var _module_kinds: Array[int] = []      # recipe id per TEMPLATE in `modules`
var _placed_kinds: Array[int] = []      # recipe id per PLACED module, in draw order
var _placed_pos: Array[Vector3] = []    # where each draw landed, in draw order
var _kind_base: int = 0                 # first recipe id the active rules can produce
var _kind_span: int = 5                 # how many recipe buckets the census draws
var _disclosure_root: Node3D = null


## Rank of the current rung, 0..4. Every gate here is `_rung() >= n`.
## NOTE the fallback: 0, not 3. The other members of this family default to
## `works` because their legacy shows its mechanism; this one's legacy shows
## nothing, so an unreadable word must land on `oracle` or it would silently
## turn on an account in 43 rooms.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 0))


# -- Regenerate handling --
func regenerate_scene() -> void:
	print("envOne: Regenerating scene")
	_clear_current_geometry()
	generate_space()
	apply_lighting()
	apply_atmosphere()
	_build_disclosure()

func _clear_current_geometry() -> void:
	for module in placed_modules:
		if module and is_instance_valid(module):
			module.queue_free()
	placed_modules.clear()
	# The record goes with the world it described.
	_placed_kinds.clear()
	_placed_pos.clear()

	var to_remove: Array = []
	for child in get_children():
		if child is Camera3D:
			continue
		if child is MeshInstance3D or child is MultiMeshInstance3D or child is CSGPrimitive3D or child is GPUParticles3D:
			to_remove.append(child)
		elif child is WorldEnvironment or child is Light3D or child is SpotLight3D or child is OmniLight3D or child is DirectionalLight3D:
			to_remove.append(child)
	for node in to_remove:
		if is_instance_valid(node):
			node.queue_free()

func connect_regenerate_signal() -> void:
	if _regenerate_connected:
		return
	_attach_to_regenerate_cubes()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	_regenerate_connected = true

func _attach_to_regenerate_cubes() -> void:
	for cube in get_tree().get_nodes_in_group("regenerate_emitters"):
		_connect_regenerate_cube(cube)

func _on_tree_node_added(node: Node) -> void:
	if node and node.is_in_group("regenerate_emitters"):
		_connect_regenerate_cube(node)

func _connect_regenerate_cube(cube) -> void:
	if cube and cube.has_signal("regenerate_requested") and not cube.regenerate_requested.is_connected(_on_regenerate_requested):
		cube.regenerate_requested.connect(_on_regenerate_requested)
		print("envOne: connected to regenerate cube %s" % cube.get_path())

func _on_regenerate_requested(_origin: Vector3, targets: Array, metadata: Dictionary) -> void:
	print("envOne: regenerate signal received with %d target(s)" % targets.size())
	if targets.is_empty() or _matches_target(targets):
		regenerate_scene()

func _matches_target(targets: Array) -> bool:
	var this_path = get_script().resource_path
	for target in targets:
		var value = str(target)
		if value.ends_with("envOne.gd") or value.ends_with("env_one.tscn"):
			return true
		if value == this_path:
			return true
	return false

var _initial_children: Array = []
var _regenerate_connected: bool = false

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child, so the meta
	# read happens here, before the first draw.
	_read_meta_overrides()
	# BEFORE anything draws. At the default (-1) this is the identical randomize()
	# call that has always stood here and the whole stream below is untouched.
	if kitbash_seed >= 0:
		seed(kitbash_seed)
	else:
		randomize()
	color_theme = color_themes[randi() % color_themes.size()]
	load_or_create_modules()
	generate_space()
	apply_lighting()
	apply_atmosphere()
	connect_regenerate_signal()
	# APPENDED LAST, after every draw the world is made of, and using none of its
	# own. At `oracle` this builds nothing at all.
	_build_disclosure()

func load_or_create_modules() -> void:
	# Try to load existing modules
	var dir = DirAccess.open(modules_path)
	if dir and dir.list_dir_begin() == OK:
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var module = load(modules_path + file_name)
				if module:
					modules.append(module)
			file_name = dir.get_next()
	
	# If no modules found, create procedural ones
	if modules.size() == 0:
		create_procedural_modules()

func create_procedural_modules() -> void:
	# Create module types based on the selected generation style.
	# _kind_base/_kind_span tell the census which recipe buckets this run can
	# produce at all, so a surrealist world draws five columns and not thirteen.
	match generation_rules:
		"surrealist":
			_kind_base = 0
			_kind_span = 5
			create_surrealist_modules()
		"mechanical":
			_kind_base = 5
			_kind_span = 4
			create_mechanical_modules()
		"organic":
			_kind_base = 9
			_kind_span = 4
			create_organic_modules()
		_:
			_kind_base = 0
			_kind_span = 13
			create_mixed_modules()

func create_surrealist_modules() -> void:
	# Create modules inspired by exquisite corpse and surrealist works
	for i in range(10):
		# Base objects
		var module = Node3D.new()
		module.name = "SurrealistModule_" + str(i)

		# Add some random geometry - mixing disparate elements is key to surrealism
		# The draw is lifted into a variable so the census can record WHICH recipe
		# this template is. Exactly one randi() either way: the stream is untouched.
		var kind: int = randi() % 5
		_module_kinds.append(kind)
		match kind:
			0: # Stack of primitive shapes
				add_stacked_primitives(module)
			1: # Floating parts
				add_floating_parts(module)
			2: # Nonsensical machine
				add_nonsensical_machine(module)
			3: # Abstract sculpture
				add_abstract_sculpture(module)
			4: # Composite creature
				add_composite_creature(module)
		
		modules.append(module)

func create_mechanical_modules() -> void:
	# Create modules inspired by Vitaly Bulgarov's mechanical kit parts
	for i in range(10):
		var module = Node3D.new()
		module.name = "MechanicalModule_" + str(i)

		var kind: int = randi() % 4
		_module_kinds.append(5 + kind)
		match kind:
			0: # Mechanical joint
				add_mechanical_joint(module)
			1: # Control panel
				add_control_panel(module)
			2: # Industrial pipe system
				add_pipe_system(module)
			3: # Electronic component
				add_electronic_component(module)
				
		modules.append(module)

func create_organic_modules() -> void:
	# Create modules inspired by more organic forms
	for i in range(10):
		var module = Node3D.new()
		module.name = "OrganicModule_" + str(i)

		var kind: int = randi() % 4
		_module_kinds.append(9 + kind)
		match kind:
			0: # Plant-like structure
				add_plant_structure(module)
			1: # Fluid-containing vessel
				add_fluid_vessel(module)
			2: # Coral-like growth
				add_coral_structure(module)
			3: # Alien egg sac
				add_egg_structure(module)
				
		modules.append(module)

func create_mixed_modules() -> void:
	# Create some of each type for variety
	create_surrealist_modules()
	create_mechanical_modules()
	create_organic_modules()

# Helper functions to create different module types
func add_stacked_primitives(parent) -> void:
	var height = 0
	var pieces = randi() % 5 + 2  # 2-6 pieces
	
	for i in range(pieces):
		var mesh_instance = MeshInstance3D.new()
		
		# Choose a primitive mesh
		match randi() % 5:
			0: mesh_instance.mesh = SphereMesh.new()
			1: mesh_instance.mesh = BoxMesh.new()
			2: mesh_instance.mesh = CylinderMesh.new()
			3: mesh_instance.mesh = PrismMesh.new()
			4: mesh_instance.mesh = TorusMesh.new()
		
		# Randomize size
		var scale_factor = randf_range(0.5, 1.5)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Position above previous piece
		mesh_instance.position.y = height
		height += randf_range(0.5, 1.0) * scale_factor
		
		# Random material
		apply_random_material(mesh_instance)
		
		parent.add_child(mesh_instance)

func add_floating_parts(parent) -> void:
	var parts = randi() % 5 + 3  # 3-7 parts
	
	for i in range(parts):
		var mesh_instance = MeshInstance3D.new()
		
		# Choose a primitive mesh
		match randi() % 5:
			0: mesh_instance.mesh = SphereMesh.new()
			1: mesh_instance.mesh = BoxMesh.new()
			2: mesh_instance.mesh = CylinderMesh.new()
			3: mesh_instance.mesh = PrismMesh.new()
			4: mesh_instance.mesh = TorusMesh.new()
		
		# Randomize size
		var scale_factor = randf_range(0.3, 1.0)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Position randomly in space
		mesh_instance.position = Vector3(
			randf_range(-2, 2),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)
		
		# Apply material
		apply_random_material(mesh_instance)
		
		parent.add_child(mesh_instance)

func add_nonsensical_machine(parent) -> void:
	# Base
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.5, 0.2, 1.5)
	apply_material(base, "metal")
	parent.add_child(base)
	
	# Main body
	var body = MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	body.position.y = 1.0
	body.scale = Vector3(0.8, 1.0, 0.8)
	apply_material(body, "primary")
	parent.add_child(body)
	
	# Add random attachments
	for i in range(randi() % 4 + 2):  # 2-5 attachments
		var attachment = MeshInstance3D.new()
		var mesh_choice = randi() % 3
		
		if mesh_choice == 0:
			attachment.mesh = CylinderMesh.new()
			attachment.scale = Vector3(0.2, randf_range(0.5, 1.5), 0.2)
		elif mesh_choice == 1:
			attachment.mesh = BoxMesh.new()
			attachment.scale = Vector3(randf_range(0.3, 0.6), randf_range(0.3, 0.6), randf_range(0.3, 0.6))
		else:
			attachment.mesh = SphereMesh.new()
			var radius = randf_range(0.3, 0.5)
			attachment.scale = Vector3(radius, radius, radius)
		
		# Position around the body randomly
		var angle = randf_range(0, TAU)
		var distance = randf_range(0.8, 1.2)
		attachment.position = Vector3(
			cos(angle) * distance,
			randf_range(0.5, 1.5),
			sin(angle) * distance
		)
		
		apply_random_material(attachment)
		parent.add_child(attachment)

func add_abstract_sculpture(parent) -> void:
	# Create a base
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.0, 0.2, 1.0)
	apply_material(base, "secondary")
	parent.add_child(base)
	
	# Create the main sculpture body - use CSG for more complex shapes
	var main_body = CSGCombiner3D.new()
	main_body.position.y = 0.5
	
	# Add primary shape
	var primary = CSGSphere3D.new()
	primary.radius = 0.7
	main_body.add_child(primary)
	
	# Subtract random shapes to create interesting form
	for i in range(randi() % 3 + 2):
		var cutter = CSGBox3D.new() if randf() > 0.5 else CSGSphere3D.new()
		cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
		
		if cutter is CSGBox3D:
			cutter.size = Vector3(randf_range(0.3, 0.5), randf_range(0.3, 0.5), randf_range(0.3, 0.5))
		else:
			cutter.radius = randf_range(0.3, 0.5)
		
		cutter.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
		
		main_body.add_child(cutter)
	
	# Apply material to the CSG result
	var material = StandardMaterial3D.new()
	material.albedo_color = color_theme["primary"]
	material.metallic = randf_range(0.0, 0.5)
	material.roughness = randf_range(0.3, 0.7)
	
	primary.material = material
	
	parent.add_child(main_body)

func add_composite_creature(parent) -> void:
	# Inspired by exquisite corpse - create a creature with mismatched parts
	
	# Body
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.scale = Vector3(0.7, 1.0, 0.7)
	apply_material(body, "primary")
	parent.add_child(body)
	
	# Head (random object)
	var head = MeshInstance3D.new()
	match randi() % 4:
		0: head.mesh = SphereMesh.new()
		1: head.mesh = BoxMesh.new()
		2: head.mesh = TorusMesh.new()
		3: 
			head.mesh = PrismMesh.new()
			head.rotation_degrees.x = 90
	
	head.position.y = 1.3
	head.scale = Vector3(0.6, 0.6, 0.6)
	apply_material(head, "secondary")
	parent.add_child(head)
	
	# Limbs
	for i in range(randi() % 3 + 2):  # 2-4 limbs
		var limb = MeshInstance3D.new()
		limb.mesh = CylinderMesh.new()
		limb.scale = Vector3(0.2, randf_range(0.7, 1.2), 0.2)
		
		var angle = randf_range(0, TAU)
		limb.position = Vector3(
			cos(angle) * 0.7,
			randf_range(-0.5, 0.5),
			sin(angle) * 0.7
		)
		
		# Random rotation to point outward
		limb.look_at_from_position(limb.position, limb.position * 2, Vector3.UP)
		limb.rotation_degrees.x += 90
		
		apply_material(limb, "accent")
		parent.add_child(limb)

func add_mechanical_joint(parent) -> void:
	# Base plate
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.scale = Vector3(1.0, 0.1, 1.0)
	apply_material(base, "metal")
	parent.add_child(base)
	
	# Main joint cylinder
	var joint = MeshInstance3D.new()
	joint.mesh = CylinderMesh.new()
	joint.position.y = 0.3
	joint.scale = Vector3(0.3, 0.3, 0.3)
	apply_material(joint, "primary")
	parent.add_child(joint)
	
	# Joint arm
	var arm = MeshInstance3D.new()
	arm.mesh = BoxMesh.new()
	arm.scale = Vector3(0.2, 0.2, 1.0)
	arm.position = Vector3(0, 0.3, 0.5)
	apply_material(arm, "secondary")
	parent.add_child(arm)
	
	# Add details
	for i in range(randi() % 5 + 3):
		var detail = MeshInstance3D.new()
		if randf() > 0.5:
			detail.mesh = CylinderMesh.new()
			detail.scale = Vector3(0.1, 0.1, 0.1)
		else:
			detail.mesh = BoxMesh.new()
			detail.scale = Vector3(0.1, 0.1, 0.1)
		
		detail.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(0.1, 0.5),
			randf_range(-0.5, 0.5)
		)
		
		apply_material(detail, "metal")
		parent.add_child(detail)

func add_control_panel(parent) -> void:
	# Panel base
	var panel = MeshInstance3D.new()
	panel.mesh = BoxMesh.new()
	panel.scale = Vector3(1.0, 0.1, 1.5)
	panel.rotation_degrees.x = -30
	apply_material(panel, "metal")
	parent.add_child(panel)
	
	# Add controls
	for i in range(randi() % 10 + 5):
		var control = MeshInstance3D.new()
		
		if randf() > 0.7:
			# Button
			control.mesh = CylinderMesh.new()
			control.scale = Vector3(0.1, 0.05, 0.1)
			apply_material(control, "accent")
		elif randf() > 0.4:
			# Dial
			control.mesh = CylinderMesh.new()
			control.scale = Vector3(0.15, 0.03, 0.15)
			apply_material(control, "secondary")
		else:
			# Switch
			control.mesh = BoxMesh.new()
			control.scale = Vector3(0.05, 0.1, 0.05)
			apply_material(control, "primary")
		
		# Position on panel
		var panel_local_x = randf_range(-0.8, 0.8)
		var panel_local_z = randf_range(-1.2, 1.2)
		
		# Adjust for panel rotation
		var angle_rad = deg_to_rad(-30)
		control.position = Vector3(
			panel_local_x,
			panel_local_z * sin(angle_rad) + 0.1,
			panel_local_z * cos(angle_rad)
		)
		
		parent.add_child(control)

func add_pipe_system(parent) -> void:
	# Start and end points
	var start_pos = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	var end_pos = Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 2.0), randf_range(-1.0, 1.0))
	
	# Create main pipe
	create_pipe_segment(parent, start_pos, Vector3(start_pos.x, start_pos.y + 0.5, start_pos.z))
	create_pipe_segment(parent, Vector3(start_pos.x, start_pos.y + 0.5, start_pos.z), 
						Vector3(end_pos.x, start_pos.y + 0.5, start_pos.z))
	create_pipe_segment(parent, Vector3(end_pos.x, start_pos.y + 0.5, start_pos.z),
						Vector3(end_pos.x, end_pos.y, start_pos.z))
	create_pipe_segment(parent, Vector3(end_pos.x, end_pos.y, start_pos.z), end_pos)
	
	# Add some connections/valves
	var valve_pos = Vector3(
		(start_pos.x + end_pos.x) / 2,
		start_pos.y + 0.5,
		start_pos.z
	)
	
	var valve = MeshInstance3D.new()
	valve.mesh = CylinderMesh.new()
	valve.position = valve_pos
	valve.scale = Vector3(0.25, 0.15, 0.25)
	valve.rotation_degrees.x = 90
	apply_material(valve, "accent")
	parent.add_child(valve)
	
	# Add a wheel to the valve
	var wheel = MeshInstance3D.new()
	wheel.mesh = TorusMesh.new()
	wheel.position = Vector3(valve_pos.x, valve_pos.y, valve_pos.z + 0.2)
	wheel.scale = Vector3(0.2, 0.2, 0.05)
	apply_material(wheel, "metal")
	parent.add_child(wheel)

func create_pipe_segment(parent, start, end) -> void:
	var segment = MeshInstance3D.new()
	segment.mesh = CylinderMesh.new()
	
	# Calculate position (midpoint)
	var midpoint = (start + end) / 2
	segment.position = midpoint
	
	# Calculate height (distance)
	var height = start.distance_to(end)
	segment.scale = Vector3(0.1, height / 2, 0.1)
	
	# Calculate rotation
	segment.look_at_from_position(midpoint, end, Vector3.UP)
	segment.rotation_degrees.x += 90
	
	apply_material(segment, "metal")
	parent.add_child(segment)

func add_electronic_component(parent) -> void:
	# Base board
	var board = MeshInstance3D.new()
	board.mesh = BoxMesh.new()
	board.scale = Vector3(1.0, 0.05, 1.5)
	apply_material(board, "secondary")
	parent.add_child(board)
	
	# Add electronic components
	for i in range(randi() % 15 + 10):
		var component = MeshInstance3D.new()
		
		match randi() % 4:
			0: # Chip
				component.mesh = BoxMesh.new()
				component.scale = Vector3(0.2, 0.05, 0.2)
				apply_material(component, "primary")
			1: # Capacitor
				component.mesh = CylinderMesh.new()
				component.scale = Vector3(0.07, 0.15, 0.07)
				apply_material(component, "metal")
			2: # LED
				component.mesh = SphereMesh.new()
				component.scale = Vector3(0.05, 0.05, 0.05)
				apply_material(component, "accent")
			3: # Resistor
				component.mesh = CylinderMesh.new()
				component.scale = Vector3(0.05, 0.1, 0.05)
				component.rotation_degrees.z = 90
				apply_material(component, "primary")
		
		component.position = Vector3(
			randf_range(-0.8, 0.8),
			0.05,
			randf_range(-1.3, 1.3)
		)
		
		parent.add_child(component)
	
	# Add circuits (thin lines)
	for i in range(randi() % 10 + 5):
		var circuit = MeshInstance3D.new()
		circuit.mesh = BoxMesh.new()
		
		var start_x = randf_range(-0.8, 0.8)
		var start_z = randf_range(-1.3, 1.3)
		var end_x = randf_range(-0.8, 0.8)
		var end_z = randf_range(-1.3, 1.3)
		
		var midpoint = Vector3((start_x + end_x) / 2, 0.03, (start_z + end_z) / 2)
		circuit.position = midpoint
		
		var length = sqrt(pow(end_x - start_x, 2) + pow(end_z - start_z, 2))
		circuit.scale = Vector3(0.01, 0.01, length)
		
		var angle = atan2(end_z - start_z, end_x - start_x)
		circuit.rotation_degrees.y = rad_to_deg(angle)
		
		apply_material(circuit, "accent")
		parent.add_child(circuit)

# Organic module builders
func add_plant_structure(parent) -> void:
	# Base/soil
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.scale = Vector3(0.8, 0.3, 0.8)
	apply_organic_material(base, Color(0.4, 0.25, 0.15), 0.0, 1.0)
	parent.add_child(base)
	
	# Main stem
	var stem = MeshInstance3D.new()
	stem.mesh = CylinderMesh.new()
	stem.position.y = 0.7
	stem.scale = Vector3(0.1, 0.7, 0.1)
	apply_organic_material(stem, Color(0.2, 0.5, 0.2), 0.0, 0.7)
	parent.add_child(stem)
	
	# Add branches or leaves
	var branch_count = randi() % 5 + 3
	for i in range(branch_count):
		var branch = MeshInstance3D.new()
		if randf() > 0.5:
			# Branch
			branch.mesh = CylinderMesh.new()
			branch.scale = Vector3(0.05, randf_range(0.3, 0.7), 0.05)
			apply_organic_material(branch, Color(0.3, 0.4, 0.2), 0.0, 0.7)
		else:
			# Leaf/flower
			if randf() > 0.3:
				branch.mesh = SphereMesh.new()
				branch.scale = Vector3(0.2, 0.1, 0.2)
				apply_organic_material(branch, Color(0.1, 0.7, 0.3), 0.0, 0.9)
			else:
				branch.mesh = SphereMesh.new()
				branch.scale = Vector3(0.15, 0.15, 0.15)
				apply_organic_material(branch, Color(0.9, 0.3, 0.5), 0.0, 0.6)
		
		var height = randf_range(0.3, 1.1)
		var angle = randf_range(0, TAU)
		var distance = randf_range(0.1, 0.3)
		
		branch.position = Vector3(
			cos(angle) * distance,
			height,
			sin(angle) * distance
		)
		
		# Point outward for branches
		if branch.mesh is CylinderMesh:
			branch.look_at_from_position(branch.position, branch.position + Vector3(cos(angle), 0.2, sin(angle)), Vector3.UP)
			branch.rotation_degrees.x += 90
		
		parent.add_child(branch)

func add_fluid_vessel(parent) -> void:
	# Container
	var container = MeshInstance3D.new()
	container.mesh = SphereMesh.new()
	container.scale = Vector3(0.8, 1.0, 0.8)
	
	# Make the container transparent
	var container_mat = StandardMaterial3D.new()
	container_mat.albedo_color = Color(0.9, 0.9, 1.0, 0.3)
	container_mat.metallic = 0.1
	container_mat.roughness = 0.1
	container_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	container.material_override = container_mat
	
	parent.add_child(container)
	
	# Inner fluid - slightly smaller
	var fluid = MeshInstance3D.new()
	fluid.mesh = SphereMesh.new()
	fluid.scale = Vector3(0.7, 0.9, 0.7)
	
	# Fluid material
	var fluid_color = Color(
		randf_range(0.0, 0.3),
		randf_range(0.2, 0.7),
		randf_range(0.5, 0.9),
		0.8
	)
	var fluid_mat = StandardMaterial3D.new()
	fluid_mat.albedo_color = fluid_color
	fluid_mat.metallic = 0.0
	fluid_mat.roughness = 0.3
	fluid_mat.emission_enabled = true
	fluid_mat.emission = fluid_color
	fluid_mat.emission_energy = 0.2
	fluid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fluid.material_override = fluid_mat
	
	parent.add_child(fluid)
	
	# Add connecting tubes
	add_tube(parent, Vector3(0, 0.7, 0), Vector3(0, 1.2, 0.5))
	add_tube(parent, Vector3(0, -0.7, 0), Vector3(0, -1.2, -0.5))

func add_tube(parent, start, end) -> void:
	var tube = MeshInstance3D.new()
	tube.mesh = CylinderMesh.new()
	
	var midpoint = (start + end) / 2
	tube.position = midpoint
	
	var height = start.distance_to(end)
	tube.scale = Vector3(0.1, height / 2, 0.1)
	
	tube.look_at_from_position(midpoint, end, Vector3.UP)
	tube.rotation_degrees.x += 90
	
	var tube_mat = StandardMaterial3D.new()
	tube_mat.albedo_color = Color(0.7, 0.7, 0.8, 0.5)
	tube_mat.metallic = 0.1
	tube_mat.roughness = 0.3
	tube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tube.material_override = tube_mat
	
	parent.add_child(tube)

func add_coral_structure(parent) -> void:
	# Base
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.scale = Vector3(0.8, 0.2, 0.8)
	apply_organic_material(base, Color(0.8, 0.7, 0.6), 0.0, 0.9)
	parent.add_child(base)
	
	# Main structure - use CSG for more organic shape
	var main_form = CSGCombiner3D.new()
	main_form.position.y = 0.5
	
	# Create a branching structure
	create_coral_branch(main_form, Vector3.ZERO, 0.7, 0)
	
	parent.add_child(main_form)
func create_coral_branch(parent, position, size, depth, max_depth = 3) -> void:
	# Stop if we've reached max depth
	if depth > max_depth:
		return
	
	# Create this branch segment
	var branch = CSGSphere3D.new() if randf() > 0.3 else CSGCylinder3D.new()
	
	if branch is CSGSphere3D:
		branch.radius = size
	else:
		branch.radius = size / 2
		branch.height = size * 2
		branch.rotation_degrees.x = randf_range(-30, 30)
		branch.rotation_degrees.z = randf_range(-30, 30)
	
	branch.position = position
	
	# Material
	var branch_mat = StandardMaterial3D.new()
	branch_mat.albedo_color = Color(
		randf_range(0.7, 1.0),
		randf_range(0.2, 0.5),
		randf_range(0.5, 0.8)
	)
	branch_mat.roughness = randf_range(0.7, 0.9)
	branch.material = branch_mat
	
	parent.add_child(branch)
	
	# Create sub-branches if not at max depth
	if depth < max_depth:
		var sub_branches = randi() % 3 + 1
		for i in range(sub_branches):
			var angle = randf_range(0, TAU)
			var branch_dir = Vector3(cos(angle), randf_range(0.5, 1.5), sin(angle))
			var new_pos = position + branch_dir * size
			create_coral_branch(parent, new_pos, size * 0.6, depth + 1, max_depth)

func add_egg_structure(parent) -> void:
	# Base structure
	var base = MeshInstance3D.new()
	base.mesh = SphereMesh.new()
	base.scale = Vector3(1.0, 0.5, 1.0)
	apply_organic_material(base, Color(0.3, 0.3, 0.4), 0.3, 0.5)
	parent.add_child(base)
	
	# Add multiple small egg-like protrusions
	var egg_count = randi() % 8 + 5
	for i in range(egg_count):
		var egg = MeshInstance3D.new()
		egg.mesh = SphereMesh.new()
		
		var scale_factor = randf_range(0.15, 0.3)
		egg.scale = Vector3(scale_factor, scale_factor * 1.2, scale_factor)
		
		var angle = randf_range(0, TAU)
		var radius = randf_range(0.5, 0.9)
		egg.position = Vector3(
			cos(angle) * radius,
			randf_range(-0.1, 0.3),
			sin(angle) * radius
		)
		
		# Random egg colors
		var egg_color = Color(
			randf_range(0.5, 0.9),
			randf_range(0.2, 0.6),
			randf_range(0.2, 0.6)
		)
		
		var egg_mat = StandardMaterial3D.new()
		egg_mat.albedo_color = egg_color
		egg_mat.metallic = 0.1
		egg_mat.roughness = 0.2
		egg_mat.emission_enabled = true
		egg_mat.emission = egg_color
		egg_mat.emission_energy = 0.3
		egg.material_override = egg_mat
		
		parent.add_child(egg)
	
	# Add organic connecting tendrils
	for i in range(egg_count - 2):
		var tendril = MeshInstance3D.new()
		tendril.mesh = CylinderMesh.new()
		
		var start_angle = randf_range(0, TAU)
		var end_angle = randf_range(0, TAU)
		var start_radius = randf_range(0.5, 0.9)
		var end_radius = randf_range(0.5, 0.9)
		
		var start_pos = Vector3(
			cos(start_angle) * start_radius,
			randf_range(-0.1, 0.3),
			sin(start_angle) * start_radius
		)
		
		var end_pos = Vector3(
			cos(end_angle) * end_radius,
			randf_range(-0.1, 0.3),
			sin(end_angle) * end_radius
		)
		
		var midpoint = (start_pos + end_pos) / 2
		tendril.position = midpoint
		
		var length = start_pos.distance_to(end_pos)
		tendril.scale = Vector3(0.03, length / 2, 0.03)
		
		tendril.look_at_from_position(midpoint, end_pos, Vector3.UP)
		tendril.rotation_degrees.x += 90
		
		apply_organic_material(tendril, Color(0.6, 0.2, 0.5), 0.0, 0.6)
		parent.add_child(tendril)

func generate_space() -> void:
	# Place modules in 3D space
	for i in range(module_count):
		place_random_module()
	
	# Connect some modules
	connect_modules()
	
	# Add ambient objects like particles or floating elements
	add_ambient_elements()

func place_random_module() -> void:
	if modules.size() == 0:
		push_error("No modules available!")
		return
		
	# Lifted into a variable so the record knows WHICH recipe was drawn. Exactly
	# one randi() either way: the stream is untouched.
	var pick: int = randi() % modules.size()
	var module_instance = modules[pick].duplicate()
	if not module_instance:
		return

	# Position randomly in space
	var position = Vector3(
		randf_range(-space_size.x/2, space_size.x/2),
		randf_range(-space_size.y/2, space_size.y/2),
		randf_range(-space_size.z/2, space_size.z/2)
	)
	
	module_instance.position = position
	
	# Random rotation
	module_instance.rotation_degrees = Vector3(
		randf_range(0, 360),
		randf_range(0, 360),
		randf_range(0, 360)
	)
	
	# Random scale variations for more diverse results
	var scale_factor = randf_range(0.5, 2.0)
	module_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	add_child(module_instance)
	placed_modules.append(module_instance)
	# THE RECORD. Written for every world, read only above `oracle`.
	_placed_kinds.append(_module_kinds[pick] if pick < _module_kinds.size() else _kind_base)
	_placed_pos.append(position)

func connect_modules() -> void:
	# Check if we have enough modules to connect
	if placed_modules.size() < 2:
		return
		
	# Create connections between modules
	var connections = min(placed_modules.size() / 2.0, 15) # Limit to prevent too many connections
	for i in range(connections):
		var index_a = randi() % placed_modules.size()
		var index_b = randi() % placed_modules.size()
		
		# Make sure we're not connecting a module to itself
		while index_a == index_b:
			index_b = randi() % placed_modules.size()
			
		var module_a = placed_modules[index_a]
		var module_b = placed_modules[index_b]
		
		create_connection(module_a, module_b)

func create_connection(module_a, module_b) -> void:
	# Choose connection type based on distance
	var distance = module_a.global_position.distance_to(module_b.global_position)
	
	if distance < 5.0:
		create_mechanical_connection(module_a, module_b)
	elif distance < 15.0:
		create_beam_connection(module_a, module_b)
	else:
		create_floating_connection(module_a, module_b)

func create_mechanical_connection(module_a, module_b) -> void:
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	
	if randf() > 0.5:
		# Pipe connection
		create_pipe_path(start_pos, end_pos)
	else:
		# Solid connector
		create_solid_connector(start_pos, end_pos)

func create_pipe_path(start_pos, end_pos) -> void:
	var midpoint = (start_pos + end_pos) / 2
	midpoint.y += randf_range(1.0, 3.0) # Arch up
	
	# Create a 3-segment path
	create_pipe_segment_with_joint(start_pos, Vector3(start_pos.x, midpoint.y, start_pos.z))
	create_pipe_segment_with_joint(Vector3(start_pos.x, midpoint.y, start_pos.z), 
								Vector3(end_pos.x, midpoint.y, start_pos.z))
	create_pipe_segment_with_joint(Vector3(end_pos.x, midpoint.y, start_pos.z), 
								Vector3(end_pos.x, midpoint.y, end_pos.z))
	create_pipe_segment_with_joint(Vector3(end_pos.x, midpoint.y, end_pos.z), end_pos)

func create_pipe_segment_with_joint(start_pos, end_pos) -> void:
	# Create pipe segment
	var pipe = MeshInstance3D.new()
	pipe.mesh = CylinderMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	pipe.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	pipe.scale = Vector3(0.1, distance / 2, 0.1)
	
	pipe.look_at_from_position(midpoint, end_pos, Vector3.UP)
	pipe.rotation_degrees.x += 90
	
	var pipe_material = StandardMaterial3D.new()
	pipe_material.albedo_color = color_theme["metal"]
	pipe_material.metallic = 0.8
	pipe_material.roughness = 0.2
	pipe.material_override = pipe_material
	
	add_child(pipe)
	
	# Add joint at end position if it's not the destination
	if randf() > 0.5 and start_pos.distance_to(end_pos) > 0.5:
		var joint = MeshInstance3D.new()
		joint.mesh = SphereMesh.new()
		joint.position = end_pos
		joint.scale = Vector3(0.15, 0.15, 0.15)
		
		var joint_material = StandardMaterial3D.new()
		joint_material.albedo_color = color_theme["primary"]
		joint_material.metallic = 0.7
		joint_material.roughness = 0.3
		joint.material_override = joint_material
		
		add_child(joint)

func create_solid_connector(start_pos, end_pos) -> void:
	# Create a solid bar between positions
	var connector = MeshInstance3D.new()
	connector.mesh = BoxMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	connector.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	
	# Figure out rotation to point from start to end
	connector.look_at_from_position(connector.position, end_pos, Vector3.UP)
	
	# Adjust scale to match distance
	connector.scale = Vector3(0.2, 0.2, distance)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color_theme["secondary"]
	material.metallic = 0.5
	material.roughness = 0.4
	connector.material_override = material
	
	add_child(connector)

func create_beam_connection(module_a, module_b) -> void:
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	
	# Create a beam effect - thinner and with emission
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	
	var midpoint = (start_pos + end_pos) / 2
	beam.position = midpoint
	
	var distance = start_pos.distance_to(end_pos)
	beam.scale = Vector3(0.05, distance / 2, 0.05)
	
	beam.look_at_from_position(midpoint, end_pos, Vector3.UP)
	beam.rotation_degrees.x += 90
	
	var beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = color_theme["accent"]
	beam_material.emission_enabled = true
	beam_material.emission = color_theme["accent"]
	beam_material.emission_energy = 2.0
	beam_material.metallic = 0.0
	beam_material.roughness = 0.2
	beam.material_override = beam_material
	
	add_child(beam)
	
	# Add energy particles along the beam
	if randf() > 0.3:
		add_particles_along_beam(start_pos, end_pos, color_theme["accent"])

func create_floating_connection(module_a, module_b) -> void:
	var start_pos = module_a.global_position
	var end_pos = module_b.global_position
	var steps = randi() % 5 + 3

	var sphere_data: Array[Transform3D] = []
	var box_data: Array[Transform3D] = []

	for i in range(steps):
		var t_val = float(i) / float(steps - 1)
		var pos = start_pos.lerp(end_pos, t_val)
		pos += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))

		if randf() > 0.6:
			sphere_data.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.2, 0.2, 0.2)), pos))
		else:
			var rot = Basis.from_euler(Vector3(deg_to_rad(randf_range(0, 360)), deg_to_rad(randf_range(0, 360)), deg_to_rad(randf_range(0, 360))))
			box_data.append(Transform3D(rot.scaled(Vector3(0.15, 0.15, 0.15)), pos))

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_theme["primary"]
	mat.emission_enabled = true
	mat.emission = color_theme["primary"]
	mat.emission_energy = 0.5

	if not sphere_data.is_empty():
		var sphere = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.material = mat
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = sphere_data.size()
		mm.mesh = sphere
		for i in range(sphere_data.size()):
			mm.set_instance_transform(i, sphere_data[i])
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "FloatingSphereMM"
		mmi.multimesh = mm
		add_child(mmi)

	if not box_data.is_empty():
		var box = BoxMesh.new()
		box.material = mat
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = box_data.size()
		mm.mesh = box
		for i in range(box_data.size()):
			mm.set_instance_transform(i, box_data[i])
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "FloatingBoxMM"
		mmi.multimesh = mm
		add_child(mmi)

func add_particles_along_beam(start_pos, end_pos, color) -> void:
	var particle_count = randi() % 5 + 3

	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	sphere.radial_segments = 6
	sphere.rings = 4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 3.0
	sphere.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = particle_count
	mm.mesh = sphere

	for i in range(particle_count):
		var t = randf()
		var pos = start_pos.lerp(end_pos, t)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1, 1)), pos))

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "BeamParticlesMM"
	mmi.multimesh = mm
	add_child(mmi)

func add_ambient_elements() -> void:
	var total = randi() % 20 + 10
	# Pre-generate per-type data
	var type_data: Array[Array] = [[], [], [], [], []]  # sphere, box, cyl, prism, torus

	for i in range(total):
		var type_idx = randi() % 5
		var scale_factor = randf_range(0.1, 0.5)
		var pos = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		)
		var rot = Vector3(randf_range(0, 360), randf_range(0, 360), randf_range(0, 360))
		var col = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))
		var emit = randf() > 0.7
		type_data[type_idx].append({"pos": pos, "rot": rot, "scale": scale_factor, "color": col, "emit": emit})

	var meshes: Array[Mesh] = []
	meshes.append(SphereMesh.new())
	meshes.append(BoxMesh.new())
	meshes.append(CylinderMesh.new())
	meshes.append(PrismMesh.new())
	meshes.append(TorusMesh.new())

	for type_idx in range(5):
		var entries = type_data[type_idx]
		if entries.is_empty():
			continue

		# Use average color for the material
		var avg_col = Color.BLACK
		for e in entries:
			avg_col += e["color"]
		avg_col /= entries.size()

		var mat = StandardMaterial3D.new()
		mat.albedo_color = avg_col
		mat.emission_enabled = true
		mat.emission = avg_col
		mat.emission_energy = 1.0
		meshes[type_idx].material = mat

		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = entries.size()
		mm.mesh = meshes[type_idx]

		for i in range(entries.size()):
			var e = entries[i]
			var t = Transform3D()
			t.basis = Basis.from_euler(Vector3(deg_to_rad(e["rot"].x), deg_to_rad(e["rot"].y), deg_to_rad(e["rot"].z)))
			t.basis = t.basis.scaled(Vector3(e["scale"], e["scale"], e["scale"]))
			t.origin = e["pos"]
			mm.set_instance_transform(i, t)

		var mmi = MultiMeshInstance3D.new()
		mmi.name = "AmbientElementsMM_" + str(type_idx)
		mmi.multimesh = mm
		add_child(mmi)

func apply_lighting() -> void:
	# Create a dynamic lighting setup
	
	# Environment light
	var world_environment = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Set background
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.07, 0.1)
	
	# Add fog for atmosphere
	environment.fog_enabled = true
	#environment.fog_color = Color(0.1, 0.12, 0.15)
	environment.fog_density = 0.02
	
	# Ambient light settings
	environment.ambient_light_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_energy = 0.5
	
	# Tone mapping
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	
	# Add bloom
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.3
	
	world_environment.environment = environment
	add_child(world_environment)
	
	# Main directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.0
	dir_light.light_color = Color(1.0, 0.95, 0.9)
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	# Add colored spotlights
	var colors = [
		Color(0.8, 0.2, 0.3),  # Red
		Color(0.2, 0.5, 0.9),  # Blue
		Color(0.9, 0.7, 0.2)   # Yellow/Orange
	]
	
	for i in range(5):
		var spot_light = SpotLight3D.new()
		spot_light.light_color = colors[randi() % colors.size()]
		spot_light.light_energy = randf_range(2.0, 5.0)
		spot_light.spot_range = randf_range(10.0, 20.0)
		spot_light.spot_angle = randf_range(20.0, 45.0)
		
		# Position the light randomly but pointing toward the center
		var light_pos = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		) * 0.8
		
		spot_light.position = light_pos
		spot_light.look_at_from_position(spot_light.position, Vector3.ZERO, Vector3.UP)
		
		add_child(spot_light)

func apply_atmosphere() -> void:
	# In Godot 4, we can add volumetric fog and other atmosphere effects
	# For a more basic approach without full volumetrics, we'll use particles
	
	# Create fog particle system
	create_atmosphere_particles()
	
	# Add a skybox or environment texture if desired
	# (This would require an actual texture resource)

func create_atmosphere_particles() -> void:
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.06  # average size
	sphere_mesh.height = 0.12
	sphere_mesh.radial_segments = 6
	sphere_mesh.rings = 4

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.8, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 100
	mm.mesh = sphere_mesh

	for i in range(100):
		var t = Transform3D()
		var scale_factor = randf_range(0.02, 0.1) / 0.06  # normalize to base radius
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = Vector3(
			randf_range(-space_size.x, space_size.x),
			randf_range(-space_size.y, space_size.y),
			randf_range(-space_size.z, space_size.z)
		)
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "AtmosphereParticlesMM"
	mmi.multimesh = mm
	add_child(mmi)

# Utility functions for materials

func apply_random_material(mesh_instance) -> void:
	var material_type = randi() % 4
	
	match material_type:
		0: apply_material(mesh_instance, "primary")
		1: apply_material(mesh_instance, "secondary")
		2: apply_material(mesh_instance, "accent")
		3: apply_material(mesh_instance, "metal")

func apply_material(mesh_instance, type) -> void:
	var material = StandardMaterial3D.new()
	
	match type:
		"primary":
			material.albedo_color = color_theme["primary"]
			material.metallic = randf_range(0.0, 0.3)
			material.roughness = randf_range(0.3, 0.7)
		"secondary":
			material.albedo_color = color_theme["secondary"]
			material.metallic = randf_range(0.0, 0.3)
			material.roughness = randf_range(0.3, 0.7)
		"accent":
			material.albedo_color = color_theme["accent"]
			material.emission_enabled = randf() > 0.5
			if material.emission_enabled:
				material.emission = color_theme["accent"]
				material.emission_energy = randf_range(0.5, 2.0)
			material.metallic = 0.0
			material.roughness = randf_range(0.2, 0.5)
		"metal":
			material.albedo_color = color_theme["metal"]
			material.metallic = randf_range(0.7, 1.0)
			material.roughness = randf_range(0.1, 0.3)
	
	mesh_instance.material_override = material

func apply_organic_material(mesh_instance, base_color, metallic_range, roughness) -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.metallic = metallic_range
	material.roughness = roughness
	mesh_instance.material_override = material

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-08-02): this was `pass`. GridInteractablesComponent parsed
## every `#token: value` on an env_one placement, logged it, stashed it as metadata
## and then nothing on this artifact ever read it back — so across 43 rooms nobody
## could configure this environment at all, silently. It reads its metadata now.
## The grid sets that metadata BEFORE add_child and calls this deferred, so _ready
## does the read that decides the world; this is the re-read for direct callers.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var before: String = disclosure
	_read_meta_overrides()
	# Only the ACCOUNT is rebuilt, never the world: a rung change must not reroll
	# 43 rooms' backdrops. A config that carries no disclosure key touches nothing.
	if disclosure != before:
		_build_disclosure()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		var raw: String = str(get_meta("config_disclosure")).strip_edges().to_lower()
		disclosure = raw if DISCLOSURES.has(raw) else disclosure
	if has_meta("config_kitbash_seed"):
		kitbash_seed = int(str(get_meta("config_kitbash_seed")))
	if has_meta("config_generation_rules"):
		generation_rules = str(get_meta("config_generation_rules")).strip_edges().to_lower()


# ── DISCLOSURE ───────────────────────────────────────────────────────────────
# Four structures at world scale, each a rung. Every one of them is built from
# the record the generator wrote (_placed_kinds, _placed_pos, kitbash_seed) with
# no draws of its own, and every one is drawn as MultiMesh so it cannot move the
# capture camera. Text is deliberately absent: the fitted camera for a 30 m field
# stands ~140 m out, where a legible glyph would have to be two metres tall. An
# account you cannot read from the viewing distance is not an account.

## Accumulators, flushed into exactly two MultiMesh instances per build.
var _disc_lit: Array = []
var _disc_body: Array = []


func _build_disclosure() -> void:
	if _disclosure_root != null and is_instance_valid(_disclosure_root):
		# remove first: queue_free is deferred, and a same-named sibling added
		# before it runs would be auto-renamed.
		remove_child(_disclosure_root)
		_disclosure_root.queue_free()
	_disclosure_root = null
	_disc_lit.clear()
	_disc_body.clear()

	var r: int = _rung()
	if r < 1:
		return                          # oracle — the world admits nothing. The legacy.

	_disclosure_root = Node3D.new()
	_disclosure_root.name = "DisclosureRig"
	add_child(_disclosure_root)

	if r >= 1:
		_disc_census()
	if r >= 2:
		_disc_drop_lines()
	if r >= 3:
		_disc_sample_cage()
	if r >= 4:
		_disc_seed_row()
	_disc_flush()


## One box for the rig to draw. `lit` picks the emissive material.
func _disc_box(lit: bool, center: Vector3, size_vec: Vector3, col: Color) -> void:
	var t := Transform3D(Basis.IDENTITY.scaled(size_vec), center)
	if lit:
		_disc_lit.append({"t": t, "c": col})
	else:
		_disc_body.append({"t": t, "c": col})


func _disc_flush() -> void:
	_disc_emit(_disc_lit, true, "DisclosureLit")
	_disc_emit(_disc_body, false, "DisclosureBody")


func _disc_emit(entries: Array, lit: bool, nm: String) -> void:
	if entries.is_empty():
		return
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.2 if lit else 0.55
	mat.roughness = 0.35 if lit else 0.6
	# THE ACCOUNT IS NOT IN THE WEATHER. apply_lighting() gives this world an
	# exponential fog at density 0.02, and the fitted camera for a 30 m field
	# stands ~140 m out, where that fog is 94% opaque: every structure below would
	# have been drawn perfectly and then washed to a flat grey, and the axis would
	# have measured nothing while looking like it had been tested. A reading of a
	# world is not subject to that world's atmosphere.
	mat.disable_fog = true
	if lit:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(1, 1, 1)
		mat.emission_energy_multiplier = 1.4
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = entries.size()
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		mm.set_instance_transform(i, e["t"])
		mm.set_instance_color(i, e["c"])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disclosure_root.add_child(mmi)


## tally — THE CENSUS. One column per module recipe the active rules can produce,
## standing on a rail inside the east wall of the field, height proportional to how
## many of that kind the draw actually placed. The aggregate: how much of each was
## made, and nothing about which one went where.
func _disc_census() -> void:
	var half: Vector3 = space_size * 0.5
	var floor_y: float = -half.y
	var n: int = maxi(_kind_span, 1)
	var counts: Array[int] = []
	var top: int = 1
	for b in range(n):
		var c: int = 0
		for k in _placed_kinds:
			if int(k) == _kind_base + b:
				c += 1
		counts.append(c)
		top = maxi(top, c)

	var pitch: float = 3.2
	var x: float = half.x * 0.86
	var z0: float = -pitch * float(n - 1) * 0.5
	var body: Color = color_theme["metal"] if color_theme else Color(0.7, 0.7, 0.75)
	var bar: Color = color_theme["secondary"] if color_theme else Color(0.9, 0.7, 0.1)

	# The rail the columns stand on — present even where a column is zero, so an
	# empty bucket reads as "none of these were drawn" and not as "no such recipe".
	_disc_box(false, Vector3(x, floor_y + 0.35, 0.0),
		Vector3(2.6, 0.7, pitch * float(n) + 1.2), body)
	for b in range(n):
		var z: float = z0 + pitch * float(b)
		var h: float = 1.2 + 13.0 * (float(counts[b]) / float(top))
		_disc_box(true, Vector3(x, floor_y + 0.7 + h * 0.5, z), Vector3(2.2, h, 2.2), bar)
		# A cap block so the top of each column reads as a measured height.
		_disc_box(false, Vector3(x, floor_y + 0.7 + h + 0.2, z), Vector3(2.6, 0.4, 2.6), body)


## ledger — THE RECORD. One rod per placed module, dropped from where the draw put
## it to the floor plane, with a pad where it lands. Thirty entries, in order,
## every one of them visible at once: the scatter stops being an impression of
## clutter and becomes a readable set of individual results.
func _disc_drop_lines() -> void:
	var half: Vector3 = space_size * 0.5
	var floor_y: float = -half.y
	var rod: Color = color_theme["accent"] if color_theme else Color(0.7, 0.1, 0.3)
	var pad: Color = color_theme["metal"] if color_theme else Color(0.7, 0.7, 0.75)
	for p in _placed_pos:
		var pos: Vector3 = p
		var h: float = maxf(pos.y - floor_y, 0.4)
		_disc_box(true, Vector3(pos.x, floor_y + h * 0.5, pos.z), Vector3(0.72, h, 0.72), rod)
		_disc_box(false, Vector3(pos.x, floor_y + 0.15, pos.z), Vector3(1.6, 0.3, 1.6), pad)


## works — THE MECHANISM. The sampling domain, drawn: twelve edges of exactly the
## box every position was drawn uniformly inside, with graduated ticks along one
## edge of each axis. "Uniform in here" is the whole generator, and at this rung
## it is an object with corners you could walk to.
func _disc_sample_cage() -> void:
	var half: Vector3 = space_size * 0.5
	var t: float = 0.9
	var edge: Color = color_theme["primary"] if color_theme else Color(0.1, 0.5, 0.8)
	var tick: Color = color_theme["metal"] if color_theme else Color(0.7, 0.7, 0.75)
	var signs: Array[float] = [-1.0, 1.0]
	for sy in signs:
		for sz in signs:
			_disc_box(true, Vector3(0, half.y * sy, half.z * sz), Vector3(space_size.x, t, t), edge)
	for sx in signs:
		for sz2 in signs:
			_disc_box(true, Vector3(half.x * sx, 0, half.z * sz2), Vector3(t, space_size.y, t), edge)
	for sx2 in signs:
		for sy2 in signs:
			_disc_box(true, Vector3(half.x * sx2, half.y * sy2, 0), Vector3(t, t, space_size.z), edge)
	# Ten graduations along one edge per axis — the measure the draw was uniform in.
	for i in range(11):
		var f: float = float(i) / 10.0
		_disc_box(false, Vector3(lerpf(-half.x, half.x, f), -half.y, -half.z),
			Vector3(0.45, 1.6, 1.6), tick)
		_disc_box(false, Vector3(-half.x, lerpf(-half.y, half.y, f), -half.z),
			Vector3(1.6, 0.45, 1.6), tick)
		_disc_box(false, Vector3(-half.x, -half.y, lerpf(-half.z, half.z, f)),
			Vector3(1.6, 1.6, 0.45), tick)


## origin — THE SUBSTRATE. Thirty-two lamps along the south edge of the field, MSB
## left: the seed this entire world unrolls from, standing in the world it made.
##
## When no seed was pinned there are no lamps — thirty-two empty sockets and a bar
## struck across them. That is not a failure to display; it is the true state of
## affairs. randomize() cannot be read back, so this world had an origin, nobody
## wrote it down, and no one will ever see it again.
func _disc_seed_row() -> void:
	var half: Vector3 = space_size * 0.5
	var floor_y: float = -half.y
	var z: float = -half.z * 0.9
	var pitch: float = (space_size.x * 0.86) / 32.0
	var x0: float = -pitch * 31.0 * 0.5
	var sill: Color = color_theme["metal"] if color_theme else Color(0.7, 0.7, 0.75)
	var lamp: Color = Color(0.55, 0.85, 1.0)
	var stub: Color = Color(0.14, 0.15, 0.20)

	_disc_box(false, Vector3(0, floor_y + 0.4, z), Vector3(pitch * 33.0, 0.8, 2.0), sill)
	for i in range(32):
		var x: float = x0 + pitch * float(i)
		_disc_box(false, Vector3(x, floor_y + 1.0, z), Vector3(pitch * 0.8, 0.5, 1.5), sill)
		if kitbash_seed < 0:
			continue                    # no seed was recorded; the sockets stay empty
		# MSB left, so the row reads the way the number is written.
		var bit: int = (kitbash_seed >> (31 - i)) & 1
		if bit == 1:
			_disc_box(true, Vector3(x, floor_y + 4.2, z), Vector3(pitch * 0.72, 6.0, 1.3), lamp)
		else:
			_disc_box(false, Vector3(x, floor_y + 1.75, z), Vector3(pitch * 0.72, 1.1, 1.3), stub)
	if kitbash_seed < 0:
		# The row is not merely empty, it is CLOSED. Nothing was ever written here.
		_disc_box(true, Vector3(0, floor_y + 1.9, z + 0.2),
			Vector3(pitch * 32.0, 0.55, 0.5), Color(0.85, 0.24, 0.14))
