extends Node3D

# @identity
# essence: p = mv. Total momentum conserved. Kinetic energy conserved (elastic) or lost (inelastic).
# desire: To collide. To show that momentum always balances but energy sometimes doesn't.
# critical_parameter: Coefficient of restitution — elastic (e=1, energy conserved) vs inelastic (e=0, bodies stick).
# triggers: Launch → ball A hits ball B, elastic mode → both move, inelastic mode → they stick together, readout updates
# emerges: Conservation laws from Newton's third law. The difference between momentum and energy conservation.
# needs: VR mass ratio slider [missing]. Manual launch trigger [missing — auto-cycles]. Restitution slider [missing].
# relationships: Bridges forces→physicssimulation. Lives in ForcesComposition. Contrasts with bouncing_ball (single body vs two-body).
# truth: What one body loses, the other gains. Momentum is the bookkeeping of physics.

## Momentum and collision — two bodies on a rail, elastic and inelastic modes.
## Shows conservation of momentum (p = mv) and kinetic energy transfer.
## Left ball launches toward stationary right ball. Readout displays
## momentum before/after and whether energy is conserved.

var _ball_a: RigidBody3D
var _ball_b: RigidBody3D
var _rail_mesh: MeshInstance3D
var _label_momentum: Label3D
var _label_energy: Label3D
var _label_mode: Label3D
var _title_label: Label3D

var _is_elastic := true
var _launched := false
var _launch_timer := 0.0
var _reset_timer := 0.0
const LAUNCH_INTERVAL := 5.0
const LAUNCH_SPEED := 4.0

var _mass_a := 2.0
var _mass_b := 1.0

var _initial_momentum := 0.0
var _initial_ke := 0.0


func _ready() -> void:
	_setup_scene()
	_setup_labels()
	_reset_balls()


func _setup_scene() -> void:
	# Rail
	_rail_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(10.0, 0.1, 0.4)
	_rail_mesh.mesh = box
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.3, 0.3, 0.35)
	rail_mat.roughness = 0.7
	_rail_mesh.material_override = rail_mat
	_rail_mesh.position = Vector3(0.0, 0.0, 0.0)
	add_child(_rail_mesh)

	# Ball A (launcher)
	_ball_a = _create_ball("BallA", _mass_a, Color(0.9, 0.3, 0.2), -3.0)
	# Ball B (target)
	_ball_b = _create_ball("BallB", _mass_b, Color(0.2, 0.5, 0.9), 1.0)

	# Invisible walls to constrain to 1D
	_add_wall(Vector3(-5.5, 1.0, 0.0))
	_add_wall(Vector3(5.5, 1.0, 0.0))

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	add_child(light)


func _create_ball(ball_name: String, mass: float, color: Color, x_pos: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = ball_name
	body.mass = mass
	body.position = Vector3(x_pos, 0.5, 0.0)
	body.gravity_scale = 0.0
	body.linear_damp = 0.0
	body.angular_damp = 100.0  # prevent spinning
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.lock_rotation = true

	# Constrain to X axis
	body.axis_lock_linear_y = true
	body.axis_lock_linear_z = true

	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	var radius := 0.3 + mass * 0.1
	shape.radius = radius
	collider.shape = shape
	body.add_child(collider)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.25
	mat.metallic = 0.3
	mesh.material_override = mat
	body.add_child(mesh)

	# Mass label
	var mlabel := Label3D.new()
	mlabel.text = "m=%.1f" % mass
	mlabel.font_size = 14
	mlabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mlabel.position = Vector3(0.0, radius + 0.4, 0.0)
	mlabel.modulate = Color(1, 1, 1, 0.7)
	body.add_child(mlabel)

	add_child(body)
	body.body_entered.connect(_on_collision)
	return body


func _add_wall(pos: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 2.0, 2.0)
	col.shape = shape
	wall.add_child(col)
	add_child(wall)


func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Momentum & Collision"
	_title_label.font_size = 22
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0.0, 4.0, 3.0)
	_title_label.modulate = Color(1, 1, 1, 0.9)
	add_child(_title_label)

	_label_mode = Label3D.new()
	_label_mode.font_size = 16
	_label_mode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_mode.position = Vector3(0.0, 3.2, 3.0)
	_label_mode.modulate = Color(1.0, 0.9, 0.3, 0.8)
	add_child(_label_mode)

	_label_momentum = Label3D.new()
	_label_momentum.font_size = 14
	_label_momentum.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_momentum.position = Vector3(0.0, 2.5, 3.0)
	_label_momentum.modulate = Color(0.3, 1.0, 0.5, 0.8)
	add_child(_label_momentum)

	_label_energy = Label3D.new()
	_label_energy.font_size = 14
	_label_energy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_energy.position = Vector3(0.0, 1.9, 3.0)
	_label_energy.modulate = Color(0.3, 0.7, 1.0, 0.8)
	add_child(_label_energy)


