extends "res://algorithms/joint/shared/joint_demo_base.gd"

var leg: RigidBody3D

func _build_demo():
	var torso := create_box("Torso", Vector3(1.0, 2.0, 0.5), Vector3(0.0, 4.0, 0.0), 6.0, Color(0.35, 0.7, 0.6))
	leg = create_box("Leg", Vector3(0.6, 2.0, 0.5), Vector3(0.0, 1.8, 0.0), 4.0, Color(0.7, 0.4, 0.4))

	var joint := ConeTwistJoint3D.new()
	joint.name = "HipJoint"
	joint.node_a = torso.get_path()
	joint.node_b = leg.get_path()
	joint.position = Vector3(0.0, 3.0, 0.0)
	joint.swing_span = deg_to_rad(35.0)
	joint.twist_span = deg_to_rad(25.0)
	joint.bias = 0.3
	joint.softness = 0.8
	joint.relaxation = 1.0
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	add_label("Character Joint Hip", Vector3(0.0, 5.5, 2.5))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		leg.apply_impulse(Vector3(2.0, 0.0, 1.5))
