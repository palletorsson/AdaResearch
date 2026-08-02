extends Node3D

# @identity
# essence: RigidBody3D hub rotating at ride_speed, with PinJoint3D chains suspending SoftBody3D spheres — centripetal force stretches the soft bodies outward while gravity pulls them down
# desire: to spin you inside a carousel where every hanging blob deforms differently depending on its chain length and the ride's angular velocity
# critical_parameter: ride_speed — slow rotation lets soft bodies dangle and sway, fast rotation stretches them into elongated teardrops that barely hold together
# triggers: rotation.y increment in _physics_process drives the entire chain system; obstacle ring at the perimeter causes collision-deformation events
# emerges: at certain speeds the chain links begin to oscillate in phase, creating synchronized pendulum waves across the four arms
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: builds on jelly_cube's spring-mass intro by adding chain dynamics and centripetal force; contrasts with breathing_room's static pressure oscillation
# truth: a carousel is a centrifuge for compliance — the soft bodies do not choose their shape, the rotation imposes it

# Configuration
@export var ride_radius: float = 3.0
@export var ride_speed: float = 1.0 # Radians per second
@export var arm_length: float = 0.75
@export var soft_body_radius: float = 0.25
@export_group("Obstacles")
@export var obstacle_radius_offset: float = 2.0
@export var obstacle_height: float = 3.0
@export var obstacle_y_pos: float = 1.5

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## with [[mass_spring_bench]] and the rest of the soft-body bench family: one question,
## one vocabulary, so a ride and a bench-top lattice can be compared without translating.
##
## The ride's own claim — "the soft bodies do not choose their shape, the rotation imposes
## it" — is made by MOTION, and a still photograph of a carousel is a carousel at some
## arbitrary phase. Every value below is therefore fixed to the ground and unaffected by
## where the arms happen to be, which is the only way an axis on this artifact measures
## itself rather than measuring the shutter.
##
##   none      the bare ride — the legacy lineage, byte for byte
##   gauge     a graduated mast outside the obstacle ring, twinned across the diameter,
##             each with a cantilever arm reaching in over the swept circle and a stylus
##             dropped to flight height. The ride stops being a spectacle and reports a
##             radius.
##   control   one witness plinth carrying an empty wire cage at the size a body had
##             BEFORE the ride, with a silhouette board behind it. The hanging shapes stop
##             being shapes and become a difference from something.
##   chart     twinned record boards on the perimeter, paper both sides, carrying the
##             settling trace: an oscillation damping onto the rest line. The ride stops
##             showing a state and starts keeping a history.
##   vitrine   a glass case over the entire ride — posts at the corners, rails top and
##             bottom, a capping plate, a caption rail. The demonstration stops being
##             something you could climb into and becomes an exhibit.
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

var ride_hub: RigidBody3D
var _assay_root: Node3D = null

# Shaders
const SHADER_PINK_TARTAN = preload("res://commons/resourses/shaders/pinktartan.gdshader")
const SHADER_PEARLESCENT = preload("res://commons/resourses/shaders/pearlescent.gdshader")
const SHADER_FROSTED = preload("res://commons/resourses/shaders/frosted_glass.gdshader")
const SHADER_DISCO = preload("res://commons/resourses/shaders/discoLights.gdshader")

func _ready() -> void:
	setup_camera()
	setup_lighting()
	setup_ride()
	setup_obstacles()
	_build_assay()   # APPENDED LAST — nothing above it moves

func create_shader_material(shader: Shader, params: Dictionary = {}) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = shader
	for key in params:
		mat.set_shader_parameter(key, params[key])
	return mat

func setup_camera() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2.5, 6.25)
	cam.look_at(Vector3(0, 1.25, 0))
	add_child(cam)

func setup_lighting() -> void:
	var light = DirectionalLight3D.new()
	light.position = Vector3(2.5, 5, 2.5)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment = environment
	add_child(env)

