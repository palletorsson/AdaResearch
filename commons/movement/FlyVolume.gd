extends CharacterBody3D

@export var fly_speed: float = 5.0
@onready var xr_origin: Node3D = $XROrigin3D 
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D

func _physics_process(delta: float) -> void:
	# Check if the fly action is pressed
	if Input.is_action_pressed("fly"):
		# Get the forward direction from the headset (camera)
		var direction = -xr_camera.global_transform.basis.z
		# Zero out Y if you want horizontal flight only, 
		# or keep Y for true 3D flying.
		# direction.y = 0
		direction = direction.normalized()

		# Apply velocity
		velocity = direction * fly_speed
	else:
		# Stop moving when not flying
		velocity = Vector3.ZERO

	move_and_slide()
