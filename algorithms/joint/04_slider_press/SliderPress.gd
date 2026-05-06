extends "res://algorithms/joint/shared/joint_demo_base.gd"

# @identity
# essence: SliderJoint3D — 1 translational DOF. The opposite of a hinge. Linear motion, no spin.
# desire: To slide. To show that constraining rotation while freeing translation builds pistons, drawers, rails.
# critical_parameter: Motor speed and force — how fast and how hard the piston drives.
# triggers: Speed slider → piston oscillates faster/slower, force slider → piston pushes harder against resistance
# emerges: Mechanical rhythm from oscillating motor. The feel of constrained linear motion.
# needs: VR speed slider [has], VR force slider [has], position/velocity labels [has]. Could use: adjustable joint limits.
# relationships: Contrasts with HingeCrank (rotation vs translation). Pairs with SpringSuspension in same map. Feeds into constraints artifact.
# truth: Sliders translate without rotating. The opposite constraint to the hinge. Together they build machines.

## Slider Joint Press — linear motion along one axis.
##
## A piston slides back and forth on a rail, constrained by SliderJoint3D.
## The motor drives it with controllable force. VR slider controls motor speed.
## Labels show position, velocity, and the constraint: 1 translational DOF.
##
## The opposite of a hinge: hinge allows rotation, slider allows translation.

var slider_joint: SliderJoint3D
var piston: RigidBody3D
var frame_body: StaticBody3D
var motor_speed := 2.0
var motor_impulse := 30.0
var _position_label: Label3D
var _velocity_label: Label3D
var _control_panel: Node3D


func _build_demo() -> void:
	# Static frame (the rail housing)
	frame_body = create_static_box("Frame", Vector3(0.6, 1.5, 4.0), Vector3(0.0, 1.5, 0.0), Color(0.3, 0.3, 0.35))

	# Rail tracks (visual only)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.5, 0.5, 0.55)
	rail_mat.metallic = 0.6
	rail_mat.roughness = 0.3
	for side in [-0.35, 0.35]:
		var rail := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 4.0
		rail.mesh = cyl
		rail.material_override = rail_mat
		rail.position = Vector3(side, 1.5, 0.0)
		rail.rotation = Vector3(deg_to_rad(90), 0, 0)
		add_child(rail)

	# Piston (the moving part)
	piston = create_box("Piston", Vector3(0.5, 0.8, 0.8), Vector3(0.0, 1.5, 0.0), 3.0, Color(0.85, 0.7, 0.2))
	piston.linear_damp = 0.5
	piston.angular_damp = 10.0

	# Slider joint — constrains to Z axis
	slider_joint = SliderJoint3D.new()
	slider_joint.name = "PressSlider"
	slider_joint.node_a = frame_body.get_path()
	slider_joint.node_b = piston.get_path()
	slider_joint.position = Vector3(0.0, 1.5, 0.0)
	# Rotate joint so linear axis is along Z (forward/back)
	slider_joint.rotation = Vector3(0, 0, deg_to_rad(90))
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -1.5)
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 1.5)
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_MOTION_SOFTNESS, 1.0)
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_MOTION_DAMPING, 0.5)
	slider_joint.set_exclude_nodes_from_collision(true)
	add_child(slider_joint)

	# Limit markers (visual)
	for z in [-1.5, 1.5]:
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.3, 0.1)
		marker.mesh = box
		var mmat := StandardMaterial3D.new()
		mmat.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
		mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override = mmat
		marker.position = Vector3(0.0, 1.5, z)
		add_child(marker)

	# Labels
	add_label("Slider Joint — 1 Translational DOF", Vector3(0.0, 4.0, 3.0))

	var constraint_label := Label3D.new()
	constraint_label.text = "Allows: translation along one axis\nForbids: rotation, lateral motion"
	constraint_label.font_size = 12
	constraint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	constraint_label.position = Vector3(0.0, 3.3, 3.0)
	constraint_label.modulate = Color(1, 1, 1, 0.6)
	add_child(constraint_label)

	_position_label = Label3D.new()
	_position_label.font_size = 14
	_position_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_position_label.position = Vector3(0.0, 2.8, 3.0)
	_position_label.modulate = Color(0.3, 1.0, 0.5, 0.8)
	add_child(_position_label)

	_velocity_label = Label3D.new()
	_velocity_label.font_size = 12
	_velocity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_velocity_label.position = Vector3(0.0, 2.3, 3.0)
	_velocity_label.modulate = Color(0.3, 0.7, 1.0, 0.7)
	add_child(_velocity_label)

	# VR control panel
	_setup_controls()

	set_process(true)
	set_physics_process(true)


func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		2, ["MOTOR SPEED", "MOTOR FORCE"],
		[motor_speed / 6.0, (motor_impulse - 5.0) / 55.0]
	)
	_control_panel.position = Vector3(2.5, 2.0, 0.0)
	_control_panel.rotation_degrees = Vector3(0, -90, 0)
	add_child(_control_panel)

	var speed_slider: Node = _control_panel.get_node_or_null("Param_0")
	var force_slider: Node = _control_panel.get_node_or_null("Param_1")

	if speed_slider and speed_slider.has_signal("slider_moved"):
		speed_slider.slider_moved.connect(func(_pos):
			if speed_slider.has_method("get_normalized_value"):
				motor_speed = speed_slider.get_normalized_value() * 6.0
		)
	if force_slider and force_slider.has_signal("slider_moved"):
		force_slider.slider_moved.connect(func(_pos):
			if force_slider.has_method("get_normalized_value"):
				motor_impulse = 5.0 + force_slider.get_normalized_value() * 55.0
		)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(piston):
		return

	# Oscillating motor: drives piston back and forth
	var t := Time.get_ticks_msec() * 0.001
	var target_vel := motor_speed * sin(t * 1.5)

	# Apply force toward target velocity
	var current_vel := piston.linear_velocity.z
	var force := (target_vel - current_vel) * motor_impulse
	piston.apply_central_force(Vector3(0, 0, force) * delta * 60.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(piston):
		return

	var pos := piston.position.z
	var vel := piston.linear_velocity.z
	_position_label.text = "position: %.2f (limits: -1.5 to 1.5)" % pos
	_velocity_label.text = "velocity: %.2f  motor: %.1f" % [vel, motor_speed]


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