func setup_ride() -> void:
	# Create the central hub that rotates
	ride_hub = RigidBody3D.new()
	ride_hub.name = "RideHub"
	ride_hub.position = Vector3(0, 3.75, 0) # High up
	ride_hub.freeze = true
	ride_hub.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	add_child(ride_hub)
	
	# Visual for the ring
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = ride_radius - 0.125
	ring_mesh.outer_radius = ride_radius + 0.125
	var ring_instance = MeshInstance3D.new()
	ring_instance.mesh = ring_mesh
	# Apply Disco Shader to Ring
	ring_instance.material_override = create_shader_material(SHADER_DISCO)
	ride_hub.add_child(ring_instance)
	
	# Create 4 arms
	for i in range(4):
		var angle = i * (PI / 2.0)
		create_arm(angle)

func create_arm(angle: float) -> void:
	var pos_on_ring = Vector3(cos(angle) * ride_radius, 0, sin(angle) * ride_radius)
	
	# Visual sphere
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	var sphere_vis = MeshInstance3D.new()
	sphere_vis.mesh = sphere_mesh
	sphere_vis.position = pos_on_ring
	sphere_vis.material_override = create_shader_material(SHADER_PEARLESCENT, {"base": Color(1.0, 0.2, 0.8), "shift": Color(0.2, 1.0, 1.0)})
	ride_hub.add_child(sphere_vis)
	
	# 2. First Link (RigidBody)
	var link1 = create_link(pos_on_ring - Vector3(0, 0.5, 0), Color.RED)
	link1.name = "Link1_%d" % int(rad_to_deg(angle))
	add_child(link1)
	
	# Joint 1: Hub -> Link1
	var joint1 = PinJoint3D.new()
	# Parent to hub so it rotates with it
	ride_hub.add_child(joint1)
	joint1.position = pos_on_ring # Local to hub
	joint1.node_a = ride_hub.get_path()
	joint1.node_b = link1.get_path()
	
	# 3. Second Link (RigidBody)
	var link2 = create_link(pos_on_ring - Vector3(0, 1.25, 0), Color.BLUE)
	link2.name = "Link2_%d" % int(rad_to_deg(angle))
	add_child(link2)
	
	# Joint 2: Link1 -> Link2
	var joint2 = PinJoint3D.new()
	# Parent to link1 so it moves with the chain
	link1.add_child(joint2)
	joint2.position = Vector3(0, -0.375, 0) # Local to link1
	joint2.node_a = link1.get_path()
	joint2.node_b = link2.get_path()
	
	# 4. SoftBody
	create_hanging_soft_body(link2)

