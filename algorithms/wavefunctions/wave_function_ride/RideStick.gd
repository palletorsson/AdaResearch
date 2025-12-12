extends XRToolsClimbable

# Wave Parameters
@export var speed: float = 0.5 # Radians per second (angular speed)
@export var radius_x: float = 15.0 # Long axis of oval
@export var radius_z: float = 8.0 # Short axis of oval
@export var base_height: float = 2.0 
@export var start_delay: float = 0.0 # Seconds to wait before moving

# State
var time_accum: float = 0.0
var is_moving: bool = false
var start_angle: float = PI # Start at back of oval (-X)

func _ready():
	super()
	set_process(false) 
	set_physics_process(true)
	
	# Initialize position immediately (Stand Still at Start Point)
	_update_position(0.0)

func _physics_process(delta):
	time_accum += delta
	
	if time_accum < start_delay:
		# Standing Still phase
		return
		
	# Moving phase
	# Effective time since start of motion
	var move_time = time_accum - start_delay
	var angle = start_angle + (move_time * speed)
	
	_update_position(angle)

func _update_position(angle: float):
	# Parametric Oval:
	# X = cos(angle) * rX
	# Z = sin(angle) * rZ
	# Y = constant
	
	var tx = cos(angle) * radius_x
	var tz = sin(angle) * radius_z
	var ty = base_height
	
	global_position = Vector3(tx, ty, tz)

