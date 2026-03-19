extends Area3D

# @identity
# essence: on_area_entered -> set_shader_param("is_touched", true); after cooldown -> false — a reflective sphere that glows when touched, then cools down on a timer
# desire: to reach out in VR and touch the crystal ball — to see it light up in response and wait for it to reset, a minimal call-and-response between hand and object
# critical_parameter: cooldown_time — 3.5 seconds of glow before the sphere resets; the duration of magical contact
# triggers: Area3D.on_area_entered activates the shader's is_touched parameter; Timer.timeout deactivates it; material is duplicated on _ready for independent shader state
# emerges: the simplest possible VR interaction — touch and glow — creates a ritual quality when placed in F26_Portal_Chamber as the threshold object
# needs: [has] Area3D collision detection for VR hand interaction; [missing] no sliders, no buttons — the hand itself is the only control
# relationships: the focal artifact for F26_Portal_Chamber (portal/threshold space); a primitive interaction model that contrasts with complex multi-slider artifacts
# truth: the crystal ball does not predict — it responds; and the shortest possible feedback loop between body and light is already enough to feel presence

@export var cooldown_time: float = 3.5  # Cooldown time in seconds
var is_on_cooldown: bool = false  # To track whether the sphere is on cooldown

@onready var material = $MeshInstance3D.material_override
var cooldown_timer: Timer  # Timer for cooldown handling

func _ready():
	# Ensure the material is an instance for dynamic parameter changes
	if material:
		material = material.duplicate()
		$MeshInstance3D.material_override = material

	# Create a Timer node for the cooldown
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timeout"))
	add_child(cooldown_timer)

func _on_area_entered(_area: Area3D) -> void:
	if not is_on_cooldown:
		# Activate glowing color
		if material:
			material.set("shader_param/is_touched", true)

		# Start cooldown
		is_on_cooldown = true
		cooldown_timer.start()

func _on_cooldown_timeout():
	# Reset glowing effect after cooldown
	if material:
		material.set("shader_param/is_touched", false)

	# Reset cooldown flag
	is_on_cooldown = false