func create_link(pos: Vector3, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = ride_hub.position + pos # Convert local offset to global
	body.mass = 5.0
	
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.075
	mesh.height = 0.75
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	
	# Apply Pearlescent Shader to Links
	# Vary base color slightly based on input color
	var base = Color(1.0, 0.5, 0.5) if color == Color.RED else Color(0.5, 0.5, 1.0)
	var shift = Color(1.0, 1.0, 0.0) if color == Color.RED else Color(0.0, 1.0, 1.0)
	mesh_inst.material_override = create_shader_material(SHADER_PEARLESCENT, {"base": base, "shift": shift})
	
	body.add_child(mesh_inst)
	
	var shape = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	(shape.shape as CapsuleShape3D).radius = 0.075
	(shape.shape as CapsuleShape3D).height = 0.75
	body.add_child(shape)
	
	return body

func create_hanging_soft_body(parent_body: RigidBody3D) -> void:
	var sb = SoftBody3D.new()
	
	# Create Mesh
	var mesh = SphereMesh.new()
	mesh.radius = soft_body_radius
	mesh.height = soft_body_radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	sb.mesh = mesh
	
	# Parent to the rigid body but keep transform independent to avoid double-motion issues
	parent_body.add_child(sb)
	sb.top_level = true
	
	# Position at the bottom of the link (Link height is 0.75, so bottom is -0.375)
	# We need global position since it's top_level
	# The parent_body (link2) is at a certain position.
	# We want to be at parent_body.global_position + (rotation * local_offset)
	# But initially, rotation is identity.
	var local_offset = Vector3(0, -0.375 - soft_body_radius, 0)
	sb.global_position = parent_body.global_position + local_offset
	
	sb.total_mass = 2.0
	sb.linear_stiffness = 0.3
	sb.damping_coefficient = 0.05
	sb.simulation_precision = 5
	
	# Defer pinning to ensure nodes are ready
	call_deferred("_pin_soft_body", sb, parent_body)

func _pin_soft_body(sb: SoftBody3D, parent_body: RigidBody3D) -> void:
	if not is_instance_valid(sb) or not is_instance_valid(parent_body):
		return

	# Find top vertices (pin a cap, not just one point)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(sb.mesh, 0)
	var pinned_indices = []
	var max_y = -INF
	
	# First pass: find max Y
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y > max_y:
			max_y = v.y
			
	# Second pass: collect vertices near top
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y > max_y - 0.05: # Pin top 5cm (scaled down from 20cm)
			pinned_indices.append(i)
	
	if not pinned_indices.is_empty():
		print("Pinning %d vertices of SoftBody to %s" % [pinned_indices.size(), parent_body.name])
		
		# Use absolute path to be safe
		var attachment_path = parent_body.get_path()
		
		for idx in pinned_indices:
			sb.set_point_pinned(idx, true, attachment_path)
		
		# Prevent collision between soft body and its anchor to avoid physics explosions
		sb.add_collision_exception_with(parent_body)
		
		# Visual material - Pink Tartan!
		sb.material_override = create_shader_material(SHADER_PINK_TARTAN)
	else:
		print("ERROR: Could not find top vertices for pinning!")

func setup_obstacles() -> void:
	var obstacle_ring = Node3D.new()
	obstacle_ring.name = "Obstacles"
	add_child(obstacle_ring)
	
	var count = 12
	var radius = ride_radius + obstacle_radius_offset
	
	for i in range(count):
		var angle = i * (TAU / count)
		# Position obstacles so their bottom is at y=0
		var pos = Vector3(cos(angle) * radius, obstacle_height / 2.0, sin(angle) * radius)
		
		var static_body = StaticBody3D.new()
		static_body.position = pos
		
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.25, obstacle_height, 0.25)
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = mesh
		# Apply Frosted Glass (or similar) to obstacles
		mesh_inst.material_override = create_shader_material(SHADER_FROSTED, {"albedo": Color(0.2, 1.0, 0.8, 0.5)})
		static_body.add_child(mesh_inst)
		
		var shape = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = Vector3(0.25, obstacle_height, 0.25)
		static_body.add_child(shape)
		
		obstacle_ring.add_child(static_body)

func _physics_process(delta: float) -> void:
	if ride_hub:
		ride_hub.rotation.y += ride_speed * delta

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("assay"):
		var want: String = str(config["assay"]).strip_edges().to_lower()
		# An unknown word keeps the default. A typo must never publish a silent variant.
		if ASSAYS.has(want):
			assay = want
	if is_inside_tree():
		_build_assay()


# ═══════════════════════════════════════════════════════════════════════════
# ASSAY — the apparatus around the ride. All of it is bolted to the ground and
# holds still while the hub turns, so a still photograph is of the axis and not
# of the phase. Parented under one node so a rebuild frees exactly this.
# ═══════════════════════════════════════════════════════════════════════════
const AS_READ := Color(0.98, 0.74, 0.26)     # the instrument accent: readings and ink
const AS_WIRE := Color(0.55, 0.88, 0.98)     # the reference standard's cool wire
const AS_STEEL := Color(0.38, 0.41, 0.46)
const AS_PAPER := Color(0.87, 0.86, 0.81)
const AS_DARK := Color(0.17, 0.18, 0.22)
# The apparatus stands one bay outside the obstacle ring, and the primary unit sits at
# 40 deg — between the default capture camera and the ride, so nothing hides behind it.
const AS_AZIMUTH := 0.6981317


func _build_assay() -> void:
	if is_instance_valid(_assay_root):
		_assay_root.queue_free()
	_assay_root = null
	if assay == "none":
		return
	var root := Node3D.new()
	root.name = "Assay"
	add_child(root)
	_assay_root = root
	var outer: float = ride_radius + obstacle_radius_offset + 1.3
	match assay:
		"gauge":
			_as_gauge(root, AS_AZIMUTH, outer)
			_as_gauge(root, AS_AZIMUTH + PI, outer)
		"control":
			_as_control(root, AS_AZIMUTH, outer)
		"chart":
			_as_chart(root, AS_AZIMUTH, outer)
			_as_chart(root, AS_AZIMUTH + PI, outer)
		"vitrine":
			_as_vitrine(root, outer + 0.4)
		_:
			pass


