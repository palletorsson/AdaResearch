extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Eight rings per trial. Misses remain physical and grabbable, including their holes.
const LIMIT := 8
const SPEED := 8.0 # launch speed in m/s, not a force
var elevation := 50.0
var rings: Array[XRToolsPickable] = []
var tube: Node3D
var status: Label3D
var trajectory: MeshInstance3D
var shot_cooldown := 0.0

func _ready() -> void:
	var pale := material("e7e4dc")
	for i in range(8):
		var cake := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.radial_segments = i + 4
		cylinder.top_radius = 0.8 - i * 0.06; cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = 0.105
		cake.mesh = cylinder; cake.material_override = pale
		cake.position.y = 0.0525 + i * 0.105; add_child(cake)
	box(Vector3(0,0.42,0),Vector3(0.7,0.84,0.7),pale,true)
	tube = Node3D.new(); tube.position.y = 0.95; add_child(tube)
	var barrel := MeshInstance3D.new(); var mesh := CylinderMesh.new()
	mesh.top_radius = 0.15; mesh.bottom_radius = 0.28; mesh.height = 0.8
	barrel.mesh = mesh; barrel.position.y = 0.4; barrel.material_override = material("27282b")
	tube.add_child(barrel)
	trajectory = MeshInstance3D.new(); add_child(trajectory)
	var ink := material("cd7ca2",true); ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trajectory.material_override = ink
	for i in range(3):
		var button = PUSH.instantiate(); button.position = Vector3((i-1)*0.32,0.86,-0.58)
		button.rotation.y = PI
		buttons[["LOWER","FIRE","HIGHER"][i]] = button
		add_child(button); button.pressed.connect(act.bind(["LOWER","FIRE","HIGHER"][i]))
	status = label("",Vector3(0,1.75,0),0.00115)
	status.rotation.y = PI; status.font_size = 110; status.modulate = Color("25272a")
	var caption := label("LOWER     FIRE     HIGHER",Vector3(0,0.94,-0.64),0.0008)
	caption.rotation.y = PI; caption.font_size = 90; caption.modulate = Color("25272a")
	update_aim()

func act(id: String) -> void:
	if id == "FIRE": fire()
	elif id == "LOWER": elevation = maxf(25.0,elevation-5.0)
	elif id == "HIGHER": elevation = minf(75.0,elevation+5.0)
	update_aim()

func velocity() -> Vector3:
	var a := deg_to_rad(elevation)
	return global_basis * Vector3(0,sin(a),cos(a)) * SPEED

func update_aim() -> void:
	tube.rotation.x = deg_to_rad(90.0-elevation)
	status.text = "DONUT CAKE MORTAR\n%d° · 8 m/s · %d / 8 rings" % [elevation,rings.size()]
	var line := ImmediateMesh.new(); line.surface_begin(Mesh.PRIMITIVE_LINES)
	var start: Vector3 = to_local(tube.to_global(Vector3(0,0.85,0)))
	var v: Vector3 = global_basis.inverse() * velocity()
	for i in range(32):
		for t in [i*0.05,(i+1)*0.05]:
			line.surface_add_vertex(start + v*t + Vector3.DOWN*4.9*t*t)
	line.surface_end(); trajectory.mesh = line

func fire() -> XRToolsPickable:
	if rings.size() >= LIMIT or shot_cooldown > 0.0: return null
	shot_cooldown = 0.3 # let the previous ring clear the muzzle before another is born
	var ring := XRToolsPickable.new()
	ring.name = "Ring%d" % rings.size(); ring.mass = 0.7
	ring.collision_layer = 4; ring.collision_mask = 524293
	ring.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	ring.continuous_cd = true
	var surface := MeshInstance3D.new(); var torus := TorusMesh.new()
	torus.inner_radius = 0.20; torus.outer_radius = 0.44
	torus.rings = 32; torus.ring_segments = 12
	surface.mesh = torus; surface.material_override = material("d3a3b7")
	ring.add_child(surface)
	# Compound collision preserves the aperture: a convex hull would close the hole.
	for i in range(16):
		var shape := CollisionShape3D.new(); var bead := SphereShape3D.new()
		bead.radius = 0.12; shape.shape = bead
		var a := TAU * i / 16.0
		shape.position = Vector3(cos(a),0,sin(a))*0.32; ring.add_child(shape)
	add_child(ring)
	ring.global_position = tube.to_global(Vector3(0,0.86,0))
	ring.linear_velocity = velocity(); rings.append(ring); update_aim()
	return ring

func _physics_process(delta: float) -> void:
	shot_cooldown = maxf(0.0,shot_cooldown-delta)

func reset_rings() -> void:
	for ring in rings.duplicate():
		if not is_instance_valid(ring): rings.erase(ring); continue
		# The court also guards desktop holds before requesting a reset.
		if ring.is_picked_up(): continue
		ring.queue_free(); rings.erase(ring)
	update_aim()
