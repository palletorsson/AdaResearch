extends Node3D

@export var demo_mode: bool = true
@export var speed: float = 1.0
@export var radius: float = 0.5

@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

var _time: float = 0.0
var _initial_left_pos: Vector3
var _initial_right_pos: Vector3



const LEFT_SPIRAL_RADIUS = 0.3
const RIGHT_CONE_RADIUS = 0.4
const HIP_ROTATION = 0.1
const NOISE_SCALE = 0.05

var _last_left_base: Vector3
var _last_right_base: Vector3

func _process(delta):
	if not demo_mode:
		return
		
	_time += delta * speed
	
	# 1. Calculate Base Positions (The "Intention")
	# We move the centers closer to allow crossing (from +/- 0.5 to +/- 0.2)
	var left_center = _initial_left_pos + Vector3(0.3, 0, 0) 
	var right_center = _initial_right_pos - Vector3(0.3, 0, 0)
	
	# William Forsythe Diagonal Sweep + Arm Cone Rotation
	# LEFT HAND
	var ls_x = LEFT_SPIRAL_RADIUS * sin(_time * 4.2)
	var ls_z = LEFT_SPIRAL_RADIUS * cos(_time * 4.2)
	var ls_y = 0.14 * sin(_time * 1.3) + 0.20 * sin(_time * 0.5) * 2.0
	# Add a large crossover sweep
	ls_x += 0.4 * sin(_time * 0.7) 
	
	var left_target = left_center + Vector3(ls_x, ls_y, ls_z)

	# RIGHT HAND
	var rs_x = RIGHT_CONE_RADIUS * sin(_time * 1.8)
	var rs_z = RIGHT_CONE_RADIUS * cos(_time * 1.8)
	var rs_y = 0.28 * sin(_time * 0.9) + 0.30 * sin(_time * 0.5) * 2.0
	# Add a large crossover sweep (out of phase)
	rs_x -= 0.4 * sin(_time * 0.8 + 1.0)
	
	var right_target = right_center + Vector3(rs_x, rs_y, rs_z)
	
	# 2. Calculate "Force" (Velocity) and "Energy" (Force * Distance from Center)
	if _last_left_base == Vector3.ZERO:
		_last_left_base = left_target
		_last_right_base = right_target
		
	var left_speed = left_target.distance_to(_last_left_base) / delta
	var right_speed = right_target.distance_to(_last_right_base) / delta
	
	_last_left_base = left_target
	_last_right_base = right_target
	
	# Calculate distance from the shared center (0, 1.5, 0) approx
	# We use the local center relative to the initial positions
	var center_point = (_initial_left_pos + _initial_right_pos) / 2.0
	var left_dist = left_target.distance_to(center_point)
	var right_dist = right_target.distance_to(center_point)
	
	# Energy = Speed * Distance (Angular Momentum-ish)
	var left_energy = left_speed * left_dist
	var right_energy = right_speed * right_dist
	
	# 3. Apply Cross-Coupled Flow (Smooth Circular Perturbation)
	# "Fuzziness must be round" -> Circular wobble
	# "Flow" -> Continuous sine waves
	
	var wobble_freq = 12.0 # Fast wobble
	
	# Left gets perturbed by Right's energy
	var l_wobble_angle = _time * wobble_freq
	var left_perturbation = Vector3(
		cos(l_wobble_angle),
		sin(l_wobble_angle),
		0
	) * right_energy * NOISE_SCALE
	
	# Right gets perturbed by Left's energy (offset phase)
	var r_wobble_angle = _time * wobble_freq + PI
	var right_perturbation = Vector3(
		cos(r_wobble_angle),
		sin(r_wobble_angle),
		0
	) * left_energy * NOISE_SCALE
	
	if left_hand:
		left_hand.position = left_target + left_perturbation
		
	if right_hand:
		right_hand.position = right_target + right_perturbation

func _ready():
	if left_hand:
		_initial_left_pos = left_hand.position
	if right_hand:
		_initial_right_pos = right_hand.position