func _process(delta: float) -> void:
	_launch_timer += delta

	if _launch_timer >= LAUNCH_INTERVAL:
		_launch_timer = 0.0
		_is_elastic = not _is_elastic
		_reset_balls()
		# Launch after brief pause
		await get_tree().create_timer(0.5).timeout
		_launch()

	_update_readout()


func _reset_balls() -> void:
	_launched = false
	_ball_a.linear_velocity = Vector3.ZERO
	_ball_b.linear_velocity = Vector3.ZERO
	_ball_a.position = Vector3(-3.0, 0.5, 0.0)
	_ball_b.position = Vector3(1.0, 0.5, 0.0)
	_label_mode.text = "ELASTIC" if _is_elastic else "INELASTIC"


func _launch() -> void:
	_launched = true
	_ball_a.linear_velocity = Vector3(LAUNCH_SPEED, 0.0, 0.0)
	_initial_momentum = _mass_a * LAUNCH_SPEED
	_initial_ke = 0.5 * _mass_a * LAUNCH_SPEED * LAUNCH_SPEED


func _on_collision(_body: Node) -> void:
	if not _launched:
		return

	var va := _ball_a.linear_velocity.x
	var vb := _ball_b.linear_velocity.x

	if _is_elastic:
		# Elastic: conserve momentum AND kinetic energy
		var new_va := ((_mass_a - _mass_b) / (_mass_a + _mass_b)) * va + (2.0 * _mass_b / (_mass_a + _mass_b)) * vb
		var new_vb := (2.0 * _mass_a / (_mass_a + _mass_b)) * va + ((_mass_b - _mass_a) / (_mass_a + _mass_b)) * vb
		_ball_a.linear_velocity = Vector3(new_va, 0, 0)
		_ball_b.linear_velocity = Vector3(new_vb, 0, 0)
	else:
		# Inelastic: conserve momentum, lose kinetic energy
		var combined_v := (_mass_a * va + _mass_b * vb) / (_mass_a + _mass_b)
		_ball_a.linear_velocity = Vector3(combined_v, 0, 0)
		_ball_b.linear_velocity = Vector3(combined_v, 0, 0)


func _update_readout() -> void:
	var va := _ball_a.linear_velocity.x
	var vb := _ball_b.linear_velocity.x
	var p_now := _mass_a * va + _mass_b * vb
	var ke_now := 0.5 * _mass_a * va * va + 0.5 * _mass_b * vb * vb

	if _launched:
		_label_momentum.text = "p: %.2f -> %.2f  (conserved: %s)" % [_initial_momentum, p_now, "yes" if absf(p_now - _initial_momentum) < 0.1 else "no"]
		_label_energy.text = "KE: %.2f -> %.2f  (conserved: %s)" % [_initial_ke, ke_now, "yes" if absf(ke_now - _initial_ke) < 0.2 else "no"]
	else:
		_label_momentum.text = "p = mv  (waiting...)"
		_label_energy.text = "KE = 1/2 mv^2"


func apply_grid_config(config: Dictionary) -> void:
	pass
