# SystemsMusicListener.gd
# Path: res://commons/audio/airpoints/SystemsMusicListener.gd
# Agent: Agent-SynthesisEngineer (Agent B)
# Task: 020 - Implement AirPoint Listener Node
# Architecture: Designed by Agent-SoundArchitect (Agent A)
#
# Tracks an Air Point's position, velocity, and acceleration in 3D space
# Outputs modulation signals for audio synthesis
# Part of the Audio_AirPoints system inspired by Teropa's Systems Music (2016)
# Renamed to avoid conflict with existing AirPointListener class

extends Node3D
class_name SystemsMusicListener

## The Air Point (Node3D) to track. Set this in the editor or via code.
@export var target_air_point: Node3D

## Reference position for distance calculations (usually the listener/camera)
@export var reference_position: Node3D

## Maximum distance for normalization (meters)
@export var max_distance: float = 10.0

## Update rate in Hz (default 60 Hz as per architecture)
@export var update_rate: float = 60.0

# === OUTPUT SIGNALS ===
# These are the modulation signals that drive audio synthesis

## Emitted when modulation parameters update
signal modulation_updated(params: Dictionary)

# === TRACKED PARAMETERS ===

## Distance from reference position to Air Point (meters)
var distance: float = 0.0

## Velocity of the Air Point (m/s)
var velocity: Vector3 = Vector3.ZERO

## Speed (magnitude of velocity) in m/s
var speed: float = 0.0

## Acceleration of the Air Point (m/s²)
var acceleration: Vector3 = Vector3.ZERO

## Direction vector from reference to Air Point (normalized)
var direction_vector: Vector3 = Vector3.ZERO

## Proximity factor (0-1, where 1 = very close, 0 = far)
var proximity_factor: float = 0.0

# === INTERNAL STATE ===

var _previous_position: Vector3 = Vector3.ZERO
var _previous_velocity: Vector3 = Vector3.ZERO
var _update_timer: float = 0.0
var _delta_accumulator: float = 0.0
var _is_initialized: bool = false


func _ready() -> void:
	# Initialize reference position if not set
	if reference_position == null:
		# Try to find the camera
		var camera = get_viewport().get_camera_3d()
		if camera:
			reference_position = camera
		else:
			# Fall back to world origin
			push_warning("AirPointListener: No reference_position set and no camera found. Using world origin.")
	
	# Initialize tracking
	if target_air_point:
		_previous_position = target_air_point.global_position
		_is_initialized = true
	
	print("SystemsMusicListener: Ready")
	print("  Target Air Point: ", target_air_point)
	print("  Reference Position: ", reference_position)
	print("  Max Distance: %.1f m" % max_distance)
	print("  Update Rate: %.0f Hz" % update_rate)


func _process(delta: float) -> void:
	if not target_air_point or not reference_position:
		return
	
	# Accumulate delta for fixed update rate
	_delta_accumulator += delta
	_update_timer += delta
	
	# Update at specified rate (default 60 Hz)
	var update_interval = 1.0 / update_rate
	if _update_timer >= update_interval:
		_update_parameters(_delta_accumulator)
		_delta_accumulator = 0.0
		_update_timer = 0.0


func _update_parameters(delta: float) -> void:
	if not _is_initialized:
		_previous_position = target_air_point.global_position
		_is_initialized = true
		return
	
	# === POSITION & DISTANCE ===
	var current_position = target_air_point.global_position
	var ref_pos = reference_position.global_position
	
	direction_vector = (current_position - ref_pos).normalized()
	distance = current_position.distance_to(ref_pos)
	proximity_factor = 1.0 - clamp(distance / max_distance, 0.0, 1.0)
	
	# === VELOCITY ===
	if delta > 0.0:
		velocity = (current_position - _previous_position) / delta
		speed = velocity.length()
	
	# === ACCELERATION ===
	if delta > 0.0:
		acceleration = (velocity - _previous_velocity) / delta
	
	# === UPDATE STATE ===
	_previous_position = current_position
	_previous_velocity = velocity
	
	# === EMIT MODULATION SIGNAL ===
	var params = {
		"distance": distance,
		"velocity": velocity,
		"speed": speed,
		"acceleration": acceleration,
		"direction_vector": direction_vector,
		"proximity_factor": proximity_factor,
		"position": current_position,
		"reference_position": ref_pos
	}
	
	modulation_updated.emit(params)


## Get current modulation parameters as a dictionary
func get_modulation_params() -> Dictionary:
	return {
		"distance": distance,
		"velocity": velocity,
		"speed": speed,
		"acceleration": acceleration,
		"direction_vector": direction_vector,
		"proximity_factor": proximity_factor,
		"position": target_air_point.global_position if target_air_point else Vector3.ZERO,
		"reference_position": reference_position.global_position if reference_position else Vector3.ZERO
	}


## Set the target Air Point to track
func set_target(new_target: Node3D) -> void:
	target_air_point = new_target
	if target_air_point:
		_previous_position = target_air_point.global_position
		_is_initialized = true


## Set the reference position for distance calculations
func set_reference(new_reference: Node3D) -> void:
	reference_position = new_reference
