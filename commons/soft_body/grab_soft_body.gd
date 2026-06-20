# Helper kit for NATIVE SoftBody3D artifacts that you can GRAB and POKE.
#
# Godot's SoftBody3D is physics-server simulated: it collides, inflates, drapes, and deforms when
# something pushes into it. Two interaction verbs this kit enables:
#   POKE  — the soft body's collision_mask includes the player layer (524288), so a hand or body
#           pushing into it dents it. soft_setup() wires that.
#   GRAB  — pin chosen vertices to a grabbable grab_cube handle; grab the handle and the soft body
#           stretches with it. pin_patch() + add_handle() wire that.
#
# Reuse (preload by path; no class_name to avoid collisions):
#   const GSB = preload("res://commons/soft_body/grab_soft_body.gd")
#   var sb := GSB.soft_setup(SoftBody3D.new(), {"mass": 2.0, "stiffness": 0.4, "pressure": 0.0})
#   sb.mesh = GSB.soft_box(0.5, 5)     # subdivided so it can actually deform
#   add_child(sb)
#   var h := GSB.add_handle(self, sb.to_global(Vector3(0.25, 0.25, 0.25)), 0.06, Color(0.95,0.6,0.3))
#   sb.call_deferred("set_meta", "_h", h)   # (any deferral) then pin once the body is in the tree:
#   call_deferred("_pin")  # in _pin(): GSB.pin_patch(sb, Vector3(0.25,0.25,0.25), h)
#
# Pinning MUST be deferred to after the SoftBody3D (and the attachment node) are inside the tree.
extends RefCounted

const GRAB_CUBE := preload("res://commons/interactables/grab_cube.tscn")

# Configure a SoftBody3D with the project's proven, poke-able defaults. Returns the same node.
static func soft_setup(sb: SoftBody3D, cfg: Dictionary = {}) -> SoftBody3D:
	sb.total_mass = float(cfg.get("mass", 2.0))
	sb.linear_stiffness = float(cfg.get("stiffness", 0.45))
	sb.pressure_coefficient = float(cfg.get("pressure", 0.0))
	sb.damping_coefficient = float(cfg.get("damping", 0.2))
	sb.simulation_precision = int(cfg.get("precision", 5))
	sb.collision_layer = 1
	sb.collision_mask = 1 | 524288          # world + PLAYER — so a hand/body poke deforms it
	if not sb.material_override:
		var col: Color = cfg.get("color", Color(0.86, 0.42, 0.5))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.5
		mat.subsurf_scatter_enabled = true
		mat.subsurf_scatter_strength = 0.6
		if bool(cfg.get("emissive", false)):
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 0.25
		sb.material_override = mat
	return sb

# A box mesh subdivided enough to deform like a soft body (a plain BoxMesh has only 8 verts = stiff).
static func soft_box(size: float, subdiv: int = 5) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = Vector3(size, size, size)
	bm.subdivide_width = subdiv
	bm.subdivide_height = subdiv
	bm.subdivide_depth = subdiv
	return bm

# A sphere mesh dense enough to deform; good for balloons, blobs, pets.
static func soft_sphere(radius: float, rings: int = 12, radial: int = 16) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.rings = rings
	sm.radial_segments = radial
	return sm

# Instance a grabbable grab_cube handle (a frozen Pickable RigidBody) at a WORLD position.
# Pinned soft-body vertices attached to it hang from it at rest and follow it when grabbed.
static func add_handle(parent: Node3D, world_pos: Vector3, size: float = 0.06,
		color: Color = Color(0.95, 0.6, 0.3)) -> Node3D:
	var h := GRAB_CUBE.instantiate()
	if "cube_size" in h:
		h.cube_size = size
	if "cube_color" in h:
		h.cube_color = color
	parent.add_child(h)
	h.global_position = world_pos
	return h

# Pin every vertex within grip_radius of local_pos (always at least the single nearest) to `attach`
# (a Node3D the vertices follow) — or to the world if attach is null. Call DEFERRED, after both the
# soft body and the attach node are in the tree. Returns how many vertices were pinned.
static func pin_patch(sb: SoftBody3D, local_pos: Vector3, attach: Node3D,
		grip_radius: float = 0.13) -> int:
	if not is_instance_valid(sb) or sb.mesh == null:
		return 0
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(sb.mesh, 0) != OK:
		return 0
	var nearest := -1
	var nd := INF
	for i in mdt.get_vertex_count():
		var d := mdt.get_vertex(i).distance_to(local_pos)
		if d < nd:
			nd = d
			nearest = i
	if nearest < 0:
		return 0
	var ap: NodePath = attach.get_path() if attach != null else NodePath()
	var cutoff: float = max(grip_radius, nd + 0.001)
	var n := 0
	for i in mdt.get_vertex_count():
		if mdt.get_vertex(i).distance_to(local_pos) <= cutoff:
			sb.set_point_pinned(i, true, ap)
			n += 1
	return n