# ── GAUGE — the ride reports a radius ─────────────────────────────────────
func _as_gauge(root: Node3D, azimuth: float, at_r: float) -> void:
	var steel: StandardMaterial3D = _as_mat(AS_STEEL, 0.35, 0.7)
	var tick: StandardMaterial3D = _as_mat(Color(0.88, 0.88, 0.84), 0.5, 0.1)
	var read: StandardMaterial3D = _as_glow(AS_READ, 1.0)
	var inward: Vector3 = Vector3(-cos(azimuth), 0.0, -sin(azimuth))
	var foot: Vector3 = Vector3(cos(azimuth) * at_r, 0.0, sin(azimuth) * at_r)
	var top_y: float = 4.9

	root.add_child(_as_box(foot + Vector3(0.0, 0.06, 0.0), Vector3(1.0, 0.12, 1.0), steel))
	root.add_child(_as_box(foot + Vector3(0.0, top_y * 0.5, 0.0), Vector3(0.24, top_y, 0.24), steel))
	# Graduations up the inward face — every fifth long and lit, the rest hairlines.
	for i in range(21):
		var gy: float = 0.35 + float(i) * 0.21
		var major: bool = (i % 5) == 0
		var gl: float = (0.42 if major else 0.20)
		var gm: StandardMaterial3D = (read if major else tick)
		root.add_child(_as_box(foot + inward * (0.14 + gl * 0.5) + Vector3(0.0, gy, 0.0),
			_as_span(inward, gl, 0.045, 0.055), gm))
	# The reading: a collar on the mast, an arm out over the swept circle, a lit tip and a
	# stylus dropped from it to the height the bodies fly at.
	var arm_y: float = 2.35
	var reach: float = at_r - ride_radius - 0.4
	var collar: Vector3 = foot + Vector3(0.0, arm_y, 0.0)
	root.add_child(_as_box(collar, Vector3(0.42, 0.30, 0.42), _as_mat(AS_DARK, 0.6, 0.2)))
	root.add_child(_as_box(collar + inward * (reach * 0.5), _as_span(inward, reach, 0.11, 0.11), read))
	var tipv: Vector3 = collar + inward * reach
	root.add_child(_as_sphere(tipv, 0.16, read))
	root.add_child(_as_box(tipv + Vector3(0.0, -0.26, 0.0), Vector3(0.06, 0.52, 0.06), read))
	root.add_child(_as_label("GAUGE", foot + Vector3(0.0, top_y + 0.35, 0.0), 26, AS_READ))


