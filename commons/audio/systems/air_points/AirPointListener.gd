extends Node3D
class_name AirPointListener

## AirPointListener
## Tracks an Air Point in 3D space and generates modulation signals for audio synthesis.
## Part of Audio_AirPoints System Phase 1.

# Target to track (The Air Point)
@export var target_path: NodePath
var target_node: Node3D

# Tracking Data (Read these from the Oscillator)
var distance: float = 0.0
var speed: float = 0.0
var direction: Vector3 = Vector3.FORWARD
var proximity: float = 0.0 # 0.0 to 1.0 (normalized inverse distance)
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO

# Configuration
@export var max_distance: float = 10.0 # Distance where proximity becomes 0
@export var smoothing: float = 0.1 # Smoothing factor for values (0.0 - 1.0)

# Internal state
var _last_target_position: Vector3
var _last_velocity: Vector3
var _initialized: bool = false

func _ready():
	if target_path:
		target_node = get_node(target_path)
		if target_node:
			_last_target_position = target_node.global_position
			_initialized = true

func set_target(node: Node3D):
	target_node = node
	if target_node:
		_last_target_position = target_node.global_position
		_initialized = true

func _process(delta: float):
	if not target_node or not _initialized:
		return
		
	# current_target_pos is the global position of the Air Point
	var current_target_pos = target_node.global_position
	
	# my_pos is the position of the Listener (usually attached to Camera or Player)
	var my_pos = global_position
	
	# 1. Calculate Distance Vector
	var dist_vec = current_target_pos - my_pos
	var new_distance = dist_vec.length()
	
	# Smooth the distance
	distance = lerp(distance, new_distance, smoothing)
	
	# 2. Calculate Direction
	if new_distance > 0.001:
		direction = dist_vec / new_distance
	
	# 3. Calculate Target Velocity (World Space)
	# We track how fast the point is moving in the world, not relative to us
	# (though relative velocity could be useful for doppler, spec says "speed")
	if delta > 0:
		var raw_velocity = (current_target_pos - _last_target_position) / delta
		velocity = velocity.lerp(raw_velocity, smoothing)
		speed = velocity.length()
		
		# 4. Calculate Acceleration
		var raw_accel = (velocity - _last_velocity) / delta
		acceleration = acceleration.lerp(raw_accel, smoothing)
	
	# 5. Calculate Proximity (Inverse Square Law approximation or Linear?)
	# Spec says: map(proximity, 0-1, 0-0.7). Proximity is usually 1 at 0 dist.
	# We'll use linear falloff for predictability in Phase 1, clamped.
	proximity = clamp(1.0 - (distance / max_distance), 0.0, 1.0)
	
	# Store history
	_last_target_position = current_target_pos
	_last_velocity = velocity