# ── CONTROL — the shape before the ride happened to it ────────────────────
func _as_control(root: Node3D, azimuth: float, at_r: float) -> void:
	var pale: StandardMaterial3D = _as_mat(Color(0.80, 0.80, 0.76), 0.6, 0.0)
	var wire: StandardMaterial3D = _as_glow(AS_WIRE, 1.0)
	var steel: StandardMaterial3D = _as_mat(AS_STEEL, 0.4, 0.6)
	var inward: Vector3 = Vector3(-cos(azimuth), 0.0, -sin(azimuth))
	var foot: Vector3 = Vector3(cos(azimuth) * at_r, 0.0, sin(azimuth) * at_r)
	var deck: float = 1.85

	# Witness plinth: a small reference given a large pedestal, which is the whole point.
	root.add_child(_as_box(foot + Vector3(0.0, 0.09, 0.0), Vector3(1.5, 0.18, 1.5), steel))
	root.add_child(_as_box(foot + Vector3(0.0, deck * 0.5, 0.0), Vector3(0.9, deck, 0.9),
		_as_mat(AS_DARK, 0.7, 0.1)))
	root.add_child(_as_box(foot + Vector3(0.0, deck + 0.07, 0.0), Vector3(1.25, 0.14, 1.25), pale))
	# Silhouette board behind it so the small cage reads against something.
	root.add_child(_as_box(foot - inward * 0.62 + Vector3(0.0, deck + 0.95, 0.0),
		_as_span(inward, 0.10, 1.7, 1.7), _as_mat(Color(0.24, 0.25, 0.29), 0.85, 0.0)))
	root.add_child(_as_sphere(foot - inward * 0.55 + Vector3(0.0, deck + 0.95, 0.0),
		soft_body_radius, _as_mat(Color(0.10, 0.10, 0.12), 0.95, 0.0)))

	# Twelve edges of an undeformed body with nothing inside it.
	var s: float = soft_body_radius
	var c: Vector3 = foot + Vector3(0.0, deck + 0.22 + s, 0.0)
	for sx: float in [-s, s]:
		for sz: float in [-s, s]:
			root.add_child(_as_box(c + Vector3(sx, 0.0, sz), Vector3(0.025, s * 2.0, 0.025), wire))
	for sy: float in [-s, s]:
		for sz2: float in [-s, s]:
			root.add_child(_as_box(c + Vector3(0.0, sy, sz2), Vector3(s * 2.0, 0.025, 0.025), wire))
		for sx2: float in [-s, s]:
			root.add_child(_as_box(c + Vector3(sx2, sy, 0.0), Vector3(0.025, 0.025, s * 2.0), wire))
	for cx: float in [-s, s]:
		for cy: float in [-s, s]:
			for cz: float in [-s, s]:
				root.add_child(_as_sphere(c + Vector3(cx, cy, cz), 0.045, wire))
	root.add_child(_as_label("CONTROL", c + Vector3(0.0, s + 0.4, 0.0), 26, AS_WIRE))


# ── CHART — the ride keeps a history ──────────────────────────────────────
func _as_chart(root: Node3D, azimuth: float, at_r: float) -> void:
	var frame: StandardMaterial3D = _as_mat(Color(0.26, 0.27, 0.31), 0.7, 0.2)
	var paper: StandardMaterial3D = _as_mat(AS_PAPER, 0.85, 0.0)
	var rule: StandardMaterial3D = _as_mat(Color(0.58, 0.58, 0.54), 0.7, 0.0)
	var ink: StandardMaterial3D = _as_glow(AS_READ, 1.1)
	var inward: Vector3 = Vector3(-cos(azimuth), 0.0, -sin(azimuth))
	var across: Vector3 = Vector3(-sin(azimuth), 0.0, cos(azimuth))
	var foot: Vector3 = Vector3(cos(azimuth) * at_r, 0.0, sin(azimuth) * at_r)
	var bw: float = 4.0
	var bh: float = 2.3
	var by: float = 1.35 + bh * 0.5

	for lx: float in [-bw * 0.36, bw * 0.36]:
		root.add_child(_as_box(foot + across * lx + Vector3(0.0, 0.68, 0.0),
			Vector3(0.16, 1.36, 0.16), frame))
	root.add_child(_as_box(foot + Vector3(0.0, by, 0.0),
		_as_span(inward, 0.16, bw + 0.18, bh + 0.18), frame))
	# Paper on BOTH faces, and the trace drawn on both — a record board that is blank from
	# behind is a record only for whoever stands on the right side of it.
	for face: float in [-1.0, 1.0]:
		var fz: Vector3 = inward * (0.085 * face)
		root.add_child(_as_box(foot + fz + Vector3(0.0, by, 0.0),
			_as_span(inward, 0.02, bw, bh), paper))
		var x0: float = -bw * 0.42
		var x1: float = bw * 0.42
		var y0: float = by - bh * 0.34
		var y1: float = by + bh * 0.34
		var pz: Vector3 = inward * (0.10 * face)
		root.add_child(_as_box(foot + pz + Vector3(0.0, y0, 0.0),
			_as_span(inward, 0.012, bw * 0.86, 0.03), rule))
		root.add_child(_as_box(foot + across * x0 + pz + Vector3(0.0, by, 0.0),
			_as_span(inward, 0.012, 0.03, bh * 0.70), rule))
		for i in range(4):
			root.add_child(_as_box(foot + pz + Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), 0.0),
				_as_span(inward, 0.010, bw * 0.86, 0.012), rule))
		# CLOSED FORM, not sampled from the running ride: a plot that came out different on
		# every launch would be noise wearing the costume of a record.
		var prev: Vector3 = Vector3.ZERO
		for i in range(33):
			var f: float = float(i) / 32.0
			var v: float = exp(-3.2 * f) * cos(f * 14.0)
			var p: Vector3 = foot + across * lerpf(x0, x1, f) + inward * (0.115 * face) \
				+ Vector3(0.0, lerpf(y0, y1, 0.5 + v * 0.44), 0.0)
			if i > 0:
				root.add_child(_as_link(prev, p, 0.028, ink))
			prev = p
		root.add_child(_as_sphere(prev, 0.055, ink))
	root.add_child(_as_label("CHART", foot + Vector3(0.0, by + bh * 0.5 + 0.3, 0.0), 26, AS_READ))


# ── VITRINE — the ride becomes an exhibit ─────────────────────────────────
func _as_vitrine(root: Node3D, half: float) -> void:
	var post: StandardMaterial3D = _as_mat(Color(0.30, 0.32, 0.36), 0.35, 0.8)
	var cap: StandardMaterial3D = _as_mat(AS_DARK, 0.7, 0.2)
	var top: float = obstacle_height + 2.6
	var c: Vector3 = Vector3(0.0, top * 0.5, 0.0)

	root.add_child(_as_box(c, Vector3(half * 2.0, top, half * 2.0),
		_as_glass(Color(0.72, 0.84, 0.95), 0.10)))
	for px: float in [-half, half]:
		for pz: float in [-half, half]:
			root.add_child(_as_box(Vector3(px, top * 0.5, pz), Vector3(0.22, top, 0.22), post))
	# Rails, not floors: a solid pan would hide the obstacle ring standing inside.
	for ry: float in [0.09, top]:
		for rz: float in [-half, half]:
			root.add_child(_as_box(Vector3(0.0, ry, rz), Vector3(half * 2.0, 0.16, 0.16), post))
		for rx: float in [-half, half]:
			root.add_child(_as_box(Vector3(rx, ry, 0.0), Vector3(0.16, 0.16, half * 2.0), post))
	root.add_child(_as_box(Vector3(0.0, top + 0.16, 0.0),
		Vector3(half * 2.0 + 0.35, 0.2, half * 2.0 + 0.35), cap))
	# Caption rail on the face nearest the default capture camera.
	var cap_pos: Vector3 = Vector3(cos(AS_AZIMUTH), 0.0, sin(AS_AZIMUTH)) * (half + 0.14)
	root.add_child(_as_box(cap_pos + Vector3(0.0, 0.62, 0.0), Vector3(2.4, 0.42, 0.08),
		_as_mat(Color(0.13, 0.14, 0.17), 0.8, 0.0)))
	root.add_child(_as_label("VITRINE", cap_pos + Vector3(0.0, 0.62, 0.10), 26,
		Color(0.90, 0.92, 0.97)))


# ── Small builders (prefixed so nothing in the ride can collide) ──────────
# A box sized along an inward direction: thickness along `dir`, `w` across it, `h` up.
func _as_span(dir: Vector3, thick: float, w: float, h: float) -> Vector3:
	var ax: float = absf(dir.x)
	var az: float = absf(dir.z)
	if ax >= az:
		return Vector3(thick, h, w)
	return Vector3(w, h, thick)


func _as_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _as_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _as_glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.08
	m.metallic = 0.2
	return m


func _as_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


func _as_sphere(p: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	return mi


# A cylinder spanning a to b, oriented by a hand-built Basis. look_at() needs the node in
# the tree already, and these are built before they are parented.
func _as_link(a: Vector3, b: Vector3, r: float, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var d: Vector3 = b - a
	var span: float = d.length()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(span, 0.002)
	mi.mesh = cm
	mi.material_override = m
	var dir: Vector3 = Vector3.UP
	if span > 0.0001:
		dir = d / span
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var fwd: Vector3 = right.cross(dir).normalized()
	mi.transform = Transform3D(Basis(right, dir, fwd), (a + b) * 0.5)
	return mi


func _as_label(text: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.008
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p
	return l
